# =============================================================================
# CONFIGURACIÓN PRINCIPAL DE TERRAFORM
# Plataforma VOD - Infraestructura como Código
# =============================================================================

terraform {
  required_version = ">= 1.0"
  
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
  
  backend "s3" {
    bucket = "vod-platform-terraform-state"
    key    = "prod/terraform.tfstate"
    region = "us-east-1"
  }
}

# Configuración del proveedor AWS
provider "aws" {
  region = var.aws_region
  
  default_tags {
    tags = {
      Project     = "VOD-Platform"
      Environment = var.environment
      ManagedBy   = "Terraform"
      Owner       = "DevOps Team"
    }
  }
}

# =============================================================================
# VARIABLES DE CONFIGURACIÓN
# =============================================================================

variable "aws_region" {
  description = "Región de AWS donde se desplegará la infraestructura"
  type        = string
  default     = "us-east-1"
}

variable "environment" {
  description = "Ambiente de despliegue (dev, staging, prod)"
  type        = string
  default     = "prod"
}

variable "vpc_cidr" {
  description = "CIDR block para la VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "availability_zones" {
  description = "Zonas de disponibilidad a utilizar"
  type        = list(string)
  default     = ["us-east-1a", "us-east-1b"]
}

# =============================================================================
# RECURSOS DE RED
# =============================================================================

# VPC Principal
resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true
  
  tags = {
    Name = "${var.environment}-vod-vpc"
  }
}

# Internet Gateway
resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id
  
  tags = {
    Name = "${var.environment}-vod-igw"
  }
}

# Subnets Públicas
resource "aws_subnet" "public" {
  count             = length(var.availability_zones)
  vpc_id            = aws_vpc.main.id
  cidr_block        = cidrsubnet(var.vpc_cidr, 8, count.index)
  availability_zone = var.availability_zones[count.index]
  
  map_public_ip_on_launch = true
  
  tags = {
    Name = "${var.environment}-public-subnet-${count.index + 1}"
    Tier = "Public"
  }
}

# Subnets Privadas para ECS
resource "aws_subnet" "private_ecs" {
  count             = length(var.availability_zones)
  vpc_id            = aws_vpc.main.id
  cidr_block        = cidrsubnet(var.vpc_cidr, 8, count.index + 2)
  availability_zone = var.availability_zones[count.index]
  
  tags = {
    Name = "${var.environment}-private-ecs-subnet-${count.index + 1}"
    Tier = "Private"
  }
}

# Subnets Privadas para Base de Datos
resource "aws_subnet" "private_db" {
  count             = length(var.availability_zones)
  vpc_id            = aws_vpc.main.id
  cidr_block        = cidrsubnet(var.vpc_cidr, 8, count.index + 4)
  availability_zone = var.availability_zones[count.index]
  
  tags = {
    Name = "${var.environment}-private-db-subnet-${count.index + 1}"
    Tier = "Private"
  }
}

# NAT Gateway para acceso a internet desde subnets privadas
resource "aws_eip" "nat" {
  domain = "vpc"
  
  tags = {
    Name = "${var.environment}-nat-eip"
  }
}

resource "aws_nat_gateway" "main" {
  allocation_id = aws_eip.nat.id
  subnet_id     = aws_subnet.public[0].id
  
  tags = {
    Name = "${var.environment}-vod-nat"
  }
  
  depends_on = [aws_internet_gateway.main]
}

# Tabla de rutas para subnets públicas
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id
  
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }
  
  tags = {
    Name = "${var.environment}-public-routes"
  }
}

# Tabla de rutas para subnets privadas
resource "aws_route_table" "private" {
  vpc_id = aws_vpc.main.id
  
  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.main.id
  }
  
  tags = {
    Name = "${var.environment}-private-routes"
  }
}

