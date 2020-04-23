data "google_compute_network" "vpn_network" {
  name    = "${var.vpn_network_name}"
  project = "${var.project_id}"
}

data "google_compute_address" "vpn_static_ip" {
  name    = "${var.vpn_static_ip_name}"
  project = "${var.project_id}"
  region  = "${var.region}"
}

resource "google_compute_vpn_gateway" "gcp_vpn_gw01" {
  name    = "${var.name}"
  network = "${data.google_compute_network.vpn_network.self_link}"
  project = "${var.project_id}"
  region  = "${var.region}"
}

resource "google_compute_forwarding_rule" "fr_esp" {
  name        = "${google_compute_vpn_gateway.gcp_vpn_gw01.name}-esp"
  ip_protocol = "ESP"
  ip_address  = "${data.google_compute_address.vpn_static_ip.address}"
  target      = "${google_compute_vpn_gateway.gcp_vpn_gw01.self_link}"
  project     = "${var.project_id}"
  region      = "${var.region}"
}

resource "google_compute_forwarding_rule" "fr_udp500" {
  name        = "${google_compute_vpn_gateway.gcp_vpn_gw01.name}-udp500"
  ip_protocol = "UDP"
  port_range  = "500"
  ip_address  = "${data.google_compute_address.vpn_static_ip.address}"
  target      = "${google_compute_vpn_gateway.gcp_vpn_gw01.self_link}"
  project     = "${var.project_id}"
  region      = "${var.region}"
}

resource "google_compute_forwarding_rule" "fr_udp4500" {
  name        = "${google_compute_vpn_gateway.gcp_vpn_gw01.name}-udp4500"
  ip_protocol = "UDP"
  port_range  = "4500"
  ip_address  = "${data.google_compute_address.vpn_static_ip.address}"
  target      = "${google_compute_vpn_gateway.gcp_vpn_gw01.self_link}"
  project     = "${var.project_id}"
  region      = "${var.region}"
}

resource "google_compute_vpn_tunnel" "vpn_tunnel1" {
  name          = "${var.vpn_tunnel1_name}"
  project       = "${var.project_id}"
  region        = "${var.region}"
  peer_ip       = "${var.vpn_tunnel1_peer_ip}"
  shared_secret = "${var.vpn_tunnel1_pre_shared_key}"

  target_vpn_gateway = "${google_compute_vpn_gateway.gcp_vpn_gw01.self_link}"

  depends_on = [
    "google_compute_forwarding_rule.fr_esp",
    "google_compute_forwarding_rule.fr_udp500",
    "google_compute_forwarding_rule.fr_udp4500",
  ]
}

resource "google_compute_route" "vpn_tunnel1_route1" {
  name       = "vpn-tunnel1-route1"
  project    = "${var.project_id}"
  network    = "${data.google_compute_network.vpn_network.name}"
  dest_range = "${var.remote_network_cidr}"
  priority   = 1000

  next_hop_vpn_tunnel = "${google_compute_vpn_tunnel.vpn_tunnel1.self_link}"
}

resource "google_compute_vpn_tunnel" "vpn_tunnel2" {
  name          = "${var.vpn_tunnel2_name}"
  project       = "${var.project_id}"
  region        = "${var.region}"
  peer_ip       = "${var.vpn_tunnel2_peer_ip}"
  shared_secret = "${var.vpn_tunnel2_pre_shared_key}"

  target_vpn_gateway = "${google_compute_vpn_gateway.gcp_vpn_gw01.self_link}"

  depends_on = [
    "google_compute_forwarding_rule.fr_esp",
    "google_compute_forwarding_rule.fr_udp500",
    "google_compute_forwarding_rule.fr_udp4500",
  ]
}

resource "google_compute_route" "vpn_tunnel2_route1" {
  name       = "vpn-tunnel1-route2"
  project    = "${var.project_id}"
  network    = "${data.google_compute_network.vpn_network.name}"
  dest_range = "${var.remote_network_cidr}"
  priority   = 1000

  next_hop_vpn_tunnel = "${google_compute_vpn_tunnel.vpn_tunnel2.self_link}"
}

resource "google_compute_firewall" "zabbix_server_network" {
  name          = "${var.name}-zabbix-server"
  project       = "${var.project_id}"
  network       = "${data.google_compute_network.vpn_network.name}"
  source_ranges = ["${var.remote_network_cidr}"]

  allow {
    protocol = "tcp"
  }
  allow {
    protocol = "udp"
  }
  allow {
    protocol = "icmp"
  }
}
