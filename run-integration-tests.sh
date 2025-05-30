#!/bin/bash

# Colores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Variables
SERVICES=("order-service" "payment-service" "product-service" "user-service")
FAILED_TESTS=()
PASSED_TESTS=()

echo -e "${BLUE}🚀 Iniciando ejecución de pruebas de integración...${NC}"

# Función para ejecutar pruebas de un servicio
run_service_tests() {
    local service=$1
    echo -e "${YELLOW}📋 Ejecutando pruebas de integración para ${service}...${NC}"
    
    cd ${service}
    
    # Ejecutar solo pruebas de integración
    mvn test -Dtest="*IntegrationTest" -Dspring.profiles.active=integration-test
    
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✅ Pruebas de ${service} - PASSED${NC}"
        PASSED_TESTS+=("${service}")
    else
        echo -e "${RED}❌ Pruebas de ${service} - FAILED${NC}"
        FAILED_TESTS+=("${service}")
    fi
    
    cd ..
}

# Verificar que Maven esté instalado
if ! command -v mvn &> /dev/null; then
    echo -e "${RED}❌ Maven no está instalado. Por favor, instala Maven para continuar.${NC}"
    exit 1
fi

# Verificar que H2 database esté disponible para pruebas
echo -e "${BLUE}🔍 Verificando entorno de pruebas...${NC}"

# Ejecutar pruebas para cada servicio
for service in "${SERVICES[@]}"; do
    if [ -d "$service" ]; then
        run_service_tests "$service"
    else
        echo -e "${YELLOW}⚠️  Directorio ${service} no encontrado, saltando...${NC}"
    fi
done

# Reporte final
echo -e "${BLUE}📊 REPORTE FINAL DE PRUEBAS DE INTEGRACIÓN${NC}"
echo "=================================="

if [ ${#PASSED_TESTS[@]} -gt 0 ]; then
    echo -e "${GREEN}✅ PRUEBAS EXITOSAS (${#PASSED_TESTS[@]}):${NC}"
    for service in "${PASSED_TESTS[@]}"; do
        echo "   - $service"
    done
fi

if [ ${#FAILED_TESTS[@]} -gt 0 ]; then
    echo -e "${RED}❌ PRUEBAS FALLIDAS (${#FAILED_TESTS[@]}):${NC}"
    for service in "${FAILED_TESTS[@]}"; do
        echo "   - $service"
    done
    echo -e "${RED}🚨 Algunas pruebas fallaron. Revisa los logs para más detalles.${NC}"
    exit 1
else
    echo -e "${GREEN}🎉 ¡Todas las pruebas de integración pasaron exitosamente!${NC}"
fi

echo "=================================="
echo -e "${BLUE}📋 Para ver reportes detallados:${NC}"
echo "   - Reportes JaCoCo: [servicio]/target/site/jacoco/index.html"
echo "   - Logs de pruebas: [servicio]/target/surefire-reports/"