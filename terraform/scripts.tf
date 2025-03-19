resource "null_resource" "update_kubeconfig" {
  depends_on = [module.eks]

  provisioner "local-exec" {
    command = "aws eks update-kubeconfig --name ${module.eks.cluster_name} --region ${local.region}"
  }
}

resource "null_resource" "wait_for_lb_controller" {
  depends_on = [helm_release.lb_controller]

  provisioner "local-exec" {
    command = "kubectl get ingressclass alb || sleep 30"
  }
}
