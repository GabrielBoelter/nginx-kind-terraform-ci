output "cluster_name" {
  description = "Nome do cluster kind"
  value       = kind_cluster.this.name
}

output "endpoint" {
  description = "Endpoint da API do Kubernetes"
  value       = kind_cluster.this.endpoint
}

output "kubectl_context" {
  description = "Contexto do kubectl para acessar o cluster"
  value       = "kind-${kind_cluster.this.name}"
}

output "app_url" {
  description = "URL da aplicação após o deploy dos manifestos"
  value       = "http://localhost:${var.host_port}"
}

output "kubeconfig_path" {
  description = "Caminho do kubeconfig gerado pelo Terraform/kind"
  value       = kind_cluster.this.kubeconfig_path
}
