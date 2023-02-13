#!/bin/bash -l
set -eo pipefail

export HELM_VERSION=${HELM_VERSION:="3.5.1"}
export HELM_ARTIFACTORY_PLUGIN_VERSION=${HELM_ARTIFACTORY_PLUGIN_VERSION:="v1.0.2"}
export CHART_VERSION=${CHART_VERSION:-}

print_title(){
    echo "#####################################################"
    echo "$1"
    echo "#####################################################"
}

get_chart_version(){
    if [ -n "$CHART_VERSION" ]; then
        echo "CHART_VERSION variable is already set (value: $CHART_VERSION), will override Chart.yaml"
        return
    fi
    print_title "Calculating chart version"
	echo "Installing prerequisites"
	pip3 install PyYAML
    pushd "$CHART_DIR"
    CANDIDATE_VERSION=$(python3 -c "import yaml; f=open('Chart.yaml','r');  p=yaml.safe_load(f.read()); print(p['version']); f.close()" )
    popd
    echo "${GITHUB_EVENT_NAME}"
    if [ "${GITHUB_EVENT_NAME}" == "pull_request" ]; then
        CHART_VERSION="${CANDIDATE_VERSION}-$(git rev-parse --short "$GITHUB_SHA")"
    else
        CHART_VERSION="${CANDIDATE_VERSION}"
    fi
    export CHART_VERSION
}

get_helm() {
    print_title "Get helm:${HELM_VERSION}"
    curl -L "https://get.helm.sh/helm-v${HELM_VERSION}-linux-amd64.tar.gz" | tar xvz
    chmod +x linux-amd64/helm
    sudo mv linux-amd64/helm /usr/local/bin/helm
}

install_helm() {
    if ! command -v helm; then
        echo "Helm is missing"
        get_helm
    elif ! [[ $(helm version --short -c) == *${HELM_VERSION}* ]]; then
        echo "Helm $(helm version --short -c) is not desired version"
        get_helm
    fi
}

install_artifactory_plugin(){
    print_title "Install helm artifactory plugin"
    if ! (helm plugin list  | grep -q push-artifactory); then
        helm plugin install https://github.com/belitre/helm-push-artifactory-plugin --version "${HELM_ARTIFACTORY_PLUGIN_VERSION}"
    fi
}

remove_helm(){
    helm plugin uninstall push-artifactory
    sudo rm -rf /usr/local/bin/helm
}

helm_dependency(){
    print_title "Helm dependency build"
    helm dependency build "${CHART_DIR}"
}

helm_lint(){
    print_title "Linting"
    helm lint "${CHART_DIR}"
}

helm_package(){
    print_title "Packaging"
    helm package "${CHART_DIR}" --version v"${CHART_VERSION}" --app-version "${CHART_VERSION}" --destination "${RUNNER_WORKSPACE}"
}

helm_push(){
    print_title "Push chart"
    if [[ "${SKIP_REINDEX}" == "true" ]]; then
        extra_args="--skip-reindex"
    else
        extra_args=""
    fi
    if [[ -v ARTIFACTORY_API_KEY ]]; then
        helm push-artifactory "${CHART_DIR}" "${ARTIFACTORY_URL}" --api-key "${ARTIFACTORY_API_KEY}" --version "${CHART_VERSION}" "${extra_args}"
    elif [[ -v ARTIFACTORY_PASSWORD ]] && [[ -v ARTIFACTORY_USERNAME ]]; then
        helm push-artifactory "${CHART_DIR}" "${ARTIFACTORY_URL}" --username "${ARTIFACTORY_USERNAME}" --password "${ARTIFACTORY_PASSWORD}" --version "${CHART_VERSION}" "${extra_args}"
    else
        echo "ARTIFACTORY_API_KEY or ARTIFACTORY_PASSWORD and ARTIFACTORY_USERNAME must be set"
        exit 1
    fi
}
