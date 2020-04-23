# Multi Cloud Platform issues

## ELK instance is unreachable from Zabbix instance and from node network of K8S cluster

**Cloud:** AWS

**Status:** Resolved

After setup the Cluster Manager, Rancher cluster and monitoring VPC with 2 instances
(Zabbix, ELK) the ELK instance has access to internet, but can't reach Zabbix server
(same VPC and subnet) as well as Rancher cluster (cluster VPC, connected via peering connection).

ELK instance is provisioned with 3 services: elasticsearch, logstash and kibana.
All of them run in Docker

**Workaround:**
Restart ELK services by running the command `docker-compose down` and then `docker-compose up -d`

**Resolution:**

1.  Bridge interface of docker network gets the address from the range `172.18.0.0/16`.
    Kubernetes cluster's VPC has same CIDR. This is the source of the issue.
    The Kubernetes cluster VPC CIDR - changed to `172.22.0.0/16`
    This change fixed the communication between the ELK server and cluster network.

2.  Communication between ELK and Zabbix servers, which located in same subnet, should be 
    allowed explicitly by ingress rule in `zabbix_vpc.aws_security_group.zabbix_server_ports`
    security group.
     
---

## Security group rule `aws_security_group_rule.allow_from_cluster` continuously introduce changes in terraform plan

**Cloud:** AWS

**Status:** Resolved

Monitoring infrastructure deployment goes well and creates all the resources and services work well.
But after deployment every run of `terraform plan` shows changes.
First time run - plan shows that rule should be removed from the security group.
Second time run - plan shows that rule should be added to the security group.
This two changes repeat continuously.
Terraform version: 11.14

**Resolution:**

The resolution is to create the security group first and after that create security group rules
and associate them with security group.

The module `aws-zabbix-vpc` shows this. The `aws_security_group.zabbix_server_ports` is created
without specifying any security group rules in it's resource block.

The security group rules, like `aws_security_group_rule.zabbix_subnet`, `aws_security_group_rule.ssh`
and other, are created after.

This approach prevents the issue when we add additional rules to this security group in other modules.
