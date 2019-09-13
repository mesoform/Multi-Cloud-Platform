#!/usr/bin/env bash

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

    local cloud_list=()
    # Select cloud
    case "${current_cloud}" in
    aws | gcp)
      cloud_list=("${current_cloud}")
      ;;

    all)
      cloud_list=("aws" "gcp")
      current_cloud="${DEFAULT_CLOUD}"
      ;;

    *)
      echo "Unsupported cloud: '${current_cloud}'" && return
      ;;
    esac

    export MANAGER_NAME="${ENV}-${current_cloud}-${BASE_MANAGER_NAME}"
    renderManagerConfig "${current_cloud}" > \
      "${CONFIG_DIR}/${ENV}/${ENV}-${current_cloud}-${BASE_MANAGER_NAME}.yaml"


    for cln in $(echo "${BASE_CLUSTER_NAMES}")
    do
      for cloud_in_list in "${cloud_list[@]}"
      do
        export CLUSTER_NAME="${ENV}-${cloud_in_list}-${cln}"
        export ETCD_NODE_NAME="${CLUSTER_NAME}-${BASE_ETCD_NODE_NAME}"
        export CONTROL_NODE_NAME="${CLUSTER_NAME}-${BASE_CONTROL_NODE_NAME}"
        export WORKER_NODE_NAME="${CLUSTER_NAME}-${BASE_WORKER_NODE_NAME}"
        renderClusterConfig "${cloud_in_list}" > "${CONFIG_DIR}/${ENV}/${ENV}-${cloud_in_list}-${cln}.yaml"
      done
    done

}
