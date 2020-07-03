#!/usr/bin/env bash

set -e
help() {
   echo "Usage: ${SCRIPT_NAME} <command> [options]"
   echo ""
   echo "Commands:"
   echo "  setup    <cloud>    Setup monitoring/ELK infrastructure"
   echo "  destroy  <cloud>    Destroy monitoring/ELK infrastructure"
#   echo "  gends    <cloud>    Generate k8s manifests"
#   echo "  applyDS  <cloud>    Apply daemon sets"
#   echo "  deleteDS            Destroy daemon sets"
   echo ""
   echo "Commands options:"
   echo "  aws    Apply command to monitoring and ELK on AWS"
   echo "  gcp    Apply command to monitoring and ELK on Google cloud"
   echo "  all    Apply command to monitoring and ELK on all supported clouds"
   echo ""
}

SCRIPT_NAME=$0

echo "${SCRIPT_NAME}"

# Get script directory
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

COMMAND=$1
[[ -z "${COMMAND}" ]] && help && exit 1
shift

OPTION_1=$1
[[ -z "${OPTION_1}" ]] && help && exit 1
shift

OPTION_2=$1

# Load functions
source "${SCRIPT_DIR}/../functions.sh"

# Get local public IP address
LOCAL_PUBLIC_IP=$(dig +short -4 myip.opendns.com @resolver1.opendns.com)
export LOCAL_PUBLIC_IP=$LOCAL_PUBLIC_IP

export_env_vars

verify_env_vars

BIN="${SCRIPT_DIR}/../bin"
mkdir -p ${BIN}

PATH="${BIN}:${PATH}"

TERRAFORM="${BIN}/terraform"
TERRAFORM_BASE="${SCRIPT_DIR}/../terraform"
TERRAFORM_MODULES="${TERRAFORM_BASE}/modules"

TEMPLATES_DIR="${SCRIPT_DIR}/../config/templates"
ZBX_CONFIG_NAME="zabbix-agent-ds.yaml"
ELK_CONFIG_NAME="filebeat-ds.yaml"

MO="${BIN}/mo"

ZABBIX_RESOURCES="${SCRIPT_DIR}/../config/zabbix"

#source "${SCRIPT_DIR}/funcsmon.sh"

verifyTfvars() {
  if [[ -f ${TERRAFORM_ROOT}/terraform.tfvars ]]; then
    echo "Found terraform.tfvars file for ${TERRAFORM_ROOT_MODULE} setup"
  else
    echo "File terraform.tfvars not found for ${TERRAFORM_ROOT_MODULE} setup" && exit 1
  fi
}

runSetup() {
    [[ -z "${OPTION_1}" ]] && help && exit 1

    case "${OPTION_1}" in
      aws)
        TERRAFORM_ROOT_MODULE="zabbix-elk-aws-only"
        TERRAFORM_ROOT="${TERRAFORM_BASE}/monitoring/${TERRAFORM_ROOT_MODULE}"
        [[ ${TERRAFORM_COMMAND} == "destroy" ]] && verifyTfvars
        ;;

      gcp)
        export SERVICE_ACCOUNT_EMAIL=$(jq -r .client_email ${MCP_GCP_CREDENTIALS_PATH})
        echo "MCP_ENV:" ${MCP_ENV}
        [[ ${MCP_ENV} != "prod" ]] && export EXPIRATION_POLICY="604800s"
        TERRAFORM_ROOT_MODULE="zabbix-elk-gcp-only"
        TERRAFORM_ROOT="${TERRAFORM_BASE}/monitoring/${TERRAFORM_ROOT_MODULE}"
        [[ ${TERRAFORM_COMMAND} == "destroy" ]] && verifyTfvars
        ;;

      all)
        TERRAFORM_ROOT_MODULE="zabbix-elk-mcp"
        TERRAFORM_ROOT="${TERRAFORM_BASE}/monitoring/${TERRAFORM_ROOT_MODULE}"
        [[ ${TERRAFORM_COMMAND} == "destroy" ]] && verifyTfvars
        ;;

      *)
        echo "Option not available"
        help && exit 1
        ;;
    esac

    installDependencies
    ${TERRAFORM} version
    cd ${TERRAFORM_ROOT}
    ${MO} "${TERRAFORM_ROOT}/terraform.tfvars.template" > "${TERRAFORM_ROOT}/terraform.tfvars"
    setupOrDestroyZabbixServer
}

