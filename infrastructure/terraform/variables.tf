variable "region" {
  description = "Región de AWS"
  type        = string
  default     = "us-east-1"
}

variable "project" {
  description = "Prefijo para nombrar los recursos"
  type        = string
  default     = "datacorp"
}

variable "ami_id" {
  description = "AMI de la instancia de DEV simulado"
  type        = string
  default     = "ami-0123456789abcdef0"
}

variable "dev_instance_type" {
  description = "Tamaño de la instancia de DEV"
  type        = string
  default     = "t3.small"
}

variable "prod_db_instance_class" {
  description = "Tamaño de la base de datos de PROD"
  type        = string
  default     = "db.t3.medium"
}

variable "db_username" {
  description = "Usuario administrador de la base de datos"
  type        = string
  default     = "datacorp_admin"
}