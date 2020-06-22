data "template_file" "install_zabbix" {
  template = "${file("${path.module}/files/install_zabbix.sh.tpl")}"

  vars {
    hostname                  = "${var.hostname}"
    docker_engine_install_url = "${var.docker_engine_install_url}"

    volume_device_name = "${var.gcp_volume_device_name}"
    volume_mount_path  = "${var.gcp_volume_mount_path}"
    zabbix_server_image = "${var.zabbix_server_image}"
    elk_private_ip      = "${var.elk_private_ip}"
  }
}

# Create zabbix server instance
resource "google_compute_instance" "zabbix_server" {
  name          = "${var.hostname}"
  machine_type  = "${var.gcp_machine_type}"
  zone          = "${var.gcp_instance_zone}"
  project       = "${var.gcp_project_id}"

  tags          = ["${var.hostname}"]

  boot_disk {
    initialize_params {
      image = "${var.gcp_image}"
    }
  }
//  gcp_public_key_path
  attached_disk {
    source = "${element(concat(google_compute_disk.zabbix_volume.*.self_link, list("")), 0)}"
  }

  network_interface {
    network = "${var.gcp_compute_network_name}"

    subnetwork = "${var.gcp_compute_subnetwork_name}"

    access_config {
      // Ephemeral IP
    }
  }

  service_account {
    email = "${var.gcp_service_account_email}"
    scopes = ["https://www.googleapis.com/auth/cloud-platform"]
  }

  metadata {
    ssh-keys = "${var.gcp_ssh_user}:${file(var.gcp_public_key_path)}"
  }

  metadata_startup_script = "${data.template_file.install_zabbix.rendered}"
}

resource "google_compute_disk" "zabbix_volume" {
  name    = "${var.hostname}-volume"
  project = "${var.gcp_project_id}"

  count   = "${var.gcp_disk_type == "" ? 0 : 1}"
  type    = "${var.gcp_disk_type}"
  zone    = "${var.gcp_instance_zone}"
  size    = "${var.gcp_disk_size}"
}
