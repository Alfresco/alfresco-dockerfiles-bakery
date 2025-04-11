name: Bump tomcat versions

{{ $tomcatMajors := list "10" "9" }}

sources:
{{ range $tomcatMajor := $tomcatMajors }}

  tomcat{{ $tomcatMajor }}Version:
    name: Get latest tomcat {{ $tomcatMajor }} version
    kind: gittag
    scmid: tomcat
    spec:
      versionfilter:
        kind: semver
        pattern: ~{{ $tomcatMajor }}
  {{ $tomcatSourceRef := printf "tomcat%sVersion" $tomcatMajor }}
  tomcat{{ $tomcatMajor }}Checksum:
    name: Get tomcat {{ $tomcatMajor }} archive checksum
    kind: http
    sourceid: {{ $tomcatSourceRef }}
    spec:
      url: 'https://archive.apache.org/dist/tomcat/tomcat-{{ $tomcatMajor }}/v{{ source $tomcatSourceRef }}/bin/apache-tomcat-{{ source $tomcatSourceRef }}.tar.gz.sha512'
    transformers:
      - findsubmatch:
          pattern: '([a-fA-F0-9]{128})'
{{ end }}

conditions:
{{ range $tomcatMajor := $tomcatMajors }}
  {{ $tomcatSourceRef := printf "tomcat%sVersion" $tomcatMajor }}
  tomcat{{ $tomcatMajor }}targz:
    name: Check if artifact exists on mirror
    kind: http
    sourceid: {{ $tomcatSourceRef }}
    spec:
      url: 'https://archive.apache.org/dist/tomcat/tomcat-{{ $tomcatMajor }}/v{{ source $tomcatSourceRef }}/bin/apache-tomcat-{{ source $tomcatSourceRef }}.tar.gz'
      request:
        verb: HEAD
{{ end }}

targets:
{{ range $tomcatMajor := $tomcatMajors }}
  tomcat{{ $tomcatMajor }}Config:
    name: Update tomcat version in config
    kind: yaml
    scmid: github
    sourceid: tomcat{{ $tomcatMajor }}Version
    spec:
      file: tomcat/tomcat_versions.yaml
      key: '$.tomcat{{ $tomcatMajor }}.version'
  tomcat{{ $tomcatMajor }}Checksum:
    name: Update tomcat checksum in config
    kind: yaml
    scmid: github
    sourceid: tomcat{{ $tomcatMajor }}Checksum
    spec:
      file: tomcat/tomcat_versions.yaml
      key: '$.tomcat{{ $tomcatMajor }}.sha512'
{{ end }}

actions:
  pr:
    kind: github/pullrequest
    scmid: github
    spec:
      title: Bump Tomcat versions
      labels:
        - updatecli
      reviewers:
        - Alfresco/alfresco-ops-readiness

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
  tomcat:
    kind: git
    spec:
      url: https://github.com/apache/tomcat.git
      branch: main
