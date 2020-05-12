provider "kubernetes" {
  config_path = "${var.kube_config_path}"
}

data "template_file" "filebeat" {
  template = "${file("${path.module}/files/filebeat.yml.tpl")}"
  vars {
      elksrv_private_ip = "${var.elksrv_private_ip}"
      k8s_cluster_name = "${var.k8s_cluster_name}"
  }
}

resource "null_resource" "before" {
}

resource "null_resource" "delay" {
  provisioner "local-exec" {
    command = "sleep 120"
  }
  triggers = {
    "before" = "${null_resource.before.id}"
  }
}

resource "kubernetes_config_map" "filebeat_config" {
  metadata {
    name = "filebeat-config"
    namespace = "kube-system"
    labels {
      k8s-app = "filebeat"
    }
  }

  data = {
    "filebeat.yml" = "${data.template_file.filebeat.rendered}"
  }

  depends_on = ["null_resource.delay"]
}

resource "kubernetes_daemonset" "filebeat" {
  metadata {
    name = "filebeat"
    namespace = "kube-system"
    labels {
      k8s-app = "filebeat"
    }
  }

  spec {
    selector {
      match_labels {
        k8s-app = "filebeat"
      }
    }
    template {
      metadata {
        labels {
          k8s-app = "filebeat"
        }
      }
      spec {
        service_account_name = "filebeat"
        termination_grace_period_seconds = "30"
        host_network = true
        dns_policy = "ClusterFirstWithHostNet"
        container {
          name = "filebeat"
          image = "docker.elastic.co/beats/filebeat:7.6.0"
          args = [
            "-c",
            "/etc/filebeat.yml",
            "-e",
          ]
          env {
            name = "NODE_NAME"
            value_from {
              field_ref {
                field_path = "spec.nodeName"
              }
            }
          }
          env {
            name = "ELK_SERVER_HOST"
            value = "${var.elksrv_private_ip}"
          }
          env {
            name = "ELK_SRV_PUB_IP"
            value = "${var.elksrv_public_ip}"
          }
          security_context {
            privileged = true
          }
          resources {
            requests {
              cpu = "100m"
              memory = "100Mi"
            }
            limits {
              memory = "200Mi"
            }
          }

          volume_mount {
            name        = "config"
            mount_path  = "/etc/filebeat.yml"
            read_only   = true
            sub_path    = "filebeat.yml"
          }
          volume_mount {
            name        = "data"
            mount_path  = "/usr/share/filebeat/data"
          }
          volume_mount {
            name        = "varlibdockercontainers"
            mount_path  = "/var/lib/docker/containers"
            read_only   = true
          }
          volume_mount {
            name        = "varlog"
            mount_path  = "/var/log"
            read_only   = true
          }
        }
        volume {
          name = "config"
          config_map {
            name = "filebeat-config"
            default_mode = "0600"
          }
        }
        volume {
          name = "varlibdockercontainers"
          host_path {
            path = "/var/lib/docker/containers"
          }
        }
        volume {
          name = "varlog"
          host_path {
            path = "/var/log"
          }
        }
        volume {
          name = "data"
          host_path {
            path = "/var/lib/filebeat-data"
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

resource "kubernetes_cluster_role_binding" "filebeat" {
  metadata {
    name = "filebeat"
  }
  role_ref {
    kind = "ClusterRole"
    name = "filebeat"
    api_group = "rbac.authorization.k8s.io"
  }
  subject {
    kind = "ServiceAccount"
    name = "filebeat"
    namespace = "kube-system"
  }
  depends_on = ["null_resource.delay"]
}

resource "kubernetes_cluster_role" "filebeat" {
  metadata {
    name = "filebeat"
    labels {
      k8s-app = "filebeat"
    }
  }
  rule {
    api_groups = [""]
    resources = [
      "namespaces",
      "pods"
    ]
    verbs = [
      "get",
      "watch",
      "list"
    ]
  }
  depends_on = ["null_resource.delay"]
}

resource "kubernetes_service_account" "filebeat" {
  metadata {
    name = "filebeat"
    namespace = "kube-system"
    labels {
      k8s-app = "filebeat"
    }
  }
  depends_on = ["null_resource.delay"]
}
