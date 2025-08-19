# =============================================================================
# ARCHIVO DE VARIABLES PARA TERRAFORM
# Plataforma VOD - Configuración de Variables
# =============================================================================

# Región de AWS donde se desplegará la infraestructura
variable "aws_region" {
  description = "AWS Region"
  type        = string
  default     = "us-east-1"
  
  validation {
    condition     = can(regex("^[a-z]{2}-[a-z]+-[1-9][0-9]*$", var.aws_region))
    error_message = "La región de AWS debe tener un formato válido (ej: us-east-1, eu-west-1)."
  }
}

# Ambiente de despliegue
variable "environment" {
  description = "Ambiente"
  type        = string
  default     = "prod"
  
  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "El ambiente debe ser uno de: dev, staging, prod."
  }
}

# CIDR block para la VPC
variable "vpc_cidr" {
  description = "CIDR block VPC"
  type        = string
  default     = "10.0.0.0/16"
  
  validation {
    condition     = can(cidrhost(var.vpc_cidr, 0))
    error_message = "El CIDR block de la VPC debe ser válido."
  }
}

# Zonas de disponibilidad a desplegar recursos
variable "availability_zones" {
  description = "Zonas de disponibilidad"
  type        = list(string)
  default     = ["us-east-1a", "us-east-1b"]
  
  validation {
    condition     = length(var.availability_zones) >= 2
    error_message = "Se deben especificar al menos 2 zonas de disponibilidad para alta disponibilidad."
  }
}

# Configuración de la base de datos
variable "db_instance_class" {
  description = "Tipo de instancia para RDS PostgreSQL"
  type        = string
  default     = "db.t3.medium"
  
  validation {
    condition     = can(regex("^db\\.[a-z0-9]+\\.[a-z0-9]+$", var.db_instance_class))
    error_message = "El tipo de instancia de RDS debe tener un formato válido."
  }
}

variable "db_allocated_storage" {
  description = "Almacenamiento inicial asignado para RDS (GB)"
  type        = number
  default     = 100
  
  validation {
    condition     = var.db_allocated_storage >= 20 && var.db_allocated_storage <= 65536
    error_message = "El almacenamiento de RDS debe estar entre 20 y 65536 GB."
  }
}

variable "db_max_allocated_storage" {
  description = "Almacenamiento máximo que puede alcanzar RDS (GB)"
  type        = number
  default     = 1000
  
  validation {
    condition     = var.db_max_allocated_storage >= var.db_allocated_storage
    error_message = "El almacenamiento máximo debe ser mayor o igual al almacenamiento inicial."
  }
}

# Configuración de ECS
variable "ecs_cpu" {
  description = "Unidades de CPU para las tareas de ECS (1024 = 1 vCPU)"
  type        = number
  default     = 512
  
  validation {
    condition     = contains([256, 512, 1024, 2048, 4096], var.ecs_cpu)
    error_message = "Las unidades de CPU deben ser una de: 256, 512, 1024, 2048, 4096."
  }
}

variable "ecs_memory" {
  description = "Memoria para las tareas de ECS (MB)"
  type        = number
  default     = 1024
  
  validation {
    condition     = var.ecs_memory >= 512 && var.ecs_memory <= 16384
    error_message = "La memoria debe estar entre 512 y 16384 MB."
  }
}

# Configuración de ElastiCache
variable "cache_node_type" {
  description = "Tipo de nodo para ElastiCache Redis"
  type        = string
  default     = "cache.t3.micro"
  
  validation {
    condition     = can(regex("^cache\\.[a-z0-9]+\\.[a-z0-9]+$", var.cache_node_type))
    error_message = "El tipo de nodo de ElastiCache debe tener un formato válido."
  }
}

variable "cache_num_nodes" {
  description = "Número de nodos en el cluster de ElastiCache"
  type        = number
  default     = 1
  
  validation {
    condition     = var.cache_num_nodes >= 1 && var.cache_num_nodes <= 20
    error_message = "El número de nodos debe estar entre 1 y 20."
  }
}

