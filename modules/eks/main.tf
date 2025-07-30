data "aws_iam_policy_document" "eks_assume_role" {
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["eks.amazonaws.com"]
    }

    actions = ["sts:AssumeRole"]
  }
}

resource "aws_iam_role" "eks_iam_role" {
  name               = "${var.project_name}-eks-role"
  assume_role_policy = data.aws_iam_policy_document.eks_assume_role.json
}

#resource : policy attachment for EKS cluster
resource "aws_iam_role_policy_attachment" "amazon_eks_cluster_policy" {
  # The ARN policy you want to apply
  # https://github.com/summitRoute/aws_managed_polices/blob/master/polices/AmazonEKSClusterPolicy
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
  #The role the policy should be applied to
  role       = aws_iam_role.eks_iam_role.name
}

#create the security group for the instance 


resource "aws_security_group" "eks_sg" {
  count       = length(var.cluster_names)
  name        = "${var.cluster_names[count.index]}-eks"
  description = "Security group for the EKS"

  vpc_id = var.vpc_id

  # Inbound rule to allow SSH access (adjust as per your requirements)
  ingress {
    from_port   = 0
    to_port     = 65535
    protocol    = "tcp"
    cidr_blocks = [var.vpc_ip]
  }
   egress {
    from_port   = 0
    to_port     = 0
    protocol    = -1
    cidr_blocks = ["0.0.0.0/0"]
  }

}

data "tls_certificate" "eks_tls_certificate" {
  count = length(var.cluster_names)
  url   = aws_eks_cluster.eks[count.index].identity[0].oidc[0].issuer
}

resource "aws_iam_openid_connect_provider" "eks_iam_openid_connect" {
  count           = length(var.cluster_names)
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = data.tls_certificate.eks_tls_certificate[count.index].certificates[*].sha1_fingerprint
  url             = data.tls_certificate.eks_tls_certificate[count.index].url
}

data "aws_iam_policy_document" "eks_assume_role_policy" {
  count = length(var.cluster_names)
  statement {
    actions = ["sts:AssumeRoleWithWebIdentity"]
    effect  = "Allow"

    condition {
      test     = "StringEquals"
      variable = "${replace(aws_iam_openid_connect_provider.eks_iam_openid_connect[count.index].url, "https://", "")}:sub"
      values   = ["system:serviceaccount:kube-system:aws-node"]
    }

    principals {
      identifiers = [aws_iam_openid_connect_provider.eks_iam_openid_connect[count.index].arn]
      type        = "Federated"
    }
  }
}

resource "aws_iam_role" "eks-service-account" {
  count              = length(var.cluster_names)
  assume_role_policy = data.aws_iam_policy_document.eks_assume_role_policy[count.index].json
  name               = "${var.cluster_names[count.index]}-eks-service-account"
}

resource "aws_eks_cluster" "eks" {
  count    = length(var.cluster_names)
  name     = var.cluster_names[count.index]
  role_arn = aws_iam_role.eks_iam_role.arn
  # https://docs.aws.amazon.com/eks/latest/userguide/kubernetes-versions.html
  version  = var.eks_version[count.index]

  vpc_config {
    # Indicates whether or not the EKS private API server endpoint is enabled
    endpoint_private_access = true
    # Indicates whether or not the EKS private API server endpoint is enabled
    endpoint_public_access  = false
    subnet_ids              = var.private_subnet_ids
    security_group_ids      = [aws_security_group.eks_sg[count.index].id]
  }

  enabled_cluster_log_types = ["api", "audit", "authenticator", "controllerManager", "scheduler"]

  depends_on = [aws_iam_role_policy_attachment.amazon_eks_cluster_policy]
}

resource "aws_eks_addon" "vpc-cni" {
  count        = length(var.cluster_names)
  cluster_name = aws_eks_cluster.eks[count.index].name
  addon_name   = "vpc-cni"
}

resource "aws_eks_addon" "coredns" {
  count        = length(var.cluster_names)
  cluster_name = aws_eks_cluster.eks[count.index].name
  addon_name   = "coredns"
}

resource "aws_eks_addon" "kube-proxy" {
  count        = length(var.cluster_names)
  cluster_name = aws_eks_cluster.eks[count.index].name
  addon_name   = "kube-proxy"
}


#EKs nodegroup iam role group creation

