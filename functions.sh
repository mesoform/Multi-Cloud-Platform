#!/usr/bin/env bash

##
## Configuration
##

source_environment() {
  echo "Source Environment"
  set -a
  source "${ENV_PATH}"
  set +a
}

print_env_vars() {
  echo "MCP_ENV:" ${MCP_ENV}
  echo "MCP_BASE_MANAGER_CLOUD:" ${MCP_BASE_MANAGER_CLOUD}
  echo "MCP_BASE_MANAGER_NAME:" ${MCP_BASE_MANAGER_NAME}
  echo "MCP_RANCHER_ADMIN_PWD:" ${MCP_RANCHER_ADMIN_PWD}
  echo "MCP_BASE_CLUSTER_NAME:" ${MCP_BASE_CLUSTER_NAME}
  echo "MCP_K8S_NETWORK_PROVIDER:" ${MCP_K8S_NETWORK_PROVIDER}
  echo "MCP_BASE_ETCD_NODE_NAME:" ${MCP_BASE_ETCD_NODE_NAME}
  echo "MCP_BASE_CONTROL_NODE_NAME:" ${MCP_BASE_CONTROL_NODE_NAME}
  echo "MCP_BASE_WORKER_NODE_NAME:" ${MCP_BASE_WORKER_NODE_NAME}
  echo "MCP_ETCD_NODE_COUNT:" ${MCP_ETCD_NODE_COUNT}
  echo "MCP_CONTROL_NODE_COUNT:" ${MCP_CONTROL_NODE_COUNT}
  echo "MCP_WORKER_NODE_COUNT:" ${MCP_WORKER_NODE_COUNT}
  echo "MCP_AWS_ACCESS_KEY:" ${MCP_AWS_ACCESS_KEY}
  echo "MCP_AWS_SECRET_KEY:" ${MCP_AWS_SECRET_KEY}
  echo "MCP_AWS_DEFAULT_REGION:" ${MCP_AWS_DEFAULT_REGION}
  echo "MCP_AWS_PUBLIC_KEY_PATH:" ${MCP_AWS_PUBLIC_KEY_PATH}
  echo "MCP_AWS_PRIVATE_KEY_PATH:" ${MCP_AWS_PRIVATE_KEY_PATH}
  echo "MCP_GCP_PROJECT_ID:" ${MCP_GCP_PROJECT_ID}
  echo "MCP_GCP_PATH_TO_CREDENTIALS:" ${MCP_GCP_PATH_TO_CREDENTIALS}
  echo "MCP_GCP_DEFAULT_REGION:" ${MCP_GCP_DEFAULT_REGION}
  echo "MCP_GCP_PUBLIC_KEY_PATH:" ${MCP_GCP_PUBLIC_KEY_PATH}
  echo "MCP_GCP_PRIVATE_KEY_PATH:" ${MCP_GCP_PRIVATE_KEY_PATH}
}

verify_env_vars() {
  # Verify whether environment vars are selected
  echo "Environment:" ${MCP_ENV}
  [[ -z "${MCP_ENV}" ]] && echo "No environment selected" && exit 1
  echo "AWS access key:" ${MCP_AWS_ACCESS_KEY}
  [[ -z "${MCP_AWS_ACCESS_KEY}" ]] && echo "No AWS access key selected" && exit 1
  echo "AWS secret key:" ${MCP_AWS_SECRET_KEY}
  [[ -z "${MCP_AWS_SECRET_KEY}" ]] && echo "No AWS secret key selected" && exit 1
  echo "GCP project id:" ${MCP_GCP_PROJECT_ID}
  [[ -z "${MCP_GCP_PROJECT_ID}" ]] && echo "No GCP project selected" && exit 1
  echo "GCP credentials:" ${MCP_GCP_PATH_TO_CREDENTIALS}
  [[ -z "${MCP_GCP_PATH_TO_CREDENTIALS}" ]] && echo "No GCP credentials selected" && exit 1
  echo "> Environment variables verification completed"
}

