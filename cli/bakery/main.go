// Command bakery builds the Alfresco container images defined in docker-bake.hcl.
package main

import (
	"context"
	"fmt"
	"os"
	"strings"

	"github.com/spf13/cobra"
	"github.com/spf13/pflag"

	"github.com/Alfresco/alfresco-dockerfiles-bakery/cli/internal/artifacts"
	"github.com/Alfresco/alfresco-dockerfiles-bakery/cli/internal/bake"
	"github.com/Alfresco/alfresco-dockerfiles-bakery/cli/internal/clean"
	"github.com/Alfresco/alfresco-dockerfiles-bakery/cli/internal/logx"
	"github.com/Alfresco/alfresco-dockerfiles-bakery/cli/internal/repo"
	"github.com/Alfresco/alfresco-dockerfiles-bakery/cli/internal/shellwords"
)

// Set by the release build.
var version = "dev"

func main() {
	if err := newRootCmd().ExecuteContext(context.Background()); err != nil {
		fmt.Fprintln(os.Stderr, "Error:", err)
		os.Exit(1)
	}
}

const envAnnotation = "bakery_env"

// bindEnv makes a flag fall back to an environment variable.
func bindEnv(f *pflag.FlagSet, flag, env string) {
	f.Lookup(flag).Usage += " (env " + env + ")"
	_ = f.SetAnnotation(flag, envAnnotation, []string{env})
}

// applyEnv sets every flag not given on the command line from its environment
// variable, when that is not empty. Any non-empty value turns a bool flag on.
func applyEnv(cmd *cobra.Command) error {
	var err error
	cmd.Flags().VisitAll(func(fl *pflag.Flag) {
		env, ok := fl.Annotations[envAnnotation]
		if !ok || fl.Changed || err != nil {
			return
		}
		v := os.Getenv(env[0])
		if v == "" {
			return
		}
		if fl.Value.Type() == "bool" {
			v = "true"
		}
		if e := fl.Value.Set(v); e != nil {
			err = fmt.Errorf("%s: %w", env[0], e)
		}
	})
	return err
}

type globalOpts struct {
	dir        string
	acsVersion string
	apsVersion string
	root       string
}

func (g *globalOpts) resolveRoot() error {
	start := g.dir
	if start == "" {
		wd, err := os.Getwd()
		if err != nil {
			return err
		}
		start = wd
	}
	root, err := repo.FindRoot(start)
	g.root = root
	return err
}

func (g *globalOpts) fetcher(logLevel, logFile string) (*artifacts.Fetcher, func(), error) {
	level, err := logx.ParseLevel(logLevel)
	if err != nil {
		return nil, nil, err
	}
	log, err := logx.New(os.Stdout, level, logFile)
	if err != nil {
		return nil, nil, err
	}
	return &artifacts.Fetcher{
		Root:        g.root,
		SourcesFile: os.Getenv("SOURCES_FILE"),
		ACSVersion:  g.acsVersion,
		Log:         log,
	}, func() { _ = log.Close() }, nil
}

// bakeOptions completes o with the global options, the grype arguments and stdio.
func (g *globalOpts) bakeOptions(o *bake.Options, grypeArgs string) error {
	args, err := shellwords.Split(grypeArgs, shellwords.Shell)
	if err != nil {
		return fmt.Errorf("--grype-opts: %w", err)
	}
	o.Root, o.ACSVersion, o.APSVersion = g.root, g.acsVersion, g.apsVersion
	o.GrypeOpts.Args = args
	o.Stdin, o.Stdout, o.Stderr = os.Stdin, os.Stdout, os.Stderr
	return nil
}

func newRootCmd() *cobra.Command {
	g := &globalOpts{}
	root := &cobra.Command{
		Use:           "bakery",
		Short:         "Build Alfresco container images with docker buildx bake",
		Version:       version,
		SilenceUsage:  true,
		SilenceErrors: true,
		PersistentPreRunE: func(cmd *cobra.Command, _ []string) error {
			if err := applyEnv(cmd); err != nil {
				return err
			}
			return g.resolveRoot()
		},
	}
	pf := root.PersistentFlags()
	pf.StringVar(&g.dir, "dir", "", "Bakery checkout to work in (default: nearest parent holding docker-bake.hcl)")
	pf.StringVar(&g.acsVersion, "acs-version", "26", "ACS major version")
	pf.StringVar(&g.apsVersion, "aps-version", "26", "APS major version")
	bindEnv(pf, "acs-version", "ACS_VERSION")
	bindEnv(pf, "aps-version", "APS_VERSION")

	root.AddCommand(newBuildCmd(g), newFetchCmd(g), newGrypeCmd(g), newCleanCmd(g), newVersionsCmd(g))
	return root
}

func bakeFlags(cmd *cobra.Command, o *bake.Options) {
	f := cmd.Flags()
	f.StringVar(&o.Registry, "registry", "", "registry to push to; unset or localhost loads images locally")
	f.StringVar(&o.Namespace, "namespace", "", "registry namespace, default alfresco")
	f.StringVar(&o.Tag, "tag", "", "image tag; default is the version of the packaged artifact")
	bindEnv(f, "registry", "REGISTRY")
	bindEnv(f, "namespace", "REGISTRY_NAMESPACE")
	bindEnv(f, "tag", "TAG")
}

func grypeFlags(cmd *cobra.Command, o *bake.GrypeOptions, args *string) {
	f := cmd.Flags()
	f.StringVar(args, "grype-opts", "-f high --only-fixed --ignore-states wont-fix", "grype arguments")
	f.StringVar(&o.OutputDir, "grype-output-dir", "", "write one report per image to this directory")
	f.StringVar(&o.OutputFormat, "grype-output-format", "", "grype output format, e.g. sarif")
	bindEnv(f, "grype-opts", "GRYPE_OPTS")
	bindEnv(f, "grype-output-dir", "GRYPE_OUTPUT_DIR")
	bindEnv(f, "grype-output-format", "GRYPE_OUTPUT_FORMAT")
}

