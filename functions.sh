#!/usr/bin/env bash

##
## Configuration
##

print_env_vars() {
  echo ""
  echo "MCP ENVIRONMENT VARIABLES"
  echo "-------------------------"
  echo "MCP_ENV:" ${MCP_ENV}
  echo "MCP_BASE_MANAGER_CLOUD:" ${MCP_BASE_MANAGER_CLOUD}
  echo "MCP_BASE_MANAGER_NAME:" ${MCP_BASE_MANAGER_NAME}
  echo -n "MCP_RANCHER_ADMIN_PWD: " && echo ${MCP_RANCHER_ADMIN_PWD} | awk 'BEGIN{OFS=FS=""}{for(i=1;i<=NF-1 ;i++){ $i="*"} }1'
  echo "MCP_BASE_CLUSTER_NAME:" ${MCP_BASE_CLUSTER_NAME}
  echo "MCP_K8S_NETWORK_PROVIDER:" ${MCP_K8S_NETWORK_PROVIDER}
  echo "MCP_BASE_ETCD_NODE_NAME:" ${MCP_BASE_ETCD_NODE_NAME}
  echo "MCP_BASE_CONTROL_NODE_NAME:" ${MCP_BASE_CONTROL_NODE_NAME}
  echo "MCP_BASE_WORKER_NODE_NAME:" ${MCP_BASE_WORKER_NODE_NAME}
  echo "MCP_ETCD_NODE_COUNT:" ${MCP_ETCD_NODE_COUNT}
  echo "MCP_CONTROL_NODE_COUNT:" ${MCP_CONTROL_NODE_COUNT}
  echo "MCP_WORKER_NODE_COUNT:" ${MCP_WORKER_NODE_COUNT}
  echo -n "MCP_AWS_ACCESS_KEY: " && echo ${MCP_AWS_ACCESS_KEY} | awk 'BEGIN{OFS=FS=""}{for(i=1;i<=NF-2 ;i++){ $i="*"} }1'
  echo -n "MCP_AWS_SECRET_KEY: " && echo ${MCP_AWS_SECRET_KEY} | awk 'BEGIN{OFS=FS=""}{for(i=1;i<=NF-4 ;i++){ $i="*"} }1'
  echo "MCP_AWS_DEFAULT_REGION:" ${MCP_AWS_DEFAULT_REGION}
  echo "MCP_AWS_PUBLIC_KEY_PATH:" ${MCP_AWS_PUBLIC_KEY_PATH}
  echo "MCP_AWS_PRIVATE_KEY_PATH:" ${MCP_AWS_PRIVATE_KEY_PATH}
  echo "MCP_GCP_PROJECT_ID:" ${MCP_GCP_PROJECT_ID}
  echo "MCP_GCP_PATH_TO_CREDENTIALS:" ${MCP_GCP_PATH_TO_CREDENTIALS}
  echo "MCP_GCP_DEFAULT_REGION:" ${MCP_GCP_DEFAULT_REGION}
  echo "MCP_GCP_PUBLIC_KEY_PATH:" ${MCP_GCP_PUBLIC_KEY_PATH}
  echo "MCP_GCP_PRIVATE_KEY_PATH:" ${MCP_GCP_PRIVATE_KEY_PATH}
  echo ""
}

verify_env_vars() {
  # Verify whether environment vars are selected
  case "${OPTION_1}" in
  aws)
    [[ -z "${MCP_AWS_ACCESS_KEY}" ]] && echo "No AWS access key selected" && exit 1
    [[ -z "${MCP_AWS_SECRET_KEY}" ]] && echo "No AWS secret key selected" && exit 1
    ;;

  gcp)
    [[ -z "${MCP_GCP_PROJECT_ID}" ]] && echo "No GCP project selected" && exit 1
    [[ -z "${MCP_GCP_PATH_TO_CREDENTIALS}" ]] && echo "No GCP credentials selected" && exit 1
    ;;

  all)
    [[ -z "${MCP_AWS_ACCESS_KEY}" ]] && echo "No AWS access key selected" && exit 1
    [[ -z "${MCP_AWS_SECRET_KEY}" ]] && echo "No AWS secret key selected" && exit 1
    [[ -z "${MCP_GCP_PROJECT_ID}" ]] && echo "No GCP project selected" && exit 1
    [[ -z "${MCP_GCP_PATH_TO_CREDENTIALS}" ]] && echo "No GCP credentials selected" && exit 1
    ;;

  manager | cluster | node | enode | cnode | wnode)
    if [[ -z "${OPTION_2}" ]]; then
      echo "Continue"
    elif [[ ${OPTION_2} == *"aws"* ]]; then
      [[ -z "${MCP_AWS_ACCESS_KEY}" ]] && echo "No AWS access key selected" && exit 1
      [[ -z "${MCP_AWS_SECRET_KEY}" ]] && echo "No AWS secret key selected" && exit 1
    elif [[ ${OPTION_2} == *"gcp"* ]]; then
      [[ -z "${MCP_GCP_PROJECT_ID}" ]] && echo "No GCP project selected" && exit 1
      [[ -z "${MCP_GCP_PATH_TO_CREDENTIALS}" ]] && echo "No GCP credentials selected" && exit 1
    else
      help && exit 1
    fi
    ;;

  *)
    help && exit 1
    ;;
  esac

  echo "Environment variables verification completed"
}

