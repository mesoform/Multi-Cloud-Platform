data "template_file" "install_elk" {
  template = "${file("${path.module}/files/install_elk.sh.tpl")}"

  vars {
    hostname                  = "${var.hostname}"
    docker_engine_install_url = "${var.docker_engine_install_url}"

    volume_device_name = "${var.ebs_volume_device_name}"
    volume_mount_path  = "${var.ebs_volume_mount_path}"
    elasticsearch_image = "${var.elasticsearch_image}"
  }
}

# Create elk server instanse
resource "aws_instance" "elk_host" {
  ami                    = "${var.aws_ami_id}"
  instance_type          = "${var.aws_instance_type}"
  subnet_id              = "${var.aws_subnet_id}"
  vpc_security_group_ids = ["${var.aws_security_group_id}"]
  key_name               = "${var.aws_key_name}"

  tags = {
    Name = "${var.hostname}"
  }

  user_data = "${data.template_file.install_elk.rendered}"
}

resource "aws_ebs_volume" "host_volume" {
  count = "${var.ebs_volume_device_name != "" ? 1 : 0}"

  availability_zone = "${aws_instance.elk_host.availability_zone}"
  type              = "${var.ebs_volume_type}"
  size              = "${var.ebs_volume_size}"

  tags = {
    Name = "${var.hostname}-volume"
  }
}

resource "aws_volume_attachment" "host_volume_attachment" {
  count = "${var.ebs_volume_device_name != "" ? 1 : 0}"

  # Forcing detach to prevent VolumeInUse error
  force_detach = true

  device_name = "${var.ebs_volume_device_name}"
  volume_id   = "${aws_ebs_volume.host_volume.id}"
  instance_id = "${aws_instance.elk_host.id}"
}
