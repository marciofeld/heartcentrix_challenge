module "iam_eks_lb_role" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"
  version = "5.54.0"

  role_name                              = "eks-lb-controller"
  attach_load_balancer_controller_policy = true

  oidc_providers = {
    main = {
      provider_arn               = module.eks.oidc_provider_arn
      namespace_service_accounts = ["kube-system:aws-load-balancer-controller"]
    }
  }
}

resource "aws_iam_policy" "ecr_access" {
  name        = "${local.name}-ecr-access"
  description = "Policy allowing access to ECR repository for ${local.name}"
  policy      = data.aws_iam_policy_document.ecr_access.json
}

resource "aws_iam_role_policy_attachment" "ecr_access" {
  for_each = module.eks.eks_managed_node_groups

  role       = split("/", each.value.iam_role_arn)[1]
  policy_arn = aws_iam_policy.ecr_access.arn
}
