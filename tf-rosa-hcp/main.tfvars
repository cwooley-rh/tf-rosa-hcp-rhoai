ocp_version = "4.16.4"
region = "us-east-2"
multi_az = false
cluster_name = "cwooley-rhoai"
tags = {
    "cost-center"   = "CC468"
    "service-phase" = "lab"
    "app-code"      = "MOBB-001"
    "owner"         = "cwooley_redhat.com"
    "provisioner"   = "Terraform"
}
bucket_names = ["my-cluster-bucket1", "my-cluster-bucket2"]
compute_machine_type = "p3.2xlarge"
secondary_machine_pool_name = "secondary-pool"
secondary_machine_pool_instance_type = "m5.xlarge"
secondary_machine_pool_replicas = 2
vpc_cidr  = "10.10.0.0/16"
developer_password = ""
