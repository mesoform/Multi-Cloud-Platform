#!/bin/sh

sudo curl ${docker_engine_install_url} | sh
sudo service docker stop
sudo bash -c 'echo "{
  \"storage-driver\": \"overlay2\"
}" > /etc/docker/daemon.json'
sudo service docker restart
sudo apt-get install -y docker-compose

sudo hostnamectl set-hostname ${hostname}

# Mounting the Volume
# The device name that the user entered. (not necessarily the one that the OS is using)
# This is assumed to have the format /dev/sd[f-p] (e.g. /dev/sdf, /dev/sdp)
DEVICE_NAME_INPUT='${volume_device_name}'

echo "device name: $DEVICE_NAME_INPUT" >> /var/log/syslog

if [ "$DEVICE_NAME_INPUT" != '' ]; then
	MOUNT_PATH='${volume_mount_path}'

	# Extract the last character of the device name
	LAST_CHAR=$(echo -n $DEVICE_NAME_INPUT | tail -c 1)

	# Finding the device name the OS is using the last character of the device name
	# This assumes the OS will map the device name to a format such as "/dev/xvd?"
	# where '?' is the last character of the device name chosen by the user
	if [ -b /dev/xvd$LAST_CHAR ]; then
		INSTANCE_STORE_BLOCK_DEVICE=/dev/xvd$LAST_CHAR
	fi

	echo $INSTANCE_STORE_BLOCK_DEVICE

	if [ -b $INSTANCE_STORE_BLOCK_DEVICE ]; then
		sudo mke2fs -E nodiscard -L $MOUNT_PATH -j $INSTANCE_STORE_BLOCK_DEVICE &&
		sudo tune2fs -r 0 $INSTANCE_STORE_BLOCK_DEVICE &&
		echo "LABEL=$MOUNT_PATH     $MOUNT_PATH           ext4    defaults,noatime  1   1" >> /etc/fstab &&
		sudo mkdir -p $MOUNT_PATH &&
		sudo mount $MOUNT_PATH
	fi
fi
echo "Run docker" >> /var/log/syslog

WORK_DIR="/var/lib/cloud/instance/scripts"

echo "version: '2'
services:
  zabbix:
    restart: always
    image: ${zabbix_server_image}
    container_name: zabbix
    ports:
      - 80:80
      - 10051:10051
  filebeat:
    restart: always
    image: docker.elastic.co/beats/filebeat:7.6.0
    container_name: filebeat
    user: root
    environment:
      strict.perms: 'false'
      output.logstash.hosts: '[\"${elk_private_ip}:5044\"]'
    volumes:
      - "$WORK_DIR"/filebeat.docker.yml:/usr/share/filebeat/filebeat.yml:ro
      - /var/lib/docker/containers:/var/lib/docker/containers:ro
      - /var/run/docker.sock:/var/run/docker.sock:ro
    depends_on:
      - zabbix
" > "$WORK_DIR"/docker-compose.yml

echo "filebeat.config:
  modules:
    path: $\{path.config\}/modules.d/*.yml
    reload.enabled: false

filebeat.autodiscover:
  providers:
    - type: docker
      hints.enabled: true
      templates:
        - condition:
            equals.docker.container.image: zabbix
          config:
            - type: container
              paths:
                - /var/lib/docker/containers/*/*.log

#filebeat.inputs:
#  - type: container
#    enabled: true
#    paths:
#      - /var/lib/docker/containers/*/*.log
#    stream: all
#  processors:
#    - add_docker_metadata: ~

processors:
  - add_cloud_metadata: ~
  - add_host_metadata: ~
  - add_docker_metadata: ~

output.logstash:
  hosts: ['${elk_private_ip}:5044']
  index: \"${hostname}\"
" > "$WORK_DIR"/filebeat.docker.yml

sudo docker-compose -f "$WORK_DIR"/docker-compose.yml up -d
