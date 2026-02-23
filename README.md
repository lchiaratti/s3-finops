## S3 FinOps

Esse Projeto Terraform tem como objetivo criar uma bucket S3 com foco em boas praticas de FinOps.

## O que este projeto cria
- 1 bucket principal para dados.
- 1 bucket dedicado para logs de acesso (server access logging).
- Nomes unicos de bucket (evita falha por nome global ja existente).
- Bloqueio de acesso publico em ambos os buckets.
- Criptografia padrao SSE-S3 (AES256).
- Lifecycle para reduzir custo:
  - transicao para `STANDARD_IA` no bucket principal.
  - expiracao configuravel para logs.
  - limpeza de multipart incompleto.
- Output com estimativa mensal de custo (dados + logs + PUT + GET).

## Estrutura de arquivos
- `provider.tf`: providers, versoes e tags padrao.
- `main.tf`: recursos S3, lifecycle, logging e calculo de custo.
- `variables.tf`: variaveis de configuracao e precificacao.
- `terraform.tfvars`: valores do ambiente (customizavel).
- `output.tf`: nomes dos buckets e estimativa de custo.

## Pre-requisitos
- Terraform `>= 1.6.0`
- Credenciais AWS configuradas (por exemplo via `aws configure` ou variaveis `AWS_*`).
- Permissoes para criar recursos S3 e ler/write state.

## Como executar
1. Inicializar o projeto:
```bash
terraform init
```

2. (Opcional) Validar configuracao:
```bash
terraform validate
```

3. Gerar plano:
```bash
terraform plan -out tfplan
```

4. Aplicar:
```bash
terraform apply tfplan
```

5. Ver outputs:
```bash
terraform output
```

6. Destruir ambiente (quando nao precisar mais):
```bash
terraform destroy
```

## Exemplo de uso
Exemplo de `terraform.tfvars` para um ambiente de homologacao:

```hcl
aws_region = "sa-east-1"

project_name = "s3-finops"
environment  = "hml"
cost_center  = "finops-lab"

estimated_main_storage_gb = 200
estimated_log_storage_gb  = 20
put_request_count         = 30000
get_request_count         = 400000

ia_transition_days = 30
log_retention_days = 45
```

Com esse exemplo, apos `terraform apply`, voce pode consultar:

```bash
terraform output monthly_s3_cost_estimate_usd
terraform output main_bucket_name
terraform output log_bucket_name
```

Saida esperada (formato):

```text
monthly_s3_cost_estimate_usd = "≈ $X.XX/mes [dados: $X.XX | logs: $X.XX | PUT: $X.XX | GET: $X.XX]"
main_bucket_name             = "bucket-finops-data-s3-finops-hml-xxxxxxxx"
log_bucket_name              = "bucket-finops-logs-s3-finops-hml-xxxxxxxx"
```

## Variaveis mais importantes para FinOps
- `estimated_main_storage_gb`: volume estimado de dados do bucket principal.
- `estimated_log_storage_gb`: volume estimado de logs.
- `put_request_count`: volume mensal de PUT/POST/LIST.
- `get_request_count`: volume mensal de GET.
- `ia_transition_days`: dias para migrar para `STANDARD_IA`.
- `log_retention_days`: retencao de logs de acesso.
- `price_per_gb_standard`, `price_per_1000_put`, `price_per_1000_get`: preco de referencia usado no calculo.

## Observacoes
- Os precos em `variables.tf` sao referencia (sa-east-1, fevereiro/2026) obtidos da AWS Price List API. Ajuste para sua regiao/contrato.
- A estimativa de custo eh simplificada e nao substitui AWS Cost Explorer, CUR ou Infracost.
