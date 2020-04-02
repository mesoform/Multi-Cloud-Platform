# Multi Cloud Platform monitoring

Create monitoring environment and connect it with Triton Kubernetes clusters

## Quick start guide

### Prepare to run deployment

#### Repository layout overview

Pay attention to three folders under repository root: `k8s`, `scripts` and `terraform`

The `k8s` folder contains zabbix agent daemonset configuration - `zabbix-agent-daemonset.yaml`

The `scripts` folder contains monitoring administration script

The `terraform` folder contains the terraform code to create monitoring infrastructure:
- The module definitions are located in `terraform/modules`. 
- The `terraform/monitoring` contains plans for different scenarios of deployment. Choose one of options according to triton kubernetes clusters locations

#### Terraform variables files preparation

Create terraform variables files and fill variables values. Just make a copy of tfvars files templates.

For `AWS only` scenario:

```
cp terraform/monitoring/zabbix-aws-only/aws-zabbix.tfvars.template terraform/monitoring/zabbix-aws-only/terraform.tfvars
```

For `GCP only` scenario:

```
cp terraform/monitoring/zabbix-gcp-only/gcp-zabbix.tfvars.template terraform/monitoring/zabbix-gcp-only/terraform.tfvars
```

For `Multi cloud` scenario:

```
cp terraform/monitoring/zabbix-mcp/mcp-zabbix.tfvars.template terraform/monitoring/zabbix-mcp/terraform.tfvars
```

Fill in values of the variables in `tfvars` files.\
Draw attention the the following variables:

```
aws_k8s_cluster_name = "replace_with_cluster_name"

aws_access_key = "replace_with_access_key"
aws_secret_key = "replace_with_secret_key"

aws_key_name = "replace_with_key_name"
aws_public_key_path = "~/.ssh/id_rsa.pub"
aws_private_key_path = "~/.ssh/id_rsa"

gcp_path_to_credentials="~/.ssh/credentials.json"
gcp_cluster_network_name = "replace_with_k8s_cluster_network_name"
gcp_project_id = "replace_with_project_id"
```

#### Rancher variables file preparation

Fill in values of the variables in `k8s/rancher.vars` file  (values were returned on manager creation or get them by running the following command:
    `triton-kubernetes get manager --non-interactive --config /path/to/mcp-setup/config/<env>/manager-info.yaml`)

```
RANCHER_ACCESS_KEY="replace_with_access_key"
RANCHER_SECRET_KEY="replace_with_secret_key"
RANCHER_URL="replace_with_https_url"
```

### Monitoring infrastructure setup and teardown

Run setup script: `./scripts/moniadm.sh` from within `mcp-monitoring` folder

1.  Setup monitoring infrastructure

Run the script with `setup` command - `scripts/moniadm.sh setup <cloud_name>`
```
./scripts/moniadm.sh setup <aws|gpc|all>
```

2. Verify that the Zabbix agent pod is running on every node in cluster.

Check the nodes:

```
kubectl --kubeconfig ~/.kube/config.<aws|gcp> get pods -o wide
```

Zabbix agent daemonset will be applied to all cluster/s nodes.

3.  Destroy monitoring infrastructure

Run the script with `destroy` command - `scripts/moniadm.sh destroy <cloud_name>`
```
./scripts/moniadm.sh destroy <aws|gpc|all>
```


