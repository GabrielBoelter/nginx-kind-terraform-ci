resource "kind_cluster" "this" {
  name           = var.cluster_name
  wait_for_ready = true

  kind_config {
    kind        = "Cluster"
    api_version = "kind.x-k8s.io/v1alpha4"

    node {
      role = "control-plane"

      # Encaminha host_port (máquina/runner) para o NodePort do Service do nginx
      extra_port_mappings {
        container_port = var.node_port
        host_port      = var.host_port
        protocol       = "TCP"
      }
    }
  }
}
