// Package bake runs docker buildx bake for the Bakery targets.
package bake

import (
	"bytes"
	"context"
	"encoding/json"
	"errors"
	"fmt"
	"io"
	"os"
	"os/exec"
	"path/filepath"
	"regexp"
	"sort"
	"strings"

	"github.com/Alfresco/alfresco-dockerfiles-bakery/internal/artifacts"
	"github.com/Alfresco/alfresco-dockerfiles-bakery/internal/clean"
)

type Options struct {
	Root       string
	ACSVersion string
	APSVersion string
	Registry   string
	Namespace  string
	Tag        string
	NoCache    bool
	NoSBOM     bool
	Provenance string
	Yes        bool
	Grype      bool
	GrypeOpts  GrypeOptions
	Stdin      io.Reader
	Stdout     io.Writer
	Stderr     io.Writer
}

type GrypeOptions struct {
	Args         []string
	OutputDir    string
	OutputFormat string
}

// Target is a buildable entry point, one per bake group.
type Target struct {
	Name        string
	Description string
	// fetch lists the fetch targets (directories or globs) the images need.
	// Nil means the whole repository.
	fetch func(o Options) []string
	// bake is the bake target or group; empty bakes the default group.
	bake string
	// before lists targets built first: ats needs the tengines images.
	before []string
}

func dirs(d ...string) func(Options) []string { return func(Options) []string { return d } }

var targets = []Target{
	{Name: "all", Description: "Build all images", bake: ""},
	{Name: "enterprise", Description: "Build enterprise images", bake: "enterprise"},
	{Name: "community", Description: "Build community images", bake: "community"},
	{Name: "adf_apps", Description: "Build ADF Apps images", fetch: dirs("adf-apps"), bake: "adf_apps"},
	{Name: "aps", Description: "Build Alfresco Process Services images", bake: "aps",
		fetch: func(o Options) []string { return []string{"aps/**/artifacts-" + o.APSVersion + ".yaml"} }},
	{Name: "ats", Description: "Build Transform Service images", fetch: dirs("ats", "tengine"), bake: "ats", before: []string{"tengines"}},
	{Name: "audit_storage", Description: "Build Audit Storage images", fetch: dirs("audit-storage"), bake: "audit_storage"},
	{Name: "connectors", Description: "Build MS365/Teams Connectors images", fetch: dirs("connector"), bake: "connectors"},
	{Name: "cic_connector", Description: "Build CIC Connector images", fetch: dirs("cic-connector"), bake: "cic_connector"},
	{Name: "repository", Description: "Build Repository image", fetch: dirs("repository"), bake: "repository"},
	{Name: "search_batch_indexing", Description: "Build Search Community Batch Indexing image", fetch: dirs("search/community"), bake: "search_batch_indexing"},
	{Name: "search_enterprise", Description: "Build Search Enterprise images", fetch: dirs("search/enterprise"), bake: "search_enterprise"},
	{Name: "search_service", Description: "Build Search Service images", fetch: dirs("search/service"), bake: "search_service"},
	{Name: "share", Description: "Build Share images", fetch: dirs("share"), bake: "share"},
	{Name: "sync", Description: "Build Sync Service images", fetch: dirs("sync"), bake: "sync"},
	{Name: "tengines", Description: "Build Transform Engine images", fetch: dirs("tengine"), bake: "tengines"},
}

func Targets() []Target { return targets }

func lookup(name string) (Target, bool) {
	for _, t := range targets {
		if t.Name == name {
			return t, true
		}
	}
	return Target{}, false
}

func targetNames() string {
	names := make([]string, len(targets))
	for i, t := range targets {
		names[i] = t.Name
	}
	return strings.Join(names, ", ")
}

func (o Options) pushing() bool { return o.Registry != "" && o.Registry != "localhost" }

func (o Options) env(versions string) []string {
	env := append(os.Environ(),
		"ACS_VERSION="+o.ACSVersion,
		"APS_VERSION="+o.APSVersion,
		"ARTIFACT_VERSIONS="+versions,
	)
	for k, v := range map[string]string{"REGISTRY": o.Registry, "REGISTRY_NAMESPACE": o.Namespace, "TAG": o.Tag} {
		if v != "" {
			env = append(env, k+"="+v)
		}
	}
	return env
}

func (o Options) command(ctx context.Context, env []string, name string, args ...string) *exec.Cmd {
	cmd := exec.CommandContext(ctx, name, args...)
	cmd.Dir, cmd.Env = o.Root, env
	cmd.Stdout, cmd.Stderr = o.Stdout, o.Stderr
	return cmd
}

