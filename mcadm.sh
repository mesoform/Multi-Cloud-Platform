#!/usr/bin/env bash

set -o pipefail

help() {
  echo "Usage: ${SCRIPT_NAME} <command> [options]"
  echo ""
  echo "Commands:"
  echo "  setup      Setup multi-cloud Kubernetes"
  echo "  get        Get information about manager or cluster"
  echo "  add        Add nodes to existing cluster"
  echo "  destroy    Destroy cluster nodes or cluster manager and all associated clusters"
  echo ""
  echo ""
  echo "Setup command options:"
  echo "  aws        Setup cluster namager and Kubernetes cluster on AWS"
  echo "  gcp        Setup cluster namager and Kubernetes cluster on GCP"
  echo "  all        Setup cluster namager and Kubernetes cluster on all supported clouds"
  echo ""
  echo "Get command options:"
  echo "  manager                    Get information about current manager"
  echo "  cluster <cluster_config>   Get information about cluster, identified by <cluster_config> / e.g: cluster config/test/dev-aws-cluster.yaml "
  echo ""
  echo "Add command options:"
#  echo "  cluster <cloud> <name>      Add cluster for default manager, cluster name will be: <env>-<cloud>-<name> / e.g: add cluster aws cluster-1"
  echo "  enode <cluster_config>     Add etcd node to cluster, identified by <cluster_config> / e.g: enode config/test/dev-aws-cluster.yaml"
  echo "  cnode <cluster_config>     Add control node to cluster, identified by <cluster_config> / e.g: cnode config/test/dev-aws-cluster.yaml"
  echo "  wnode <cluster_config>     Add worker node to cluster, identified by <cluster_config> / e.g: wnode config/test/dev-aws-cluster.yaml"
  echo ""
  echo "Destroy command options:"
  echo "  manager                    Destroy current manager and all associated clusters"
#  echo "  cluster <cluster_config>     Destroy cluster, identified by <cluster_config> / e.g: cluster config/test/dev-aws-cluster.yaml"
  echo "  node <cluster_config>      Select and destroy node in cluster, identified by <cluster_config> / e.g: node config/test/dev-aws-cluster.yaml"
  echo ""
}

SCRIPT_NAME=$0

# Get script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

COMMAND=$1
[[ -z "${COMMAND}" ]] && help && exit 1
shift

OPTION_1=$1
[[ -z "${OPTION_1}" ]] && help && exit 1
shift

OPTION_2=$1
#shift

#OPTION_3=$1

# Load functions
source "${SCRIPT_DIR}/functions.sh"

# Get local public IP address
LOCAL_PUBLIC_IP=$(dig +short myip.opendns.com @resolver1.opendns.com)
export LOCAL_PUBLIC_IP=$LOCAL_PUBLIC_IP

export_env_vars

verify_env_vars

# Configurations directory
CONFIG_DIR="${SCRIPT_DIR}/config"
mkdir -p "${CONFIG_DIR}/${MCP_ENV}"
TEMPLATES_DIR="${CONFIG_DIR}/templates"
RANCHER_VARS="${CONFIG_DIR}/${MCP_ENV}/rancher.vars"

# Binaries directory
BIN="${SCRIPT_DIR}/bin"
mkdir -p "${BIN}"
PATH="${BIN}:${PATH}"

TERRAFORM="${BIN}/terraform"
TERRAFORM_MON="${SCRIPT_DIR}/terraform/monitoring"
MONIADM_ACTION=""
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

# Export config vars
export CONFIG_DIR=$CONFIG_DIR
export TEMPLATES_DIR=$TEMPLATES_DIR
export RANCHER_VARS=$RANCHER_VARS
export TERRAFORM=$TERRAFORM
export TERRAFORM_MON=$TERRAFORM_MON
export MONIADM_ACTION=$MONIADM_ACTION
export TK8S=$TK8S
export MO=$MO

set -e
set -u

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
            echo "Couldn't determine OS type."
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
        echo "Getting terraform ..."
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
        echo "Getting triton-kubernetes ..."
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
        echo "Getting mustache templates ..."
        echo ""

        cd "${BIN}"
        curl -sSL https://git.io/get-mo -o mo
        chmod +x mo
        cd "${SCRIPT_DIR}"

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
        echo "Getting terraform ..."
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
        echo "Getting triton-kubernetes ..."
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
        echo "Getting mustache templates ..."
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

