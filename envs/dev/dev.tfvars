region = "us-east-1"
project_name = "dev-demo"

# VPC Variable Values
vpc_cidr            = "10.0.0.0/16"
public_subnet_cidr  = ["10.0.0.0/20", "10.0.16.0/20", "10.0.32.0/20"]
private_subnet_cidr = ["10.0.48.0/20", "10.0.64.0/20", "10.0.80.0/20"]
tags_private_subnet = {
  "kubernetes.io/role/internal-elb"     = "1"
  "kubernetes.io/cluster/demo-shekhar-dt"   = "owned"
}

# EKS Variable Values
cluster_names                = ["dev-shekhar-dt"]
eks_version                 = ["1.31"]
mobile_node_desired_size     = [1]
website_node_desired_size    = [1]
mobile_node_min_size         = [1]
mobile_node_max_size         = [2]
website_node_min_size        = [1]
website_node_max_size        = [2]
node_max_unavailable         = 1
mobile_node_type             = ["t4g.medium"]
website_node_type            = ["t4g.medium"]
mobile_ami                   = ["AL2_ARM_64"]
website_ami                  = ["AL2_ARM_64"]
