resource "google_project_service" "mcp-pubsub-service" {
  project = "${var.project_id}"
  service = "pubsub.googleapis.com"

  disable_dependent_services = true
}

resource "google_pubsub_topic" "mcp-topic" {
  project = "${google_project_service.mcp-pubsub-service.project}"
  name = "topic-${google_project_service.mcp-pubsub-service.project}"
}

resource "google_pubsub_subscription" "mcp-subscription" {
  project = "${google_project_service.mcp-pubsub-service.project}"
  name  = "subscription-${google_project_service.mcp-pubsub-service.project}"
  topic = "${google_pubsub_topic.mcp-topic.name}"

  # 20 minutes
  message_retention_duration = "1200s"
  retain_acked_messages      = true

  ack_deadline_seconds = 20

  expiration_policy {
    ttl = "300000.5s"
  }
}

resource "google_project_iam_audit_config" "mcp-audit-log" {
  project = "${google_project_service.mcp-pubsub-service.project}"
  service = "allServices"
  audit_log_config {
    log_type = "ADMIN_READ"
  }
  audit_log_config {
    log_type = "DATA_READ"
  }
    audit_log_config {
    log_type = "DATA_WRITE"
  }
}

resource "google_logging_project_sink" "mcp-sink" {
  project = "${google_project_service.mcp-pubsub-service.project}"
  name = "logging-sink-pubsub-${google_project_service.mcp-pubsub-service.project}"
  destination = "pubsub.googleapis.com/projects/${google_project_service.mcp-pubsub-service.project}/topics/topic-mcp-testing-270009"
  filter = "logName:\"/logs/cloudaudit.googleapis.com\" OR resource.type = gce"

  unique_writer_identity = true
}

resource "google_pubsub_topic_iam_binding" "mcp-log-writer" {
  project = "${google_project_service.mcp-pubsub-service.project}"
  topic = "${google_pubsub_topic.mcp-topic.name}"
  role = "roles/pubsub.publisher"

  members = [
    "${google_logging_project_sink.mcp-sink.writer_identity}",
  ]
}
