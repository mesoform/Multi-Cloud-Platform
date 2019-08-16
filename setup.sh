#!/usr/bin/env bash

set -e
set -o pipefail

help() {
   echo "Usage: ${SCRIPT_NAME} <command> [opitons]"
   echo ""
   echo "Commands:"
   echo "  setup      Setup multi-cloud Kubernetes"
   echo "  destroy    Destroy cluster manager and all associated clouds"
   echo ""
   echo "Setup options:"
   echo "  aws        Setup cluster namager and Kubernetes cluster on AWS"
   echo "  gcp        Setup cluster namager and Kubernetes cluster on Google cloud"
   echo "  all        Setup cluster namager and Kubernetes cluster on all supported clouds"
   echo ""
   echo "Destroy options:"
   echo "  manager   The name of cluster manager to destroy."
   echo ""
}

SCRIPT_NAME=$0

# Get script directory
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

COMMAND=$1
[[ -z "${COMMAND}" ]] && help && exit 1
shift

OPTION_1=$1
[[ -z "${OPTION_1}" ]] && help && exit 1
shift

set -u

BIN="${SCRIPT_DIR}/bin"
mkdir -p "${BIN}"
PATH="${BIN}:${PATH}"

TERRAFORM="${BIN}/terraform"
TK8S="${BIN}/triton-kubernetes"

SOURCE_URL_BASE=github.com/mesoform/triton-kubernetes
if [[ -e "$HOME/go/src/${SOURCE_URL_BASE}"  ]]; then
    export SOURCE_URL="$HOME/go/src/${SOURCE_URL_BASE}"
else
    export SOURCE_URL="${SOURCE_URL_BASE}"
fi
export SOURCE_REF=master

AWS_MANAGER=config/aws/aws-manager.yaml
AWS_CLUSTER=config/aws/aws-cluster.yaml

GCP_MANAGER=config/gcp/gcp-manager.yaml
GCP_CLUSTER=config/gcp/gcp-cluster.yaml

GET_MANAGER_CONFIG=config/get-manager.yaml

runSetup() {
  installDependencies

  case "${OPTION_1}" in
    aws)
      MANAGER_CONFIG=${AWS_MANAGER}
      CLUSTER_CONFIG=${AWS_CLUSTER}
      setupManager
      sleep 5
      setupCluster
      ;;

    gcp)
      MANAGER_CONFIG=${GCP_MANAGER}
      CLUSTER_CONFIG=${GCP_CLUSTER}
      setupManager
      sleep 5
      setupCluster
      ;;

    all)
      MANAGER_CONFIG=${GCP_MANAGER}
      CLUSTER_CONFIG=${GCP_CLUSTER}
      setupManager
      sleep 5
      setupCluster

      sleep 5
      CLUSTER_CONFIG=${AWS_CLUSTER}
      setupCluster
      ;;

    *)
      help && exit 1
      ;;
  esac

  # Getting info about created manager
  ${TK8S} get manager --non-interactive --config "${SCRIPT_DIR}/${GET_MANAGER_CONFIG}"
}

runDestroy() {
  case "${OPTION_1}" in
    manager)
      destroyManager
      ;;

    *)
      help && exit 1
      ;;
  esac

}


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

        cd "${BIN}"
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

function destroyManager() {
    echo ""
    echo "Destroing manager"
    echo ""

    echo "Triton Kubernetes version: $(${TK8S} version)"
    ${TK8S} destroy manager --non-interactive --config "${SCRIPT_DIR}/${GET_MANAGER_CONFIG}"
}


case "${COMMAND}" in
  setup)
    runSetup
    ;;

  destroy)
    runDestroy
    ;;

  *)
    help && exit 1
    ;;
esac

echo ""
echo "Done"
echo ""
