#!/usr/bin/env bash

help() {
   echo ""
   echo "Usage: ${SCRIPT_NAME} <environment_name>"
   echo ""
}

SCRIPT_NAME=$0

# Get script directory
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# Get environment name
ENV=$1
[[ -z "${ENV}" ]] && help && return
shift

ENV_PATH="${SCRIPT_DIR}/env/${ENV}.vars"

if [[ ! -f "${ENV_PATH}" ]]; then
  echo "Environment file not found: ${ENV_PATH}"
  help && return
fi

# Configurations directory
CONFIG_DIR="${SCRIPT_DIR}/config"
mkdir -p "${CONFIG_DIR}/${ENV}"
TEMPLATES_DIR="${CONFIG_DIR}/templates"

# Binaries directory
BIN="${SCRIPT_DIR}/bin"
mkdir -p "${BIN}"
PATH="${BIN}:${PATH}"

TERRAFORM="${BIN}/terraform"
TK8S="${BIN}/triton-kubernetes"
MO="${BIN}/mo"
# Determine whether to use local triton-kubernetes sources
SOURCE_URL_BASE=github.com/mesoform/triton-kubernetes
if [[ -e "$HOME/go/src/${SOURCE_URL_BASE}"  ]]; then
    export SOURCE_URL="$HOME/go/src/${SOURCE_URL_BASE}"
else
    export SOURCE_URL="${SOURCE_URL_BASE}"
fi
export SOURCE_REF=master

# Export environment vars
export ENV=$ENV
export CONFIG_DIR=$CONFIG_DIR
export TERRAFORM=$TERRAFORM
export TK8S=$TK8S
export MO=$MO

#export $(grep -E -v '^#' "${ENV_PATH}" | xargs)
set -a
source ${ENV_PATH}
set +a

##
## Install section
##
installDependencies() {
    echo "Installing dependencies"

    OS="$(uname)"
    case ${OS} in
        'Linux')
            installLinuxDependencies
            ;;
        'Darwin')
            installDarwinDependencies
            ;;
        *)
            echo "Couldn't determine os type."
            return
            ;;
    esac
}

installLinuxDependencies() {
    # Install JSON processor
    echo "Getting jq ..."
    sudo apt-get install -y jq

    # Install Terraform
    if [[ ! -e "${TERRAFORM}" ]]; then
        echo ""
        echo "Getting the terraform ..."
        echo ""

        cd "${BIN}"
        #TERRAFORM_URL_LIN=https://releases.hashicorp.com/terraform/0.11.13/terraform_0.11.13_linux_amd64.zip
        TERRAFORM_URL_LIN=https://releases.hashicorp.com/terraform/0.11.14/terraform_0.11.14_linux_amd64.zip
        TERRAFORM_FILE_LIN="${TERRAFORM_URL_LIN##*/}"
        wget "${TERRAFORM_URL_LIN}"
        unzip -o "${TERRAFORM_FILE_LIN}"
        rm "${TERRAFORM_FILE_LIN}"
        cd "${SCRIPT_DIR}"

        echo ""
        echo "Terraform for $OS installed."
        echo ""
    fi

    # Install triton-kubernetes
    if [[ ! -e "${TK8S}" ]]; then
        echo ""
        echo "Getting the triton-kubernetes ..."
        echo ""

        cd "${BIN}"
        TK8S_URL_LIN=https://github.com/mesoform/triton-kubernetes/releases/download/v0.9.1-mf/triton-kubernetes_0.9.1-mf_linux-amd64.zip
        TK8S_FILE_LIN="${TK8S_URL_LIN##*/}"

        echo "URL: ${TK8S_URL_LIN}"
        echo "File: ${TK8S_FILE_LIN}"

        wget "${TK8S_URL_LIN}"
        unzip "${TK8S_FILE_LIN}"
        rm "${TK8S_FILE_LIN}"
        cd "${SCRIPT_DIR}"

        echo ""
        echo "triton-kubernetes for $OS installed"
        echo ""
    fi

    # Install Mustache templates binary
    if [[ ! -e "${MO}" ]]; then
        echo ""
        echo "Getting the mustache templates ..."
        echo ""

        cd "${BIN}"

        curl -sSL https://git.io/get-mo -o mo
        chmod +x mo

        echo ""
        echo "mustache binary for $OS installed"
        echo ""
    fi
}

