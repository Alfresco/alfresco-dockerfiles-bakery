name: Update Artifacts for {{ .updatecli_matrix_version }} version using reusable matrix

sources:
{{- range $key, $artifact := .artifacts }}
  {{- if $artifact.updatecli_matrix_target }}
  src_{{ $key }}:
    name: {{ $artifact.name }}
    kind: maven
    spec:
      repository: {{ requiredEnv "NEXUS_USERNAME" }}:{{ requiredEnv "NEXUS_PASSWORD" }}@nexus.alfresco.com/nexus/repository/{{ $artifact.repository }}
      groupid: {{ $artifact.group }}
      artifactid: {{ $artifact.name}}
      {{- $matrix_filter := index $ "matrix" $.updatecli_matrix_version $artifact.updatecli_matrix_target }}
      {{- if $matrix_filter }}
      versionFilter:
        kind: regex
        pattern: >-
          ^{{ index $matrix_filter "version" }}{{ index $matrix_filter "pattern" }}$
      {{- end }}
  {{- end }}
{{- end }}

targets:
{{- range $key, $artifact := .artifacts }}
  {{- if $artifact.updatecli_matrix_target }}
  yml_{{ $key }}:
    name: {{ $artifact.name }} yml
    kind: yaml
    sourceid: src_{{ $key }}
    spec:
      file: "{{ $.updatecli_self }}"
      key: "$.artifacts.{{ $key }}.version"
  {{- end }}
{{- end }}