export_env_vars() {
  ### EXPORT ENVIRONMENT VARS
  # deployment environment (dev/test/prod/etc.)
  export MCP_ENV=${MCP_ENV:-test}
  ### RANCHER
  # default cloud provider for rancher manager: aws or gcp
  export MCP_BASE_MANAGER_CLOUD=${MCP_BASE_MANAGER_CLOUD:-aws}
  # rancher manager name
  export MCP_BASE_MANAGER_NAME=${MCP_BASE_MANAGER_NAME:-manager}
  # rancher admin password
  export MCP_RANCHER_ADMIN_PWD=${MCP_RANCHER_ADMIN_PWD:-rancher}
  ### K8S
  # k8s cluster name
  export MCP_BASE_CLUSTER_NAME=${MCP_BASE_CLUSTER_NAME:-cluster}
  # k8s network provider: calico|canal|flannel|weave
  export MCP_K8S_NETWORK_PROVIDER=${MCP_K8S_NETWORK_PROVIDER:-calico}
  # k8s etcd node name
  export MCP_BASE_ETCD_NODE_NAME=${MCP_BASE_ETCD_NODE_NAME:-etcd}
  # k8s control node name
  export MCP_BASE_CONTROL_NODE_NAME=${MCP_BASE_CONTROL_NODE_NAME:-control}
  # k8s worker node name
  export MCP_BASE_WORKER_NODE_NAME=${MCP_BASE_WORKER_NODE_NAME:-worker}
  # number of etcd nodes per cluster
  export MCP_ETCD_NODE_COUNT=${MCP_ETCD_NODE_COUNT:-1}
  # number of control nodes per cluster
  export MCP_CONTROL_NODE_COUNT=${MCP_CONTROL_NODE_COUNT:-1}
  # number of worker nodes per cluster
  export MCP_WORKER_NODE_COUNT=${MCP_WORKER_NODE_COUNT:-1}
  ### AWS
  # aws platform access key
  export MCP_AWS_ACCESS_KEY=${MCP_AWS_ACCESS_KEY}
  # aws platform secret key
  export MCP_AWS_SECRET_KEY=${MCP_AWS_SECRET_KEY}
  # aws default region
  export MCP_AWS_DEFAULT_REGION=${MCP_AWS_DEFAULT_REGION:-eu-west-2}
  # auth public rsa key
  export MCP_AWS_PUBLIC_KEY_PATH=${MCP_AWS_PUBLIC_KEY_PATH:-~/.ssh/id_rsa.pub}
  # auth private rsa key
  export MCP_AWS_PRIVATE_KEY_PATH=${MCP_AWS_PRIVATE_KEY_PATH:-~/.ssh/id_rsa}
  ### GCP
  # gcp project id
  export MCP_GCP_PROJECT_ID=${MCP_GCP_PROJECT_ID}
  # gcp service account credentials
  export MCP_GCP_PATH_TO_CREDENTIALS=${MCP_GCP_PATH_TO_CREDENTIALS}
  # gcp default region
  export MCP_GCP_DEFAULT_REGION=${MCP_GCP_DEFAULT_REGION:-europe-west2}
  # auth public rsa key
  export MCP_GCP_PUBLIC_KEY_PATH=${MCP_GCP_PUBLIC_KEY_PATH:-~/.ssh/id_rsa.pub}
  # auth private rsa key
  export MCP_GCP_PRIVATE_KEY_PATH=${MCP_GCP_PRIVATE_KEY_PATH:-~/.ssh/id_rsa}
  echo "Environment variables exported"
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