# Configuración de S3
variable "s3_versioning_enabled" {
  description = "Habilitar versionado en buckets S3"
  type        = bool
  default     = true
}

variable "s3_lifecycle_enabled" {
  description = "Habilitar políticas de lifecycle en buckets S3"
  type        = bool
  default     = true
}

# Configuración de logs
variable "cloudwatch_log_retention" {
  description = "Días de retención para logs de CloudWatch"
  type        = number
  default     = 30
  
  validation {
    condition     = contains([1, 3, 5, 7, 14, 30, 60, 90, 120, 150, 180, 365, 400, 545, 731, 1827, 3653], var.cloudwatch_log_retention)
    error_message = "La retención de logs debe ser uno de los valores permitidos por CloudWatch."
  }
}

# Configuración de seguridad
variable "enable_deletion_protection" {
  description = "Habilitar protección contra eliminación para recursos críticos"
  type        = bool
  default     = true
}

variable "enable_encryption" {
  description = "Habilitar encriptación para todos los recursos"
  type        = bool
  default     = true
}

# Configuración de monitoreo
variable "enable_container_insights" {
  description = "Habilitar Container Insights en el cluster ECS"
  type        = bool
  default     = true
}

variable "enable_xray_tracing" {
  description = "Habilitar X-Ray tracing para servicios"
  type        = bool
  default     = true
}

# Configuración de CI/CD
variable "github_repository" {
  description = "URL del repositorio de GitHub para CI/CD"
  type        = string
  default     = "https://github.com/username/vod-platform"
}

variable "docker_image_tag" {
  description = "Tag de la imagen Docker a desplegar"
  type        = string
  default     = "latest"
}

# Configuración de dominio
variable "domain_name" {
  description = "Nombre de dominio para la aplicación"
  type        = string
  default     = "vodplatform.com"
  
  validation {
    condition     = can(regex("^[a-zA-Z0-9][a-zA-Z0-9-]{1,61}[a-zA-Z0-9]\\.[a-zA-Z]{2,}$", var.domain_name))
    error_message = "El nombre de dominio debe tener un formato válido."
  }
}

# Configuración de tags
variable "common_tags" {
  description = "Tags comunes para todos los recursos"
  type        = map(string)
  default = {
    Project     = "VOD-Platform"
    ManagedBy   = "Terraform"
    Owner       = "DevOps Team"
    CostCenter  = "Engineering"
    Environment = "Production"
  }
}

# Configuración de backup
variable "backup_retention_period" {
  description = "Período de retención de backups de RDS (días)"
  type        = number
  default     = 7
  
  validation {
    condition     = var.backup_retention_period >= 0 && var.backup_retention_period <= 35
    error_message = "El período de retención de backups debe estar entre 0 y 35 días."
  }
}

variable "backup_window" {
  description = "Ventana de tiempo para backups de RDS (UTC)"
  type        = string
  default     = "03:00-04:00"
  
  validation {
    condition     = can(regex("^([01]?[0-9]|2[0-3]):[0-5][0-9]-([01]?[0-9]|2[0-3]):[0-5][0-9]$", var.backup_window))
    error_message = "La ventana de backup debe tener formato HH:MM-HH:MM en UTC."
  }
}

variable "maintenance_window" {
  description = "Ventana de tiempo para mantenimiento de RDS (UTC)"
  type        = string
  default     = "sun:04:00-sun:05:00"
  
  validation {
    condition     = can(regex("^(sun|mon|tue|wed|thu|fri|sat):([01]?[0-9]|2[0-3]):[0-5][0-9]-(sun|mon|tue|wed|thu|fri|sat):([01]?[0-9]|2[0-3]):[0-5][0-9]$", var.maintenance_window))
    error_message = "La ventana de mantenimiento debe tener formato DDD:HH:MM-DDD:HH:MM en UTC."
  }
}
