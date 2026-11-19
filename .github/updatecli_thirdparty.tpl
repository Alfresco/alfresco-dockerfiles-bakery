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
    {{- /* Semver orders "-N-ci-M" as text (6 > 36), so sort -V picks the newest. */}}
    kind: shell
    spec:
      shell: bash
      environments:
        - name: PATH
        - name: NEXUS_USERNAME
        - name: NEXUS_PASSWORD
      command: >-
        set -o pipefail;
        curl -fsS -u "$NEXUS_USERNAME:$NEXUS_PASSWORD"
        'https://{{ $nexus }}/{{ $c.group | replace "." "/" }}/{{ $c.artifact }}/maven-metadata.xml'
        | grep -o '<version>[^<]*</version>' | sed -e 's/<[^>]*>//g'
        | grep -E '{{ $c.versionregex }}' | sort -V | tail -n 1 | grep .
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
