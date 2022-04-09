# A minimal Terraform example

terraform {
# Remember activating strict versions before going live
  required_version = "= 1.1.8"
  
  required_providers {
    local = "= 2.2.2"
  }
}
  
locals {
  project_name = "bme-terraform-example"
}

resource "local_file" "project_name" {
  filename        = "${path.module}/${local.project_name}.txt"
  file_permission = "0640"
  content         = "${local.project_name}\n"
}

output "hello_world" {
  value = "Hello from project ${local.project_name}"
}
