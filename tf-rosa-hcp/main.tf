
locals {
}

module "rosa" {
  source = "git::https://github.com/rh-mobb/terraform-rosa.git"
  admin_password = var.admin_password
  cluster_name         = var.cluster_name
  private              = var.private
  region               = var.region
  multi_az             = false
  hosted_control_plane = true
  replicas             = 2
  max_replicas         = 4
  ocp_version          = var.ocp_version
  pod_cidr             = var.pod_cidr
  service_cidr         = var.service_cidr
  tags                 = var.tags
  developer_password   = var.developer_password
  compute_machine_type = var.compute_machine_type
  token                = var.token
}

resource "aws_s3_bucket" "multiple_buckets" {
  for_each = toset(var.bucket_names)
  bucket = each.value
}


resource "aws_s3_bucket_public_access_block" "bucket1_private" {
  for_each = aws_s3_bucket.multiple_buckets
  bucket = each.value.bucket

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "rhcs_hcp_machine_pool" "secondary_machine_pool" {
    auto_repair = false
    autoscaling = {
      enabled = false
    }
    replicas = 2
    aws_node_pool = {
      instance_type = var.secondary_machine_pool_instance_type
      tags          = var.tags
    }
    cluster   = module.rosa.cluster_id
    name      = var.secondary_machine_pool_name
    subnet_id = element(module.rosa.private_subnet_ids, 0)

}
