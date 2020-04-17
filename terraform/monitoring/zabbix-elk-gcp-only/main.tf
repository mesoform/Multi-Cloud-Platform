/* Setup google provider */
provider "google" {
  credentials = "${file("${var.gcp_path_to_credentials}")}"
  project     = "${var.gcp_project_id}"
  region      = "${var.gcp_compute_region}"
}

data "google_compute_subnetwork" "cluster-subnet" {
  name = "${var.gcp_k8s_cluster_name}"
  region = "${var.gcp_default_region}"
}

# Network
resource "google_compute_network" "zabbix_elk_net" {
  name                    = "${var.name}-network"
  auto_create_subnetworks = "false"
}

resource "google_compute_subnetwork" "zabbix_elk_subnet" {
  name          = "${var.name}-subnetwork651"
  ip_cidr_range = "10.65.1.0/24"
  region        = "${var.gcp_compute_region}"
  network       = "${google_compute_network.zabbix_elk_net.self_link}"
}

resource "google_compute_firewall" "zabbix_elk_firewall" {
  name          = "${var.name}-ports"
  network       = "${google_compute_network.zabbix_elk_net.name}"
//  source_tags = ["${var.name}-servers"]
  source_ranges = ["${data.google_compute_subnetwork.cluster-subnet.ip_cidr_range}", "${google_compute_subnetwork.zabbix_elk_subnet.ip_cidr_range}"]

  allow {
    protocol = "tcp"

    ports = [
      "22",          # SSH
      "80",          # HTTP
      "443",         # HTTPS
      "5044",        # Elastic Stack: Logstash Beats interface
      "5601",        # Elastic Stack: Kibana web interface
      "9200",        # Elastic Stack: Elasticsearch JSON interface
      "9300",        # Elastic Stack: Elasticsearch transport interface
      "9600",        # Elastic Stack: Logstash
      "10051",       # Zabbix server
    ]
  }
}

resource "google_compute_firewall" "zabbix_elk_external" {
  name          = "${var.name}-ext-ports"
  network       = "${google_compute_network.zabbix_elk_net.name}"
//  source_tags = ["${var.name}-servers"]
  source_ranges = ["${var.local_public_ip}"]

  allow {
    protocol = "tcp"

    ports = [
      "22",          # SSH
      "80",          # HTTP
      "443",         # HTTPS
      "5601",        # Elastic Stack: Kibana web interface
    ]
  }
}

module "gcp_zabbix_pc" {
  source = "../../modules/gcp-peering-connection"

  name                    = "${var.name}-pc01"
  peering_network01_name  = "${google_compute_network.zabbix_elk_net.name}"
  peering_network02_name  = "${var.gcp_k8s_cluster_name}"
  project_id              = "${var.gcp_project_id}"
}

# ELK server
module "elk_server" {
  source = "../../modules/gcp-elk-server"

  hostname                    = "elk-server"
  gcp_project_id              = "${var.gcp_project_id}"
  gcp_compute_region          = "${var.gcp_compute_region}"
  gcp_instance_zone           = "${var.gcp_instance_zone}"
  gcp_compute_network_name    = "${google_compute_network.zabbix_elk_net.name}"
  gcp_compute_subnetwork_name = "${google_compute_subnetwork.zabbix_elk_subnet.name}"
  gcp_image                   = "${var.gcp_image}"
  gcp_volume_device_name      = "${var.gcp_volume_device_name}"
  gcp_ssh_user                = "${var.gcp_ssh_user}"
  gcp_public_key_path         = "${var.gcp_public_key_path}"
}

# Zabbix server
module "zabbix_server" {
  source = "../../modules/gcp-zabbix-server"

  hostname                    = "zabbix-server"
  gcp_project_id              = "${var.gcp_project_id}"
  gcp_compute_region          = "${var.gcp_compute_region}"
  gcp_instance_zone           = "${var.gcp_instance_zone}"
  gcp_compute_network_name    = "${google_compute_network.zabbix_elk_net.name}"
  gcp_compute_subnetwork_name = "${google_compute_subnetwork.zabbix_elk_subnet.name}"
  gcp_image                   = "${var.gcp_image}"
  gcp_volume_device_name      = "${var.gcp_volume_device_name}"
  gcp_ssh_user                = "${var.gcp_ssh_user}"
  gcp_public_key_path         = "${var.gcp_public_key_path}"
  elk_private_ip              = "${module.elk_server.elk_gcp_private_ip}"
}

## Setup zabbix agents on GCP cluster
module "kubernetes_daemonset_zabbix_gcp" {
  source = "../../modules/k8s-zabbix-agent-daemonset"

  kube_config_path = "~/.kube/config.gcp"
  zbxsrv_private_ip = "${module.zabbix_server.zabbix_gcp_private_ip}"
  zbxsrv_public_ip = "${module.zabbix_server.zabbix_gcp_public_ip}"
}

## Setup elk filebeatsh on GCP cluster
module "kubernetes_daemonset_elk_gcp" {
  source = "../../modules/k8s-elk-filebeat-daemonset"

  kube_config_path = "~/.kube/config.gcp"
  elksrv_private_ip = "${module.elk_server.elk_gcp_private_ip}"
  k8s_cluster_name = "${var.gcp_k8s_cluster_name}"
}
