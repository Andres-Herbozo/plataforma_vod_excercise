# Arquitectura Cloud para Plataforma VOD
## Módulo 6 - DevOps

**Estudiante:** [Andrés Herbozo]  
**Fecha:** [13-08-2025]  
---

## 1. DISEÑO DE INFRAESTRUCTURA EN LA NUBE (1.5 puntos)

### 1.1 Justificación del Modelo de Implementación Cloud

**Modelo Seleccionado: Cloud Público (AWS)**

La elección del modelo de nube pública se fundamenta en los siguientes criterios técnicos y de negocio:

**Ventajas Técnicas:**
- **Escalabilidad Automática**: AWS proporciona capacidades de auto-scaling que permiten manejar picos de tráfico de miles de usuarios simultáneos sin intervención manual.
- **Alta Disponibilidad**: Infraestructura distribuida globalmente con múltiples zonas de disponibilidad, garantizando 99.99% de uptime.
- **Seguridad Avanzada**: Cumplimiento con estándares internacionales (SOC 2, ISO 27001, PCI DSS) y herramientas de seguridad nativas.
- **Costos Optimizados**: Modelo de pago por uso que elimina inversiones en infraestructura física y permite optimización continua.

**Justificación para VOD:**
- **Distribución Global**: CloudFront CDN permite entregar contenido multimedia a usuarios en cualquier parte del mundo con latencia mínima.
- **Procesamiento de Video**: AWS MediaConvert proporciona transcodificación profesional de videos a formatos HLS/DASH para streaming adaptativo.
- **Almacenamiento Escalable**: S3 proporciona almacenamiento ilimitado para contenido multimedia con políticas de lifecycle automáticas.
- **Búsqueda Avanzada**: Amazon OpenSearch permite indexación y búsqueda eficiente en catálogos de videos masivos.

### 1.2 Definición del Modelo de Servicio

**Modelo Seleccionado: PaaS (Platform as a Service) con elementos de FaaS**

**Justificación Técnica:**

**PaaS como Base Principal:**
- **ECS Fargate**: Proporciona una plataforma completamente gestionada para ejecutar contenedores sin necesidad de gestionar servidores.
- **RDS PostgreSQL**: Base de datos gestionada con backups automáticos, parches de seguridad y escalado automático.
- **ElastiCache Redis**: Cache distribuido gestionado con alta disponibilidad y replicación automática.

**FaaS para Funciones Específicas:**
- **Lambda Functions**: Para tareas de procesamiento de video, generación de thumbnails y notificaciones push.
- **AWS MediaConvert**: Para transcodificación profesional de videos a formatos HLS/DASH.
- **Ventajas**: Escalado automático a cero, pago solo por ejecución, y gestión automática de recursos.

**IaaS para Control Granular:**
- **VPC Personalizada**: Control completo sobre la red, subnets y security groups.
- **EC2 (opcional)**: Para cargas de trabajo que requieren control total sobre el sistema operativo.

### 1.3 Uso de Almacenamiento Cloud

**Estrategia de Almacenamiento Multi-Tier:**

**S3 Standard (Acceso Frecuente):**
- **Contenido Activo**: Videos recientes y populares con acceso frecuente.
- **Durabilidad**: 99.999999999%.
- **Disponibilidad**: 99.99%.

**S3 Intelligent Tiering:**
- **Optimización Automática**: AWS mueve automáticamente objetos entre tiers basándose en patrones de acceso.
- **Ahorro de Costos**: Hasta 40% de reducción en costos de almacenamiento.

**S3 Standard-IA (Acceso Infrecuente):**
- **Contenido Menos Popular**: Videos con acceso ocasional (30-90 días).
- **Costo**: 40% menos que S3 Standard.

**S3 Glacier:**
- **Archivo a Largo Plazo**: Contenido antiguo (>90 días) con acceso muy ocasional.
- **Costo**: Hasta 90% menos que S3 Standard.

**S3 Deep Archive:**
- **Archivo Permanente**: Contenido histórico (>365 días) con acceso mínimo.
- **Costo**: Hasta 95% menos que S3 Standard.

**Estrategia de Almacenamiento Dual para VOD:**
- **S3 - Ingesta**: Almacenamiento intermedio para videos sin procesar, optimizado para escritura frecuente.
- **S3 - Videos**: Almacenamiento final para videos procesados en formatos HLS/DASH, optimizado para lectura y distribución.

