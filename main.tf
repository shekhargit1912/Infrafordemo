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