# A minimal Terraform example

terraform {
# Remember activating strict versions before going live
  required_version = "= 1.0.1"
  
  required_providers {
    local = "= 2.1.0"
  }
}
  
locals {
  project_name = "bme-terraform-example"
}

resource "local_file" "project_name" {
  content  = local.project_name
  filename = "${path.module}/${local.project_name}.txt"
}

output "hello_world" {
  value = "Hello from project ${local.project_name}"
}