resource "aws_iam_role" "nodes" {
  count = length(var.cluster_names)
  name  = "${aws_eks_cluster.eks[count.index].name}-node-group"

  assume_role_policy = jsonencode({
    Statement = [
      {
        Action    = "sts:AssumeRole"
        Effect    = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
    Version = "2012-10-17"
  })
}


resource "aws_iam_policy" "ebs_volumes" {
  name = "eks-ebs-permissions"

  policy = jsonencode({
    Version   = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "ec2:CreateVolume",
          "ec2:DeleteVolume",
          "ec2:DescribeVolumes",
          "ec2:AttachVolume",
          "ec2:DetachVolume"
        ]
        Resource = "*"
      }
    ]
  })
}


resource "aws_iam_role_policy_attachment" "nodes-EBSPolicy" {
  count      = length(var.cluster_names)
  policy_arn = aws_iam_policy.ebs_volumes.arn
  role       = aws_iam_role.nodes[count.index].name
}

resource "aws_iam_role_policy_attachment" "nodes-AmazonEKSWorkerNodePolicy" {
  count      = length(var.cluster_names)
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
  role       = aws_iam_role.nodes[count.index].name
}

resource "aws_iam_role_policy_attachment" "nodes-AmazonEKS_CNI_Policy" {
  count      = length(var.cluster_names)
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
  role       = aws_iam_role.nodes[count.index].name
}

resource "aws_iam_role_policy_attachment" "nodes-AmazonEC2ContainerRegistryReadOnly" {
  count      = length(var.cluster_names)
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
  role       = aws_iam_role.nodes[count.index].name
}

resource "aws_iam_role_policy_attachment" "nodes-AmazonCloudWatch" {
  count      = length(var.cluster_names)
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy"
  role       = aws_iam_role.nodes[count.index].name
}


#eks node group creation
#mobile_node group creation 
resource "aws_eks_node_group" "mobile_nodes" {
  count           = length(var.mobile_ami)
  cluster_name    = aws_eks_cluster.eks[count.index].name
  version         = aws_eks_cluster.eks[count.index].version
  node_group_name = "${aws_eks_cluster.eks[count.index].name}-mobile-nodes"
  node_role_arn   = aws_iam_role.nodes[count.index].arn

  subnet_ids = var.private_subnet_ids

  ami_type       = var.mobile_ami[count.index]
  capacity_type  = "ON_DEMAND"
  instance_types = [var.mobile_node_type[count.index]]
  disk_size      = 50

  # Force version update if existing pods are unable to be drained due to a pod disruption budget issue
  force_update_version = true
  # Config the block with scaling settings
  scaling_config {
    desired_size = var.mobile_node_desired_size[count.index]
    max_size     = var.mobile_node_max_size[count.index]
    min_size     = var.mobile_node_min_size[count.index]
  }

  update_config {
    max_unavailable = var.node_max_unavailable
  }

  depends_on = [
    aws_iam_role_policy_attachment.nodes-AmazonEKSWorkerNodePolicy,
    aws_iam_role_policy_attachment.nodes-AmazonEKS_CNI_Policy,
    aws_iam_role_policy_attachment.nodes-AmazonEC2ContainerRegistryReadOnly,
  ]
}


#website node group creation
resource "aws_eks_node_group" "website_nodes" {
  count           = length(var.website_ami)
  cluster_name    = aws_eks_cluster.eks[count.index].name
  version         = aws_eks_cluster.eks[count.index].version
  node_group_name = "${aws_eks_cluster.eks[count.index].name}-website-nodes"
  node_role_arn   = aws_iam_role.nodes[count.index].arn

  subnet_ids = var.private_subnet_ids

  ami_type       = var.website_ami[count.index]
  capacity_type  = "ON_DEMAND"
  instance_types = [var.website_node_type[count.index]]
  disk_size      = 50

  # Force version update if existing pods are unable to be drained due to a pod disruption budget issue
  force_update_version = true
  # Config the block with scaling settings
  scaling_config {
    desired_size = var.website_node_desired_size[count.index]
    max_size     = var.website_node_max_size[count.index]
    min_size     = var.website_node_min_size[count.index]
  }

  update_config {
    max_unavailable = var.node_max_unavailable
  }

  depends_on = [
    aws_iam_role_policy_attachment.nodes-AmazonEKSWorkerNodePolicy,
    aws_iam_role_policy_attachment.nodes-AmazonEKS_CNI_Policy,
    aws_iam_role_policy_attachment.nodes-AmazonEC2ContainerRegistryReadOnly,
  ]
}