variable "aws_region" {
  description = "AWS region for S3 buckets"
  type        = string
  default     = "sa-east-1"
}

variable "project_name" {
  description = "Project identifier used in names and tags"
  type        = string
  default     = "s3-finops"
}

variable "environment" {
  description = "Environment tag and naming suffix"
  type        = string
  default     = "dev"
}

variable "cost_center" {
  description = "Tag to support FinOps allocation"
  type        = string
  default     = "finops-lab"
}

variable "main_bucket_prefix" {
  description = "Prefix for the main data bucket name"
  type        = string
  default     = "bucket-finops-data"
}

variable "log_bucket_prefix" {
  description = "Prefix for the access-logs bucket name"
  type        = string
  default     = "bucket-finops-logs"
}

variable "estimated_main_storage_gb" {
  description = "Estimated monthly storage (GB) for the main bucket"
  type        = number
  default     = 20
}

variable "estimated_log_storage_gb" {
  description = "Estimated monthly storage (GB) for access logs bucket"
  type        = number
  default     = 2
}

variable "put_request_count" {
  description = "Estimated number of PUT/POST/LIST requests per month"
  type        = number
  default     = 1000
}

variable "get_request_count" {
  description = "Estimated number of GET requests per month"
  type        = number
  default     = 20000
}

variable "ia_transition_days" {
  description = "Days before transitioning objects to STANDARD_IA"
  type        = number
  default     = 30
}

variable "log_retention_days" {
  description = "Retention (days) for server access logs in log bucket"
  type        = number
  default     = 30
}

/* Precos de referencia (fev/2026) para sa-east-1.
 * Ajuste conforme regiao e acordo comercial.
 * S3 Standard storage (primeiros 50 TB): USD 0.0405 por GB-mes
 * PUT/COPY/POST/LIST: USD 0.0070 por 1 000 req
 * GET e demais requests: USD 0.0056 por 10 000 req (equivale a USD 0.00056 por 1 000 req)
 * (fonte: AWS Price List API, versao 20260218175156)
 */
variable "price_per_gb_standard" {
  type    = number
  default = 0.0405
}

variable "price_per_1000_put" {
  type    = number
  default = 0.0070
}

variable "price_per_1000_get" {
  type    = number
  default = 0.00056
}