func requireBuildx(ctx context.Context) error {
	if err := exec.CommandContext(ctx, "docker", "buildx", "version").Run(); err != nil {
		return fmt.Errorf("docker with the buildx plugin is required (docker buildx version: %v)", err)
	}
	return nil
}

func requireGrype() error {
	if _, err := exec.LookPath("grype"); err != nil {
		return errors.New("grype is required but it's not installed. See https://github.com/anchore/grype/blob/main/README.md#installation")
	}
	return nil
}

func valueOr(v, def string) string {
	if v == "" {
		return def
	}
	return v
}

// confirmPush logs in to the registry and asks before pushing anywhere but
// the local image store.
func confirmPush(ctx context.Context, o Options) error {
	switch {
	case o.Registry == "localhost":
		fmt.Fprintln(o.Stdout, "REGISTRY environment variable is set to localhost. Images will be build & loaded locally")
		return nil
	case o.Registry == "":
		fmt.Fprintln(o.Stdout, "REGISTRY environment variable is not set. Images will be build & loaded locally")
		return nil
	}
	fmt.Fprintln(o.Stdout, "Checking for REGISTRY authentication")
	login := exec.CommandContext(ctx, "docker", "login", o.Registry)
	if f, ok := o.Stdin.(*os.File); ok {
		login.Stdin = f
	}
	login.Stdout, login.Stderr = o.Stdout, o.Stderr
	if err := login.Run(); err != nil {
		fmt.Fprintf(o.Stdout, "Failed to login to %s. Stopping build.\n", o.Registry)
		return fmt.Errorf("docker login %s failed", o.Registry)
	}
	banner := strings.Repeat("!", 69)
	fmt.Fprintf(o.Stdout, `%s
Images will be pushed to %s/%s
Do make sure this location is safe to push to!
In particular, make sure you are not pushing to a public registry
without paying attention to the security & legal implications.
If you are not sure, please stop the build and check
%s
`, banner, o.Registry, valueOr(o.Namespace, "alfresco"), banner)
	if o.Yes {
		return nil
	}
	fmt.Fprint(o.Stdout, "Do you want to continue? [y/N] ")
	if !clean.Confirm(o.Stdin) {
		fmt.Fprintln(o.Stdout, "\nStopping build")
		return errors.New("push not confirmed")
	}
	fmt.Fprintln(o.Stdout)
	return nil
}

func bakeArgs(o Options, target string) []string {
	args := []string{"buildx", "bake", "--progress=plain"}
	if o.NoCache {
		args = append(args, "--no-cache")
	}
	if o.pushing() {
		args = append(args, "--set", "*.output=type=registry,push=true")
		if !o.NoSBOM {
			args = append(args, "--sbom=true")
		}
		args = append(args, "--provenance="+valueOr(o.Provenance, "false"))
	}
	if target != "" {
		args = append(args, target)
	}
	return args
}

// Build fetches what each target needs through fetch, then bakes it.
func Build(ctx context.Context, opts Options, names []string, fetch func(targets []string) error) error {
	var plan []Target
	seen := map[string]bool{}
	var add func(name string) error
	add = func(name string) error {
		t, ok := lookup(name)
		if !ok {
			return fmt.Errorf("unknown target %q (valid targets: %s)", name, targetNames())
		}
		for _, b := range t.before {
			if err := add(b); err != nil {
				return err
			}
		}
		if !seen[name] {
			seen[name] = true
			plan = append(plan, t)
		}
		return nil
	}
	for _, n := range names {
		if err := add(n); err != nil {
			return err
		}
	}

	if err := requireBuildx(ctx); err != nil {
		return err
	}
	if opts.Grype {
		if err := requireGrype(); err != nil {
			return err
		}
	}
	versions, err := artifacts.VersionsJSON(opts.Root, opts.ACSVersion, opts.APSVersion)
	if err != nil {
		return err
	}
	if err := confirmPush(ctx, opts); err != nil {
		return err
	}
	fmt.Fprintf(opts.Stdout, "REGISTRY=%s REGISTRY_NAMESPACE=%s TAG=%s\n",
		valueOr(opts.Registry, "localhost"), valueOr(opts.Namespace, "alfresco"), valueOr(opts.Tag, "<none, tags come from artifact versions>"))

	env := opts.env(versions)
	for _, t := range plan {
		var scope []string
		if t.fetch != nil {
			scope = t.fetch(opts)
		}
		fmt.Fprintf(opts.Stdout, "Fetching artifacts for %s\n", t.Name)
		if err := fetch(scope); err != nil {
			return err
		}
		fmt.Fprintf(opts.Stdout, "Building %s\n", t.Name)
		cmd := opts.command(ctx, env, "docker", bakeArgs(opts, t.bake)...)
		if err := cmd.Run(); err != nil {
			return fmt.Errorf("docker buildx bake %s: %w", t.bake, err)
		}
		if opts.Grype {
			if err := scan(ctx, opts, env, t.bake); err != nil {
				return err
			}
		}
	}
	return nil
}

