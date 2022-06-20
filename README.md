# Mesoform Multi-Cloud Platform

# Multi-Cloud Platform Foundations

* [Information](#Information)  
* [Structure](#Structure)     
* [Setup](#Setup)
* [MMCF](#MMCF)  
* [project.yml](#projectyml)      
* [Google Cloud Platform Adapters](#google-cloud-platform)  
    * [App Engine](mcp/docs/GCP_APP_ENGINE.md)  
    * [Cloud Run](mcp/docs/GCP_CLOUDRUN.md)  
* [Kubernetes adapter](mcp/docs/KUBERNETES.md)  
* [Contributing](#Contributing)  
* [License](#License)  

## Information
Mesoform Multi-Cloud Platform (MCP) is a concept, and supporting infrastructure code which simplifies the deployment of 
applications across multiple Cloud providers. The basis behind MCP is for platform engineers and application 
engineers to be working with a single structure and configuration for deploying foundational infrastructure (like IAM 
policies, Google App Engine or Kubernetes clusters) as would be used for deploying workloads to that infrastructure
(e.g. Containers/Pods).

Within this framework is a unified configuration language called Mesoform Multi-Cloud Configuration Format (or MMCF), 
which is detailed below and provides a familiar YAML structure to what many of the native original services offer and 
adapts it into HCL, the language of Hashicorp Terraform, and deploys it using Terraform, to gain the benefits (like
state management) which Terraform offers.

## Structure
Each version of your application/service (AS) is defined in corresponding set of YAML configuration
files. As a minimum, your AS will require two files: project.yaml which contains some basic
configuration about your project, like the version of MCF to use; and another file containing the
target platform-specific configuration (e.g. gcp_ae.yml for Google App Engine). These files act as
a deployment description and define things like scaling, runtime settings, AS configuration and
other resource settings for the specific target platform.

If your application is made up of a number of microservices, you can structure such Component AS
(CAS) source code files and resources into sub-directories. Then, in the MMCF file, the deployment
configuration for each CAS each will have its own definition in the `specs` section (described
below). For example,

```
mesoform-service/
    L project.yml
    L gcp_ae.yml
    L micro-service1/
    |     L src/
    |     L resources/
    L micro-service2/
    |     L __init__.py
    |     L resources
```

Specifications for different target platforms can be found below

## Setup
To use the MCP modules to deploy your service, download the `mcpadm.sh` (Linux or Mac), or `mcpadm.ps1` (Windows), 
and run the setup within a `/terraform` sub-directory of your service. 

```
mesoform-service/
L project.yml
L gcp_ae.yml
L micro-service1/
|     L src/
|     L resources/
L micro-service2/
|     L __init__.py
|     L resources
L terraform/              <----Run setup in this directory
|     L main.tf
```
Running `./mcpadm.sh setup` will interactively configure a `main.tf` file with a backend for managing terraform state, and the modules for all available adaptors.  
Running:
```shell
./mcpadm.sh setup gcs -bucket=bucket-id -prefix=tf-state-files -auto-approve
```
Would produce the following main.tf file:
```hcl
terraform{
  backend "gcs" {
    bucket = bucket-id
    prefix = tf-state-files
  }
}
module{
  source = "github.com/mesoform/terraform-infrastructure-modules/mcp"
}
```
Run `mcpadm.sh setup -help` for more setup options.

The `mcpadm` scripts can also get, deploy and destroy terraform infrastructure, as well as configure workspaces for management of multiple service versions.

## MMCF
MMCF is a YAML-based configuration allowing for simple mapping of platform APIs for deploying
 applications. It follows the YAML 1.2 specification. For example, YAML anchors can be used to
 reference values from other fields. For example, if you wanted `service` to be the same as name,
 would write:

```yaml
name: &name ecat-admin
service: *name
```

Reused anchors overwrite previous values. I.e. when anchors are repeated, the value of the last
 found anchor will be used.

For example, with the configuration:

```yaml
components:
  common:
    env_variables:
      'env': dev
    threadsafe: True
    name: &name common-name
  specs:
    spec_version: v1.0.0
    app1:
      name: &name ecat-admin
      runtime: custom
      env: flex
      service: *name
```

`service` will evaluate to `ecat-admin`

The following sections describe how to use MMCF for different target platforms. In each section, any
 required settings are stated so. Everything else is optional. Any defaults that are set within
 MMCF are stated for each individual setting but this doesn't mean that you may not get some default
 set by the target platform. All expected settings, with their defaults from MMCF and the target
 platform will be output. Refer to the target platform's documentation for specifics



### project.yml

| Key | Type | Required | Description | Default |
|:----|:----:|:--------:|:------------|:-------:|
| `mcf_version` | string | false | version of MCF to use. | `1.0` |
| `name` | string | true | Name of the project. If you want to reference this in later configuration, it must meet the minimum requirements of the target platform(s) being deployed to. For example, Google App Engine requires that many IDs/names must be 1-63 characters long, and comply with RFC1035. Specifically, the name must be 1-63 characters long and match the regular expression [a-z]\([-a-z0-9]*[a-z0-9])?. The first character must be a lowercase letter, and all following characters (except for the last character) must be a dash, lowercase letter, or digit. The last character must be a lowercase letter or digit. | none |
| `version` | string | false | deployment version of your application/service. Version must contain only lowercase letters, numbers, dashes (-), underscores (_), and dots (.). Spaces are not allowed, and dashes, underscores and dots cannot be consecutive (e.g. "1..2" or "1.\_2") and cannot be at the beginning or end (e.g. "-1.2" or "1.2\_") | none |
| `labels` | map | false | a collection of keys and values to represent labels required for your deployment. | none |

Example:

```yaml
mcf_version: "1.0"
name: &name "mesoform-frontend"
version: &deployment_version "1"
labels: &project_labels
  billing: central
  name: *name
```

### Enterprise attributes
MMCF has a collection of standard attributes. These attributes exist to allow secure management of the platform and 
services which they deploy. They can be defined by the user of the adapters or equally by a core platform team who's
responsibility it is to maintain security and stability of Cloud platforms. These attributes are:

| Key                           |  Type  | Required | Description                                                                             | Default |
|:------------------------------|:------:|:--------:|:----------------------------------------------------------------------------------------|:-------:|
| `service_account`             | string | false | defines what service account to use to deploy resources                                 | `1.0` |
| `compliance`                  | object | false | defines details of how to manage resources in a compliant manner                        | `1.0` |
| `compliance.policies`         | object | false | defines details of what policies to use for verifying if the configuration is compliant | `1.0` |
| `compliance.policies.url`     | object | false | URL to where to pull the policies from                                                  | `1.0` |
| `compliance.policies.version` | object | false | What version of the policies to use                                                     | `1.0` |


## Google Cloud Platform 
* [App Engine](mcp/docs/GCP_APP_ENGINE.md)  
* [Cloud Run](mcp/docs/GCP_CLOUDRUN.md)  

Manage serverless deployments to Google Cloud using the App Engine or the Cloud Run adapter. 
To use these adapters you will need an existing Google Cloud account, either with an existing project, or that you can create a project in.   

An example `gcp_ae.yml` configuration:
```yaml
create_google_project: true
project_id: &project_id protean-buffer-230514
organization_name: mesoform.com
folder_id: 320337270566
billing_account: "1234-5678-2345-7890"
location_id: "europe-west"
project_labels: &google_project_labels
  type: frontend
service_account: app-engine-admin@gserviceaccount.google.com
compliance:
  policies:
    url: https://github.com/mesoform/compliance-policies.git
    version: 1.0.0


components:
  common:
    entrypoint: java -cp "WEB-INF/lib/*:WEB-INF/classes/." io.ktor.server.jetty.EngineMain
    runtime: java11
    env: flex
    env_variables:
      GCP_ENV: true
      GCP_PROJECT_ID: *project_id
    system_properties:
      java.util.logging.config.file: WEB-INF/logging.properties
  specs:
    spec_version: 1.0.0
    experiences-search-sync:
      env: standard
    experiences-search:
      env: standard
    experiences-sidecar:
      env: standard
    default:
      root_dir: experiences-service
      runtime: java8
```
## Kubernetes
* [K8s adapter documentation](mcp/docs/GCP_APP_ENGINE.md)

Use this module to interact with kubernetes resources. To use this module you must have a configured and running kubernetes cluster.

The `KUBE_CONFIG_PATH` environment variable must be set to the path of the config file for the cluster you will use.  
Run the following command to set the path to the default location:  
Linux:
```bash
 export KUBE_CONFIG_PATH=~/.kube/config
 ```
Windows Power Shell:
```powershell
 $Env:KUBE_CONFIG_PATH=~/.kube/config
```
NOTE: replace `~/.kube/config` with custom path if not using the default. Or set multiple paths with `KUBE_CONFIG_PATHS`

Kubernetes resources are configured with `k8s.yml` file.  Example shown below:
```yaml
components:
  specs:
    spec_version: 1.0.0
    app_1: 
      deployment:
        metadata:
          name: "mosquitto"
          namespace:
            labels:
            app: "mosquitto"
        spec:
          selector:
            match_labels:
              app: "mosquitto"
          template:
            metadata:
              labels:
                app: "mosquitto"
            spec:
              container:
                - name: "mosquitto"
                  image: "eclipse-mosquitto:1.6.2"
                  port:
                    - container_port: 1883
                  resources:
                    limits:
                      cpu: "0.5"
                      memory: "512Mi"
                    requests:
                      cpu: "250m"
                      memory: "50Mi"
      config_map:
        metadata:
          name: "mosquitto-config-file"
          labels:
            env: "test"
        data:
          'test': 'test'
        data_file:
          - ../resources/mosquitto.conf
        binary_data:
          bar: L3Jvb3QvMTAw
        binary_file:
          - ../resources/binary.bin
      secret:
        metadata:
          annotations:
            key1:
            key2:
          name: "mosquitto-secret-file"
          namespace:
          labels:
            env: "test"
        type: Opaque
        data:
          login: login
          password: password
          data_file:
          - ../resources/secret.file
```

# This repository

This repository contains the scripts and configurations to run interactive deployment of Triton 
Kubernetes solution. Our current implementation of a container platform deployment across multiple 
Cloud providers

## Quick start guide

### Prepare to run deployment

Clone the `mcp-setup` git repository and set environment variables locally on your current shell:

   E.g:
   
    export MCP_ENV="test"
    export MCP_BASE_MANAGER_CLOUD="aws"
    export MCP_BASE_MANAGER_NAME="manager"
    export MCP_RANCHER_ADMIN_PWD="R4nch3R"
    export MCP_BASE_CLUSTER_NAME="cluster"
    export MCP_K8S_NETWORK_PROVIDER="calico"
    export MCP_BASE_ETCD_NODE_NAME="etcd"
    export MCP_BASE_CONTROL_NODE_NAME="control"
    export MCP_BASE_WORKER_NODE_NAME="worker"
    export MCP_ETCD_NODE_COUNT=1
    export MCP_CONTROL_NODE_COUNT=1
    export MCP_WORKER_NODE_COUNT=1
    export MCP_AWS_ACCESS_KEY="ABCD1EFGHI23JKLMNOP"
    export MCP_AWS_SECRET_KEY="aB1c23de4FGhi5jklmnOPqRSTuvWXY6zabcdefgh"
    export MCP_AWS_DEFAULT_REGION="eu-west-2"
    export MCP_AWS_PUBLIC_KEY_PATH="~/.ssh/id_rsa.pub"
    export MCP_AWS_PRIVATE_KEY_PATH="~/.ssh/id_rsa"
    export MCP_GCP_PROJECT_ID="mcp-testing"
    export MCP_GCP_CREDENTIALS_PATH="~/.ssh/gcp-service-account.json"
    export MCP_GCP_GCS_BUCKET="mcp-testing-elk"
    export MCP_GCP_DEFAULT_REGION="europe-west2"
    export MCP_GCP_PUBLIC_KEY_PATH="~/.ssh/id_rsa.pub"
    export MCP_GCP_PRIVATE_KEY_PATH="~/.ssh/id_rsa"
    export SECURE_SOURCE_IP="147.161.96.35"
    ```

`MCP_AWS_ACCESS_KEY`, `MCP_AWS_SECRET_KEY` and/or `MCP_GCP_PROJECT_ID`, `MCP_GCP_CREDENTIALS_PATH` are mandatory and do not have a default value.

Default variables values are as follows:

    MCP_ENV="test"                                 # deployment environment (dev/test/prod/etc.)
    # RANCHER
    MCP_BASE_MANAGER_CLOUD="aws"                   # default cloud provider for rancher manager: aws or gcp
    MCP_BASE_MANAGER_NAME="manager"                # rancher manager name
    MCP_RANCHER_ADMIN_PWD="R4nch3R"                # rancher admin password
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
    MCP_AWS_ACCESS_KEY=""                          # aws platform access key. E.g. MCP_AWS_ACCESS_KEY=ABCD1EFGHI23JKLMNOP
    MCP_AWS_SECRET_KEY=""                          # aws platform secret key. E.g. MCP_AWS_SECRET_KEY=aB1c23de4FGhi5jklmnOPqRSTuvWXY6zabcdefgh
    MCP_AWS_DEFAULT_REGION="eu-west-2"             # aws default region
    MCP_AWS_PUBLIC_KEY_PATH="~/.ssh/id_rsa.pub"    # auth public rsa key
    MCP_AWS_PRIVATE_KEY_PATH="~/.ssh/id_rsa"       # auth private rsa key
    # GCP
    MCP_GCP_PROJECT_ID=""                          # gcp project id. E.g. MCP_GCP_PROJECT_ID=mcp-testing
    MCP_GCP_CREDENTIALS_PATH=""                    # gcp service account credentials. E.g. MCP_GCP_CREDENTIALS_PATH=~/.ssh/gcp-credentials.json
    MCP_GCP_GCS_BUCKET=""                          # gcp gcs bucket to store elastic snapshots
    MCP_GCP_DEFAULT_REGION="europe-west2"          # gcp default region
    MCP_GCP_PUBLIC_KEY_PATH="~/.ssh/id_rsa.pub"    # auth public rsa key
    MCP_GCP_PRIVATE_KEY_PATH="~/.ssh/id_rsa"       # auth private rsa key
    # SECURE SOURCE IP
    SECURE_SOURCE_IP="80.229.44.137"               # any secure IP to add to the monitoring services (Zabbix/ELK) firewalls
    

Exported variables on your shell will take precedence from the defined default values. 


To check exported variables on current shell run the following command: `env | grep MCP`

    
### Deployment

- To deploy resources run `setup` command and specify cloud name (aws|gcp|all):

    
     E.g: `./mcadm.sh setup aws`

### Cleanup

- To remove all the resources deployed run the `destroy` command:

      E.g: `./mcadm.sh destroy manager`

### Adding nodes to a cluster 

- To add a node (etcd|control|worker) to an existing cluster run the add command:

      E.g: add a new worker node to an AWS cluster:
        
      `./mcadm.sh add wnode config/test/test-aws-cluster.yaml`

### Removing nodes from an existing cluster 

- To remove a node (etcd|control|worker) from a cluster run the destroy command:

      E.g: remove a node from an AWS cluster:
        
      `./mcadm.sh destroy node config/test/test-aws-cluster.yaml`
      
      
     A prompt will ask you which node to remove 
  
### Getting information about manager or cluster 

- To get information about a manager or a cluster run the get command:

      E.g: to get information about the cluster manager:
    
      `./mcadm.sh get manager`
    
### FAQ

- Run `./mcadm.sh help` to see details about script usage


- The information about the Kubernetes Cluster Manager will be shown in the console output. Rancher manager UI user: admin
      
      E.g:
    
      `rancher_access_key = token-1abcd`

      `rancher_secret_key = xyz1xyz2xyz`
      
      `rancher_url = https://3.4.1.2`
        

- Use SECURE_SOURCE_IP to add any IP to the monitoring services firewalls so Zabbix Web and Kibana UI can be reached from that IP 


- The Zabbix Web Frontend can be accessed on a browser using the public Zabbix Server IP. User: Admin


- Kibana UI can be accessed on a browser using the public ELK Server IP and port 5601


- A multi-cloud setup on both AWS and GCP currently only allows the creation of Zabbix and Elastic Stack servers on AWS. 

```
./mcadm.sh destroy manager
```

## Contributing
Please read:
* [CONTRIBUTING.md](https://github.com/mesoform/documentation/blob/master/CONTRIBUTING.md)
* [CODE_OF_CONDUCT.md](https://github.com/mesoform/documentation/blob/master/CODE_OF_CONDUCT.md)

## License
This project is licensed under the [MPL 2.0](https://www.mozilla.org/en-US/MPL/2.0/FAQ/)