export_env_vars() {
  # Export environment vars
  export MCP_ENV=${MCP_ENV:-${DEFAULT_MCP_ENV}}
  # RANCHER
  export MCP_BASE_MANAGER_CLOUD=${MCP_BASE_MANAGER_CLOUD:-${DEFAULT_MCP_BASE_MANAGER_CLOUD}}
  export MCP_BASE_MANAGER_NAME=${MCP_BASE_MANAGER_NAME:-${DEFAULT_MCP_BASE_MANAGER_NAME}}
  export MCP_RANCHER_ADMIN_PWD=${MCP_RANCHER_ADMIN_PWD:-${DEFAULT_MCP_RANCHER_ADMIN_PWD}}
  # K8S
  export MCP_BASE_CLUSTER_NAME=${MCP_BASE_CLUSTER_NAME:-${DEFAULT_MCP_BASE_CLUSTER_NAME}}
  export MCP_K8S_NETWORK_PROVIDER=${MCP_K8S_NETWORK_PROVIDER:-${DEFAULT_MCP_K8S_NETWORK_PROVIDER}}
  export MCP_BASE_ETCD_NODE_NAME=${MCP_BASE_ETCD_NODE_NAME:-${DEFAULT_MCP_BASE_ETCD_NODE_NAME}}
  export MCP_BASE_CONTROL_NODE_NAME=${MCP_BASE_CONTROL_NODE_NAME:-${DEFAULT_MCP_BASE_CONTROL_NODE_NAME}}
  export MCP_BASE_WORKER_NODE_NAME=${MCP_BASE_WORKER_NODE_NAME:-${DEFAULT_MCP_BASE_WORKER_NODE_NAME}}
  export MCP_ETCD_NODE_COUNT=${MCP_ETCD_NODE_COUNT:-${DEFAULT_MCP_ETCD_NODE_COUNT}}
  export MCP_CONTROL_NODE_COUNT=${MCP_CONTROL_NODE_COUNT:-${DEFAULT_MCP_CONTROL_NODE_COUNT}}
  export MCP_WORKER_NODE_COUNT=${MCP_WORKER_NODE_COUNT:-${DEFAULT_MCP_WORKER_NODE_COUNT}}
  # AWS
  export MCP_AWS_ACCESS_KEY=${MCP_AWS_ACCESS_KEY:-${DEFAULT_MCP_AWS_ACCESS_KEY}}
  export MCP_AWS_SECRET_KEY=${MCP_AWS_SECRET_KEY:-${DEFAULT_MCP_AWS_SECRET_KEY}}
  export MCP_AWS_DEFAULT_REGION=${MCP_AWS_DEFAULT_REGION:-${DEFAULT_MCP_AWS_DEFAULT_REGION}}
  export MCP_AWS_PUBLIC_KEY_PATH=${MCP_AWS_PUBLIC_KEY_PATH:-${DEFAULT_MCP_AWS_PUBLIC_KEY_PATH}}
  export MCP_AWS_PRIVATE_KEY_PATH=${MCP_AWS_PRIVATE_KEY_PATH:-${DEFAULT_MCP_AWS_PRIVATE_KEY_PATH}}
  # GCP
  export MCP_GCP_PROJECT_ID=${MCP_GCP_PROJECT_ID:-${DEFAULT_MCP_GCP_PROJECT_ID}}
  export MCP_GCP_PATH_TO_CREDENTIALS=${MCP_GCP_PATH_TO_CREDENTIALS:-${DEFAULT_MCP_GCP_PATH_TO_CREDENTIALS}}
  export MCP_GCP_DEFAULT_REGION=${MCP_GCP_DEFAULT_REGION:-${DEFAULT_MCP_GCP_DEFAULT_REGION}}
  export MCP_GCP_PUBLIC_KEY_PATH=${MCP_GCP_PUBLIC_KEY_PATH:-${DEFAULT_MCP_GCP_PUBLIC_KEY_PATH}}
  export MCP_GCP_PRIVATE_KEY_PATH=${MCP_GCP_PRIVATE_KEY_PATH:-${DEFAULTMCP_GCP_PRIVATE_KEY_PATH}}
  echo "> Environment variables exported"
}

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
    source_environment
    local current_cloud=$1
    [[ -z "${current_cloud}" ]] && echo "Configuration: Cloud name is required" && return


    set -a
    local cloud_list=()
    # Select cloud
    case "${current_cloud}" in
    aws | gcp)
      cloud_list=("${current_cloud}")
      ;;

    all)
      cloud_list=("aws" "gcp")
      current_cloud="${MCP_BASE_MANAGER_CLOUD}"
      ;;

    *)
      echo "Unsupported cloud: '${current_cloud}'" && return
      ;;
    esac

    echo "DEBUG: manager name"
    export MCP_MANAGER_NAME="${MCP_ENV}-${current_cloud}-${MCP_BASE_MANAGER_NAME}"
    if [ "${current_cloud}" = "aws" ]; then
      key_name_suffix=$(date +%s | md5 | head -c 8)
      export MCP_AWS_MANAGER_KEY_NAME="${MCP_ENV}-${MCP_BASE_MANAGER_NAME}_public_key_${key_name_suffix}"
    fi
    echo "DEBUG: render manager config"
    renderManagerConfig "${current_cloud}" > \
      "${CONFIG_DIR}/${MCP_ENV}/${MCP_ENV}-${current_cloud}-${MCP_BASE_MANAGER_NAME}.yaml"


    for cln in $(echo "${MCP_BASE_CLUSTER_NAME}")
    do
      for cloud_in_list in "${cloud_list[@]}"
      do
        export MCP_CLUSTER_NAME="${MCP_ENV}-${cloud_in_list}-${cln}"
        if [ "${cloud_in_list}" = "aws" ]; then
          key_name_suffix=$(date +%s | md5 | head -c 8)
          export MCP_AWS_CLUSTER_KEY_NAME="${MCP_CLUSTER_NAME}_public_key_${key_name_suffix}"
        fi
        export MCP_ETCD_NODE_NAME="${MCP_CLUSTER_NAME}-${MCP_BASE_ETCD_NODE_NAME}"
        export MCP_CONTROL_NODE_NAME="${MCP_CLUSTER_NAME}-${MCP_BASE_CONTROL_NODE_NAME}"
        export MCP_WORKER_NODE_NAME="${MCP_CLUSTER_NAME}-${MCP_BASE_WORKER_NODE_NAME}"
        renderClusterConfig "${cloud_in_list}" > "${CONFIG_DIR}/${MCP_ENV}/${MCP_ENV}-${cloud_in_list}-${cln}.yaml"
      done
    done

}
