#!/usr/bin/env bash

set -o pipefail

help() {
  echo "Usage: ${SCRIPT_NAME} <command> [opitons]"
  echo ""
  echo "Commands:"
  echo "  setup      Setup multi-cloud Kubernetes"
  echo "  get        Get information about manager or cluster"
  echo "  add        Adding instances for existing cluster"
  echo "  destroy    Destroy cluster manager and all associated clouds"
  echo ""
  echo ""
  echo "Setup command options:"
  echo "  aws        Setup cluster namager and Kubernetes cluster on AWS"
  echo "  gcp        Setup cluster namager and Kubernetes cluster on Google cloud"
  echo "  all        Setup cluster namager and Kubernetes cluster on all supported clouds"
  echo ""
  echo "Get command options:"
  echo "  manager                      Get information about current manager"
  echo "  cluster <cluster_config>     Get information about cluster, identified by <cluster_config>"
  echo ""
  echo "Add command options:"
  echo "  cluster <cloud> <name>      Add cluster for default manager, with name: ENV-<cloud>-<name>"
  echo "  enode   <cluster_config>    Add etcd node to cluster, identified by <cluster_config>"
  echo "  cnode   <cluster_config>    Add control node to cluster, identified by <cluster_config>"
  echo "  wnode   <cluster_config>    Add worker node to cluster, identified by <cluster_config>"
  echo ""
  echo "Destroy command options:"
  echo "  manager                      Destroy current manager and associated clusters"
  echo "  cluster <cluster_config>     Destroy cluster, identified by <cluster_config>"
  echo "  node    <cluster_config>     Select and destroy node in cluster, identified by <cluster_config>"
  echo ""
}

SCRIPT_NAME=$0

# Get script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

source "${SCRIPT_DIR}/functions.sh"

COMMAND=$1
[[ -z "${COMMAND}" ]] && help && exit 1
shift

OPTION_1=$1
[[ -z "${OPTION_1}" ]] && help && exit 1
shift

OPTION_2=$1
shift

OPTION_3=$1

# Verify whether envronment is selected
[[ -z "${ENV}" ]] && echo "No envronment is selected. Run: source load-env.sh <env_name>" && exit 1

set -e
set -u

# ####################################################
# Command Runners
# ####################################################

runSetup() {
  case "${OPTION_1}" in
  aws | gcp | all)
    # TODO: Decide whether we need auto re-generation of configs each time setup command runs
    generateConfiguration "${OPTION_1}"
    setupManager "${OPTION_1}"
    sleep 5
    setupCluster "${OPTION_1}"
    ;;

  *)
    help && exit 1
    ;;
  esac

  # Getting info about created manager
  getManager
}

runGet() {
  case "${OPTION_1}" in
  manager)
    getManager
    ;;

  cluster)
    getCluster "${OPTION_2}"
    ;;

  *)
    help && exit 1
    ;;
  esac
}

runAdd() {
  case "${OPTION_1}" in
  cluster)
    addCluster "${OPTION_2}" "${OPTION_3}"
    ;;

  enode)
    addEtcdNode "${OPTION_2}"
    ;;

  cnode)
    addControlNode "${OPTION_2}"
    ;;

  wnode)
    addWokerNode "${OPTION_2}"
    ;;

  *)
    help && exit 1
    ;;
  esac
}

runDestroy() {
  case "${OPTION_1}" in
  manager)
    destroyManager
    ;;

  cluster)
    destroyCluster "${OPTION_2}"
    ;;

  node)
    destroyNode "${OPTION_2}"
    ;;

  *)
    help && exit 1
    ;;
  esac

}

# ####################################################
# Commands
# ####################################################

# :::::::::: Setup functions

setupManager() {
  local current_cloud=$1
  [[ -z "${current_cloud}" ]] && echo "Setup manager: Cloud name is required" && return

  # Select cloud for manager
  [[ "${current_cloud}" == "all" ]] && current_cloud="${DEFAULT_CLOUD}"

  echo ""
  echo "Creating manager"
  echo ""

  echo "Triton Kubernetes version: $(${TK8S} version)"
  echo ""
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

  for cln in $(echo "${BASE_CLUSTER_NAMES}"); do
    for cnf in "${CONFIG_DIR}"/"${ENV}"/"${ENV}"-${current_cloud}-"${cln}".yaml; do
      ${TK8S} create cluster --non-interactive --config "${cnf}"
      sleep 5
    done
  done
}

# :::::::::: Get information functions

getManager() {
  # Getting info about created manager
  export MANAGER_NAME="${ENV}-${DEFAULT_CLOUD}-${BASE_MANAGER_NAME}"
  ${MO} "${TEMPLATES_DIR}/manager-info-template.yaml" >"${CONFIG_DIR}/${ENV}/manager-info.yaml"
  ${TK8S} get manager --non-interactive \
    --config "${CONFIG_DIR}/${ENV}/manager-info.yaml"
}

getCluster() {
  local cluster_config=$1
  [[ ! -e "${cluster_config}" ]] && echo "Get cluster: Config file is required" && return

  echo ""
  echo "Getting information about cluster"
  echo ""

  echo "Triton Kubernetes version: $(${TK8S} version)"
  export MANAGER_NAME="${ENV}-${DEFAULT_CLOUD}-${BASE_MANAGER_NAME}"
  export CLUSTER_NAME=$(yq r "${cluster_config}" 'name')
  ${MO} "${TEMPLATES_DIR}/cluster-info-template.yaml" >"${CONFIG_DIR}/${ENV}/cluster-info.yaml"

  ${TK8S} get cluster --non-interactive \
    --config "${CONFIG_DIR}/${ENV}/cluster-info.yaml"
}

