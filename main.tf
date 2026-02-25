resource "random_id" "suffix" {
  byte_length = 4
}

locals {
  project_slug = replace(lower(var.project_name), "_", "-")
  env_slug     = replace(lower(var.environment), "_", "-")

  main_bucket_name = "${var.main_bucket_prefix}-${local.project_slug}-${local.env_slug}-${random_id.suffix.hex}"
  log_bucket_name  = "${var.log_bucket_prefix}-${local.project_slug}-${local.env_slug}-${random_id.suffix.hex}"

  main_storage_cost_usd = var.estimated_main_storage_gb * var.price_per_gb_standard
  log_storage_cost_usd  = var.estimated_log_storage_gb * var.price_per_gb_standard
  put_request_cost_usd  = (var.put_request_count / 1000) * var.price_per_1000_put
  get_request_cost_usd  = (var.get_request_count / 1000) * var.price_per_1000_get
  monthly_cost_usd      = local.main_storage_cost_usd + local.log_storage_cost_usd + local.put_request_cost_usd + local.get_request_cost_usd
}

resource "aws_s3_bucket" "s3_bucket_finops" {
  bucket = local.main_bucket_name

  tags = { Name = local.main_bucket_name }
}

resource "aws_s3_bucket" "log_bucket" {
  bucket = local.log_bucket_name

  tags = { Name = local.log_bucket_name }
}

resource "aws_s3_bucket_public_access_block" "main_bucket_public_access_block" {
  bucket = aws_s3_bucket.s3_bucket_finops.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_public_access_block" "log_bucket_public_access_block" {
  bucket = aws_s3_bucket.log_bucket.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_ownership_controls" "main_bucket_ownership" {
  bucket = aws_s3_bucket.s3_bucket_finops.id

  rule {
    object_ownership = "BucketOwnerEnforced"
  }
}

resource "aws_s3_bucket_ownership_controls" "log_bucket_ownership" {
  bucket = aws_s3_bucket.log_bucket.id

  rule {
    object_ownership = "BucketOwnerPreferred"
  }
}

resource "aws_s3_bucket_acl" "log_bucket_acl" {
  depends_on = [
    aws_s3_bucket_ownership_controls.log_bucket_ownership,
    aws_s3_bucket_public_access_block.log_bucket_public_access_block,
  ]

  bucket = aws_s3_bucket.log_bucket.id
  acl    = "log-delivery-write"
}

resource "aws_s3_bucket_server_side_encryption_configuration" "main_bucket_encryption" {
  bucket = aws_s3_bucket.s3_bucket_finops.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
    bucket_key_enabled = true
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "log_bucket_encryption" {
  bucket = aws_s3_bucket.log_bucket.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
    bucket_key_enabled = true
  }
}

resource "aws_s3_bucket_lifecycle_configuration" "main_bucket_lifecycle" {
  bucket = aws_s3_bucket.s3_bucket_finops.id

  rule {
    id     = "transition-to-ia"
    status = "Enabled"

    filter {
      prefix = ""
    }

    transition {
      days          = var.ia_transition_days
      storage_class = "STANDARD_IA"
    }
  }

  rule {
    id     = "abort-incomplete-multipart"
    status = "Enabled"

    filter {
      prefix = ""
    }

    abort_incomplete_multipart_upload {
      days_after_initiation = var.abort_multipart_days
    }
  }
}

resource "aws_s3_bucket_lifecycle_configuration" "log_bucket_lifecycle" {
  bucket = aws_s3_bucket.log_bucket.id

  rule {
    id     = "expire-access-logs"
    status = "Enabled"

    filter {
      prefix = "access-logs/"
    }

    expiration {
      days = var.log_retention_days
    }
  }

  rule {
    id     = "abort-incomplete-multipart"
    status = "Enabled"

    filter {
      prefix = ""
    }

    abort_incomplete_multipart_upload {
      days_after_initiation = var.abort_multipart_days
    }
  }
}

resource "aws_s3_bucket_logging" "main_bucket_logging" {
  bucket        = aws_s3_bucket.s3_bucket_finops.id
  target_bucket = aws_s3_bucket.log_bucket.id
  target_prefix = "access-logs/"
}
