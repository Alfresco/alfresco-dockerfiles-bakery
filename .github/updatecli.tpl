name: Update Artifacts for version {{ .updatecli_matrix_version }} in {{ .updatecli_self }}

{{- /* Hosts the NEXUS_USERNAME/NEXUS_PASSWORD pair may be sent to. Sources on any
       other host are queried anonymously so Nexus credentials never leak to a
       third-party repository. */}}
{{- $trusted_hosts := list "nexus.alfresco.com" }}

sources:
{{- range $key, $artifact := .artifacts }}
  {{- if all $artifact.updatecli_matrix_component_key $artifact.group $artifact.name }}
  {{- $source := index $.sources $artifact.source }}
  {{- $hostpath := $source.url | trimPrefix "https://" | trimPrefix "http://" }}
  {{- $host := $hostpath | splitList "/" | first }}
  src_{{ $key }}:
    name: {{ $artifact.name }}
    kind: maven
    spec:
      repository: {{ if has $host $trusted_hosts }}{{ requiredEnv "NEXUS_USERNAME" }}:{{ requiredEnv "NEXUS_PASSWORD" }}@{{ end }}{{ $hostpath }}
      groupid: {{ $artifact.group }}
      artifactid: {{ $artifact.name}}
      {{- $matrix_filter := index $ "matrix" $.updatecli_matrix_version $artifact.updatecli_matrix_component_key }}
      {{- if $matrix_filter }}
      {{- $pattern := index $matrix_filter "pattern" }}
      {{- $version := index $matrix_filter "version" }}
      versionFilter:
        kind: {{ if $pattern }}regex{{ else }}semver{{ end }}
        pattern: >-
          {{- if $pattern }}
          ^{{ $version }}{{ $pattern }}$
          {{- else }}
          {{ $version }}
          {{- end }}
      {{- end }}
  {{- end }}
{{- end }}

targets:
{{- range $key, $artifact := .artifacts }}
  {{- if all $artifact.updatecli_matrix_component_key $artifact.group $artifact.name }}
  yml_{{ $key }}:
    name: {{ $artifact.name }} yml
    kind: yaml
    sourceid: src_{{ $key }}
    spec:
      file: "{{ $.updatecli_self }}"
      key: "$.artifacts.{{ $key }}.version"
  {{- end }}
{{- end }}
