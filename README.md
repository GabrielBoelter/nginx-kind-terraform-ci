# Aula 11 — Deploy no Kubernetes (kind) via Terraform + GitHub Actions

Pipeline de CI/CD que, a cada push na branch `main` (ou execução manual), faz
todo o ciclo sozinho dentro do runner do GitHub Actions:

1. Provisiona um cluster Kubernetes local com **Kind**, via **Terraform**.
2. Builda a imagem Docker do **nginx** com a página HTML da aula.
3. Carrega essa imagem dentro do cluster (`kind load docker-image`).
4. Aplica os manifestos Kubernetes (**Deployment** + **Service**).
5. Testa a aplicação via HTTP.
6. Destrói o cluster no final (o runner é efêmero mesmo, mas o `destroy` deixa o fluxo correto e documentado).

## Estrutura do repositório

```
.
├── .github/workflows/deploy.yml   # Pipeline do GitHub Actions
├── app/
│   ├── Dockerfile                 # Imagem nginx + index.html
│   └── index.html                 # Página da aplicação
├── k8s/
│   ├── deployment.yaml            # Deployment (2 réplicas do nginx)
│   └── service.yaml               # Service NodePort (30081 -> 81)
└── terraform/
    ├── versions.tf                # Provider tehcyx/kind
    ├── variables.tf               # cluster_name, host_port, node_port
    ├── main.tf                    # Recurso kind_cluster
    └── outputs.tf                 # Outputs (endpoint, kubeconfig_path, app_url)
```

## Como o pipeline funciona (`.github/workflows/deploy.yml`)

| Etapa | O que faz |
|---|---|
| Checkout | Baixa o código do repositório no runner. |
| Setup Terraform / kubectl / kind | Instala as ferramentas necessárias no runner Ubuntu. |
| `terraform init` / `apply` | Cria o cluster `kind` (control-plane com a porta 81 do runner mapeada para o NodePort 30081), **sem nenhum comando manual** de `kind create cluster`. |
| Export `KUBECONFIG` | Usa o output `kubeconfig_path` do Terraform para apontar o `kubectl` para o cluster recém-criado. |
| `docker build` | Gera a imagem `nginx-aula-11:1.0.0` a partir de `app/Dockerfile`. |
| `kind load docker-image` | Como não existe um registry externo, a imagem é carregada diretamente nos nodes do cluster kind. |
| `kubectl apply` | Sobe o `Deployment` (2 réplicas) e o `Service` (`NodePort` 30081). |
| `kubectl rollout status` | Aguarda os pods ficarem prontos antes de seguir. |
| Evidências (`kubectl get nodes/pods/svc`) | Ficam no log do job como prova de que o cluster e a aplicação subiram. |
| Smoke test (`curl`) | Faz uma requisição HTTP para `http://localhost:81` e valida o conteúdo da página. O HTML de resposta é publicado como *artifact* do workflow. |
| `terraform destroy` | Roda sempre (`if: always()`), mesmo se um passo anterior falhar, para encerrar o cluster de forma limpa. |

## Rodando localmente (opcional, para testar antes do push)

```bash
# 1. Provisiona o cluster
cd terraform
terraform init
terraform apply -auto-approve
export KUBECONFIG=$(terraform output -raw kubeconfig_path)
cd ..

# 2. Builda e carrega a imagem no cluster
docker build -t nginx-aula-11:1.0.0 ./app
kind load docker-image nginx-aula-11:1.0.0 --name aula-11

# 3. Deploy da aplicação
kubectl apply -f k8s/deployment.yaml
kubectl apply -f k8s/service.yaml
kubectl rollout status deployment/nginx-aula-11

# 4. Testar
curl http://localhost:81

# 5. Destruir
cd terraform && terraform destroy -auto-approve
```

## Requisitos no runner / máquina

- Docker em execução
- Terraform >= 1.5
- `kind` CLI (usado apenas para `kind load docker-image`; a criação do
  cluster em si é feita pelo provider Terraform `tehcyx/kind`)
- `kubectl`

## Observação sobre o provider `tehcyx/kind`

O provider Terraform cria/destrói o cluster (`kind_cluster`), mas **não**
expõe um recurso nativo para carregar imagens Docker dentro dos nodes nem
para aplicar manifestos Kubernetes. Por isso o pipeline usa, na sequência:

- `kind load docker-image` (CLI do kind) para colocar a imagem dentro do cluster;
- `kubectl apply` para aplicar os manifestos do diretório `k8s/`.

Essas duas etapas não substituem o Terraform no provisionamento do
cluster — apenas complementam o fluxo depois que o cluster já existe,
criado unicamente pelo `terraform apply`.