# ####################################################
# Command Runners
# ####################################################

runMoniadm() {
  if [[ -f ${TERRAFORM_MON}/zabbix-elk-aws-only/terraform.tfvars ]]; then
    echo "Found terraform.tfvars for AWS setup"
    ${SCRIPT_DIR}/monitoring/moniadm.sh ${MONIADM_ACTION} aws
  elif [[ -f ${TERRAFORM_MON}/zabbix-elk-gcp-only/terraform.tfvars ]]; then
    echo "Found terraform.tfvars for GCP setup"
    ${SCRIPT_DIR}/monitoring/moniadm.sh ${MONIADM_ACTION} gcp
  elif [[ -f ${TERRAFORM_MON}/zabbix-elk-mcp/terraform.tfvars ]]; then
    echo "Found terraform.tfvars for MCP setup"
    ${SCRIPT_DIR}/monitoring/moniadm.sh ${MONIADM_ACTION} all
  else
    echo "File terraform.tfvars not found"
  fi
}

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
    echo "Option not available"
    help && exit 1
    ;;
  esac

  # Getting info about created manager
  if [[ "${OPTION_1}" = "aws" ]]; then
    MCP_BASE_MANAGER_CLOUD="aws"
  elif [[ "${OPTION_1}" = "gcp" ]]; then
    MCP_BASE_MANAGER_CLOUD="gcp"
  fi
  getManager

  # Monitoring: Zabbix and ELK setup
  ${SCRIPT_DIR}/monitoring/moniadm.sh setup ${OPTION_1}

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
#  cluster)
#    addCluster "${OPTION_2}" "${OPTION_3}"
#    ;;

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
    MONIADM_ACTION="destroy"
    runMoniadm
    destroyManager
    ;;

#  cluster)
#    destroyCluster "${OPTION_2}"
#    ;;

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
  [[ -z "${current_cloud}" ]] && echo "Setup manager: Cloud name is required" && exit 1

  # Select cloud for manager
  [[ "${current_cloud}" == "all" ]] && current_cloud="${MCP_BASE_MANAGER_CLOUD}"

  echo ""
  echo "Creating manager"
  echo ""

  echo "Triton Kubernetes version: $(${TK8S} version)"
  echo ""
  ${TK8S} create manager --non-interactive \
    --config "${CONFIG_DIR}/${MCP_ENV}/${MCP_ENV}-${current_cloud}-${MCP_BASE_MANAGER_NAME}.yaml"
}

setupCluster() {
  local current_cloud=$1
  [[ -z "${current_cloud}" ]] && echo "Setup cluster: Cloud name is required" && exit 1

  # Select cloud for cluster
  [[ "${current_cloud}" == "all" ]] && current_cloud="*"

  echo ""
  echo "Creating cluster(s)"
  echo ""

  for cln in $(echo "${MCP_BASE_CLUSTER_NAME}"); do
    for cnf in "${CONFIG_DIR}"/"${MCP_ENV}"/"${MCP_ENV}"-${current_cloud}-"${cln}".yaml; do
      ${TK8S} create cluster --non-interactive --config "${cnf}"
      sleep 5
    done
  done
}

# :::::::::: Get information functions

