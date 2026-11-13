name: Bump third-party tengine components

{{- /* The Nexus credentials only ever go to nexus.alfresco.com. */}}
{{- $nexus := "nexus.alfresco.com/nexus/repository/thirdparty" }}
{{- $auth := printf "%s:%s" (requiredEnv "NEXUS_USERNAME") (requiredEnv "NEXUS_PASSWORD") }}

scms:
  github:
    kind: github
    spec:
      owner: Alfresco
      repository: alfresco-dockerfiles-bakery
      branch: main
      token: {{ requiredEnv "UPDATECLI_GITHUB_TOKEN" }}
      username: {{ requiredEnv "UPDATECLI_GITHUB_USERNAME" }}
      user: {{ requiredEnv "UPDATECLI_GITHUB_USERNAME" }}
      email: {{ requiredEnv "UPDATECLI_GITHUB_EMAIL" }}
      commitusingapi: true

actions:
  pr:
    kind: github/pullrequest
    scmid: github
    spec:
      title: Bump ImageMagick and LibreOffice versions
      draft: true
      labels:
        - updatecli
      reviewers:
        - Alfresco/alfresco-ops-readiness

sources:
{{- range $c := .components }}
  {{ $c.id }}Version:
    name: Latest {{ $c.name }} in Nexus thirdparty
    kind: maven
    spec:
      repository: {{ $auth }}@{{ $nexus }}
      groupid: {{ $c.group }}
      artifactid: {{ $c.artifact }}
      versionFilter:
        kind: regex/semver
        regex: '{{ $c.versionregex }}'
        pattern: '>=0.0.0-0'
{{- end }}

conditions:
{{- range $c := .components }}
  {{- $sourceRef := printf "%sVersion" $c.id }}
  {{- range $i, $classifier := $c.classifiers }}
  {{ $c.id }}File{{ $i }}:
    name: {{ $c.name }} {{ $classifier }} is published
    kind: http
    sourceid: {{ $sourceRef }}
    spec:
      url: 'https://{{ $auth }}@{{ $nexus }}/{{ $c.group | replace "." "/" }}/{{ $c.artifact }}/{{ source $sourceRef }}/{{ $c.artifact }}-{{ source $sourceRef }}{{ $classifier }}'
      request:
        verb: HEAD
  {{- end }}
{{- end }}

targets:
{{- range $c := .components }}
  {{- $sourceRef := printf "%sVersion" $c.id }}
  {{- range $fi, $file := $c.files }}
    {{- range $ki, $key := $c.keys }}
  {{ $c.id }}F{{ $fi }}K{{ $ki }}:
    name: {{ $c.name }} {{ $key }} in {{ $file }}
    kind: yaml
    scmid: github
    sourceid: {{ $sourceRef }}
    spec:
      file: "{{ $file }}"
      key: "$.artifacts.{{ $key }}.version"
    {{- end }}
  {{- end }}
{{- end }}
