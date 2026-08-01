provider "aws" {
  region = "us-east-1"
}

# ---------- Clave KMS compartida ----------
resource "aws_kms_key" "clave" {
  description         = "Clave KMS para cifrado de buckets y SNS"
  enable_key_rotation = true
  policy              = data.aws_iam_policy_document.kms_politica.json
}

# ---------- Bucket principal ----------
resource "aws_s3_bucket" "bucket_seguro" {
  bucket = "mi-bucket-devsecops-demo-12345"
}

resource "aws_s3_bucket_public_access_block" "publico" {
  bucket                  = aws_s3_bucket.bucket_seguro.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_versioning" "versionado" {
  bucket = aws_s3_bucket.bucket_seguro.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "cifrado" {
  bucket = aws_s3_bucket.bucket_seguro.id
  rule {
    apply_server_side_encryption_by_default {
      kms_master_key_id = aws_kms_key.clave.arn
      sse_algorithm     = "aws:kms"
    }
  }
}

resource "aws_s3_bucket_lifecycle_configuration" "ciclo_vida" {
  bucket = aws_s3_bucket.bucket_seguro.id
  rule {
    id     = "expiracion-objetos-antiguos"
    status = "Enabled"
    filter {}
    expiration {
      days = 365
    }
    abort_incomplete_multipart_upload {
      days_after_initiation = 7
    }
  }
}

resource "aws_s3_bucket_notification" "notificacion" {
  bucket = aws_s3_bucket.bucket_seguro.id
  topic {
    topic_arn = aws_sns_topic.notificaciones.arn
    events    = ["s3:ObjectCreated:*"]
  }
}

resource "aws_s3_bucket_logging" "logging" {
  bucket        = aws_s3_bucket.bucket_seguro.id
  target_bucket = aws_s3_bucket.bucket_logs.id
  target_prefix = "log/"
}

# ---------- Bucket de logs ----------
resource "aws_s3_bucket" "bucket_logs" {
  bucket = "mi-bucket-devsecops-demo-12345-logs"
}

resource "aws_s3_bucket_public_access_block" "publico_logs" {
  bucket                  = aws_s3_bucket.bucket_logs.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_versioning" "versionado_logs" {
  bucket = aws_s3_bucket.bucket_logs.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "cifrado_logs" {
  bucket = aws_s3_bucket.bucket_logs.id
  rule {
    apply_server_side_encryption_by_default {
      kms_master_key_id = aws_kms_key.clave.arn
      sse_algorithm     = "aws:kms"
    }
  }
}

resource "aws_s3_bucket_lifecycle_configuration" "ciclo_vida_logs" {
  bucket = aws_s3_bucket.bucket_logs.id
  rule {
    id     = "expiracion-logs"
    status = "Enabled"
    filter {}
    expiration {
      days = 90
    }
    abort_incomplete_multipart_upload {
      days_after_initiation = 7
    }
  }
}

resource "aws_s3_bucket_notification" "notificacion_logs" {
  bucket = aws_s3_bucket.bucket_logs.id
  topic {
    topic_arn = aws_sns_topic.notificaciones.arn
    events    = ["s3:ObjectCreated:*"]
  }
}

# ---------- SNS ----------
resource "aws_sns_topic" "notificaciones" {
  name              = "notificaciones-bucket-devsecops"
  kms_master_key_id = aws_kms_key.clave.arn
}

# ---------- Security Group ----------
resource "aws_security_group" "sg_seguro" {
  name        = "sg_ssh_restringido"
  description = "Grupo de seguridad para acceso SSH restringido a red privada"
  ingress {
    description = "Acceso SSH unicamente desde la red privada interna"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["10.0.0.0/16"]
  }
}

data "aws_caller_identity" "actual" {}

data "aws_iam_policy_document" "kms_politica" {
  statement {
    sid       = "PermitirAdministracionPorCuentaRaiz"
    effect    = "Allow"
    actions   = ["kms:*"]
    resources = ["*"]
    principals {
      type        = "AWS"
      identifiers = ["arn:aws:iam::${data.aws_caller_identity.actual.account_id}:root"]
    }
  }
}
