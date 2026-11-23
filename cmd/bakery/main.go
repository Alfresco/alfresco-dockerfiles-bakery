// Command bakery builds the Alfresco container images defined in docker-bake.hcl.
package main

import (
	"context"
	"fmt"
	"os"
	"strings"

	"github.com/spf13/cobra"

	"github.com/Alfresco/alfresco-dockerfiles-bakery/internal/artifacts"
	"github.com/Alfresco/alfresco-dockerfiles-bakery/internal/bake"
	"github.com/Alfresco/alfresco-dockerfiles-bakery/internal/clean"
	"github.com/Alfresco/alfresco-dockerfiles-bakery/internal/logx"
	"github.com/Alfresco/alfresco-dockerfiles-bakery/internal/repo"
)

// Set by the release build.
var version = "dev"

func main() {
	if err := newRootCmd().ExecuteContext(context.Background()); err != nil {
		fmt.Fprintln(os.Stderr, "Error:", err)
		os.Exit(1)
	}
}

func envOr(key, def string) string {
	if v := os.Getenv(key); v != "" {
		return v
	}
	return def
}

func envSet(key string) bool { return os.Getenv(key) != "" }

type globalOpts struct {
	dir        string
	acsVersion string
	apsVersion string
}

func (g *globalOpts) root() (string, error) {
	start := g.dir
	if start == "" {
		wd, err := os.Getwd()
		if err != nil {
			return "", err
		}
		start = wd
	}
	return repo.FindRoot(start)
}

type fetchOpts struct {
	logLevel string
	logFile  string
}

func (g *globalOpts) fetcher(root string, f fetchOpts) (*artifacts.Fetcher, func(), error) {
	level, err := logx.ParseLevel(f.logLevel)
	if err != nil {
		return nil, nil, err
	}
	log, err := logx.New(os.Stdout, level, f.logFile)
	if err != nil {
		return nil, nil, err
	}
	return &artifacts.Fetcher{
		Root:        root,
		SourcesFile: os.Getenv("SOURCES_FILE"),
		ACSVersion:  g.acsVersion,
		Log:         log,
	}, func() { _ = log.Close() }, nil
}

func newRootCmd() *cobra.Command {
	g := &globalOpts{}
	root := &cobra.Command{
		Use:           "bakery",
		Short:         "Build Alfresco container images with docker buildx bake",
		Version:       version,
		SilenceUsage:  true,
		SilenceErrors: true,
	}
	pf := root.PersistentFlags()
	pf.StringVar(&g.dir, "dir", "", "Bakery checkout to work in (default: nearest parent holding docker-bake.hcl)")
	pf.StringVar(&g.acsVersion, "acs-version", envOr("ACS_VERSION", "26"), "ACS major version (env ACS_VERSION)")
	pf.StringVar(&g.apsVersion, "aps-version", envOr("APS_VERSION", "26"), "APS major version (env APS_VERSION)")

	root.AddCommand(newBuildCmd(g), newFetchCmd(g), newGrypeCmd(g), newCleanCmd(g), newVersionsCmd(g))
	return root
}

func bakeFlags(cmd *cobra.Command, o *bake.Options) {
	f := cmd.Flags()
	f.StringVar(&o.Registry, "registry", os.Getenv("REGISTRY"), "registry to push to; unset or localhost loads images locally (env REGISTRY)")
	f.StringVar(&o.Namespace, "namespace", os.Getenv("REGISTRY_NAMESPACE"), "registry namespace, default alfresco (env REGISTRY_NAMESPACE)")
	f.StringVar(&o.Tag, "tag", os.Getenv("TAG"), "image tag; default is the version of the packaged artifact (env TAG)")
}

func grypeFlags(cmd *cobra.Command, o *bake.GrypeOptions, args *string) {
	f := cmd.Flags()
	f.StringVar(args, "grype-opts", envOr("GRYPE_OPTS", "-f high --only-fixed --ignore-states wont-fix"), "grype arguments (env GRYPE_OPTS)")
	f.StringVar(&o.OutputDir, "grype-output-dir", os.Getenv("GRYPE_OUTPUT_DIR"), "write one report per image to this directory (env GRYPE_OUTPUT_DIR)")
	f.StringVar(&o.OutputFormat, "grype-output-format", os.Getenv("GRYPE_OUTPUT_FORMAT"), "grype output format, e.g. sarif (env GRYPE_OUTPUT_FORMAT)")
}

