terraform {
  required_version = ">= 1.5"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  # Estado remoto simulado. En un entorno real se activaría para que el
  # estado quede cifrado y bloqueado, fuera de Git:
  # backend "s3" {
  #   bucket         = "datacorp-tfstate"
  #   key            = "dataops/terraform.tfstate"
  #   region         = "us-east-1"
  #   dynamodb_table = "datacorp-tf-locks"
  #   encrypt        = true
  # }
}

provider "aws" {
  region = var.region

  default_tags {
    tags = {
      Project   = var.project
      ManagedBy = "terraform"
    }
  }
}


# 1. Bucket S3 para datos de staging (QA)

resource "aws_s3_bucket" "staging_data" {
  bucket = "${var.project}-staging-data"

  tags = {
    Environment = "qa"
  }
}

resource "aws_s3_bucket_versioning" "staging_data" {
  bucket = aws_s3_bucket.staging_data.id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "staging_data" {
  bucket = aws_s3_bucket.staging_data.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_public_access_block" "staging_data" {
  bucket                  = aws_s3_bucket.staging_data.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# 4. Rol IAM con permisos restringidos
#    Solo puede leer y escribir en el bucket de staging.

resource "aws_iam_role" "dev_ec2_role" {
  name = "${var.project}-dev-ec2-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Action    = "sts:AssumeRole"
      Principal = { Service = "ec2.amazonaws.com" }
    }]
  })
}

resource "aws_iam_role_policy" "dev_s3_limited" {
  name = "${var.project}-dev-s3-limited"
  role = aws_iam_role.dev_ec2_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = ["s3:ListBucket"]
        Resource = aws_s3_bucket.staging_data.arn
      },
      {
        Effect   = "Allow"
        Action   = ["s3:GetObject", "s3:PutObject"]
        Resource = "${aws_s3_bucket.staging_data.arn}/*"
      }
    ]
  })
}

resource "aws_iam_instance_profile" "dev_profile" {
  name = "${var.project}-dev-profile"
  role = aws_iam_role.dev_ec2_role.name
}

# 2. Instancia EC2 para DEV

resource "aws_instance" "dev" {
  ami                  = var.ami_id
  instance_type        = var.dev_instance_type
  iam_instance_profile = aws_iam_instance_profile.dev_profile.name

  metadata_options {
    http_tokens = "required" # IMDSv2
  }

  tags = {
    Name        = "${var.project}-dev"
    Environment = "dev"
  }
}

# 3. Base de datos RDS para PROD

resource "aws_db_instance" "prod" {
  identifier        = "${var.project}-prod-db"
  engine            = "postgres"
  engine_version    = "15"
  instance_class    = var.prod_db_instance_class
  allocated_storage = 50
  db_name           = "datacorp"
  username          = var.db_username

  # La contraseña la genera y guarda AWS Secrets Manager: nunca va en Git
  manage_master_user_password = true

  multi_az                = true
  storage_encrypted       = true
  publicly_accessible     = false
  backup_retention_period = 7
  deletion_protection     = true

  skip_final_snapshot       = false
  final_snapshot_identifier = "${var.project}-prod-final"

  tags = {
    Environment = "prod"
  }
}