**Justificación Técnica:**
- **Escalabilidad**: Capacidad ilimitada sin límites de archivos o directorios.
- **Durabilidad**: Replicación automática en múltiples AZs.
- **Seguridad**: Encriptación en reposo y en tránsito por defecto.
- **Compliance**: Cumplimiento con regulaciones de retención de datos.

---

## 2. SERVICIOS CLOUD Y ALMACENAMIENTO (1.5 puntos)

### 2.1 Servicios de Computación

**ECS Fargate (Elastic Container Service):**

**Características Técnicas:**
- **Serverless**: No requiere gestión de servidores EC2.
- **Escalado Automático**: Basado en métricas de CPU, memoria y número de requests.
- **Integración Nativa**: Con Load Balancer, CloudWatch y ECR.

**Configuración para VOD:**
- **CPU**: 512 unidades (0.5 vCPU) para servicios básicos, 1024 (1 vCPU) para procesamiento de video.
- **Memoria**: 1024 MB para servicios básicos, 2048 MB para procesamiento intensivo.
- **Auto-scaling**: Mínimo 2 tareas, máximo 10 tareas por servicio.

**Lambda Functions:**

**Casos de Uso:**
- **Procesamiento de Video**: Transcodificación de formatos, generación de thumbnails.
- **Notificaciones**: Envío de emails y push notifications.
- **Análisis**: Procesamiento de logs y métricas en tiempo real.

**AWS MediaConvert:**

**Casos de Uso:**
- **Transcodificación Profesional**: Conversión de videos a formatos HLS/DASH para streaming adaptativo.
- **Optimización de Calidad**: Generación de múltiples resoluciones (1080p, 720p, 480p, 360p).
- **Procesamiento Asíncrono**: Manejo de colas de transcodificación para videos de larga duración.
- **Formato de Salida**: HLS (HTTP Live Streaming) y DASH (Dynamic Adaptive Streaming over HTTP).

**Configuración:**
- **Memoria**: 1024 MB para procesamiento de video, 512 MB para funciones simples.
- **Timeout**: 15 minutos para procesamiento de video, 3 minutos para funciones simples.

### 2.2 Servicios de Base de Datos

**Aurora PostgreSQL:**

**Configuración Técnica:**
- **Instancia**: db.t3.medium (2 vCPU, 4 GB RAM).
- **Almacenamiento**: 100 GB inicial, auto-scaling hasta 1000 GB.
- **Multi-AZ**: Replicación automática en múltiples zonas de disponibilidad.
- **Backups**: Retención de 7 días con ventana de backup 03:00-04:00 UTC.
- **Ventajas sobre RDS**: Mejor rendimiento, escalabilidad automática y menor latencia.

**Amazon OpenSearch:**

**Configuración Técnica:**
- **Tipo**: t3.small.search (2 vCPU, 4 GB RAM).
- **Almacenamiento**: 100 GB inicial, auto-scaling hasta 1000 GB.
- **Nodos**: 3 nodos para alta disponibilidad y distribución de carga.
- **Índices**: Optimizados para búsqueda de videos, metadatos y contenido.

**Optimizaciones para VOD:**
- **Connection Pooling**: PgBouncer para manejar conexiones concurrentes.
- **Read Replicas**: Para operaciones de lectura intensiva (catálogo, búsquedas).
- **Partitioning**: Tablas de logs y métricas por fecha para mejor rendimiento.
- **Búsqueda Avanzada**: OpenSearch para indexación y búsqueda semántica en catálogos de videos.
- **Cache Inteligente**: Redis para metadatos de videos y listas de reproducción frecuentemente accedidas.

**ElastiCache Redis:**

**Configuración:**
- **Tipo**: cache.t3.micro para desarrollo, cache.r5.large para producción.
- **Cluster Mode**: Habilitado para escalabilidad horizontal.
- **Persistencia**: RDB snapshots cada 15 minutos.

**Casos de Uso:**
- **Session Storage**: Almacenamiento de sesiones de usuario.
- **Cache de Contenido**: Metadatos de videos, listas de reproducción.
- **Rate Limiting**: Control de acceso y limitación de requests.
- **Cola de Procesamiento**: Integración con SQS para desacoplar procesos de ingesta y transcodificación.

### 2.3 Servicios de Red y Distribución

**Application Load Balancer (ALB):**