# Asociaciones de tablas de rutas
resource "aws_route_table_association" "public" {
  count          = length(var.availability_zones)
  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table_association" "private_ecs" {
  count          = length(var.availability_zones)
  subnet_id      = aws_subnet.private_ecs[count.index].id
  route_table_id = aws_route_table.private.id
}

resource "aws_route_table_association" "private_db" {
  count          = length(var.availability_zones)
  subnet_id      = aws_subnet.private_db[count.index].id
  route_table_id = aws_route_table.private.id
}

# =============================================================================
# GRUPOS DE SEGURIDAD
# =============================================================================

# Security Group para Application Load Balancer
resource "aws_security_group" "alb" {
  name        = "${var.environment}-alb-sg"
  description = "Security group para Application Load Balancer"
  vpc_id      = aws_vpc.main.id
  
  ingress {
    description = "HTTP desde Internet"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  
  ingress {
    description = "HTTPS desde Internet"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  
  tags = {
    Name = "${var.environment}-alb-sg"
  }
}

# Security Group para ECS Fargate
resource "aws_security_group" "ecs" {
  name        = "${var.environment}-ecs-sg"
  description = "Security group para ECS Fargate"
  vpc_id      = aws_vpc.main.id
  
  ingress {
    description     = "Trafico desde ALB"
    from_port       = 8080
    to_port         = 8080
    protocol        = "tcp"
    security_groups = [aws_security_group.alb.id]
  }
  
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  
  tags = {
    Name = "${var.environment}-ecs-sg"
  }
}

# Security Group para RDS
resource "aws_security_group" "rds" {
  name        = "${var.environment}-rds-sg"
  description = "Security group para RDS PostgreSQL"
  vpc_id      = aws_vpc.main.id
  
  ingress {
    description     = "PostgreSQL desde ECS"
    from_port       = 5432
    to_port         = 5432
    protocol        = "tcp"
    security_groups = [aws_security_group.ecs.id]
  }
  
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  
  tags = {
    Name = "${var.environment}-rds-sg"
  }
}

# Security Group para OpenSearch
resource "aws_security_group" "opensearch" {
  name        = "${var.environment}-opensearch-sg"
  description = "Security group para OpenSearch"
  vpc_id      = aws_vpc.main.id
  
  ingress {
    description     = "HTTPS desde ECS"
    from_port       = 443
    to_port         = 443
    protocol        = "tcp"
    security_groups = [aws_security_group.ecs.id]
  }
  
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  
  tags = {
    Name = "${var.environment}-opensearch-sg"
  }
}

# Security Group para ElastiCache
resource "aws_security_group" "cache" {
  name        = "${var.environment}-cache-sg"
  description = "Security group para ElastiCache Redis"
  vpc_id      = aws_vpc.main.id
  
  ingress {
    description     = "Redis desde ECS"
    from_port       = 6379
    to_port         = 6379
    protocol        = "tcp"
    security_groups = [aws_security_group.ecs.id]
  }
  
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  
  tags = {
    Name = "${var.environment}-cache-sg"
  }
}

# =============================================================================
# ALMACENAMIENTO S3
# =============================================================================

# Bucket S3 para ingesta de videos
resource "aws_s3_bucket" "vod_ingesta" {
  bucket = "${var.environment}-vod-ingesta-${random_string.bucket_suffix.result}"
  
  tags = {
    Name = "${var.environment}-vod-ingesta-bucket"
  }
}

# Bucket S3 para videos procesados
resource "aws_s3_bucket" "vod_videos" {
  bucket = "${var.environment}-vod-videos-${random_string.bucket_suffix.result}"
  
  tags = {
    Name = "${var.environment}-vod-videos-bucket"
  }
}

# Bucket S3 para logs
resource "aws_s3_bucket" "vod_logs" {
  bucket = "${var.environment}-vod-logs-${random_string.bucket_suffix.result}"
  
  tags = {
    Name = "${var.environment}-vod-logs-bucket"
  }
}

# String aleatorio para nombres únicos de buckets
resource "random_string" "bucket_suffix" {
  length  = 8
  special = false
  upper   = false
}

# Configuración de versionado para bucket de ingesta
resource "aws_s3_bucket_versioning" "vod_ingesta" {
  bucket = aws_s3_bucket.vod_ingesta.id
  
  versioning_configuration {
    status = "Enabled"
  }
}

# Configuración de lifecycle para bucket de ingesta (videos sin procesar)
resource "aws_s3_bucket_lifecycle_configuration" "vod_ingesta" {
  bucket = aws_s3_bucket.vod_ingesta.id
  
  rule {
    id     = "delete_after_processing"
    status = "Enabled"
    
    expiration {
      days = 7
    }
  }
}

# Configuración de versionado para bucket de videos
resource "aws_s3_bucket_versioning" "vod_videos" {
  bucket = aws_s3_bucket.vod_videos.id
  
  versioning_configuration {
    status = "Enabled"
  }
}

# Configuración de lifecycle para bucket de videos (videos procesados)
resource "aws_s3_bucket_lifecycle_configuration" "vod_videos" {
  bucket = aws_s3_bucket.vod_videos.id
  
  rule {
    id     = "transition_to_ia"
    status = "Enabled"
    
    transition {
      days          = 30
      storage_class = "STANDARD_IA"
    }
    
    transition {
      days          = 90
      storage_class = "GLACIER"
    }
    
    transition {
      days          = 365
      storage_class = "DEEP_ARCHIVE"
    }
  }
}

# =============================================================================
# BASE DE DATOS AURORA
# =============================================================================

# Subnet Group para Aurora
resource "aws_db_subnet_group" "main" {
  name       = "${var.environment}-vod-aurora-subnet-group"
  subnet_ids = aws_subnet.private_db[*].id
  
  tags = {
    Name = "${var.environment}-vod-aurora-subnet-group"
  }
}

# Cluster Aurora PostgreSQL
resource "aws_rds_cluster" "main" {
  cluster_identifier = "${var.environment}-vod-aurora-cluster"
  
  engine         = "aurora-postgresql"
  engine_version = "15.4"
  engine_mode    = "provisioned"
  
  database_name   = "vodplatform"
  master_username = "vodadmin"
  master_password = random_password.db_password.result
  
  vpc_security_group_ids = [aws_security_group.rds.id]
  db_subnet_group_name   = aws_db_subnet_group.main.name
  
  backup_retention_period = 7
  storage_encrypted = true
  deletion_protection = var.environment == "prod"
  
  tags = {
    Name = "${var.environment}-vod-aurora-cluster"
  }
}

# Instancia Aurora Writer
resource "aws_rds_cluster_instance" "writer" {
  identifier         = "${var.environment}-vod-aurora-writer"
  cluster_identifier = aws_rds_cluster.main.id
  
  instance_class = "db.t3.medium"
  engine         = aws_rds_cluster.main.engine
  
  publicly_accessible = false
  
  tags = {
    Name = "${var.environment}-vod-aurora-writer"
  }
}

# Instancia Aurora Reader
resource "aws_rds_cluster_instance" "reader" {
  identifier         = "${var.environment}-vod-aurora-reader"
  cluster_identifier = aws_rds_cluster.main.id
  
  instance_class = "db.t3.medium"
  engine         = aws_rds_cluster.main.engine
  
  publicly_accessible = false
  
  tags = {
    Name = "${var.environment}-vod-aurora-reader"
  }
}

# Contraseña aleatoria para RDS
resource "random_password" "db_password" {
  length  = 16
  special = true
}

# =============================================================================
# OPENSEARCH
# =============================================================================

# Dominio OpenSearch
resource "aws_elasticsearch_domain" "main" {
  domain_name           = "${var.environment}-vod-search"
  elasticsearch_version = "OpenSearch_2.5"
  
  cluster_config {
    instance_type            = "t3.small.search"
    instance_count          = 3
    zone_awareness_enabled  = true
    
    zone_awareness_config {
      availability_zone_count = 2
    }
  }
  
  ebs_options {
    ebs_enabled = true
    volume_size = 100
    volume_type = "gp3"
  }
  
  encrypt_at_rest {
    enabled = true
  }
  
  node_to_node_encryption {
    enabled = true
  }
  
  domain_endpoint_options {
    enforce_https       = true
    tls_security_policy = "Policy-Min-TLS-1-2-2019-07"
  }
  
  vpc_options {
    subnet_ids = [aws_subnet.private_db[0].id]
    security_group_ids = [aws_security_group.opensearch.id]
  }
  
  advanced_options = {
    "rest.action.multi.allow_explicit_index" = "true"
  }
  
  tags = {
    Name = "${var.environment}-vod-opensearch"
  }
}

# =============================================================================
# ELASTICACHE REDIS
# =============================================================================

# Subnet Group para ElastiCache
resource "aws_elasticache_subnet_group" "main" {
  name       = "${var.environment}-vod-cache-subnet-group"
  subnet_ids = aws_subnet.private_db[*].id
}

# Cluster de ElastiCache Redis
resource "aws_elasticache_cluster" "main" {
  cluster_id           = "${var.environment}-vod-redis"
  engine               = "redis"
  node_type            = "cache.t3.micro"
  num_cache_nodes      = 1
  parameter_group_name = "default.redis7"
  port                 = 6379
  
  subnet_group_name = aws_elasticache_subnet_group.main.name
  security_group_ids = [aws_security_group.cache.id]
  
  tags = {
    Name = "${var.environment}-vod-redis"
  }
}

# =============================================================================
# MEDIACONVERT
# =============================================================================

# Cola de MediaConvert
resource "aws_mediaconvert_queue" "main" {
  name = "${var.environment}-vod-mediaconvert-queue"
  
  description = "Cola de transcodificación para la plataforma VOD"
  
  pricing_plan = "ON_DEMAND"
  
  tags = {
    Name = "${var.environment}-vod-mediaconvert-queue"
  }
}

# =============================================================================
# SQS
# =============================================================================

# Cola SQS para procesamiento asíncrono
resource "aws_sqs_queue" "video_processing" {
  name = "${var.environment}-vod-video-processing"
  
  visibility_timeout_seconds = 300
  message_retention_seconds = 1209600
  delay_seconds             = 0
  
  tags = {
    Name = "${var.environment}-vod-video-processing"
  }
}

# Cola SQS para notificaciones
resource "aws_sqs_queue" "notifications" {
  name = "${var.environment}-vod-notifications"
  
  visibility_timeout_seconds = 60
  message_retention_seconds = 1209600
  delay_seconds             = 0
  
  tags = {
    Name = "${var.environment}-vod-notifications"
  }
}

# =============================================================================
# APPLICATION LOAD BALANCER
# =============================================================================

# Application Load Balancer
resource "aws_lb" "main" {
  name               = "${var.environment}-vod-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb.id]
  subnets            = aws_subnet.public[*].id
  
  enable_deletion_protection = var.environment == "prod"
  
  tags = {
    Name = "${var.environment}-vod-alb"
  }
}

# Target Group para ECS
resource "aws_lb_target_group" "ecs" {
  name        = "${var.environment}-vod-ecs-tg"
  port        = 8080
  protocol    = "HTTP"
  vpc_id      = aws_vpc.main.id
  target_type = "ip"
  
  health_check {
    enabled             = true
    healthy_threshold   = 2
    interval            = 30
    matcher             = "200"
    path                = "/health"
    port                = "traffic-port"
    protocol            = "HTTP"
    timeout             = 5
    unhealthy_threshold = 2
  }
  
  tags = {
    Name = "${var.environment}-vod-ecs-tg"
  }
}

# Listener HTTP (redirige a HTTPS)
resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.main.arn
  port              = "80"
  protocol          = "HTTP"
  
  default_action {
    type = "redirect"
    
    redirect {
      port        = "443"
      protocol    = "HTTPS"
      status_code = "HTTP_301"
    }
  }
}

# Listener HTTPS
resource "aws_lb_listener" "https" {
  load_balancer_arn = aws_lb.main.arn
  port              = "443"
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-TLS-1-2-2017-01"
  certificate_arn   = aws_acm_certificate.main.arn
  
  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.ecs.arn
  }
}

