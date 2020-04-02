provider "kubernetes" {
  config_path = "${var.kube_config_path}"
}

resource "null_resource" "before" {
}

resource "null_resource" "delay" {
  provisioner "local-exec" {
    command = "sleep 90"
  }
  triggers = {
    "before" = "${null_resource.before.id}"
  }
}

resource "kubernetes_daemonset" "zabbix_agent" {
  metadata {
    name = "zabbix-agent"
    labels = {
      tier = "monitoring"
      app  = "zabbix-agent"
      version = "v1"
    }
  }

  spec {
    selector {
      match_labels = {
        name = "mcp-zabbix-agent"
      }
    }

    template {
      metadata {
        labels = {
          name = "mcp-zabbix-agent"
        }
      }
      spec {
        container {
          name = "mcp-zabbix-agent"
          resources {
            requests {
              cpu = "0.15"
            }
          }
          security_context {
            privileged = true
          }
          env {
            name = "ZBX_SERVER_HOST"
            value = "${var.zbxsrv_private_ip}"
          }
          env {
            name = "ZBX_SRV_PUB_IP"
            value = "${var.zbxsrv_public_ip}"
          }
          env {
            name = "ZBX_METADATA"
            value = "k8s-cluster"
          }
          image = "zabbix/zabbix-agent:ubuntu-4.2.1"
          port {
            container_port = 10050
            host_port = 10050
            name = "zabbix-agent"
          }
        }
        toleration {
          key = "node-role.kubernetes.io/controlplane"
          operator = "Equal"
          value = "true"
          effect = "NoSchedule"
        }
        toleration {
          key = "node-role.kubernetes.io/etcd"
          operator = "Equal"
          value = "true"
          effect = "NoExecute"
        }
      }
    }
  }
  depends_on = ["null_resource.delay"]
}