**Configuración:**
- **Tipo**: Application Load Balancer con SSL termination.
- **Health Checks**: Endpoint `/health` cada 30 segundos.
- **Sticky Sessions**: Para mantener estado de usuario.
- **WAF Integration**: Protección contra ataques DDoS y OWASP Top 10.
- **Protección Avanzada**: Reglas personalizadas para ataques específicos de plataformas VOD.

**CloudFront CDN:**

**Configuración Técnica:**
- **Edge Locations**: 400+ ubicaciones globales.
- **Compresión**: Gzip y Brotli para archivos estáticos.
- **Cache Policies**: TTL personalizado por tipo de contenido.
- **Origin Failover**: Múltiples orígenes para alta disponibilidad.

**VPC y Networking:**

**Arquitectura de Red:**
- **VPC**: 10.0.0.0/16 con subnets en múltiples AZs.
- **Subnets Públicas**: Para ALB y NAT Gateway.
- **Subnets Privadas App**: Para ECS Fargate Services y Backoffice API.
- **Subnets Privadas Datos**: Para Aurora PostgreSQL, OpenSearch y ElastiCache.
- **Security Groups**: Reglas granulares por servicio con aislamiento por capas.

---

## 3. COMPUTACIÓN Y NETWORKING (1.5 puntos)

### 3.1 Estrategia de Escalabilidad

**Auto-scaling Horizontal:**

**ECS Service Auto-scaling:**
- **Target Tracking**: Basado en métricas de CPU (70%) y memoria (80%).
- **Step Scaling**: Ajustes graduales basados en umbrales predefinidos.
- **Scheduled Scaling**: Anticipación de picos de tráfico (horarios de mayor uso).

**Load Balancing:**

**Application Load Balancer:**
- **Health Checks**: Verificación de endpoints críticos.
- **Sticky Sessions**: Para aplicaciones que requieren estado.
- **SSL Offloading**: Terminación SSL en el ALB para mejor rendimiento.

**Database Scaling:**

**Aurora Read Replicas:**
- **Configuración**: 2-3 réplicas para operaciones de lectura.
- **Auto-scaling**: Creación automática de réplicas basada en métricas.
- **Connection Distribution**: Routing inteligente de queries de lectura.

**OpenSearch Scaling:**
- **Nodos de Datos**: Escalado horizontal automático basado en carga.
- **Índices Distribuidos**: Sharding automático para mejor rendimiento.
- **Replicación**: Múltiples copias de índices para alta disponibilidad.

### 3.2 Alta Disponibilidad

**Multi-AZ Deployment:**

**Estrategia:**
- **ECS**: Tareas distribuidas en múltiples AZs.
- **RDS**: Instancia primaria y standby en AZs separadas.
- **ElastiCache**: Cluster distribuido con replicación automática.

**Disaster Recovery:**

**Backup Strategy:**
- **Aurora**: Backups automáticos diarios con retención de 7 días.
- **OpenSearch**: Snapshots automáticos con retención configurable.
- **S3**: Versioning habilitado para recuperación de archivos.
- **Cross-Region Replication**: Replicación de datos críticos a región secundaria.
- **MediaConvert**: Preservación de jobs de transcodificación para recuperación.

**Monitoring y Alerting:**

**CloudWatch:**
- **Métricas Personalizadas**: Latencia, throughput, errores.
- **Logs Centralizados**: Agregación de logs de todos los servicios.
- **Alarmas**: Notificaciones automáticas para métricas críticas.

### 3.3 Seguridad de Red

**Security Groups:**

**Configuración Granular:**
- **ALB**: Solo puertos 80 y 443 desde internet.
- **ECS**: Solo puerto 8080 desde ALB.
- **Aurora**: Solo puerto 5432 desde ECS.
- **OpenSearch**: Solo puerto 443 desde ECS con TLS obligatorio.
- **ElastiCache**: Solo puerto 6379 desde ECS.
- **MediaConvert**: Acceso solo desde VPC a través de endpoints privados.

**Network ACLs:**

**Reglas de Control:**
- **Nivel 1**: Control de tráfico entre subnets.
- **Nivel 2**: Control de tráfico entre VPCs.
- **Logging**: Registro de todo el tráfico para auditoría.

**WAF (Web Application Firewall):**

**Protecciones:**
- **OWASP Top 10**: Prevención de ataques comunes.
- **Rate Limiting**: Control de requests por IP.
- **Geo-blocking**: Restricción de acceso por ubicación geográfica.
- **Protección VOD**: Reglas específicas para ataques de streaming y descarga de contenido.
- **Bot Protection**: Detección y bloqueo de bots maliciosos.

