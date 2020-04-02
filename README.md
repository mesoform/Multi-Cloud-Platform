# Multi cloud platform scripts

Multi cloud platform contains scripts and configurations to run interactive deployment of Triton Kubernetes solution on AWS and/or GCP along with Zabbix monitoring and Elastic Stack logging.

## Quick start guide

### Prepare to run deployment

Clone the `mcp-setup` git repository and make a copy of the `sample.vars` file found under `env` folder giving it an environment name (`dev/test/prod/etc.`)

E.g: `cp samples.vars dev.vars`

Edit the configuration file and make the appropriate changes relevant to your cloud providers (AWS/GCP): 

```

# RANCHER
MCP_BASE_MANAGER_CLOUD=aws          # default cloud provider for rancher manager: aws|gcp
MCP_BASE_MANAGER_NAME="manager"     # rancher manager name
MCP_RANCHER_ADMIN_PASSWORD=change   # rancher admin password

# K8S
MCP_BASE_CLUSTER_NAME="cluster"     # k8s cluster name
MCP_K8S_NETWORK_PROVIDER="calico"   # k8s network provider: calico|canal|flannel|weave

MCP_BASE_ETCD_NODE_NAME=etcd        # k8s etcd node name
MCP_BASE_CONTROL_NODE_NAME=control  # k8s control node name
MCP_BASE_WORKER_NODE_NAME=worker    # k8s worker node name

MCP_ETCD_NODE_COUNT=1      # number of etcd nodes per cluster
MCP_CONTROL_NODE_COUNT=1   # number of control nodes per cluster
MCP_WORKER_NODE_COUNT=1    # number of worker nodes per cluster

# AWS
MCP_AWS_ACCESS_KEY=change                    # aws platform access key
MCP_AWS_SECRET_KEY=change                    # aws platform secret key
MCP_AWS_PUBLIC_KEY_PATH=~/.ssh/mcp_rsa.pub   # auth public rsa key
MCP_AWS_PRIVATE_KEY_PATH=~/.ssh/mcp_rsa      # auth private rsa key

# GCP
MCP_GCP_PROJECT_ID=gcp-project-id                         # gcp project id
MCP_GCP_PATH_TO_CREDENTIALS=~/.ssh/gcp-credentials.json   # gcp service account credentials
MCP_GCP_PUBLIC_KEY_PATH=~/.ssh/mcp_rsa.pub                # auth public rsa key
MCP_GCP_PRIVATE_KEY_PATH=~/.ssh/mcp_rsa                   # auth private rsa key

```

### Deployment

- Source the environment from the configuration file running the following command:

    ```
    source load-env.sh <env>
    ```

    E.g: `source load-env.sh dev`

- To deploy resources run `setup` command and specify cloud name (aws|gcp|all)

    ```
    ./mcadm.sh setup aws
    ```

### Cleanup

To remove all the resources deployed run the command:

```
./mcadm.sh destroy manager
```

### FAQ

- Run `./mcadm.sh help` to see details about script usage.

- The information about the Kubernetes Cluster Manager will be shown in the console output.

    E.g:
    ```
    rancher_access_key = token-1abcd
    rancher_secret_key = xyz1xyz2xyz
    rancher_url = https://3.4.1.2
    ```

- A multi-cloud setup on both AWS and GCP currently only allows the creation of Zabbix and Elastic Stack servers on AWS. 

