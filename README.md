# Multi cloud platform scripts

Multi cloud platform contains scripts and configurations to run interactive deployment of Triton Kubernetes solution on AWS and/or GCP along with Zabbix monitoring and Elastic Stack logging.

## Quick start guide

### Prepare to run deployment

Clone the `mcp-setup` git repository and edit the configuration file `default.vars` found under `env` folder to set defaults for environment variables:

```
# Edit and make the appropriate changes relevant to your environment and cloud providers (AWS/GCP)
#
DEFAULT_MCP_ENV="test"                                 # deployment environment (dev/test/prod/etc.)
# RANCHER
DEFAULT_MCP_BASE_MANAGER_CLOUD="aws"                   # default cloud provider for rancher manager: aws or gcp
DEFAULT_MCP_BASE_MANAGER_NAME="manager"                # rancher manager name
DEFAULT_MCP_RANCHER_ADMIN_PWD="rancher"                # rancher admin password
# K8S
DEFAULT_MCP_BASE_CLUSTER_NAME="cluster"                # k8s cluster name
DEFAULT_MCP_K8S_NETWORK_PROVIDER="calico"              # k8s network provider: calico|canal|flannel|weave
DEFAULT_MCP_BASE_ETCD_NODE_NAME="etcd"                 # k8s etcd node name
DEFAULT_MCP_BASE_CONTROL_NODE_NAME="control"           # k8s control node name
DEFAULT_MCP_BASE_WORKER_NODE_NAME="worker"             # k8s worker node name
DEFAULT_MCP_ETCD_NODE_COUNT=1                          # number of etcd nodes per cluster
DEFAULT_MCP_CONTROL_NODE_COUNT=1                       # number of control nodes per cluster
DEFAULT_MCP_WORKER_NODE_COUNT=1                        # number of worker nodes per cluster
# AWS
DEFAULT_MCP_AWS_ACCESS_KEY=""                          # aws platform access key. E.g. MCP_AWS_ACCESS_KEY=AKIB6TGAWR66MFOPZAW
DEFAULT_MCP_AWS_SECRET_KEY=""                          # aws platform secret key. E.g. MCP_AWS_SECRET_KEY=bX4r02gt7OPDfv5lcdueKJdXSKcNNT9rklczescd
DEFAULT_MCP_AWS_DEFAULT_REGION="eu-west-2"             # aws default region
DEFAULT_MCP_AWS_PUBLIC_KEY_PATH="~/.ssh/id_rsa.pub"    # auth public rsa key
DEFAULT_MCP_AWS_PRIVATE_KEY_PATH="~/.ssh/id_rsa"       # auth private rsa key
# GCP
DEFAULT_MCP_GCP_PROJECT_ID=""                          # gcp project id. E.g. MCP_GCP_PROJECT_ID=mcp-testing
DEFAULT_MCP_GCP_PATH_TO_CREDENTIALS=""                 # gcp service account credentials. E.g. MCP_GCP_PATH_TO_CREDENTIALS=~/.ssh/gcp-credentials.json
DEFAULT_MCP_GCP_DEFAULT_REGION="europe-west2"          # gcp default region
DEFAULT_MCP_GCP_PUBLIC_KEY_PATH="~/.ssh/id_rsa.pub"    # auth public rsa key
DEFAULT_MCP_GCP_PRIVATE_KEY_PATH="~/.ssh/id_rsa"       # auth private rsa key
```

Environment variables can also be set locally on your current shell (name should be the same as the default variables without the DEFAULT_ prefix):
    
    E.g:
    ```
    export MCP_ENV="test"
    export MCP_BASE_MANAGER_CLOUD="aws"
    export MCP_BASE_MANAGER_NAME="manager"
    export MCP_RANCHER_ADMIN_PWD="rancher"
    export MCP_BASE_CLUSTER_NAME="cluster"
    export MCP_K8S_NETWORK_PROVIDER="calico"
    export MCP_BASE_ETCD_NODE_NAME="etcd"
    export MCP_BASE_CONTROL_NODE_NAME="control"
    export MCP_BASE_WORKER_NODE_NAME="worker"
    export MCP_ETCD_NODE_COUNT=1
    export MCP_CONTROL_NODE_COUNT=1
    export MCP_WORKER_NODE_COUNT=1
    export MCP_AWS_ACCESS_KEY="AKIB6TGAWR66MFOPZAW"
    export MCP_AWS_SECRET_KEY="bX4r02gt7OPDfv5lcdueKJdXSKcNNT9rklczescd"
    export MCP_AWS_DEFAULT_REGION="eu-west-2"
    export MCP_AWS_PUBLIC_KEY_PATH="~/.ssh/id_rsa.pub"
    export MCP_AWS_PRIVATE_KEY_PATH="~/.ssh/id_rsa"
    export MCP_GCP_PROJECT_ID="mcp-testing"
    export MCP_GCP_PATH_TO_CREDENTIALS="~/.ssh/gcp-service-account.json"
    export MCP_GCP_DEFAULT_REGION="europe-west2"
    export MCP_GCP_PUBLIC_KEY_PATH="~/.ssh/id_rsa.pub"
    export MCP_GCP_PRIVATE_KEY_PATH="~/.ssh/id_rsa"
    ```

Exported variables on your shell will take precedence from the defined default values on the `default.vars` file. 

If variables are not set locally default values from the `default.vars` file will be used. Make sure all the variables are set either on the current shell or on the default variables file.

To check exported variables on current shell run the following command:

    ```
    env | grep MCP
    ```
    
### Deployment

- To deploy resources run `setup` command and specify cloud name (aws|gcp|all)

    ```
    ./mcadm.sh setup aws
    ```

### Cleanup

- To remove all the resources deployed run the command:

    ```
    ./mcadm.sh destroy manager
    ```

### FAQ

- Run `./mcadm.sh help` to see details about script usage.

- The information about the Kubernetes Cluster Manager will be shown in the console output. Rancher manager UI user: admin

    E.g:
    ```
    rancher_access_key = token-1abcd
    rancher_secret_key = xyz1xyz2xyz
    rancher_url = https://3.4.1.2
    ```

- The Zabbix Web Frontend can be accessed on a browser using the public Zabbix Server IP. User: Admin

- Kibana UI can be accessed on a browser using the public ELK Server IP and port 5601

- A multi-cloud setup on both AWS and GCP currently only allows the creation of Zabbix and Elastic Stack servers on AWS. 
