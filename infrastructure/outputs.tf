output "project_ids" {
  value = { for name, project in google_project.project : name => project.project_id }
}