# =============================================================================
# CERTIFICADO SSL
# =============================================================================

# Certificado ACM para HTTPS
resource "aws_acm_certificate" "main" {
  domain_name       = "*.vodplatform.com"
  validation_method = "DNS"
  
  lifecycle {
    create_before_destroy = true
  }
  
  tags = {
    Name = "${var.environment}-vod-ssl-cert"
  }
}

# =============================================================================
# ECS CLUSTER Y SERVICIOS
# =============================================================================

# Cluster ECS
resource "aws_ecs_cluster" "main" {
  name = "${var.environment}-vod-cluster"
  
  setting {
    name  = "containerInsights"
    value = "enabled"
  }
  
  tags = {
    Name = "${var.environment}-vod-cluster"
  }
}

# Task Definition para el servicio principal
resource "aws_ecs_task_definition" "main" {
  family                   = "${var.environment}-vod-service"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = 512
  memory                   = 1024
  execution_role_arn       = aws_iam_role.ecs_execution_role.arn
  task_role_arn            = aws_iam_role.ecs_task_role.arn
  
  container_definitions = jsonencode([
    {
      name  = "vod-service"
      image = "${aws_ecr_repository.main.repository_url}:latest"
      
      portMappings = [
        {
          containerPort = 8080
          protocol      = "tcp"
        }
      ]
      
      environment = [
        {
          name  = "DB_HOST"
          value = aws_rds_cluster.main.endpoint
        },
        {
          name  = "DB_NAME"
          value = aws_rds_cluster.main.database_name
        },
        {
          name  = "REDIS_HOST"
          value = aws_elasticache_cluster.main.cache_nodes[0].address
        },
        {
          name  = "OPENSEARCH_ENDPOINT"
          value = aws_elasticsearch_domain.main.endpoint
        },
        {
          name  = "S3_INGESTA_BUCKET"
          value = aws_s3_bucket.vod_ingesta.bucket
        },
        {
          name  = "S3_VIDEOS_BUCKET"
          value = aws_s3_bucket.vod_videos.bucket
        },
        {
          name  = "MEDIACONVERT_QUEUE"
          value = aws_mediaconvert_queue.main.arn
        },
        {
          name  = "SQS_VIDEO_PROCESSING"
          value = aws_sqs_queue.video_processing.url
        }
      ]
      
      secrets = [
        {
          name      = "DB_PASSWORD"
          valueFrom = aws_ssm_parameter.db_password.arn
        }
      ]
      
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          awslogs-group         = aws_cloudwatch_log_group.ecs.name
          awslogs-region        = var.aws_region
          awslogs-stream-prefix = "ecs"
        }
      }
    }
  ])
  
  tags = {
    Name = "${var.environment}-vod-task-definition"
  }
}