func targetsHelp() string {
	var b strings.Builder
	b.WriteString("Targets:\n")
	for _, t := range bake.Targets() {
		fmt.Fprintf(&b, "  %-22s %s\n", t.Name, t.Description)
	}
	return b.String()
}

func newBuildCmd(g *globalOpts) *cobra.Command {
	o := bake.Options{}
	var grypeArgs, logLevel string
	cmd := &cobra.Command{
		Use:   "build <target>...",
		Short: "Fetch artifacts and build images for one or more targets",
		Args:  cobra.MinimumNArgs(1),
		RunE: func(cmd *cobra.Command, args []string) error {
			if err := g.bakeOptions(&o, grypeArgs); err != nil {
				return err
			}
			f, closeLog, err := g.fetcher(logLevel, "")
			if err != nil {
				return err
			}
			defer closeLog()
			return bake.Build(cmd.Context(), o, args, f.Run)
		},
	}
	cmd.Long = "Fetch the artifacts each target needs, then run docker buildx bake.\n\n" + targetsHelp()
	bakeFlags(cmd, &o)
	f := cmd.Flags()
	f.BoolVar(&o.NoCache, "no-cache", false, "build without the Docker cache")
	f.BoolVar(&o.NoSBOM, "no-sbom", false, "skip SBOM attestations when pushing")
	f.StringVar(&o.Provenance, "provenance", "false", "provenance attestation mode when pushing")
	f.BoolVarP(&o.Yes, "yes", "y", false, "push without asking for confirmation")
	f.BoolVar(&o.Grype, "grype", false, "scan the built images with grype")
	f.StringVar(&logLevel, "log-level", "INFO", "artifact fetch log level: DEBUG, INFO, WARNING, ERROR")
	bindEnv(f, "no-cache", "BAKE_NO_CACHE")
	bindEnv(f, "no-sbom", "BAKE_NO_SBOM")
	bindEnv(f, "provenance", "BAKE_PROVENANCE")
	bindEnv(f, "grype", "GRYPE_ONBUILD")
	grypeFlags(cmd, &o.GrypeOpts, &grypeArgs)
	return cmd
}

func newFetchCmd(g *globalOpts) *cobra.Command {
	var logLevel, logFile string
	cmd := &cobra.Command{
		Use:   "fetch [target|path|glob]...",
		Short: "Download the artifacts declared in artifacts-*.yaml manifests",
		Long: `Download the artifacts declared in artifacts-*.yaml manifests into the image build contexts.

Each argument is relative to the repository root and is either a directory
(searched for artifacts-<acs-version>.yaml), a manifest file, or a glob
pattern such as "aps/**/artifacts-26.yaml". No argument fetches everything
for the ACS version. Sources come from sources.yaml (env SOURCES_FILE
overrides it) and credentials from ~/.netrc.`,
		RunE: func(cmd *cobra.Command, args []string) error {
			f, closeLog, err := g.fetcher(logLevel, logFile)
			if err != nil {
				return err
			}
			defer closeLog()
			return f.Run(args)
		},
	}
	cmd.Flags().StringVar(&logLevel, "log-level", "INFO", "DEBUG, INFO, WARNING or ERROR")
	cmd.Flags().StringVar(&logFile, "log-file", "", "also write logs to this file")
	return cmd
}

func newGrypeCmd(g *globalOpts) *cobra.Command {
	o := bake.Options{}
	var grypeArgs string
	cmd := &cobra.Command{
		Use:   "grype [target]",
		Short: "Scan the images of a target with grype",
		Long:  "Scan the images of a bake target or group with grype. The target defaults to GRYPE_TARGET, then to the default group.",
		Args:  cobra.MaximumNArgs(1),
		RunE: func(cmd *cobra.Command, args []string) error {
			if err := g.bakeOptions(&o, grypeArgs); err != nil {
				return err
			}
			target := os.Getenv("GRYPE_TARGET")
			if len(args) == 1 {
				target = args[0]
			}
			return bake.Grype(cmd.Context(), o, target)
		},
	}
	bakeFlags(cmd, &o)
	grypeFlags(cmd, &o.GrypeOpts, &grypeArgs)
	return cmd
}

func newCleanCmd(g *globalOpts) *cobra.Command {
	var force, caches bool
	cmd := &cobra.Command{
		Use:   "clean",
		Short: "Delete fetched artifacts, or with --caches the Docker and artifact caches",
		Args:  cobra.NoArgs,
		RunE: func(cmd *cobra.Command, _ []string) error {
			if caches {
				return clean.Caches(cmd.Context(), g.root, os.Stdout, os.Stderr)
			}
			return clean.Artifacts(g.root, force, os.Stdin, os.Stdout)
		},
	}
	cmd.Flags().BoolVarP(&force, "force", "f", false, "delete without asking for confirmation")
	cmd.Flags().BoolVar(&caches, "caches", false, "prune the Docker build cache and empty artifacts_cache/")
	return cmd
}

func newVersionsCmd(g *globalOpts) *cobra.Command {
	return &cobra.Command{
		Use:   "versions",
		Short: "Print the artifact version map used to tag images, as JSON",
		Args:  cobra.NoArgs,
		RunE: func(cmd *cobra.Command, _ []string) error {
			out, err := artifacts.VersionsJSON(g.root, g.acsVersion, g.apsVersion)
			if err != nil {
				return err
			}
			fmt.Println(out)
			return nil
		},
	}
}
