# Multi Cloud Platform monitoring

Create monitoring environment (Zabbix + Elastic Stack) and connect it with Triton Kubernetes clusters

## Quick start guide

#### Rancher variables file

Make sure your rancher variables file `rancher.vars` exists on folder `config/<env>`

```
RANCHER_ACCESS_KEY="rancher_access_key"
RANCHER_SECRET_KEY="rancher_secret_key"
RANCHER_URL="rancher_https_url"
```

### Monitoring infrastructure setup and teardown

Run setup script: `./monitoring/moniadm.sh` from within `mcp-setup` cloned repo.

1.  Setup monitoring infrastructure

Run the script with `setup` command - `monitoring/moniadm.sh setup <cloud_name>`
```
./monitoring/moniadm.sh setup <aws|gpc|all>
```

2. Verify that the Zabbix agent pod is running on every node in cluster.

Check the nodes:

```
kubectl --kubeconfig ~/.kube/config.<aws|gcp> get pods -o wide
```

Zabbix agent daemonset will be applied to all cluster/s nodes.

3.  Destroy monitoring infrastructure

Run the script with `destroy` command - `monitoring/moniadm.sh destroy <cloud_name>`
```
./monitoring/moniadm.sh destroy <aws|gpc|all>
```

### FAQ

- Run `./monitoring/moniadm.sh help` to see details about script usage.

- The Zabbix Web Frontend can be accessed on a browser using the public Zabbix Server IP. User: Admin

- Kibana UI can be accessed on a browser using the public ELK Server IP and port 5601

- A multi-cloud setup on both AWS and GCP currently only allows the creation of Zabbix and Elastic Stack servers on AWS.