gends() {
    [[ -z "${OPTION_1}" ]] && help && exit 1

    case "${OPTION_1}" in
      aws)
        TERRAFORM_ROOT_MODULE="zabbix-elk-aws-only"
        TERRAFORM_ROOT="${TERRAFORM_BASE}/monitoring/${TERRAFORM_ROOT_MODULE}"
        ;;

      gcp)
        TERRAFORM_ROOT_MODULE="zabbix-elk-gcp-only"
        TERRAFORM_ROOT="${TERRAFORM_BASE}/monitoring/${TERRAFORM_ROOT_MODULE}"
        ;;

      all)
        TERRAFORM_ROOT_MODULE="zabbix-elk-mcp"
        TERRAFORM_ROOT="${TERRAFORM_BASE}/monitoring/${TERRAFORM_ROOT_MODULE}"
        ;;

      *)
        help && exit 1
        ;;
    esac

    ${TERRAFORM} version
    cd ${TERRAFORM_ROOT}
    generateDaemonsets
}

generateKubeconfig() {

    SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
    RANCHER_VARS="${SCRIPT_DIR}/../config/${MCP_ENV}/rancher.vars"

    if [[ ! -f ${RANCHER_VARS} ]]; then
      echo "RANCHER_VARS:" $RANCHER_VARS
      echo "rancher.vars file not found. Cluster manager might not exist. Verify and run mcadm.sh script to setup MCP"
      exit 1
    fi

    source "${RANCHER_VARS}"
    rancher_token="${RANCHER_ACCESS_KEY}:${RANCHER_SECRET_KEY}"
    rancher_clusters_api="${RANCHER_URL}/v3/clusters/"

    echo "Generating Kubeconfig files"

    set +e
    clusters=$(curl -ks -u "${rancher_token}" "${rancher_clusters_api}" | jq '.data[].name' | wc  -l)
    set -e

    if [ ${clusters} -ne 0 ]; then
        cluster=0
        while [ $cluster -lt ${clusters} ]; do
		        cluster_name=$(curl -ks -u "${rancher_token}" "${rancher_clusters_api}" | jq -r --argjson i $cluster '.data[$i].name')
		        cluster_id=$(curl -ks -u "${rancher_token}" "${rancher_clusters_api}" | jq -r --argjson i $cluster '.data[$i].id')
		        if [[ $cluster_name == *"aws"* ]]; then
			          curl -ks -u "${rancher_token}" -X POST -H 'Accept: application/json' -H 'Content-Type: application/json' -d '{}' "${rancher_clusters_api}${cluster_id}?action=generateKubeconfig" | jq -rc .config > ~/.kube/config.aws
			          echo "AWS Kubeconfig file generated"
		        elif [[ $cluster_name == *"gcp"* ]]; then
			          curl -ks -u "${rancher_token}" -X POST -H 'Accept: application/json' -H 'Content-Type: application/json' -d '{}' "${rancher_clusters_api}${cluster_id}?action=generateKubeconfig" | jq -rc .config > ~/.kube/config.gcp
			          echo "GCP Kubeconfig file generated"
		        else
			          echo "Coulnd't find any cluster for AWS or GCP providers"
		        fi
            let cluster=cluster+1
        done
    else
        echo "There are no clusters registered on the manager"
    fi

}

