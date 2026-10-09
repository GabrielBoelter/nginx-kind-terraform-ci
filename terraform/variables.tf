variable "cluster_name" {
  description = "Nome do cluster kind"
  type        = string
  default     = "aula-11"
}

variable "host_port" {
  description = "Porta da máquina local (ou do runner do GitHub Actions) onde a aplicação será exposta"
  type        = number
  default     = 81
}

variable "node_port" {
  description = "NodePort do Service que recebe o tráfego vindo de host_port"
  type        = number
  default     = 30081
}