func stdio(o *bake.Options) {
	o.Stdin, o.Stdout, o.Stderr = os.Stdin, os.Stdout, os.Stderr
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
	var grypeArgs string
	var fo fetchOpts
	cmd := &cobra.Command{
		Use:   "build <target>...",
		Short: "Fetch artifacts and build images for one or more targets",
		Args:  cobra.MinimumNArgs(1),
		RunE: func(cmd *cobra.Command, args []string) error {
			root, err := g.root()
			if err != nil {
				return err
			}
			f, closeLog, err := g.fetcher(root, fo)
			if err != nil {
				return err
			}
			defer closeLog()
			o.Root, o.ACSVersion, o.APSVersion = root, g.acsVersion, g.apsVersion
			o.GrypeOpts.Args = strings.Fields(grypeArgs)
			stdio(&o)
			return bake.Build(cmd.Context(), o, args, f.Run)
		},
	}
	cmd.Long = "Fetch the artifacts each target needs, then run docker buildx bake.\n\n" + targetsHelp()
	bakeFlags(cmd, &o)
	f := cmd.Flags()
	f.BoolVar(&o.NoCache, "no-cache", envSet("BAKE_NO_CACHE"), "build without the Docker cache (env BAKE_NO_CACHE)")
	f.BoolVar(&o.NoSBOM, "no-sbom", envSet("BAKE_NO_SBOM"), "skip SBOM attestations when pushing (env BAKE_NO_SBOM)")
	f.StringVar(&o.Provenance, "provenance", envOr("BAKE_PROVENANCE", "false"), "provenance attestation mode when pushing (env BAKE_PROVENANCE)")
	f.BoolVarP(&o.Yes, "yes", "y", false, "push without asking for confirmation")
	f.BoolVar(&o.Grype, "grype", envSet("GRYPE_ONBUILD"), "scan the built images with grype (env GRYPE_ONBUILD)")
	f.StringVar(&fo.logLevel, "log-level", "INFO", "artifact fetch log level: DEBUG, INFO, WARNING, ERROR")
	grypeFlags(cmd, &o.GrypeOpts, &grypeArgs)
	return cmd
}

func newFetchCmd(g *globalOpts) *cobra.Command {
	var fo fetchOpts
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
			root, err := g.root()
			if err != nil {
				return err
			}
			f, closeLog, err := g.fetcher(root, fo)
			if err != nil {
				return err
			}
			defer closeLog()
			return f.Run(args)
		},
	}
	cmd.Flags().StringVar(&fo.logLevel, "log-level", "INFO", "DEBUG, INFO, WARNING or ERROR")
	cmd.Flags().StringVar(&fo.logFile, "log-file", "", "also write logs to this file")
	return cmd
}

func newGrypeCmd(g *globalOpts) *cobra.Command {
	o := bake.Options{}
	var grypeArgs string
	cmd := &cobra.Command{
		Use:   "grype [target]",
		Short: "Scan the images of a target with grype",
		Args:  cobra.MaximumNArgs(1),
		RunE: func(cmd *cobra.Command, args []string) error {
			root, err := g.root()
			if err != nil {
				return err
			}
			o.Root, o.ACSVersion, o.APSVersion = root, g.acsVersion, g.apsVersion
			o.GrypeOpts.Args = strings.Fields(grypeArgs)
			stdio(&o)
			target := ""
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
			root, err := g.root()
			if err != nil {
				return err
			}
			if caches {
				return clean.Caches(cmd.Context(), root, os.Stdout, os.Stderr)
			}
			return clean.Artifacts(root, force, os.Stdin, os.Stdout)
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
			root, err := g.root()
			if err != nil {
				return err
			}
			out, err := artifacts.VersionsJSON(root, g.acsVersion, g.apsVersion)
			if err != nil {
				return err
			}
			fmt.Println(out)
			return nil
		},
	}
}
