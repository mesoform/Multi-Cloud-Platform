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

data "template_file" "kubernetes" {
  template = "${file("${path.module}/files/kubernetes.yml.tpl")}"
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

resource "kubernetes_config_map" "filebeat_inputs" {
  metadata {
    name = "filebeat-inputs"
    namespace = "kube-system"
    labels {
      k8s-app = "filebeat"
    }
  }

  data = {
    "kubernetes.yml" = "${data.template_file.kubernetes.rendered}"
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
        dns_policy = "ClusterFirst"
        automount_service_account_token = true
        container {
          name = "filebeat"
          image = "docker.elastic.co/beats/filebeat:6.7.2"
          args = [
            "-c", "/etc/filebeat.yml",
            "-e",
          ]
          env {
            name = "ELK_SERVER_HOST"
            value = "${var.elksrv_private_ip}"
          }
          env {
            name = "ELK_SRV_PUB_IP"
            value = "${var.elksrv_public_ip}"
          }
          env {
            name = "ELASTIC_CLOUD_ID"
            value = ""
          }
          env {
            name = "ELASTIC_CLOUD_AUTH"
            value = ""
          }
          security_context {
            run_as_user = 0
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
            name        = "inputs"
            mount_path  = "/usr/share/filebeat/inputs.d"
            read_only   = true
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
          name = "inputs"
          config_map {
            name = "filebeat-inputs"
            default_mode = "0600"
          }
        }
        volume {
          name = "data"
          host_path {
            path = "/var/lib/filebeat-data"
            type = "DirectoryOrCreate"
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