---

## 4. SEGURIDAD Y MONITOREO (1.0 puntos)

### 4.1 Estrategia de Seguridad

**Identity and Access Management (IAM):**

**Principio de Mínimo Privilegio:**
- **ECS Execution Role**: Solo permisos necesarios para ejecutar contenedores.
- **ECS Task Role**: Permisos específicos para acceder a S3, RDS y ElastiCache.
- **Cross-Account Access**: Roles temporales para acceso entre cuentas.

**Encriptación:**

**En Reposo:**
- **S3**: Encriptación AES-256 por defecto.
- **Aurora**: Encriptación AES-256 con KMS.
- **OpenSearch**: Encriptación AES-256 con KMS.
- **ElastiCache**: Encriptación en tránsito con TLS 1.2+.
- **MediaConvert**: Encriptación de archivos de entrada y salida con KMS.

**En Tránsito:**
- **HTTPS**: TLS 1.2+ para toda la comunicación web.
- **Database**: Conexiones SSL/TLS obligatorias.
- **API**: Autenticación JWT con tokens de corta duración.

**Secrets Management:**

**AWS Secrets Manager:**
- **Database Credentials**: Rotación automática de contraseñas.
- **API Keys**: Almacenamiento seguro de claves externas.
- **MediaConvert Credentials**: Accesos a servicios de transcodificación.
- **Integration**: Con ECS para inyección automática de secrets.

**KMS (Key Management Service):**
- **Encriptación de Videos**: Claves para proteger contenido multimedia.
- **Encriptación de Base de Datos**: Claves para Aurora y OpenSearch.
- **Rotación Automática**: Gestión automática de claves de encriptación.

### 4.2 Monitoreo y Observabilidad

**CloudWatch Monitoring:**

**Métricas de Infraestructura:**
- **ECS**: CPU, memoria, número de tareas.
- **Aurora**: CPU, memoria, conexiones, I/O.
- **OpenSearch**: CPU, memoria, índices, búsquedas por segundo.
- **MediaConvert**: Jobs completados, tiempo de procesamiento, errores.
- **ALB**: Latencia, requests por segundo, códigos de error.

**Logs Centralizados:**

**Estructura de Logs:**
- **Application Logs**: Logs de la aplicación en formato JSON estructurado.
- **Access Logs**: Logs de acceso con información de usuario y IP.
- **Error Logs**: Logs de errores con stack traces y contexto.

**X-Ray Tracing:**

**Distributed Tracing:**
- **Request Flow**: Seguimiento de requests a través de microservicios.
- **Performance Analysis**: Identificación de cuellos de botella.
- **Error Correlation**: Correlación de errores entre servicios.
- **MediaConvert Tracking**: Seguimiento de jobs de transcodificación.
- **OpenSearch Performance**: Análisis de latencia de búsquedas.

**Alerting y Notificaciones:**

**SNS Topics:**
- **Critical Alerts**: Notificaciones inmediatas para problemas críticos.
- **Warning Alerts**: Notificaciones para problemas que requieren atención.
- **Escalation**: Escalamiento automático de alertas no resueltas.

---

## 5. CI/CD E INFRAESTRUCTURA COMO CÓDIGO (0.5 puntos)

### 5.1 Pipeline de CI/CD

**GitHub Actions Workflow:**

**Fases del Pipeline:**
1. **Code Quality**: Linting, formateo y análisis estático.
2. **Testing**: Tests unitarios, de integración y de rendimiento.
3. **Security Scanning**: Análisis de vulnerabilidades con Trivy.
4. **Build**: Construcción de imagen Docker y push a ECR.
5. **Deploy**: Despliegue automático a staging y producción.

**Estrategias de Despliegue:**

**Blue-Green Deployment:**
- **Staging Environment**: Validación completa antes de producción.
- **Production Rollout**: Despliegue gradual con health checks.
- **Rollback**: Reversión automática en caso de fallos.

**Canary Deployment:**
- **Traffic Splitting**: Distribución gradual del tráfico.
- **Metrics Monitoring**: Monitoreo en tiempo real de métricas críticas.
- **Automatic Rollback**: Rollback automático si se detectan problemas.

### 5.2 Infrastructure as Code

**Terraform Configuration:**