// Grype scans every image the bake target produces locally.
func Grype(ctx context.Context, opts Options, target string) error {
	if err := requireBuildx(ctx); err != nil {
		return err
	}
	if err := requireGrype(); err != nil {
		return err
	}
	versions, err := artifacts.VersionsJSON(opts.Root, opts.ACSVersion, opts.APSVersion)
	if err != nil {
		return err
	}
	return scan(ctx, opts, opts.env(versions), target)
}

var unsafeFileChars = regexp.MustCompile(`[^A-Za-z0-9_.-]`)

func scan(ctx context.Context, opts Options, env []string, target string) error {
	fmt.Fprintf(opts.Stdout, "Running grype scan for %s\n", target)
	tags, err := localTags(ctx, opts, env, target)
	if err != nil {
		return err
	}
	if opts.GrypeOpts.OutputDir != "" {
		if err := os.MkdirAll(opts.GrypeOpts.OutputDir, 0o755); err != nil {
			return err
		}
	}
	var failed []string
	for _, tag := range tags {
		fmt.Fprintf(opts.Stdout, "Scanning image %s\n", tag)
		args := append([]string{}, opts.GrypeOpts.Args...)
		if opts.GrypeOpts.OutputFormat != "" {
			args = append(args, "-o", opts.GrypeOpts.OutputFormat)
		}
		cmd := opts.command(ctx, env, "grype", append(args, tag)...)
		if dir := opts.GrypeOpts.OutputDir; dir != "" {
			out, err := os.Create(filepath.Join(dir, unsafeFileChars.ReplaceAllString(tag, "_")+".out"))
			if err != nil {
				return err
			}
			cmd.Stdout = out
			err = cmd.Run()
			out.Close()
			if err != nil {
				failed = append(failed, tag)
			}
			continue
		}
		if err := cmd.Run(); err != nil {
			failed = append(failed, tag)
		}
	}
	if len(failed) > 0 {
		return fmt.Errorf("grype failed for: %s", strings.Join(failed, ", "))
	}
	return nil
}

// localTags returns the tags of every target whose output is the local
// docker image store.
func localTags(ctx context.Context, opts Options, env []string, target string) ([]string, error) {
	args := []string{"buildx", "bake"}
	if target != "" {
		args = append(args, target)
	}
	cmd := opts.command(ctx, env, "docker", append(args, "--print")...)
	var out bytes.Buffer
	cmd.Stdout = &out
	if err := cmd.Run(); err != nil {
		return nil, fmt.Errorf("docker buildx bake --print: %w", err)
	}
	var printed struct {
		Target map[string]struct {
			Tags   []string          `json:"tags"`
			Output []json.RawMessage `json:"output"`
		} `json:"target"`
	}
	if err := json.Unmarshal(out.Bytes(), &printed); err != nil {
		return nil, fmt.Errorf("parsing docker buildx bake --print output: %w", err)
	}
	names := make([]string, 0, len(printed.Target))
	for n := range printed.Target {
		names = append(names, n)
	}
	sort.Strings(names)
	var tags []string
	for _, n := range names {
		t := printed.Target[n]
		for _, o := range t.Output {
			if outputType(o) == "docker" {
				tags = append(tags, t.Tags...)
				break
			}
		}
	}
	return tags, nil
}

// outputType reads an output entry, an object in current buildx and a
// "type=...,..." string in older releases.
func outputType(raw json.RawMessage) string {
	var obj struct {
		Type string `json:"type"`
	}
	if json.Unmarshal(raw, &obj) == nil {
		return obj.Type
	}
	var s string
	if json.Unmarshal(raw, &s) == nil {
		for _, kv := range strings.Split(s, ",") {
			if v, ok := strings.CutPrefix(kv, "type="); ok {
				return v
			}
		}
	}
	return ""
}
