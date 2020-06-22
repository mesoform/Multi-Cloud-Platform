variable "project_id" {}

variable "expiration_policy" {
  default = ""
  description = "Defaults to an empty string (never expire for prod env)"
}