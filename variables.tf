#VPC Variables
variable "vpc_cidr" {}

variable "public_subnet_cidr" {}

variable "private_subnet_cidr" {}

variable "tags_private_subnet" {}

variable "region" {}
variable "project_name" {}

# EKS Variables
variable "cluster_names" {}

variable "eks_version" {}

variable "mobile_node_desired_size" {}

variable "mobile_node_min_size" {}

variable "mobile_node_max_size" {}

variable "website_node_desired_size" {}

variable "website_node_min_size" {}

variable "website_node_max_size" {}

variable "node_max_unavailable" {}

variable "mobile_node_type" {}

variable "website_node_type" {}

variable "mobile_ami" {}

variable "website_ami" {}