provider "aws" {
  region = "us-east-1"
}

resource "aws_s3_bucket" "bucket_seguro" {
  bucket = "mi-bucket-devsecops-demo-12345"
}

# CORRECCIÓN IaC: Bloqueo explícito de acceso público
resource "aws_s3_bucket_public_access_block" "publico" {
  bucket                  = aws_s3_bucket.bucket_seguro.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# CKV_AWS_21: Versionado habilitado
resource "aws_s3_bucket_versioning" "versionado" {
  bucket = aws_s3_bucket.bucket_seguro.id
  versioning_configuration {
    status = "Enabled"
  }
}

# CKV_AWS_145: Cifrado en reposo con KMS
resource "aws_s3_bucket_server_side_encryption_configuration" "cifrado" {
  bucket = aws_s3_bucket.bucket_seguro.id
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "aws:kms"
    }
  }
}

# CKV_AWS_18: Bucket destino para logs de acceso
resource "aws_s3_bucket" "bucket_logs" {
  bucket = "mi-bucket-devsecops-demo-12345-logs"
}

resource "aws_s3_bucket_logging" "logging" {
  bucket        = aws_s3_bucket.bucket_seguro.id
  target_bucket = aws_s3_bucket.bucket_logs.id
  target_prefix = "log/"
}

# CKV2_AWS_61: Configuración de ciclo de vida
resource "aws_s3_bucket_lifecycle_configuration" "ciclo_vida" {
  bucket = aws_s3_bucket.bucket_seguro.id
  rule {
    id     = "expiracion-objetos-antiguos"
    status = "Enabled"
    filter {}
    expiration {
      days = 365
    }
  }
}

# CKV2_AWS_62: Notificaciones de eventos
resource "aws_sns_topic" "notificaciones" {
  name = "notificaciones-bucket-devsecops"
}

resource "aws_s3_bucket_notification" "notificacion" {
  bucket = aws_s3_bucket.bucket_seguro.id
  topic {
    topic_arn = aws_sns_topic.notificaciones.arn
    events    = ["s3:ObjectCreated:*"]
  }
}

resource "aws_security_group" "sg_seguro" {
  name        = "sg_ssh_restringido"
  description = "Grupo de seguridad para acceso SSH restringido a red privada"
  ingress {
    description = "Acceso SSH unicamente desde la red privada interna"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    # CORRECCIÓN IaC: Acceso SSH restringido a red privada
    cidr_blocks = ["10.0.0.0/16"]
  }
}
