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
export ENV_PATH=$ENV_PATH
export CONFIG_DIR=$CONFIG_DIR
export TEMPLATES_DIR=$TEMPLATES_DIR
export TERRAFORM=$TERRAFORM
export TK8S=$TK8S
export MO=$MO

# Load functions
source "${SCRIPT_DIR}/functions.sh"

source_environment

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

    # Install YAML processor
    echo "Getting yq ..."
    sudo add-apt-repository -y ppa:rmescandon/yq
    sudo apt-get update
    sudo apt-get install -y yq

    # Install Terraform
    if [[ ! -e "${TERRAFORM}" ]]; then
        echo ""
        echo "Getting the terraform ..."
        echo ""

        cd "${BIN}"
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
        TK8S_URL_LIN=https://github.com/mesoform/triton-kubernetes/releases/download/v0.9.2-mf/triton-kubernetes_0.9.2-mf_linux-amd64.zip
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
    [[ $(brew list jq) ]] || brew install jq

    # Install YAML processor
    echo "Getting yq ..."
    [[ $(brew list yq) ]] || brew install yq

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
        TK8S_URL_DAR=https://github.com/mesoform/triton-kubernetes/releases/download/v0.9.2-mf/triton-kubernetes_0.9.2-mf_osx-amd64.zip
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

installDependencies