registerClusterNodes() {

    cd "${SCRIPT_DIR}"
    cp "${ZABBIX_RESOURCES}/zabbix-autoreg.json.template" "${ZABBIX_RESOURCES}/zabbix-autoreg.json"
    zabbix_token_json="${ZABBIX_RESOURCES}/zabbix-token.json"
    zabbix_autoreg_json="${ZABBIX_RESOURCES}/zabbix-autoreg.json"

    case "${OPTION_1}" in
      aws | all)
        cluster_kubecfg="config.aws"
        ;;

      gcp)
        cluster_kubecfg="config.gcp"
        ;;
    esac

    zabbix_srv_pub_ip=$(kubectl --kubeconfig ~/.kube/${cluster_kubecfg} get daemonsets -o json | jq -r .items[].spec.template.spec.containers[].env[1].value)
    zabbix_api="http://${zabbix_srv_pub_ip}/api_jsonrpc.php"

    echo "Waiting for the Zabbix server to respond..."

    until $(curl --output /dev/null --silent --head --fail http://${zabbix_srv_pub_ip}/); do
      printf '.'
      sleep 10
    done

    zabbix_token=$(curl -ks -H "Content-Type: application/json" -X POST --data @${zabbix_token_json} ${zabbix_api} | jq -r .result)

    sed -i'.bck' "s/ZABBIX_TOKEN/${zabbix_token}/" ${zabbix_autoreg_json}
    zabbix_autoreg=$(curl -ks -H "Content-Type: application/json" -X POST --data @${zabbix_autoreg_json} ${zabbix_api})

    if [[ ${zabbix_autoreg} == *"actionids"* ]]; then
      echo "Auto-registration action created. Cluster nodes will be registered to Zabbix server shortly"
    elif [[ ${zabbix_autoreg} == *"exists"* ]]; then
      echo "Cluster node will be registered to Zabbix server shortly"
    else
      echo "Something went wrong. Check whether the auto-registration action exists on the Zabbix server"
    fi
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
            echo "Couldn't determine OS type."
            exit 1
            ;;
    esac
}

installLinuxDependencies() {
    # Install Terraform
    if [[ ! -e "${TERRAFORM}" ]]; then
        echo ""
        echo "Getting terraform ..."
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

    # Install Mustache templates binary
    if [[ ! -e "${MO}" ]]; then
        echo ""
        echo "Getting mustache templates ..."
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
    # Install Terraform
    if [[ ! -e "${TERRAFORM}" ]]; then
        echo ""
        echo "Getting terraform ..."
        echo ""

        cd ${BIN}
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

clusterReadiness() {
    while [ ${cluster_readiness} -lt 3 ]; do
      cluster_readiness=$(kubectl --kubeconfig ~/.kube/${cluster_kubecfg} get nodes | grep Ready | wc -l)
      printf '.'
      sleep 10
    done
}

setupOrDestroyZabbixServer() {

    if [ ${TERRAFORM_COMMAND} == "apply" ]; then
      cluster_readiness=0
      echo "Waiting for cluster readiness"
      case "${OPTION_1}" in
        aws)
          cluster_kubecfg="config.aws"
          clusterReadiness
          ;;

        gcp)
          cluster_kubecfg="config.gcp"
          clusterReadiness
          ;;

        all)
          cluster_kubecfg="config.aws"
          clusterReadiness
          cluster_readiness=0
          cluster_kubecfg="config.gcp"
          clusterReadiness
      esac
    fi

    echo "Working directory: $(pwd)"
    ${TERRAFORM} init
    ${TERRAFORM} ${TERRAFORM_COMMAND} -auto-approve -var-file "${TERRAFORM_ROOT}/terraform.tfvars"
}


case "${COMMAND}" in
  setup)
    generateKubeconfig
    TERRAFORM_COMMAND=apply
    runSetup
    registerClusterNodes
    ;;

  destroy)
    generateKubeconfig
    TERRAFORM_COMMAND=destroy
    runSetup
    rm -rf "${TERRAFORM_ROOT}/.terraform/" \
           "${TERRAFORM_ROOT}/terraform.tfstate" \
           "${TERRAFORM_ROOT}/terraform.tfstate.backup" \
           "${TERRAFORM_ROOT}/terraform.tfvars" \
           "${ZABBIX_RESOURCES}/zabbix-autoreg.json" \
           "${ZABBIX_RESOURCES}/zabbix-autoreg.json.bck"
    ;;

  gends)
    gends
    ;;

  *)
    help && exit 1
    ;;
esac

echo -e "" && echo "MCP monitoring process completed: ${COMMAND}"
