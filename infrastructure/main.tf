provider "google" {
  region = var.region
}

locals {
  projects = {
    security = "Central audit and security services"
    cicd     = "Build and deployment services"
    dev      = "Non-production public services"
    prod     = "Production public services without health data"
  }
}

resource "google_folder" "clearvisit" {
  display_name = "LucentVisit"
  parent       = "organizations/${var.organization_id}"
}

resource "google_project" "project" {
  for_each = local.projects

  name            = "${var.project_prefix}-${each.key}"
  project_id      = "${var.project_prefix}-${each.key}"
  folder_id       = google_folder.clearvisit.name
  billing_account = var.billing_account_id
  labels = {
    application = "lucentvisit"
    data_class   = "no-health-data"
    environment  = each.key
  }
}

# The regulated-data project is intentionally absent. It must be introduced by
# a separately reviewed change after BAA, legal, privacy, and security approval.
