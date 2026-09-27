variable "organization_id" {
  description = "Numeric Google Cloud organization ID."
  type        = string
}

variable "billing_account_id" {
  description = "Google Cloud billing account ID."
  type        = string
  sensitive   = true
}

variable "project_prefix" {
  description = "Globally unique project prefix."
  type        = string
  default     = "lucentvisit"
}

variable "region" {
  description = "Default U.S. region for public workloads."
  type        = string
  default     = "us-central1"
}
