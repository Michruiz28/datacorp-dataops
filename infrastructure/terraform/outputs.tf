output "staging_bucket_name" {
  description = "Nombre del bucket de staging"
  value       = aws_s3_bucket.staging_data.bucket
}

output "dev_instance_id" {
  description = "ID de la instancia EC2 de DEV"
  value       = aws_instance.dev.id
}

output "prod_db_endpoint" {
  description = "Endpoint de la base de datos de PROD"
  value       = aws_db_instance.prod.endpoint
}