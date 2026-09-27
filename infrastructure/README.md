# GCP infrastructure

This Terraform is only a starting boundary: it creates the LucentVisit folder and public/security project separation. It deliberately does not create a regulated-data project or health-data services.

Before applying:

1. Create the company Google Cloud Organization.
2. Configure a remote, versioned Terraform state bucket in a bootstrap project.
3. Authenticate CI through Workload Identity Federation—never a downloaded service-account key.
4. Add organization policies, group IAM, audit-log routing, KMS, budgets, Security Command Center, and network controls through reviewed modules.
5. Choose a collision-free `project_prefix`; GCP project IDs are globally unique.
6. Run `terraform plan` through CI and require manual production approval.

Do not place health information in Terraform variables, state, project names, resource names, labels, or logs.