**Modularización:**
- **Network Module**: VPC, subnets, route tables.
- **Compute Module**: ECS cluster, services, task definitions.
- **Database Module**: RDS, ElastiCache, parameter groups.
- **Security Module**: Security groups, IAM roles, WAF rules.

**State Management:**

**Remote State:**
- **S3 Backend**: Almacenamiento centralizado del estado de Terraform.
- **DynamoDB Locking**: Bloqueo de estado para operaciones concurrentes.
- **State Encryption**: Encriptación del estado con KMS.

**Version Control:**

**Git Workflow:**
- **Feature Branches**: Desarrollo de nuevas funcionalidades.
- **Pull Requests**: Revisión de código obligatoria.
- **Automated Testing**: Validación automática de cambios de infraestructura.

---

## 6. CONCLUSIONES Y RECOMENDACIONES

### 6.1 Resumen de la Arquitectura

La arquitectura propuesta para la plataforma VOD proporciona una base sólida y escalable que cumple con todos los requisitos del proyecto:

**Fortalezas Técnicas:**
- **Escalabilidad**: Capacidad de manejar miles de usuarios simultáneos.
- **Alta Disponibilidad**: 99.99% de uptime con múltiples zonas de disponibilidad.
- **Seguridad**: Implementación de mejores prácticas de seguridad y compliance.
- **Costos Optimizados**: Modelo de pago por uso con optimización automática.

**Tecnologías Seleccionadas:**
- **AWS como Cloud Provider**: Liderazgo en el mercado y servicios maduros.
- **ECS Fargate**: Plataforma serverless para contenedores.
- **Aurora PostgreSQL + OpenSearch + Redis**: Stack de base de datos robusto y escalable.
- **AWS MediaConvert**: Procesamiento profesional de videos para streaming.
- **Terraform**: Infraestructura como código con versionado y colaboración.

### 6.2 Recomendaciones de Implementación

**Fase 1: Infraestructura Base (2-3 semanas)**
- Despliegue de VPC y componentes de red.
- Configuración de ECS cluster y servicios básicos.
- Implementación de Aurora PostgreSQL, OpenSearch y ElastiCache.
- Configuración de S3 buckets para ingesta y videos.

**Fase 2: CI/CD y Automatización (1-2 semanas)**
- Configuración de GitHub Actions.
- Implementación de testing automatizado.
- Despliegue de monitoreo y alerting.

**Fase 3: Optimización y Escalabilidad (2-3 semanas)**
- Implementación de auto-scaling.
- Configuración de AWS MediaConvert para transcodificación.
- Implementación de SQS para procesamiento asíncrono.
- Optimización de performance y configuración de backup y disaster recovery.

### 6.3 Consideraciones de Costos

**Estimación Mensual (10,000 usuarios):**
- **Compute (ECS + Lambda)**: $200-400
- **Storage (S3 + Aurora + OpenSearch)**: $200-400
- **MediaConvert (Transcodificación)**: $100-300
- **Network (ALB + CloudFront)**: $100-200
- **Monitoring y Logs**: $50-100
- **Total Estimado**: $650-1,400/mes

**Optimizaciones de Costo:**
- **Reserved Instances**: Para cargas de trabajo predecibles.
- **Spot Instances**: Para tareas de procesamiento no críticas.
- **S3 Lifecycle Policies**: Movimiento automático a tiers más económicos.
- **MediaConvert Optimization**: Uso de presets optimizados para reducir costos de transcodificación.
- **OpenSearch Reserved Instances**: Para índices de búsqueda con uso constante.


## 7. REFERENCIAS TÉCNICAS

### 7.1 Documentación AWS
- [AWS Well-Architected Framework](https://aws.amazon.com/architecture/well-architected/)
- [ECS Best Practices](https://docs.aws.amazon.com/ecs/latest/bestpracticesguide/)
- [RDS Performance Insights](https://docs.aws.amazon.com/AmazonRDS/latest/UserGuide/USER_PerfInsights.html)

### 7.2 Herramientas y Frameworks
- [Terraform Documentation](https://www.terraform.io/docs)
- [GitHub Actions](https://docs.github.com/en/actions)
- [Docker Best Practices](https://docs.docker.com/develop/dev-best-practices/)

### 7.3 Estándares y Compliance
- [OWASP Top 10](https://owasp.org/www-project-top-ten/)
- [SOC 2 Compliance](https://aws.amazon.com/compliance/soc-faqs/)
- [GDPR Compliance](https://aws.amazon.com/compliance/gdpr-center/)
