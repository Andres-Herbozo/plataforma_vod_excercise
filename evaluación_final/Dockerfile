# =============================================================================
# DOCKERFILE PARA PLATAFORMA VOD
# Multi-stage build optimizado para producción
# =============================================================================

# =============================================================================
# ETAPA 1: BUILD DE LA APLICACIÓN
# =============================================================================
FROM python:3.11-slim as builder

# Variables de entorno para optimización
ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    PIP_NO_CACHE_DIR=1 \
    PIP_DISABLE_PIP_VERSION_CHECK=1

# Instalar dependencias del sistema necesarias para el build
RUN apt-get update && apt-get install -y \
    build-essential \
    libpq-dev \
    curl \
    && rm -rf /var/lib/apt/lists/*

# Crear directorio de trabajo
WORKDIR /app

# Copiar archivos de dependencias
COPY requirements.txt requirements-dev.txt ./

# Instalar dependencias de Python
RUN pip install --user --no-cache-dir -r requirements.txt

# =============================================================================
# ETAPA 2: RUNTIME DE PRODUCCIÓN
# =============================================================================
FROM python:3.11-slim as runtime

# Variables de entorno para producción
ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    PYTHONPATH=/app \
    PATH=/app/.local/bin:$PATH

# Crear usuario no-root para seguridad
RUN groupadd -r voduser && useradd -r -g voduser voduser

# Instalar dependencias del sistema necesarias para runtime
RUN apt-get update && apt-get install -y \
    libpq5 \
    curl \
    && rm -rf /var/lib/apt/lists/* \
    && apt-get clean

# Crear directorio de trabajo
WORKDIR /app

# Copiar dependencias instaladas desde la etapa de build
COPY --from=builder /root/.local /app/.local

# Copiar código de la aplicación
COPY src/ ./src/
COPY config/ ./config/
COPY migrations/ ./migrations/

# Crear directorios necesarios
RUN mkdir -p /app/logs /app/uploads /app/temp

# Cambiar permisos y propietario
RUN chown -R voduser:voduser /app

# Cambiar al usuario no-root
USER voduser

# Exponer puerto de la aplicación
EXPOSE 8080

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=5s --retries=3 \
    CMD curl -f http://localhost:8080/health || exit 1

# Comando de inicio
CMD ["python", "-m", "uvicorn", "src.main:app", "--host", "0.0.0.0", "--port", "8080", "--workers", "4"]

# =============================================================================
# ETAPA 3: DESARROLLO (OPCIONAL)
# =============================================================================
FROM python:3.11-slim as development

# Variables de entorno para desarrollo
ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    PYTHONPATH=/app \
    FLASK_ENV=development \
    FLASK_DEBUG=1

# Instalar dependencias del sistema
RUN apt-get update && apt-get install -y \
    build-essential \
    libpq-dev \
    curl \
    git \
    vim \
    && rm -rf /var/lib/apt/lists/*

# Crear directorio de trabajo
WORKDIR /app

# Copiar archivos de dependencias
COPY requirements.txt requirements-dev.txt ./

# Instalar dependencias de desarrollo
RUN pip install --no-cache-dir -r requirements.txt -r requirements-dev.txt

# Copiar código de la aplicación
COPY . .

# Exponer puerto de desarrollo
EXPOSE 8080

# Comando de inicio para desarrollo
CMD ["python", "-m", "flask", "run", "--host", "0.0.0.0", "--port", "8080", "--debug"]

# =============================================================================
# ETAPA 4: TESTING (OPCIONAL)
# =============================================================================
FROM python:3.11-slim as testing

# Variables de entorno para testing
ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    PYTHONPATH=/app \
    TESTING=1

# Instalar dependencias del sistema
RUN apt-get update && apt-get install -y \
    build-essential \
    libpq-dev \
    curl \
    && rm -rf /var/lib/apt/lists/*

# Crear directorio de trabajo
WORKDIR /app

# Copiar archivos de dependencias
COPY requirements.txt requirements-dev.txt ./

# Instalar dependencias de testing
RUN pip install --no-cache-dir -r requirements.txt -r requirements-dev.txt

# Copiar código de la aplicación
COPY . .

# Comando de inicio para testing
CMD ["python", "-m", "pytest", "tests/", "-v", "--cov=src", "--cov-report=html"]

# =============================================================================
# METADATOS DE LA IMAGEN
# =============================================================================
LABEL maintainer="DevOps Team <devops@vodplatform.com>" \
      version="1.0.0" \
      description="VOD Platform App" \
      vendor="VOD Platform Inc." \
      org.opencontainers.image.title="VOD Platform" \
      org.opencontainers.image.description="Video On Demand Platform App" \
      org.opencontainers.image.version="1.0.0" \
      org.opencontainers.image.vendor="VOD Platform Inc." \
      org.opencontainers.image.licenses="MIT"

# =============================================================================
# INSTRUCCIONES DE USO
# =============================================================================
# Para construir la imagen de producción:
# docker build --target runtime -t vod-platform:latest .
#
# Para construir la imagen de desarrollo:
# docker build --target development -t vod-platform:dev .
#
# Para ejecutar tests:
# docker build --target testing -t vod-platform:test .
# docker run vod-platform:test
#
# Para ejecutar en producción:
# docker run -p 8080:8080 vod-platform:latest
#
# Para ejecutar en desarrollo:
# docker run -p 8080:8080 -v $(pwd):/app vod-platform:dev
