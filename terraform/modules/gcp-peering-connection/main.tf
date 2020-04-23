data "google_compute_network" "peering_net01" {
  name    = "${var.peering_network01_name}"
  project = "${var.project_id}"
}

data "google_compute_network" "peering_net02" {
  name    = "${var.peering_network02_name}"
  project = "${var.project_id}"
}

resource "google_compute_network_peering" "peering01" {
  name = "${var.name}-peering01"
  network = "${data.google_compute_network.peering_net01.self_link}"
  peer_network = "${data.google_compute_network.peering_net02.self_link}"
}

resource "google_compute_network_peering" "peering02" {
  name = "${var.name}-peering02"
  network = "${data.google_compute_network.peering_net02.self_link}"
  peer_network = "${data.google_compute_network.peering_net01.self_link}"
}

resource "google_compute_firewall" "zabbix_server_peering_fw01" {
  name          = "${var.name}-srv-fw01"
  project       = "${var.project_id}"
  network       = "${data.google_compute_network.peering_net01.name}"
  source_ranges = ["10.142.0.0/16"]

  allow {
    protocol = "all"
  }
//  allow {
//    protocol = "udp"
//  }
//  allow {
//    protocol = "icmp"
//  }
}

resource "google_compute_firewall" "cluster_peering_fw01" {
  name          = "${var.name}-cl-fw01"
  project       = "${var.project_id}"
  network       = "${data.google_compute_network.peering_net02.name}"
  source_ranges = ["10.65.0.0/16"]

  allow {
    protocol = "all"
  }
//  allow {
//    protocol = "udp"
//  }
//  allow {
//    protocol = "icmp"
//  }
}
