output "monthly_s3_cost_estimate_usd" {
  description = "Estimativa mensal de custo S3 (USD) com breakdown"
  value = format(
    "≈ $%.2f/mes [dados: $%.2f | logs: $%.2f | PUT: $%.2f | GET: $%.2f]",
    local.monthly_cost_usd,
    local.main_storage_cost_usd,
    local.log_storage_cost_usd,
    local.put_request_cost_usd,
    local.get_request_cost_usd
  )
}

output "main_bucket_name" {
  description = "Main data bucket name"
  value       = aws_s3_bucket.s3_bucket_finops.bucket
}

output "log_bucket_name" {
  description = "Access logs bucket name"
  value       = aws_s3_bucket.log_bucket.bucket
}

output "main_bucket_arn" {
  description = "ARN of the main data bucket"
  value       = aws_s3_bucket.s3_bucket_finops.arn
}

output "log_bucket_arn" {
  description = "ARN of the access logs bucket"
  value       = aws_s3_bucket.log_bucket.arn
}
