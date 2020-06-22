# Define outputs
output "mcp_topic_name" {
  value = "${google_pubsub_topic.mcp-topic.name}"
}

output "mcp_subscription_name" {
  value = "${google_pubsub_subscription.mcp-subscription.name}"
}
