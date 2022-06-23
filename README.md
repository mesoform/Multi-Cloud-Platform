# Mesoform Multi-Cloud Platform

* [Mesoform Multi-Cloud Platform](#mesoform-multi-cloud-platform)
  * [Background](#Background)
* [This Repository](#this-repository)
  * [Quick start guide](#quick-start-guide)
* [MCCF](#MCCF)
  * [Attributes](#attributes)
  * [Project top-level attributes](#project-top-level-attributes)
  * [Adapter top-level attributes](#adapter-top-level-attributes)
  * [Service adapters](#service-adapters)
  * [Foundation adapters](#foundation-adapters)
  * [Structure](#Structure)
  * [Setup](#Setup)
* [Contributing](#Contributing)
* [License](#License)

## Background
Mesoform Multi-Cloud Platform (MCP) is a set of tools and supporting infrastructure code which simplifies the deployment of
applications across multiple Cloud providers. The basis behind MCP is for platform engineers and application
engineers to be working with a single structure and configuration for deploying foundational infrastructure (like IAM
policies, Google App Engine or Kubernetes clusters) as would be used for deploying workloads to that infrastructure
(e.g. Containers/Pods).

Within this framework is a unified configuration language called Mesoform Multi-Cloud Configuration Format (or MCCF),
which is detailed below and provides a familiar YAML structure to what many of the native original services offer and
adapts it into HCL, the language of Hashicorp Terraform, and deploys it using Terraform, to gain the benefits (like
state management) which Terraform offers.


# This Repository
This repository contains the scripts and configurations to run interactive deployment of a cross-cloud Kubernetes 
platform. Including necessary Cloud resources like networking; and basic monitoring and logging (ElasticStack and Zabbix) 

## Quick start guide
### Prepare to run deployment
Clone the `mcp-setup` git repository and set environment variables locally on your current shell:

E.g:
  ```bash
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

`MCP_AWS_ACCESS_KEY`, `MCP_AWS_SECRET_KEY` and/or `MCP_GCP_PROJECT_ID`, `MCP_GCP_CREDENTIALS_PATH` are mandatory and do
not have a default value.

Default variables values are as follows:
  ```bash
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
  ```
Exported variables on your shell will take precedence from the defined default values.

To check exported variables on current shell run the following command: `env | grep MCP`

### Deployment
- To deploy resources run `setup` command and specify cloud name (aws|gcp|all):
  ```bash
  ./mcadm.sh setup aws
  ```

### Cleanup
- To remove all the resources deployed run the `destroy` command:
  ```bash
  ./mcadm.sh destroy manager
  ```

### Adding nodes to a cluster
- To add a node (etcd | control | worker) to an existing cluster run the add command:
  ```bash
  ./mcadm.sh add wnode config/test/test-aws-cluster.yaml # add new worker node to an AWS cluster
  ```

### Removing nodes from an existing cluster
- To remove a node (etcd|control|worker) from a cluster run the destroy command:
  ```bash
  ./mcadm.sh destroy node config/test/test-aws-cluster.yaml # remove a node from an AWS cluster
  ```
  A prompt will ask you which node to remove

### Getting information about manager or cluster
- To get information about a manager or a cluster run the get command:
  ```bash
  ./mcadm.sh get manager # information about the cluster manager
  ```

### Help
- Run `./mcadm.sh help` to see details about script usage

## Tips and tricks

- The information about the Kubernetes Cluster Manager will be shown in the console output. Rancher manager UI user:
  `admin`
  ```
  rancher_access_key = token-1abcd
  rancher_secret_key = xyz1xyz2xyz
  rancher_url = https://3.4.1.2
  ```
- Use `SECURE_SOURCE_IP` to add any IP to the monitoring services firewalls so Zabbix Web and Kibana UI can be reached
  from that IP
- The Zabbix Web Frontend can be accessed on a browser using the public Zabbix Server IP. User: `Admin`
- Kibana UI can be accessed from a browser using the public ELK Server IP and port 5601
- A multi-cloud setup on both AWS and GCP currently only allows the creation of Zabbix and Elastic Stack servers on AWS.


# MCCF
MCCF is a YAML-based configuration allowing for simple mapping of platform APIs for deploying applications or services
(A/S). It follows the YAML 1.2 specification.

## Attributes
MCCF has some top-level attributes which can be defined with any adapter.

### Project top-level attributes
The first set of attributes are generic attributes relating to MCCF and the overall project. They must be set in
`project.yml` and

| Key           |  Type  | Required | Description                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                              | Default |
|:--------------|:------:|:--------:|:-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|:-------:|
| `mcf_version` | string |  false   | version of MCF to use.                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                   |  `1.0`  |
| `name`        | string |   true   | Name of the project. If you want to reference this in later configuration,<br/> it must meet the minimum requirements of the target platform(s) being deployed to. For example, Google App Engine requires that many IDs/names must be 1-63 characters long, and comply with RFC1035. Specifically, the name must be 1-63 characters long and match the regular expression [a-z]\([-a-z0-9]*[a-z0-9])?. The first character must be a lowercase letter, and all following characters (except for the last character) must be a dash, lowercase letter, or digit. The last character must be a lowercase letter or digit. |  none   |
| `version`     | string |  false   | deployment version of your application/service. Version must contain only lowercase letters, numbers, dashes (-), underscores (_), and dots (.). Spaces are not allowed, and dashes, underscores and dots cannot be consecutive (e.g. "1..2" or "1.\_2") and cannot be at the beginning or end (e.g. "-1.2" or "1.2\_")                                                                                                                                                                                                                                                                                                  |  none   |
| `labels`      |  map   |  false   | a collection of keys and values to represent labels required for your deployment.                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                        |  none   |

Example:

```yaml
mcf_version: "1.0"
name: &name "mesoform-frontend"
version: &deployment_version "1"
labels: &project_labels
  billing: central
  name: *name
```

### Adapter top-level attributes
The next set of top-level attributes which can be defined along with each adapter and are defined in the adapter
specific YAML file.

The first set of these attributes exist to allow secure management of the platform and services which they deploy.
They can be defined by the user of the adapters or equally by a team whose responsibility it is to maintain security and
stability of Cloud platforms. In such cases, such teams could block or override any deployments where the given value
isn't compliant with their standards. These attributes are:

| Key                           |  Type  | Required | Description                                                                                                                                                                                                                                                                | Default  |
|:------------------------------|:------:|:--------:|:---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|:--------:|
| `service_account`             | string |  false   | defines what service account to use to deploy resources                                                                                                                                                                                                                    |   none   |
| `spec_version`                | string |  false   | which version of the adapter code to use                                                                                                                                                                                                                                   | `latest` |
| `compliance`                  | object |  false   | defines details of how to manage resources in a compliant manner                                                                                                                                                                                                           |   none   |
| `compliance.policies`         | object |  false   | defines details of what policies to use for verifying if the configuration is compliant                                                                                                                                                                                    |   none   |
| `compliance.policies.url`     | string |  false   | URL to where to pull the policies from                                                                                                                                                                                                                                     |   none   |
| `compliance.policies.version` | string |  false   | What version of the policies to use                                                                                                                                                                                                                                        |   none   |
| `components.common`           |  map   |  false   | key/value pairs which can be used to define common or default values for each component                                                                                                                                                                                    |   none   |
| `components.specs`            |  map   |   true   | map of objects which define an app, or component of a larger app. Each key is the name for the app and the value of each key depends upon the available option for the chosen adapter. The adapter-specific attributes are defined in their own documents (examples below) |   none   |


Example:
```yaml
service_account: app-engine-admin@gserviceaccount.google.com
spec_version: v1.0.0
compliance:
  policies:
    url: https://github.com/mesoform/compliance-policies.git
    version: 1.0.0
components:
  common:
    runtime: python
    env: flex
  specs:
    app1:
      name: myapp1
    app2:
      name: myapp2
      runtime: node
    app3:
      name: myapp3
      env: standard
```

## Service adapters
Service adapters are used for deploying applications to different serverless/container orchestration platform, like
Kubernetes of Google Cloud Run. They can be found in the [mesoform/Multi-Cloud-Platform-Services](https://github.com/mesoform/Multi-Cloud-Platform-Services)
repository, along with documentation on how to use them.

## Foundation adapters
Foundation adapters are used for deploying foundational IaaS or PaaS Cloud resources. These are resources which service
adapters may depend on before they can be used. For example, in Google Cloud, you would need to have a Cloud Project,
the Cloud Run API enabled and a Project IAM policy defined before any Cloud Run apps could be deployed. They can be 
found in the [mesoform/Multi-Cloud-Platform-Foundations](https://github.com/mesoform/Multi-Cloud-Platform-Foundations) 
repository, along with documentation on how to use them.

## Structure
Each version of your application/service (AS) is defined in corresponding set of YAML configuration files. As a minimum, 
your AS will require two files: project.yaml which contains some basic configuration about your project, like the 
version of MCF to use; and another file containing the target platform-specific configuration (e.g. gcp_ae.yml for 
Google App Engine). These files act as a deployment description and define things like scaling, runtime settings, AS 
configuration and other resource settings for the specific target platform.

If your application is made up of a number of microservices, you can structure such Component AS
(CAS) source code files and resources into subdirectories. Then, in the MCCF file, the deployment
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
and run the setup within a `/terraform` subdirectory of your service.

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

Running `./mcpadm.sh setup` will interactively configure a `main.tf` file with a backend for managing terraform state,
and the modules for all available adaptors.  
Running:

```shell
./mcpadm.sh setup gcs -bucket=bucket-id -prefix=tf-state-files -auto-approve
```

Would produce the following main.tf file:

```hcl
terraform {
  backend "gcs" {
    bucket = bucket-id
    prefix = tf-state-files
  }
}
module {
  source = "github.com/mesoform/terraform-infrastructure-modules/mcp"
}
```

Run `mcpadm.sh setup -help` for more setup options.

The `mcpadm` scripts can also get, deploy and destroy terraform infrastructure, as well as configure workspaces for
management of multiple service versions.

## Anchors
We recommend using [YAML anchors](https://yaml.org/spec/1.2.2/#3222-anchors-and-aliases) to reduce duplication and ensure
consistency between various configs. Description of this feature is available in a variety of external sources,
e.g. [simple summary lives here](https://www.educative.io/blog/advanced-yaml-syntax-cheatsheet#anchors). 

Look out for them in our examples above!

# Contributing
Please read:

* [CONTRIBUTING.md](https://github.com/mesoform/documentation/blob/master/CONTRIBUTING.md)
* [CODE_OF_CONDUCT.md](https://github.com/mesoform/documentation/blob/master/CODE_OF_CONDUCT.md)


# License
This project is licensed under the [MPL 2.0](https://www.mozilla.org/en-US/MPL/2.0/FAQ/)