# Arquitectura Cloud para Plataforma VOD - Módulo 6 DevOps

## Descripción del Proyecto
Diseño de infraestructura cloud escalable y segura para una plataforma de Video On Demand (VOD) similar a Netflix, capaz de soportar miles de usuarios simultáneos con disponibilidad global.

## Entregables
- [x] Reporte técnico en PDF con justificaciones
- [x] Diagrama de arquitectura (Mermaid)
- [x] Código de ejemplo con Terraform
- [x] Configuración CI/CD con GitHub Actions

## Estructura del Proyecto
```
modulo6/
├── docs/                    # Documentación y reportes
├── infrastructure/          # Código de infraestructura
├── diagrams/               # Diagramas de arquitectura
└── ci-cd/                  # Configuraciones de CI/CD
```

## Tecnologías Utilizadas
- **Cloud Provider**: AWS (Amazon Web Services)
- **Infrastructure as Code**: Terraform
- **CI/CD**: GitHub Actions
- **Containerización**: Docker + ECS
- **Base de Datos**: Aurora PostgreSQL + OpenSearch + ElastiCache Redis
- **Almacenamiento**: Amazon S3 (Ingesta + Videos) + CloudFront
- **Procesamiento**: AWS MediaConvert + SQS
- **Monitoreo**: CloudWatch + X-Ray
- **Seguridad**: KMS + WAF + IAM
