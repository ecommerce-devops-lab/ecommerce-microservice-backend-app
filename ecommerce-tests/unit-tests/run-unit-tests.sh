#!/bin/bash

# Script para ejecutar todas las pruebas unitarias del proyecto

# Colores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}🧪 Iniciando ejecución de pruebas unitarias - Taller 2${NC}"
echo -e "${BLUE}=================================================${NC}"

# Directorio base del proyecto
PROJECT_ROOT=$(pwd)
SERVICES=("user-service" "order-service" "payment-service" "product-service" "shipping-service")

# Función para ejecutar pruebas de un servicio
run_service_tests() {
    local service=$1
    echo -e "\n${YELLOW}📝 Ejecutando pruebas unitarias para: ${service}${NC}"
    
    if [ -d "$service" ]; then
        cd "$service"
        
        # Limpiar compilaciones anteriores
        echo -e "${BLUE}🧹 Limpiando compilaciones anteriores...${NC}"
        ./mvnw clean
        
        # Compilar el proyecto
        echo -e "${BLUE}🔨 Compilando proyecto...${NC}"
        ./mvnw compile
        
        # Ejecutar solo pruebas unitarias (excluyendo integración)
        echo -e "${BLUE}🚀 Ejecutando pruebas unitarias...${NC}"
        ./mvnw test -Dtest="**/*Test" -DfailIfNoTests=false
        
        # Verificar resultado
        if [ $? -eq 0 ]; then
            echo -e "${GREEN}✅ Pruebas unitarias de ${service} completadas exitosamente${NC}"
        else
            echo -e "${RED}❌ Error en las pruebas unitarias de ${service}${NC}"
            return 1
        fi
        
        # Generar reporte de cobertura
        echo -e "${BLUE}📊 Generando reporte de cobertura...${NC}"
        ./mvnw jacoco:report
        
        cd "$PROJECT_ROOT"
    else
        echo -e "${RED}❌ Directorio ${service} no encontrado${NC}"
        return 1
    fi
}

# Crear directorio para reportes
mkdir -p reports/unit-tests
mkdir -p reports/coverage

echo -e "\n${BLUE}🔍 Servicios a probar: ${SERVICES[*]}${NC}"

# Contador de éxitos y fallos
SUCCESS_COUNT=0
FAIL_COUNT=0

# Ejecutar pruebas para cada servicio
for service in "${SERVICES[@]}"; do
    if run_service_tests "$service"; then
        ((SUCCESS_COUNT++))
        
        # Copiar reportes a directorio centralizado
        if [ -f "$service/target/site/jacoco/index.html" ]; then
            cp -r "$service/target/site/jacoco" "reports/coverage/${service}-coverage"
            echo -e "${BLUE}📋 Reporte de cobertura copiado para ${service}${NC}"
        fi
        
        if [ -f "$service/target/surefire-reports" ]; then
            cp -r "$service/target/surefire-reports" "reports/unit-tests/${service}-results"
            echo -e "${BLUE}📋 Resultados de pruebas copiados para ${service}${NC}"
        fi
    else
        ((FAIL_COUNT++))
    fi
done

# Resumen final
echo -e "\n${BLUE}📊 RESUMEN DE EJECUCIÓN${NC}"
echo -e "${BLUE}========================${NC}"
echo -e "${GREEN}✅ Servicios exitosos: ${SUCCESS_COUNT}${NC}"
echo -e "${RED}❌ Servicios fallidos: ${FAIL_COUNT}${NC}"
echo -e "${BLUE}📁 Reportes guardados en: ./reports/${NC}"

# Mostrar ubicaciones de reportes
echo -e "\n${BLUE}📁 Reportes disponibles:${NC}"
echo -e "📊 Cobertura: ${PWD}/reports/coverage/"
echo -e "📋 Resultados detallados: ${PWD}/reports/unit-tests/"

if [ $FAIL_COUNT -eq 0 ]; then
    echo -e "\n${GREEN}🎉 ¡Todas las pruebas unitarias completadas exitosamente!${NC}"
    exit 0
else
    echo -e "\n${RED}⚠️  Algunas pruebas fallaron. Revisar logs para más detalles.${NC}"
    exit 1
fi