getManager() {

  if [[ -f ${RANCHER_VARS} ]]; then
    source ${RANCHER_VARS}
    MCP_BASE_MANAGER_CLOUD=${RANCHER_CLOUD}
  fi
  # Getting info about created manager
  export MCP_MANAGER_NAME="${MCP_ENV}-${MCP_BASE_MANAGER_CLOUD}-${MCP_BASE_MANAGER_NAME}"
  ${MO} "${TEMPLATES_DIR}/manager-info-template.yaml" >"${CONFIG_DIR}/${MCP_ENV}/manager-info.yaml"
  ${TK8S} get manager --non-interactive \
    --config "${CONFIG_DIR}/${MCP_ENV}/manager-info.yaml"

  # Generate rancher variables file
  export RANCHER_ACCESS_KEY=$(${TERRAFORM} output -module=cluster-manager -state="$HOME/.triton-kubernetes/${MCP_MANAGER_NAME}/terraform.tfstate" rancher_access_key)
  export RANCHER_SECRET_KEY=$(${TERRAFORM} output -module=cluster-manager -state="$HOME/.triton-kubernetes/${MCP_MANAGER_NAME}/terraform.tfstate" rancher_secret_key)
  export RANCHER_URL=$(${TERRAFORM} output -module=cluster-manager -state="$HOME/.triton-kubernetes/${MCP_MANAGER_NAME}/terraform.tfstate" rancher_url)

  echo "RANCHER_ACCESS_KEY=\"$RANCHER_ACCESS_KEY\"" > ${RANCHER_VARS}
  echo "RANCHER_SECRET_KEY=\"$RANCHER_SECRET_KEY\"" >> ${RANCHER_VARS}
  echo "RANCHER_URL=\"$RANCHER_URL\"" >> ${RANCHER_VARS}
  echo "RANCHER_CLOUD=\"$MCP_BASE_MANAGER_CLOUD\"" >> ${RANCHER_VARS}
  echo ""
}

getCluster() {
  local cluster_config=$1
  [[ ! -e "${cluster_config}" ]] && echo "Get cluster: Config file is required" && exit 1

  echo ""
  echo "Getting information about cluster"
  echo ""

  echo "Triton Kubernetes version: $(${TK8S} version)"
  export MCP_MANAGER_NAME=$(yq r "${cluster_config}" 'cluster_manager')
  export MCP_CLUSTER_NAME=$(yq r "${cluster_config}" 'name')
  ${MO} "${TEMPLATES_DIR}/cluster-info-template.yaml" >"${CONFIG_DIR}/${MCP_ENV}/cluster-info.yaml"

  ${TK8S} get cluster --non-interactive \
    --config "${CONFIG_DIR}/${MCP_ENV}/cluster-info.yaml"
}

# :::::::::: Add functions

addCluster() {
  local current_cloud=$1
  [[ -z "${current_cloud}" ]] && echo "Add cluster: Cloud name is required" && exit 1

  local cluster_name=$2
  [[ -z "${cluster_name}" ]] && echo "Add cluster: Cluster name is required" && exit 1

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
    export MCP_MANAGER_NAME="${MCP_ENV}-${MCP_BASE_MANAGER_CLOUD}-${MCP_BASE_MANAGER_NAME}"
    export MCP_CLUSTER_NAME="${MCP_ENV}-${cld}-${cluster_name}"
    export MCP_ETCD_NODE_NAME="${MCP_CLUSTER_NAME}-${MCP_BASE_ETCD_NODE_NAME}"
    export MCP_CONTROL_NODE_NAME="${MCP_CLUSTER_NAME}-${MCP_BASE_CONTROL_NODE_NAME}"
    export MCP_WORKER_NODE_NAME="${MCP_CLUSTER_NAME}-${MCP_BASE_WORKER_NODE_NAME}"
    if [ "${cld}" = "aws" ]; then
      key_name_suffix=$(date +%s | md5 | head -c 8)
      export MCP_AWS_CLUSTER_KEY_NAME="${MCP_CLUSTER_NAME}_public_key_${key_name_suffix}"
    fi
    renderClusterConfig "${cld}" >"${CONFIG_DIR}/${MCP_ENV}/${MCP_ENV}-${cld}-${cluster_name}.yaml"
    ${TK8S} create cluster --non-interactive \
      --config "${CONFIG_DIR}/${MCP_ENV}/${MCP_ENV}-${cld}-${cluster_name}.yaml"
    sleep 5
  done
}

addEtcdNode() {
  export MCP_NODE_TYPE="etcd"
  export MCP_BASE_NODE_NAME="${MCP_BASE_ETCD_NODE_NAME}"
  export MCP_NODE_COUNT=1 #${MCP_ETCD_NODE_COUNT}
  addNode "$1"
}

addControlNode() {
  export MCP_NODE_TYPE="control"
  export MCP_BASE_NODE_NAME="${MCP_BASE_CONTROL_NODE_NAME}"
  export MCP_NODE_COUNT=1 #${MCP_CONTROL_NODE_COUNT}
  addNode "$1"
}