# =============================================================================
# ECR REPOSITORY
# =============================================================================

# Repositorio ECR para imágenes Docker
resource "aws_ecr_repository" "main" {
  name                 = "${var.environment}-vod-service"
  image_tag_mutability = "MUTABLE"
  
  image_scanning_configuration {
    scan_on_push = true
  }
  
  tags = {
    Name = "${var.environment}-vod-ecr"
  }
}

# =============================================================================
# IAM ROLES
# =============================================================================

# Rol de ejecución para ECS
resource "aws_iam_role" "ecs_execution_role" {
  name = "${var.environment}-vod-ecs-execution-role"
  
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        }
      }
    ]
  })
}

# Política para el rol de ejecución
resource "aws_iam_role_policy_attachment" "ecs_execution_role_policy" {
  role       = aws_iam_role.ecs_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

# Rol de tarea para ECS
resource "aws_iam_role" "ecs_task_role" {
  name = "${var.environment}-vod-ecs-task-role"
  
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        }
      }
    ]
  })
}

# Política personalizada para el rol de tarea
resource "aws_iam_policy" "ecs_task_policy" {
  name        = "${var.environment}-vod-ecs-task-policy"
  description = "Política para servicios ECS de la plataforma VOD"
  
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:PutObject",
          "s3:DeleteObject",
          "s3:ListBucket"
        ]
        Resource = [
          aws_s3_bucket.vod_ingesta.arn,
          "${aws_s3_bucket.vod_ingesta.arn}/*",
          aws_s3_bucket.vod_videos.arn,
          "${aws_s3_bucket.vod_videos.arn}/*"
        ]
      },
      {
        Effect = "Allow"
        Action = [
          "secretsmanager:GetSecretValue",
          "ssm:GetParameter"
        ]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "mediaconvert:CreateJob",
          "mediaconvert:GetJob",
          "mediaconvert:ListJobs"
        ]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "sqs:SendMessage",
          "sqs:ReceiveMessage",
          "sqs:DeleteMessage"
        ]
        Resource = [
          aws_sqs_queue.video_processing.arn,
          aws_sqs_queue.notifications.arn
        ]
      },
      {
        Effect = "Allow"
        Action = [
          "es:ESHttp*"
        ]
        Resource = "${aws_elasticsearch_domain.main.arn}/*"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "ecs_task_role_policy" {
  role       = aws_iam_role.ecs_task_role.name
  policy_arn = aws_iam_policy.ecs_task_policy.arn
}

# =============================================================================
# PARÁMETROS SSM
# =============================================================================

# Parámetro SSM para la contraseña de la base de datos
resource "aws_ssm_parameter" "db_password" {
  name        = "/${var.environment}/vod/db/password"
  description = "Contraseña de la base de datos PostgreSQL"
  type        = "SecureString"
  value       = random_password.db_password.result
  
  tags = {
    Name = "${var.environment}-vod-db-password"
  }
}

# =============================================================================
# CLOUDWATCH LOGS
# =============================================================================

# Grupo de logs para ECS
resource "aws_cloudwatch_log_group" "ecs" {
  name              = "/ecs/${var.environment}-vod-service"
  retention_in_days = 30
  
  tags = {
    Name = "${var.environment}-vod-ecs-logs"
  }
}

# =============================================================================
# OUTPUTS
# =============================================================================

output "alb_dns_name" {
  description = "DNS name del Application Load Balancer"
  value       = aws_lb.main.dns_name
}

output "aurora_endpoint" {
  description = "Endpoint del cluster Aurora"
  value       = aws_rds_cluster.main.endpoint
}

output "opensearch_endpoint" {
  description = "Endpoint de OpenSearch"
  value       = aws_elasticsearch_domain.main.endpoint
}

output "s3_ingesta_bucket_name" {
  description = "Nombre del bucket S3 para ingesta"
  value       = aws_s3_bucket.vod_ingesta.bucket
}

output "s3_videos_bucket_name" {
  description = "Nombre del bucket S3 para videos"
  value       = aws_s3_bucket.vod_videos.bucket
}

output "mediaconvert_queue_arn" {
  description = "ARN de la cola de MediaConvert"
  value       = aws_mediaconvert_queue.main.arn
}

output "sqs_video_processing_url" {
  description = "URL de la cola SQS para procesamiento de video"
  value       = aws_sqs_queue.video_processing.url
}

output "ecr_repository_url" {
  description = "URL del repositorio ECR"
  value       = aws_ecr_repository.main.repository_url
}
