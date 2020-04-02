/* Define static address */
resource "google_compute_address" "gcp_static_address" {
  name   = "${var.name}"
  project = "${var.project_id}"
  region = "${var.region}"
}