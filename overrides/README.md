# Artifact Overrides

These manifests are component-scoped Nexus overrides. Copy the relevant files
to the same paths on your customization branch; downloaded artifacts are not
committed.

```text
overrides/
├── repository.yaml
├── share.yaml
├── search.yaml
├── connector/
│   ├── ms365.yaml
│   └── msteams.yaml
├── adf-apps/
│   ├── acc.yaml
│   └── adw.yaml
├── aps/
│   ├── admin.yaml
│   └── app.yaml
├── ats/
│   ├── sfs.yaml
│   └── trouter.yaml
├── audit-storage.yaml
├── cic-connector/
│   ├── bulk-ingester.yaml
│   ├── live-ingester.yaml
│   └── nucleus-sync.yaml
├── sync.yaml
└── tengine.yaml
```

Set `CUSTOMIZATION_REF` and Make selects the matching manifest automatically:

```sh
CUSTOMIZATION_REF=customizations make repository ACS_VERSION=25
```

```sh
CUSTOMIZATION_REF=customizations make connectors ACS_VERSION=25
```

The default Bakery manifest is processed first, then the remote override. The
override entry's `path` must match the component's artifact directory. Change
the artifact `version` to select a different compatible Nexus version.
