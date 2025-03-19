resource "kubernetes_namespace" "challenge_api" {
  metadata {
    name = "challenge-api"
  }
  depends_on = [null_resource.update_kubeconfig]
}
