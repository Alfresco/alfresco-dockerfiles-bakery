autodiscovery:
  scmid: github
  crawlers:
    dockerfile:
      only:
        - path: "adf-apps/*/Dockerfile"

actions:
  pr:
    kind: github/pullrequest
    scmid: github
    spec:
      title: Bump Dockerfiles tags
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