addWokerNode() {
  export MCP_NODE_TYPE="worker"
  export MCP_BASE_NODE_NAME="${MCP_BASE_WORKER_NODE_NAME}"
  export MCP_NODE_COUNT=1 #${MCP_WORKER_NODE_COUNT}
  addNode "$1"
}

addNode() {
  local cluster_config=$1
  [[ ! -e "${cluster_config}" ]] && echo "Add node: Cluster config file is required" && exit 1

  echo ""
  echo "Adding ${MCP_NODE_TYPE} node"
  echo ""

  echo "Triton Kubernetes version: $(${TK8S} version)"
  export MCP_MANAGER_NAME=$(yq r "${cluster_config}" 'cluster_manager')
  export MCP_CLUSTER_NAME=$(yq r "${cluster_config}" 'name')
  export MCP_NODE_NAME="${MCP_CLUSTER_NAME}-${MCP_BASE_NODE_NAME}"
  local current_cloud=$(yq r "${cluster_config}" 'cluster_cloud_provider')

  renderNodeConfig "${current_cloud}" > \
    "${CONFIG_DIR}/${MCP_ENV}/${MCP_NODE_NAME}.yaml"

  ${TK8S} create node --non-interactive \
    --config "${CONFIG_DIR}/${MCP_ENV}/${MCP_NODE_NAME}.yaml"
}

# :::::::::: Destroy functions

function destroyManager() {
  echo ""
  echo "Destroying manager"
  echo ""

  source ${RANCHER_VARS} && MCP_BASE_MANAGER_CLOUD=${RANCHER_CLOUD}

  echo "Triton Kubernetes version: $(${TK8S} version)"
  export MCP_MANAGER_NAME="${MCP_ENV}-${MCP_BASE_MANAGER_CLOUD}-${MCP_BASE_MANAGER_NAME}"
  ${MO} "${TEMPLATES_DIR}/manager-info-template.yaml" >"${CONFIG_DIR}/${MCP_ENV}/manager-info.yaml"

  ${TK8S} destroy manager --non-interactive \
    --config "${CONFIG_DIR}/${MCP_ENV}/manager-info.yaml"

  rm -rf "${CONFIG_DIR:?}/${MCP_ENV:?}/"
}

function destroyCluster() {
  local cluster_config=$1
  [[ ! -e "${cluster_config}" ]] && echo "Destroy cluster: Config file is required" && exit 1

  echo ""
  echo "Destroying cluster"
  echo ""

  echo "Triton Kubernetes version: $(${TK8S} version)"
  export MCP_MANAGER_NAME=$(yq r "${cluster_config}" 'cluster_manager')
  export MCP_CLUSTER_NAME=$(yq r "${cluster_config}" 'name')
  ${MO} "${TEMPLATES_DIR}/cluster-info-template.yaml" >"${CONFIG_DIR}/${MCP_ENV}/cluster-info.yaml"

  ${TK8S} destroy cluster --non-interactive \
    --config "${CONFIG_DIR}/${MCP_ENV}/cluster-info.yaml"
}

function destroyNode() {
  local cluster_config=$1
  [[ ! -e "${cluster_config}" ]] && echo "Destroy node: Config file is required" && exit 1

  echo ""
  echo "Destroying node"
  echo ""

  echo "Triton Kubernetes version: $(${TK8S} version)"
  export MCP_MANAGER_NAME=$(yq r "${cluster_config}" 'cluster_manager')
  export MCP_CLUSTER_NAME=$(yq r "${cluster_config}" 'name')
  ${MO} "${TEMPLATES_DIR}/node-info-template.yaml" >"${CONFIG_DIR}/${MCP_ENV}/node-info.yaml"

  ${TK8S} destroy node \
    --config "${CONFIG_DIR}/${MCP_ENV}/node-info.yaml"
}


# ####################################################
# Command selector
# ####################################################

case "${COMMAND}" in
setup)
  print_env_vars
  installDependencies
  runSetup
  ;;

get)
  runGet
  ;;

add)
  runAdd
  MONIADM_ACTION="setup"
  runMoniadm
  ;;

destroy)
  runDestroy
  ;;

*)
  help && exit 1
  ;;
esac

echo -n "" && echo "MCP admin process completed: ${COMMAND}"
