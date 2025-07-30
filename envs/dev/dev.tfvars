region = "us-east-1"
project_name = "dev-demo"

# VPC Variable Values
vpc_cidr            = "10.0.0.0/16"
public_subnet_cidr  = ["10.0.0.0/20", "10.0.64.0/20", "10.0.128.0/20"]
private_subnet_cidr = ["10.0.32.0/20", "10.0.96.0/20", "10.0.160.0/20"]
tags_private_subnet = {
  "kubernetes.io/role/internal-elb"     = "1"
  "kubernetes.io/cluster/dev-lyca-dt"   = "owned"
  "kubernetes.io/cluster/stage-lyca-dt" = "owned"
  "kubernetes.io/cluster/test-lyca-dt"  = "owned"
}