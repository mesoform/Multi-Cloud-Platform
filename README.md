# Multi cloud platform scripts

Multi cloud platform contains scripts and configurations to run interactive deployment of Triton Kubernetes solution on AWS and/or GCP along with Zabbix monitoring and Elastic Stack logging.

## Quick start guide

### Prepare to run deployment

Clone the `mcp-setup` git repository and set environment variables locally on your current shell:

   E.g:
   
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

`MCP_AWS_ACCESS_KEY`, `MCP_AWS_SECRET_KEY` and/or `MCP_GCP_PROJECT_ID`, `MCP_GCP_PATH_TO_CREDENTIAL` are mandatory and do not have a default value.

Default variables values are as follows:

    MCP_ENV="test"                                 # deployment environment (dev/test/prod/etc.)
    # RANCHER
    MCP_BASE_MANAGER_CLOUD="aws"                   # default cloud provider for rancher manager: aws or gcp
    MCP_BASE_MANAGER_NAME="manager"                # rancher manager name
    MCP_RANCHER_ADMIN_PWD="rancher"                # rancher admin password
    # K8S
    MCP_BASE_CLUSTER_NAME="cluster"                # k8s cluster name
    MCP_K8S_NETWORK_PROVIDER="calico"              # k8s network provider: calico|canal|flannel|weave
    MCP_BASE_ETCD_NODE_NAME="etcd"                 # k8s etcd node name
    MCP_BASE_CONTROL_NODE_NAME="control"           # k8s control node name
    MCP_BASE_WORKER_NODE_NAME="worker"             # k8s worker node name
    MCP_ETCD_NODE_COUNT=1                          # number of etcd nodes per cluster
    MCP_CONTROL_NODE_COUNT=1                       # number of control nodes per cluster
    MCP_WORKER_NODE_COUNT=1                        # number of worker nodes per cluster
    # AWS
    MCP_AWS_ACCESS_KEY=""                          # aws platform access key. E.g. MCP_AWS_ACCESS_KEY=AKIB6TGAWR66MFOPZAW
    MCP_AWS_SECRET_KEY=""                          # aws platform secret key. E.g. MCP_AWS_SECRET_KEY=bX4r02gt7OPDfv5lcdueKJdXSKcNNT9rklczescd
    MCP_AWS_DEFAULT_REGION="eu-west-2"             # aws default region
    MCP_AWS_PUBLIC_KEY_PATH="~/.ssh/id_rsa.pub"    # auth public rsa key
    MCP_AWS_PRIVATE_KEY_PATH="~/.ssh/id_rsa"       # auth private rsa key
    # GCP
    MCP_GCP_PROJECT_ID=""                          # gcp project id. E.g. MCP_GCP_PROJECT_ID=mcp-testing
    MCP_GCP_PATH_TO_CREDENTIALS=""                 # gcp service account credentials. E.g. MCP_GCP_PATH_TO_CREDENTIALS=~/.ssh/gcp-credentials.json
    MCP_GCP_DEFAULT_REGION="europe-west2"          # gcp default region
    MCP_GCP_PUBLIC_KEY_PATH="~/.ssh/id_rsa.pub"    # auth public rsa key
    MCP_GCP_PRIVATE_KEY_PATH="~/.ssh/id_rsa"       # auth private rsa key
    

Exported variables on your shell will take precedence over the defined default values. 

To check exported variables on current shell run the following command:

    env | grep MCP
    
### Deployment

- To deploy resources run `setup` command and specify cloud name (aws|gcp|all):

    
        E.g:
   
        ./mcadm.sh setup aws

### Cleanup

- To remove all the resources deployed run the command:


        E.g:
        
        ./mcadm.sh destroy manager

### Adding nodes to a cluster 

- To add a node (etcd|control|worker) to an existing cluster run the add command:

        
        E.g: add a new worker node to an AWS cluster:
        
        ./mcadm.sh add wnode config/test/test-aws-cluster.yaml

### Removing nodes from an existing cluster 

- To remove a node (etcd|control|worker) from a cluster run the destroy command:

        
        E.g: remove a node from an AWS cluster:
            
        ./mcadm.sh destroy node config/test/test-aws-cluster.yaml
      
      
   A prompt will ask you which node to remove 
  
### Getting information about manager or cluster 

- To get information about a manager or a cluster run the get command:

        
        E.g: to get information about the cluster manager:
    
        ./mcadm.sh get manager
    
### FAQ

- Run `./mcadm.sh help` to see details about script usage.

- The information about the Kubernetes Cluster Manager will be shown in the console output. Rancher manager UI user: admin

    E.g:
    
    `rancher_access_key = token-1abcd` 
    `rancher_secret_key = xyz1xyz2xyz`
    `rancher_url = https://3.4.1.2`

- The Zabbix Web Frontend can be accessed on a browser using the public Zabbix Server IP. User: Admin

- Kibana UI can be accessed on a browser using the public ELK Server IP and port 5601

- A multi-cloud setup on both AWS and GCP currently only allows the creation of Zabbix and Elastic Stack servers on AWS. 