installDarwinDependencies() {
    # Install JSON processor
    echo "Getting jq ..."
    brew install jq

    # Install Terraform
    if [[ ! -e "${TERRAFORM}" ]]; then
        echo ""
        echo "Getting the terraform ..."
        echo ""

        cd "${BIN}"
        TERRAFORM_URL_DAR=https://releases.hashicorp.com/terraform/0.11.14/terraform_0.11.14_darwin_amd64.zip
        TERRAFORM_FILE_DAR="${TERRAFORM_URL_DAR##*/}"

        echo "URL: ${TERRAFORM_URL_DAR}"
        echo "File: ${TERRAFORM_FILE_DAR}"

        curl "${TERRAFORM_URL_DAR}" --output "${TERRAFORM_FILE_DAR}"
        unzip "${TERRAFORM_FILE_DAR}"
        rm "${TERRAFORM_FILE_DAR}"
        cd "${SCRIPT_DIR}"

        echo ""
        echo "Terraform for $OS installed."
        echo ""
    fi

    # Install triton-kubernetes
    if [[ ! -e "${TK8S}" ]]; then
        echo ""
        echo "Getting the triton-kubernetes ..."
        echo ""

        cd "${BIN}"
        TK8S_URL_DAR=https://github.com/mesoform/triton-kubernetes/releases/download/v0.9.1-mf/triton-kubernetes_0.9.1-mf_osx-amd64.zip
        TK8S_FILE_DAR="${TK8S_URL_DAR##*/}"

        echo "URL: ${TK8S_URL_DAR}"
        echo "File: ${TK8S_FILE_DAR}"

        curl -L "${TK8S_URL_DAR}" --output "${TK8S_FILE_DAR}"
        unzip "${TK8S_FILE_DAR}"
        rm "${TK8S_FILE_DAR}"
        cd "${SCRIPT_DIR}"

        echo ""
        echo "triton-kubernetes for $OS installed"
        echo ""
    fi

    # Install Mustache templates binary
    if [[ ! -e "${MO}" ]]; then
        echo ""
        echo "Getting the mustache templates ..."
        echo ""

        cd "${BIN}"
        curl -sSL https://git.io/get-mo -o mo
        chmod +x mo
        cd "${SCRIPT_DIR}"

        echo ""
        echo "Mustache binary for $OS installed"
        echo ""
    fi
}

##
## Configuration
##

renderManagerConfig() {
    local current_cloud=$1
    [[ -z "${current_cloud}" ]] && echo "Manager config: Cloud name is required" && return
    ${MO} "${TEMPLATES_DIR}/${current_cloud}-manager-template.yaml"
}

renderClusterConfig() {
    local current_cloud=$1
    [[ -z "${current_cloud}" ]] && echo "Cluster config: Cloud name is required" && return
    ${MO} "${TEMPLATES_DIR}/${current_cloud}-cluster-template.yaml"
}

renderNodeConfig() {
    local current_cloud=$1
    [[ -z "${current_cloud}" ]] && echo "Node config: Cloud name is required" && return
    ${MO} "${TEMPLATES_DIR}/${current_cloud}-node-template.yaml"
}

generateConfiguration() {
    local current_cloud=$1
    [[ -z "${current_cloud}" ]] && echo "Configuration: Cloud name is required" && return

    export MANAGER_NAME="${ENV}-${current_cloud}-${BASE_MANAGER_NAME}"
    renderManagerConfig "${current_cloud}" > \
      "${CONFIG_DIR}/${ENV}/${ENV}-${current_cloud}-${BASE_MANAGER_NAME}.yaml"


    for cln in $(echo "${BASE_CLUSTER_NAMES}")
    do
      echo "${cln}"
      export CLUSTER_NAME="${ENV}-${current_cloud}-${cln}"
      export ETCD_NODE_NAME="${CLUSTER_NAME}-${BASE_ETCD_NODE_NAME}"
      export CONTROL_NODE_NAME="${CLUSTER_NAME}-${BASE_CONTROL_NODE_NAME}"
      export WORKER_NODE_NAME="${CLUSTER_NAME}-${BASE_WORKER_NODE_NAME}"
      renderClusterConfig "${current_cloud}" > "${CONFIG_DIR}/${ENV}/${ENV}-${current_cloud}-${cln}.yaml"
    done

}

installDependencies
