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

WORK_DIR="$( cd "$( dirname "$BASH_SOURCE[0]" )" && pwd )"
mkdir -p "$WORK_DIR/elk/logstash"

echo "version: '2'
services:
  elasticsearch:
    image: docker.elastic.co/elasticsearch/elasticsearch:7.6.0
    container_name: elasticsearch
    environment:
      - discovery.type=single-node
    ports:
      - 9200:9200
      - 9300:9300
  kibana:
    image: docker.elastic.co/kibana/kibana:7.6.0
    container_name: kibana
    environment:
      SERVER_NAME: kibana
      ELASTICSEARCH_HOSTS: http://elasticsearch:9200
      SERVER_HOST: 0.0.0.0
    ports:
      - 5601:5601
  logstash:
    image: docker.elastic.co/logstash/logstash:7.6.0
    container_name: logstash
    ports:
      - 5044:5044
      - 9600:9600
    volumes:
      - "$WORK_DIR"/elk/logstash/logstash.conf:/usr/share/logstash/pipeline/logstash.conf
    command: sh -c \"logstash-plugin install logstash-input-google_pubsub logstash-filter-mutate && /usr/local/bin/docker-entrypoint\"
" > "$WORK_DIR"/docker-compose.yml

echo "input {
  google_pubsub {
    project_id => \"${project}\"
    topic => \""${mcp_topic_name}"\"
    subscription => \""${mcp_subscription_name}"\"
    include_metadata => true
    codec => \"json\"
    tags => [\"pubsub\"]
  }
  beats {
    port => 5044
    tags => [\"beats\"]
  }
}

filter {
  mutate { convert => { [\"container.labels.org_label-schema_build-date\",\"string\"] }
  mutate { convert => { [\"docker.container.labels.org_label-schema_build-date\",\"string\"] }
  mutate { convert => { [\"org_label-schema_build-date\",\"string\"] }
}

output {
  if \"pubsub\" in [tags] {
    elasticsearch {
      hosts    => \"elasticsearch:9200\"
      index => \"gcp-logstash-%%{+yyyy.MM.dd}\"
    }
  }
  if \"beats\" in [tags] {
    elasticsearch {
      hosts    => \"elasticsearch:9200\"
      index => \"%%{[@metadata][beat]}-%%{[@metadata][version]}-%%{+yyyy.MM.dd}\"
    }
  }
}
" > "$WORK_DIR"/elk/logstash/logstash.conf

sudo docker-compose -f "$WORK_DIR"/docker-compose.yml up -d
