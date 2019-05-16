#!/usr/bin/env bash

set -e
set -u
set -o pipefail

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
BIN="${SCRIPT_DIR}/bin"
mkdir -p ${BIN}
PATH="${BIN}:${PATH}"

TERRAFORM="${BIN}/terraform"
TK8S="${BIN}/triton-kubernetes"

SOURCE_URL_BASE=github.com/mesoform/triton-kubernetes
if [[ -d "~/go/src/${SOURCE_URL_BASE}"  ]]; then
    export SOURCE_URL="~/go/src/${SOURCE_URL_BASE}"
else
    export SOURCE_URL="${SOURCE_URL_BASE}"
fi
export SOURCE_REF=master

AWS_MANAGER=config/aws/aws-manager.yaml
AWS_CLUSTER=config/aws/aws-cluster.yaml

GCP_MANAGER=config/gcp/gcp-manager.yaml
GCP_CLUSTER=config/gcp/gcp-cluster.yaml

MANAGER_CONFIG=${AWS_MANAGER}
CLUSTER_CONFIG=${AWS_CLUSTER}

GET_MANAGER_CONFIG=config/get-manager.yaml

runSetup() {
    installDependencies
    setupManager
    sleep 5
    setupCluster

    # Getting info about created manager
    ${TK8S} get manager --non-interactive --config "${SCRIPT_DIR}/${GET_MANAGER_CONFIG}"
}

installDependencies() {
    echo "Installing dependencies"

    OS="`uname`"
    case ${OS} in
        'Linux')
            installLinuxDependencies
            ;;
        'Darwin')
            installDarwinDependencies
            ;;
        *)
            echo "Couldn't determine os type."
            exit 1
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

        cd ${BIN}
        #TERRAFORM_URL_LIN=https://releases.hashicorp.com/terraform/0.11.13/terraform_0.11.13_linux_amd64.zip
        TERRAFORM_URL_LIN=https://releases.hashicorp.com/terraform/0.11.12/terraform_0.11.12_linux_amd64.zip
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

        cd ${BIN}
        TERRAFORM_URL_DAR=https://releases.hashicorp.com/terraform/0.11.12/terraform_0.11.12_darwin_amd64.zip
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

        cd ${BIN}
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
}

setupManager() {
    echo ""
    echo "Creating manager"
    echo ""

    echo "Triton Kubernetes version: $(${TK8S} version)"
    ${TK8S} create manager --non-interactive --config "${SCRIPT_DIR}/${MANAGER_CONFIG}"
}

setupCluster() {
    echo ""
    echo "Creating cluster"
    echo ""
    ${TK8S} create cluster --non-interactive --config "${SCRIPT_DIR}/${CLUSTER_CONFIG}"
}

runSetup

echo ""
echo "Done"
echo ""
