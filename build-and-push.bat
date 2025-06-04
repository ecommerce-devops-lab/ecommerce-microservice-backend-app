@echo off
REM Script para construir imágenes Docker y publicarlas en Google Container Registry

REM Variables
SET PROJECT_ID=%1
IF "%PROJECT_ID%"=="" (
  echo Error: Debes proporcionar el ID del proyecto de GCP como primer argumento
  echo Uso: build-and-push.bat [PROJECT_ID]
  exit /b 1
)

REM Compilar los proyectos con Maven
echo Compilando todos los microservicios...
call mvnw clean package -DskipTests

REM Configurar Docker para autenticarse con GCR
echo Configurando Docker para autenticarse con Google Container Registry...
call gcloud auth configure-docker

REM Lista de microservicios
SET SERVICES=service-discovery cloud-config api-gateway user-service product-service order-service payment-service shipping-service favourite-service proxy-client

REM Construir y publicar cada imagen
FOR %%s IN (%SERVICES%) DO (
  echo Construyendo y publicando %%s...
  cd %%s
  
  REM Construir la imagen
  docker build -t %%s:0.1.0 .
  
  REM Etiquetar para GCR
  docker tag %%s:0.1.0 gcr.io/%PROJECT_ID%/%%s:0.1.0
  
  REM Publicar en GCR
  docker push gcr.io/%PROJECT_ID%/%%s:0.1.0
  
  cd ..
  echo %%s publicado con exito en gcr.io/%PROJECT_ID%/%%s:0.1.0
)

echo Todas las imagenes han sido construidas y publicadas en Google Container Registry.
echo Ahora puedes proceder a desplegar la infraestructura con Terraform.
