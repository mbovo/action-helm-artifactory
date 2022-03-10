#!/opt/homebrew/bin/bash
    
if [[ -v ARTIFACTORY_API_KEY ]]; then
    echo helm push-artifactory "${CHART_DIR}" "${ARTIFACTORY_URL}" --api-key "${ARTIFACTORY_API_KEY}" --version "${CHART_VERSION}"
elif [[ -v ARTIFACTORY_PASSWORD ]] && [[ -v ARTIFACTORY_USERNAME ]]; then
    echo helm push-artifactory "${CHART_DIR}" "${ARTIFACTORY_URL}" --username "${ARTIFACTORY_USERNAME}" --password "${ARTIFACTORY_PASSWORD}" --version "${CHART_VERSION}"
else
    echo "ARTIFACTORY_API_KEY or ARTIFACTORY_PASSWORD and ARTIFACTORY_USERNAME must be set"
    exit 1
fi