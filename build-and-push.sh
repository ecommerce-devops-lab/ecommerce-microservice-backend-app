#!/bin/bash
# Script para construir imágenes Docker y publicarlas en Google Container Registry

# Variables
PROJECT_ID=$1
if [ -z "$PROJECT_ID" ]; then
  echo "Error: Debes proporcionar el ID del proyecto de GCP como primer argumento"
  echo "Uso: ./build-and-push.sh [PROJECT_ID]"
  exit 1
fi

# Verificar que gcloud esté autenticado
echo "Verificando autenticación de gcloud..."
gcloud auth list --filter=status:ACTIVE --format="value(account)" | head -1 > /dev/null
if [ $? -ne 0 ]; then
  echo "Error: No estás autenticado en gcloud. Ejecuta 'gcloud auth login'"
  exit 1
fi

# Habilitar APIs necesarias
echo "Habilitando APIs necesarias..."
gcloud services enable artifactregistry.googleapis.com
gcloud services enable container.googleapis.com

# Compilar los proyectos con Maven
echo "Compilando todos los microservicios..."
./mvnw clean package -DskipTests
if [ $? -ne 0 ]; then
  echo "Error: Falló la compilación de Maven"
  exit 1
fi

# Configurar Docker para autenticarse con GCR
echo "Configurando Docker para autenticarse con Google Container Registry..."
gcloud auth configure-docker
if [ $? -ne 0 ]; then
  echo "Error: No se pudo configurar Docker con GCR"
  exit 1
fi

# Lista de microservicios
SERVICES=(
  "service-discovery"
  "cloud-config"
  "api-gateway"
  "user-service"
  "product-service"
  "order-service"
  "payment-service"
  "shipping-service"
  "favourite-service"
  "proxy-client"
)

# Función para construir y publicar una imagen
build_and_push_service() {
  local SERVICE=$1
  echo "Construyendo y publicando $SERVICE..."
  
  # Verificar que el directorio existe
  if [ ! -d "$SERVICE" ]; then
    echo "Error: El directorio $SERVICE no existe"
    return 1
  fi
  
  # Cambiar al directorio del servicio
  cd $SERVICE
  
  # Verificar que el Dockerfile existe
  if [ ! -f "Dockerfile" ]; then
    echo "Error: No se encontró Dockerfile en $SERVICE"
    cd ..
    return 1
  fi
  
  # Construir la imagen
  echo "Construyendo imagen Docker para $SERVICE..."
  docker build -t $SERVICE:0.1.0 .
  if [ $? -ne 0 ]; then
    echo "Error: Falló la construcción de la imagen para $SERVICE"
    cd ..
    return 1
  fi
  
  # Etiquetar para GCR
  docker tag $SERVICE:0.1.0 gcr.io/$PROJECT_ID/$SERVICE:0.1.0
  
  # Publicar en GCR
  echo "Publicando $SERVICE en Google Container Registry..."
  docker push gcr.io/$PROJECT_ID/$SERVICE:0.1.0
  if [ $? -ne 0 ]; then
    echo "Error: Falló la publicación de $SERVICE"
    cd ..
    return 1
  fi
  
  cd ..
  echo "✅ $SERVICE publicado con éxito en gcr.io/$PROJECT_ID/$SERVICE:0.1.0"
  return 0
}

# Construir y publicar cada imagen
FAILED_SERVICES=()
for SERVICE in "${SERVICES[@]}"; do
  if ! build_and_push_service "$SERVICE"; then
    FAILED_SERVICES+=("$SERVICE")
  fi
done

# Mostrar resumen
echo ""
echo "=========================================="
echo "RESUMEN DEL PROCESO DE BUILD Y PUSH"
echo "=========================================="

if [ ${#FAILED_SERVICES[@]} -eq 0 ]; then
  echo "✅ Todas las imágenes han sido construidas y publicadas exitosamente en Google Container Registry."
  echo ""
  echo "Imágenes disponibles:"
  for SERVICE in "${SERVICES[@]}"; do
    echo "  - gcr.io/$PROJECT_ID/$SERVICE:0.1.0"
  done
  echo ""
  echo "Ahora puedes proceder a desplegar la infraestructura con Terraform:"
  echo "  cd microservices-terraform"
  echo "  terraform init"
  echo "  terraform apply"
else
  echo "❌ Los siguientes servicios fallaron en el proceso:"
  for FAILED in "${FAILED_SERVICES[@]}"; do
    echo "  - $FAILED"
  done
  echo ""
  echo "Por favor, revisa los errores y vuelve a ejecutar el script."
  exit 1
fi
