@echo off
REM Script completo para resolver todos los errores de Terraform (Windows)
REM Autor: Asistente AI

echo =======================================================
echo Script de Solucion Completa para Errores de Terraform
echo =======================================================
echo.

echo [INFO] Este script realizara los siguientes pasos:
echo   1. Limpiar recursos de Kubernetes conflictivos
echo   2. Limpiar estado de Terraform problemático  
echo   3. Reinicializar Terraform
echo   4. Generar nuevo plan
echo.

REM Obtener parametros
set PROJECT_ID=%1
if "%PROJECT_ID%"=="" set PROJECT_ID=ecommerce-microservices-back

set CLUSTER_NAME=%2  
if "%CLUSTER_NAME%"=="" set CLUSTER_NAME=ecommerce-microservices-cluster

set ZONE=%3
if "%ZONE%"=="" set ZONE=us-central1-a

set NAMESPACE=%4
if "%NAMESPACE%"=="" set NAMESPACE=ecommerce

echo Parametros:
echo   Proyecto: %PROJECT_ID%
echo   Cluster: %CLUSTER_NAME%
echo   Zona: %ZONE%
echo   Namespace: %NAMESPACE%
echo.

pause

echo ====================================
echo PASO 1: Limpieza de Kubernetes
echo ====================================

REM Verificar conexion kubectl
echo [INFO] Verificando conexion con Kubernetes...
kubectl cluster-info >nul 2>&1
if errorlevel 1 (
    echo [WARNING] Configurando kubectl...
    gcloud container clusters get-credentials %CLUSTER_NAME% --zone %ZONE% --project %PROJECT_ID%
)

REM Verificar si el namespace existe
kubectl get namespace %NAMESPACE% >nul 2>&1
if not errorlevel 1 (
    echo [WARNING] Namespace %NAMESPACE% encontrado con recursos conflictivos
    echo [INFO] Eliminando namespace %NAMESPACE% para limpiar conflictos...
    kubectl delete namespace %NAMESPACE% --timeout=120s
    
    REM Esperar eliminacion completa
    echo [INFO] Esperando eliminacion completa del namespace...
    :wait_ns_delete
    kubectl get namespace %NAMESPACE% >nul 2>&1
    if not errorlevel 1 (
        timeout /t 3 /nobreak >nul
        goto wait_ns_delete
    )
    echo [SUCCESS] Namespace eliminado
) else (
    echo [INFO] Namespace %NAMESPACE% no existe, continuando...
)

echo.
echo ====================================  
echo PASO 2: Limpieza de Estado Terraform
echo ====================================

REM Limpiar recursos problematicos del estado
if exist terraform.tfstate (
    echo [INFO] Limpiando estado de Terraform...
    
    REM Remover recursos de Kubernetes del estado
    terraform state rm kubernetes_namespace.ecommerce 2>nul
    terraform state rm kubernetes_config_map.ecommerce_config 2>nul
    terraform state rm kubernetes_deployment.zipkin 2>nul
    terraform state rm kubernetes_service.zipkin 2>nul
    terraform state rm kubernetes_deployment.service_discovery 2>nul
    terraform state rm kubernetes_service.service_discovery 2>nul
    
    echo [SUCCESS] Estado limpiado
) else (
    echo [INFO] No hay estado previo de Terraform
)

echo.
echo ====================================
echo PASO 3: Reinicializar Terraform  
echo ====================================

echo [INFO] Reinicializando Terraform...
terraform init -upgrade

if errorlevel 1 (
    echo [ERROR] Error al reinicializar Terraform
    pause
    exit /b 1
)

echo [SUCCESS] Terraform reinicializado

echo.
echo ====================================
echo PASO 4: Validar Configuracion
echo ====================================

echo [INFO] Validando configuracion...
terraform validate

if errorlevel 1 (
    echo [ERROR] Error en la configuracion de Terraform
    pause
    exit /b 1
)

echo [SUCCESS] Configuracion valida

echo.
echo ====================================
echo PASO 5: Generar Plan
echo ====================================

echo [INFO] Generando nuevo plan...
terraform plan -out=tfplan

if errorlevel 1 (
    echo [ERROR] Error al generar el plan
    pause
    exit /b 1
)

echo [SUCCESS] Plan generado correctamente

echo.
echo =================================================
echo SOLUCION COMPLETADA - PROXIMO PASO
echo =================================================
echo.
echo [SUCCESS] Todos los conflictos han sido resueltos
echo.
echo [INFO] Para aplicar el plan, ejecute:
echo   terraform apply tfplan
echo.
echo [INFO] O use el script de despliegue:
echo   deploy.bat
echo.

set /p APPLY="Desea aplicar el plan ahora? (y/N): "
if /i "%APPLY%"=="y" (
    echo.
    echo [INFO] Aplicando plan...
    terraform apply tfplan
    
    if not errorlevel 1 (
        echo.
        echo [SUCCESS] Despliegue completado exitosamente!
    ) else (
        echo.
        echo [ERROR] Error durante el despliegue
    )
) else (
    echo [INFO] Plan guardado como 'tfplan'. Apliquelo cuando este listo.
)

echo.
pause 