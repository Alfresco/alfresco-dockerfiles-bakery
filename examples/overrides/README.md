# Override Examples

These examples mirror the component-specific files under `overrides/`.
Copy the relevant example to the matching path on your customization branch,
then replace its artifact version with the version available in Nexus.

For example:

```sh
CUSTOMIZATION_REF=customizations make repository ACS_VERSION=25
```

The artifact name, group, repository, classifier, and path should remain the
same as the selected Bakery manifest unless the Nexus coordinate changes. The
downloaded artifact is staged at `path` and is then consumed by that component
build.
