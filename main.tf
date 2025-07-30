resource "random_integer" "random_index" {
  min = 0
  max = length(var.public_subnet_cidr) - 1
}

module "vpc" {
  source              = "./modules/vpc"
  region              = var.region
  project_name        = var.project_name
  vpc_cidr            = var.vpc_cidr
  public_subnet_cidr  = var.public_subnet_cidr
  private_subnet_cidr = var.private_subnet_cidr
  tags_private_subnet = var.tags_private_subnet
  index               = random_integer.random_index.result
}

module "ekscluster" {
  source                    = "./modules/eks"
  project_name              = var.project_name
  eks_version               = var.eks_version
  vpc_id                    = module.vpc.vpc_id
  private_subnet_ids        = module.vpc.private_subnet_ids
  node_max_unavailable      = var.node_max_unavailable
  vpc_ip                    = module.vpc.vpc_ip
  cluster_names             = var.cluster_names
  mobile_node_desired_size  = var.mobile_node_desired_size
  mobile_node_max_size      = var.mobile_node_max_size
  mobile_node_min_size      = var.mobile_node_min_size
  website_node_desired_size = var.website_node_desired_size
  website_node_max_size     = var.website_node_max_size
  website_node_min_size     = var.website_node_min_size
  mobile_ami                = var.mobile_ami
  mobile_node_type          = var.mobile_node_type
  website_ami               = var.website_ami
  website_node_type         = var.website_node_type
}