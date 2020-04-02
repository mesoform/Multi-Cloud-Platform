filebeat.inputs:
  - type: container
    paths:
      - /var/log/containers/*.log
    processors:
      - add_kubernetes_metadata:
          host: $${NODE_NAME}
          matchers:
            - logs_path:
                logs_path: "/var/log/containers/"
# To enable hints based autodiscover, remove `filebeat.inputs` configuration and uncomment this:
#filebeat.autodiscover:
#  providers:
#    - type: kubernetes
#      node: $${NODE_NAME}
#      hints.enabled: true
#      hints.default_config:
#        type: container
#        paths:
#          - /var/log/containers/*$${data.kubernetes.container.id}.log

processors:
  - add_cloud_metadata:
  - add_host_metadata:

output.logstash:
  hosts: ['${elksrv_private_ip}:5044']
  index: "${k8s_cluster_name}"
