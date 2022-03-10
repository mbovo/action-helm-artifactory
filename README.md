# action-helm-artifactory

GitHub Action for packaging, testing helm charts and publishing to Artifactory helm repo

_Note this action is written to specifically work with Helm repos in Artifactory_

## Inputs

### Required

`action` - `[check, dependency, lint, package, check_push, push]`

- `check` - Runs all checks on helm chart (dependency build, lint, package)
- `dependency` - Run dependency build on the target helm chart
- `lint` - Run helm lint on the target chart
- `package` - Run helm package on the target chart
- `check_push` - Runs all tests and upload the chart to artifactory
- `push` - Uses helm artifactory plugin to uploads the chart

## Required Environment variables

```yaml
CHART_DIR: manifests/charts/mycomponent # path where the helm chart is located
ARTIFACTORY_URL: # Artifactory registry https://<company>.jfrog.io/<company>

ARTIFACTORY_USERNAME: ${{ secrets.ARTIFACTORY_USERNAME }} # ARTIFACTORY_USERNAME (Artifactory username) must be set in GitHub Repo secrets
ARTIFACTORY_PASSWORD: ${{ secrets.ARTIFACTORY_PASSWORD }} # ARTIFACTORY_PASSWORD (Artifactory password) must be set in GitHub Repo secrets

OR

ARTIFACTORY_API_KEY: ${{ secrets.ARTIFACTORY_API_KEY }} # ARTIFACTORY_API_KEY (Artifactory api key) must be set in GitHub Repo secrets
```

## Optional Environment variables

```yaml
CHART_VERSION: # Overide helm chart version when pushing
HELM_VERSION: # Override helm version. Default "3.5.1"
HELM_ARTIFACTORY_PLUGIN_VERSION: # Override helm artifactory plugin version. Default "v1.0.2"
CHART_VERSION: # if defined override version in Chart.yaml. Default is unset
```

## Example workflow

Perform all checks on pull requests

```yaml
name: Helm lint, test, package and publish

on: pull_request

jobs:
  helm-suite:
    runs-on: ubuntu-latest
    steps:
    - uses: actions/checkout@v2

  # - name: myOtherJob1
  #   run:

    - name: "Helm checks"
      uses: mbovo/action-helm-tools@v1.0.0
      with:
        action: "check"
      env:
        CHART_DIR: resources/helm/minechart
        ARTIFACTORY_URL: https://artifactory.zroot.org:443/artifactory/helm-local/
        ARTIFACTORY_USERNAME: ${{ secrets.ARTIFACTORY_USERNAME }}
        ARTIFACTORY_PASSWORD: ${{ secrets.ARTIFACTORY_PASSWORD }}
```

Push helm charts on merge/commits on main branch

```yaml
name: Helm lint, test, package and publish

on:
  push:
    branches: ["main"]

jobs:
  helm-suite:
    runs-on: ubuntu-latest
    steps:
    - uses: actions/checkout@v2

    # - name: myOtherJob1
    #   run:

    - name: "Helm publish"
      uses: mbovo/action-helm-tools@v1.0.0
      with:
        action: "push"
      env:
        CHART_DIR: resources/helm/minechart
        ARTIFACTORY_URL: https://artifactory.zroot.org:443/artifactory/helm-local/
        ARTIFACTORY_USERNAME: ${{ secrets.ARTIFACTORY_USERNAME }}
        ARTIFACTORY_PASSWORD: ${{ secrets.ARTIFACTORY_PASSWORD }}
```
