#!/usr/bin/env bash

renderConfig() {
    local config_template=$1
    [[ -z "${config_template}" ]] && echo "Config template pathname is required" && return
    ${MO} "${config_template}"
}

generateDaemonsets() {
    [[ -z "${TEMPLATES_DIR}" ]] && echo "Set the templates dir value" && return
    export ZABBIX_PRIVATE_IP=$(${TERRAFORM} output zabbix_private_ip)
    export ELK_PRIVATE_IP=$(${TERRAFORM} output elk_private_ip)

    # Render Zabbix ds
    echo "Zabbix server IP: ${ZABBIX_PRIVATE_IP}"
    renderConfig "${TEMPLATES_DIR}/${ZBX_CONFIG_NAME}" > \
      "${K8S}/${ZBX_CONFIG_NAME}"
    # Render ELK ds
    echo "ELK IP: ${ELK_PRIVATE_IP}"
    renderConfig "${TEMPLATES_DIR}/${ELK_CONFIG_NAME}" > \
      "${K8S}/${ELK_CONFIG_NAME}"
}

applyDaemonsets() {
    while IFS= read -r -d '' file_yaml
    do
        file_name=$(basename ${file_yaml})

        echo "Processing ${file_name}"
        kubectl apply -f ${file_yaml}
    done < <(find "${K8S}" -type f -maxdepth 1 -name "*.yaml" -print0)
}

deleteDaemonsets() {
    while IFS= read -r -d '' file_yaml
    do
        file_name=$(basename ${file_yaml})

        echo "Processing ${file_name}"
        kubectl delete -f ${file_yaml}
    done < <(find "${K8S}" -type f -maxdepth 1 -name "*.yaml" -print0)
}
