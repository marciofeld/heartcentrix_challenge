module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "20.33.1"

  cluster_name                             = "${local.name}-eks"
  cluster_version                          = "1.32"
  cluster_endpoint_private_access          = true
  cluster_endpoint_public_access           = true
  iam_role_use_name_prefix                 = false
  enable_cluster_creator_admin_permissions = true
  vpc_id                                   = module.vpc.vpc_id
  subnet_ids                               = module.vpc.private_subnets

  cluster_addons = {
    coredns                = {}
    eks-pod-identity-agent = {}
    kube-proxy             = {}
    vpc-cni                = {}
  }

  eks_managed_node_groups = {
    eks_node_group_1 = {
      instance_types = ["t3.small"]
      capacity_type  = "SPOT"
      min_size       = 1
      max_size       = 2
      desired_size   = 1
      subnet_ids     = module.vpc.private_subnets
    }
  }

  tags = local.tags
}

module "eks_aws_auth" {
  source  = "terraform-aws-modules/eks/aws//modules/aws-auth"
  version = "20.33.1"

  manage_aws_auth_configmap = true

  aws_auth_roles = [
    {
      rolearn  = data.aws_caller_identity.current.arn
      username = "creator"
      groups   = ["system:masters"]
    }
  ]

  aws_auth_users = [
    {
      userarn  = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:user/marcio.feldmann+heartcentrix"
      username = "admin"
      groups   = ["system:masters"]
    }
  ]
  depends_on = [module.eks]
}