# :::::::::: Add functions

addCluster() {
  local current_cloud=$1
  [[ -z "${current_cloud}" ]] && echo "Add cluster: Cloud name is required" && return

  local cluster_name=$2
  [[ -z "${cluster_name}" ]] && echo "Add cluster: Cluster name is required" && return

  local cloud_list=()
  # Select cloud for cluster
  case "${current_cloud}" in
  aws | gcp)
    cloud_list=("${current_cloud}")
    ;;

  all)
    cloud_list=("aws" "gcp")
    ;;

  *)
    help && exit 1
    ;;
  esac

  echo ""
  echo "Adding cluster(s)"
  echo ""

  for cld in "${cloud_list[@]}"; do
    export MANAGER_NAME="${ENV}-${DEFAULT_CLOUD}-${BASE_MANAGER_NAME}"
    export CLUSTER_NAME="${ENV}-${cld}-${cluster_name}"
    export ETCD_NODE_NAME="${CLUSTER_NAME}-${BASE_ETCD_NODE_NAME}"
    export CONTROL_NODE_NAME="${CLUSTER_NAME}-${BASE_CONTROL_NODE_NAME}"
    export WORKER_NODE_NAME="${CLUSTER_NAME}-${BASE_WORKER_NODE_NAME}"
    renderClusterConfig "${cld}" >"${CONFIG_DIR}/${ENV}/${ENV}-${cld}-${cluster_name}.yaml"
    ${TK8S} create cluster --non-interactive \
      --config "${CONFIG_DIR}/${ENV}/${ENV}-${cld}-${cluster_name}.yaml"
    sleep 5
  done
}

addEtcdNode() {
  export NODE_TYPE="etcd"
  export BASE_NODE_NAME="${BASE_ETCD_NODE_NAME}"
  export NODE_COUNT=${ETCD_NODE_COUNT}
  addNode "$1"
}

addControlNode() {
  export NODE_TYPE="control"
  export BASE_NODE_NAME="${BASE_CONTROL_NODE_NAME}"
  export NODE_COUNT=${CONTROL_NODE_COUNT}
  addNode "$1"
}

addWokerNode() {
  export NODE_TYPE="worker"
  export BASE_NODE_NAME="${BASE_WORKER_NODE_NAME}"
  export NODE_COUNT=${WORKER_NODE_COUNT}
  addNode "$1"
}

addNode() {
  local cluster_config=$1
  [[ ! -e "${cluster_config}" ]] && echo "Add node: Cluster config file is required" && return

  echo ""
  echo "Adding ${NODE_TYPE} node"
  echo ""

  echo "Triton Kubernetes version: $(${TK8S} version)"
  export MANAGER_NAME="${ENV}-${DEFAULT_CLOUD}-${BASE_MANAGER_NAME}"
  export CLUSTER_NAME=$(yq r "${cluster_config}" 'name')
  export NODE_NAME="${CLUSTER_NAME}-${BASE_NODE_NAME}"
  local current_cloud=$(yq r "${cluster_config}" 'cluster_cloud_provider')

  renderNodeConfig "${current_cloud}" > \
    "${CONFIG_DIR}/${ENV}/${NODE_NAME}.yaml"

  ${TK8S} create node --non-interactive \
    --config "${CONFIG_DIR}/${ENV}/${NODE_NAME}.yaml"
}

# :::::::::: Destroy functions

function destroyManager() {
  echo ""
  echo "Destroing manager"
  echo ""

  echo "Triton Kubernetes version: $(${TK8S} version)"
  export MANAGER_NAME="${ENV}-${DEFAULT_CLOUD}-${BASE_MANAGER_NAME}"
  ${MO} "${TEMPLATES_DIR}/manager-info-template.yaml" >"${CONFIG_DIR}/${ENV}/manager-info.yaml"

  ${TK8S} destroy manager --non-interactive \
    --config "${CONFIG_DIR}/${ENV}/manager-info.yaml"
}

function destroyCluster() {
  local cluster_config=$1
  [[ ! -e "${cluster_config}" ]] && echo "Destroy cluster: Config file is required" && return

  echo ""
  echo "Destroing cluster"
  echo ""

  echo "Triton Kubernetes version: $(${TK8S} version)"
  export MANAGER_NAME="${ENV}-${DEFAULT_CLOUD}-${BASE_MANAGER_NAME}"
  export CLUSTER_NAME=$(yq r "${cluster_config}" 'name')
  ${MO} "${TEMPLATES_DIR}/cluster-info-template.yaml" >"${CONFIG_DIR}/${ENV}/cluster-info.yaml"

  ${TK8S} destroy cluster --non-interactive \
    --config "${CONFIG_DIR}/${ENV}/cluster-info.yaml"
}

function destroyNode() {
  local cluster_config=$1
  [[ ! -e "${cluster_config}" ]] && echo "Destroy node: Config file is required" && return

  echo ""
  echo "Destroing node"
  echo ""

  echo "Triton Kubernetes version: $(${TK8S} version)"
  export MANAGER_NAME="${ENV}-${DEFAULT_CLOUD}-${BASE_MANAGER_NAME}"
  export CLUSTER_NAME=$(yq r "${cluster_config}" 'name')
  ${MO} "${TEMPLATES_DIR}/node-info-template.yaml" >"${CONFIG_DIR}/${ENV}/node-info.yaml"

  ${TK8S} destroy node \
    --config "${CONFIG_DIR}/${ENV}/node-info.yaml"
}

# ####################################################
# Command selector
# ####################################################

case "${COMMAND}" in
setup)
  runSetup
  ;;

get)
  runGet
  ;;

add)
  runAdd
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
