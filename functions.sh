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
      current_cloud="${MCP_DEFAULT_CLOUD}"
      ;;

    *)
      echo "Unsupported cloud: '${current_cloud}'" && return
      ;;
    esac

    echo "DEBUG: manager name"
    export MCP_MANAGER_NAME="${ENV}-${current_cloud}-${MCP_BASE_MANAGER_NAME}"
    if [ "${current_cloud}" = "aws" ]; then
      key_name_suffix=$(date +%s | md5 | head -c 8)
      export MCP_AWS_MANAGER_KEY_NAME="${ENV}-${MCP_BASE_MANAGER_NAME}_public_key_${key_name_suffix}"
    fi
    echo "DEBUG: render manager config"
    renderManagerConfig "${current_cloud}" > \
      "${CONFIG_DIR}/${ENV}/${ENV}-${current_cloud}-${MCP_BASE_MANAGER_NAME}.yaml"


    for cln in $(echo "${MCP_BASE_CLUSTER_NAMES}")
    do
      for cloud_in_list in "${cloud_list[@]}"
      do
        export MCP_CLUSTER_NAME="${ENV}-${cloud_in_list}-${cln}"
        if [ "${cloud_in_list}" = "aws" ]; then
          key_name_suffix=$(date +%s | md5 | head -c 8)
          export MCP_AWS_CLUSTER_KEY_NAME="${MCP_CLUSTER_NAME}_public_key_${key_name_suffix}"
        fi
        export MCP_ETCD_NODE_NAME="${MCP_CLUSTER_NAME}-${MCP_BASE_ETCD_NODE_NAME}"
        export MCP_CONTROL_NODE_NAME="${MCP_CLUSTER_NAME}-${MCP_BASE_CONTROL_NODE_NAME}"
        export MCP_WORKER_NODE_NAME="${MCP_CLUSTER_NAME}-${MCP_BASE_WORKER_NODE_NAME}"
        renderClusterConfig "${cloud_in_list}" > "${CONFIG_DIR}/${ENV}/${ENV}-${cloud_in_list}-${cln}.yaml"
      done
    done

}
