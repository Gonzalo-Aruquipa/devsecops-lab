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

resource "aws_security_group" "sg_seguro" {
  name = "sg_ssh_restringido"
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    # CORRECCIÓN IaC: Acceso SSH restringido a red privada
    cidr_blocks = ["10.0.0.0/16"]
  }
}
