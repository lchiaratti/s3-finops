## S3 FinOps

Esse Projeto Terraform tem como objetivo criar uma bucket S3 com foco em boas praticas de FinOps.

## O que este projeto cria
- 1 bucket principal para dados.
- 1 bucket dedicado para logs de acesso (server access logging).
- Nomes unicos de bucket (evita falha por nome global ja existente).
- Bloqueio de acesso publico em ambos os buckets.
- Criptografia padrao SSE-S3 (AES256).
- Lifecycle para reduzir custo:
  - transicao para `STANDARD_IA` no bucket principal (minimo de 30 dias, validado).
  - expiracao configuravel para logs.
  - limpeza de multipart incompleto (dias configuravel via `abort_multipart_days`).
- Output com estimativa mensal de custo (dados + logs + PUT + GET).
- Output com ARNs dos buckets para uso em policies IAM.

## Estrutura de arquivos
- `provider.tf`: providers, versoes e tags padrao.
- `main.tf`: recursos S3, lifecycle, logging e calculo de custo.
- `variables.tf`: variaveis de configuracao e precificacao.
- `terraform.tfvars`: valores do ambiente (apenas overrides de defaults).
- `output.tf`: nomes e ARNs dos buckets, estimativa de custo.

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
environment = "hml"
cost_center = "finops-lab"

estimated_main_storage_gb = 200
estimated_log_storage_gb  = 20
put_request_count         = 30000
get_request_count         = 400000

ia_transition_days   = 30
log_retention_days   = 45
abort_multipart_days = 7
```

Com esse exemplo, apos `terraform apply`, voce pode consultar:

```bash
terraform output monthly_s3_cost_estimate_usd
terraform output main_bucket_name
terraform output log_bucket_name
terraform output main_bucket_arn
terraform output log_bucket_arn
```

Saida esperada (formato):

```text
monthly_s3_cost_estimate_usd = "≈ $X.XX/mes [dados: $X.XX | logs: $X.XX | PUT: $X.XX | GET: $X.XX]"
main_bucket_name             = "bucket-finops-data-s3-finops-hml-xxxxxxxx"
log_bucket_name              = "bucket-finops-logs-s3-finops-hml-xxxxxxxx"
main_bucket_arn              = "arn:aws:s3:::bucket-finops-data-s3-finops-hml-xxxxxxxx"
log_bucket_arn               = "arn:aws:s3:::bucket-finops-logs-s3-finops-hml-xxxxxxxx"
```

## Variaveis mais importantes para FinOps
- `estimated_main_storage_gb`: volume estimado de dados do bucket principal.
- `estimated_log_storage_gb`: volume estimado de logs.
- `put_request_count`: volume mensal de PUT/POST/LIST.
- `get_request_count`: volume mensal de GET.
- `ia_transition_days`: dias para migrar para `STANDARD_IA` (minimo 30, validado pelo Terraform).
- `log_retention_days`: retencao de logs de acesso.
- `abort_multipart_days`: dias para cancelar uploads multipart incompletos (default: 7).
- `price_per_gb_standard`, `price_per_1000_put`, `price_per_1000_get`: preco de referencia usado no calculo.

## Observacoes
- Os precos em `variables.tf` sao referencia (sa-east-1, fevereiro/2026) obtidos da AWS Price List API. Ajuste para sua regiao/contrato.
- A estimativa de custo eh simplificada e nao substitui AWS Cost Explorer, CUR ou Infracost.
- O `terraform.tfvars` deve conter apenas overrides de defaults — variaveis como `aws_region` e `project_name` so precisam ser declaradas se forem diferentes dos valores padrao em `variables.tf`.
