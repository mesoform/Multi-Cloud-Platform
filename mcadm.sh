#!/usr/bin/env bash

set -e
set -o pipefail

help() {
   echo "Usage: ${SCRIPT_NAME} <command> [opitons]"
   echo ""
   echo "Commands:"
   echo "  setup      Setup multi-cloud Kubernetes"
   echo "  destroy    Destroy cluster manager and all associated clouds"
   echo "  add        Adding instances for existing cluster"
   echo ""
   echo "Setup options:"
   echo "  aws        Setup cluster namager and Kubernetes cluster on AWS"
   echo "  gcp        Setup cluster namager and Kubernetes cluster on Google cloud"
   echo "  all        Setup cluster namager and Kubernetes cluster on all supported clouds"
   echo ""
   echo "Destroy options:"
   echo "  manager    Destroy current manager and associated clusters"
   echo ""
   echo "Add options:"
   echo " node        Add node to current cluster"
   echo ""
   echo "Add node options:"
   echo "  aws        Create node for cluster on AWS"
   echo "  gcp        Create node for cluster on Google cloud"
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

OPTION_2=$1
[[ -z "${OPTION_2}" ]]

# Verify whether envronment is selected
[[ -z "${ENV}" ]] && echo "No envronment is selected. Run: source load-env.sh <env_name>" && exit 1

set -u

AWS_MANAGER=config/aws/aws-manager.yaml
AWS_CLUSTER=config/aws/aws-cluster.yaml
AWS_NODE=config/aws/aws-node.yaml

GCP_MANAGER=config/gcp/gcp-manager.yaml
GCP_CLUSTER=config/gcp/gcp-cluster.yaml
GCP_NODE=config/gcp/gcp-node.yaml

GET_MANAGER_CONFIG=config/get-manager.yaml

runSetup() {
  case "${OPTION_1}" in
    aws|gcp|all)
      setupManager "${OPTION_1}"
      sleep 5
      setupCluster "${OPTION_1}"
      ;;

    *)
      help && exit 1
      ;;
  esac

  # Getting info about created manager
#  ${TK8S} get manager --non-interactive --config "${SCRIPT_DIR}/${GET_MANAGER_CONFIG}"
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

runAdd() {
  case "${OPTION_1}" in
    node)
      addNode
      ;;

    *)
      help && exit 1
      ;;
  esac

}

setupManager() {
    local current_cloud=$1
    [[ -z "${current_cloud}" ]] && echo "Setup manager: Cloud name is required" && return

    # Select cloud for manager
    [[ "${current_cloud}" == "all" ]] && current_cloud="${DEFAULT_CLOUD}"

    echo ""
    echo "Creating manager"
    echo ""

    echo "Triton Kubernetes version: $(${TK8S} version)"
    echo "${CONFIG_DIR}/${ENV}/${ENV}-${current_cloud}-${BASE_MANAGER_NAME}.yaml"
    ${TK8S} create manager --non-interactive \
      --config "${CONFIG_DIR}/${ENV}/${ENV}-${current_cloud}-${BASE_MANAGER_NAME}.yaml"
}

setupCluster() {
    local current_cloud=$1
    [[ -z "${current_cloud}" ]] && echo "Setup cluster: Cloud name is required" && return

    # Select cloud for cluster
    [[ "${current_cloud}" == "all" ]] && current_cloud="*"

    echo ""
    echo "Creating cluster(s)"
    echo ""

    for cln in $(echo "${BASE_CLUSTER_NAMES}")
    do
      for cnf in "${CONFIG_DIR}"/"${ENV}"/"${ENV}"-"${current_cloud}"-"${cln}".yaml
      do
        echo "Config: ${cnf}"
        ${TK8S} create cluster --non-interactive --config "${cnf}"
        sleep 5
      done
    done

}

addNode() {
  echo ""
  echo "Adding node"
  echo ""

  case "${OPTION_2}" in
    aws)
      NODE_CONFIG=${AWS_NODE}
      ;;

    gcp)
      NODE_CONFIG=${GCP_NODE}
      ;;

    *)
      help && exit 1
      ;;
  esac
  ${TK8S} create node --non-interactive --config "${SCRIPT_DIR}/${NODE_CONFIG}"
}

function destroyManager() {
    echo ""
    echo "Destroing manager"
    echo ""

    echo "Triton Kubernetes version: $(${TK8S} version)"
    export MANAGER_NAME="${ENV}-${DEFAULT_CLOUD}-${BASE_MANAGER_NAME}"
    ${MO} "${TEMPLATES_DIR}/get-manager-template.yaml" > \
      "${CONFIG_DIR}/${ENV}/${ENV}-get-manager.yaml"

    ${TK8S} destroy manager --non-interactive \
      --config "${CONFIG_DIR}/${ENV}/${ENV}-${DEFAULT_CLOUD}-${BASE_MANAGER_NAME}.yaml"
}

case "${COMMAND}" in
  setup)
    runSetup
    ;;

  destroy)
    runDestroy
    ;;

  add)
    runAdd
    ;;

  *)
    help && exit 1
    ;;
esac

echo ""
echo "Done"
echo ""
