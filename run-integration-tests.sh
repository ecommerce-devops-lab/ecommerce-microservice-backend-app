#!/bin/bash

# Colores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Configuración
TEST_REPORT_DIR="target/integration-test-reports"
SERVICES=("user-service" "order-service" "payment-service" "product-service" "shipping-service" "api-gateway")
START_TIME=$(date +%s)

echo -e "${BLUE}===============================================${NC}"
echo -e "${BLUE}🧪 TALLER 2 - PRUEBAS DE INTEGRACIÓN${NC}"
echo -e "${BLUE}===============================================${NC}"
echo -e "${CYAN}Fecha: $(date)${NC}"
echo -e "${CYAN}Microservicios: ${SERVICES[*]}${NC}"
echo ""

# Función para imprimir encabezados
print_header() {
    echo -e "${PURPLE}=====================================${NC}"
    echo -e "${PURPLE}$1${NC}"
    echo -e "${PURPLE}=====================================${NC}"
}

# Función para verificar prerequisitos
check_prerequisites() {
    print_header "🔍 VERIFICANDO PREREQUISITOS"
    
    # Verificar Java
    if ! command -v java &> /dev/null; then
        echo -e "${RED}❌ Java no está instalado${NC}"
        exit 1
    fi
    echo -e "${GREEN}✅ Java: $(java -version 2>&1 | head -n 1)${NC}"
    
    # Verificar Maven
    if ! command -v mvn &> /dev/null; then
        echo -e "${RED}❌ Maven no está instalado${NC}"
        exit 1
    fi
    echo -e "${GREEN}✅ Maven: $(mvn --version | head -n 1)${NC}"
    
    # Verificar Docker (para WireMock)
    if ! command -v docker &> /dev/null; then
        echo -e "${YELLOW}⚠️  Docker no está disponible (requerido para algunos tests)${NC}"
    else
        echo -e "${GREEN}✅ Docker: $(docker --version)${NC}"
    fi
    
    echo ""
}

# Función para limpiar compilaciones anteriores
clean_previous_builds() {
    print_header "🧹 LIMPIANDO COMPILACIONES ANTERIORES"
    
    for service in "${SERVICES[@]}"; do
        if [ -d "$service" ]; then
            echo -e "${CYAN}Limpiando $service...${NC}"
            cd "$service"
            mvn clean -q
            cd ..
        else
            echo -e "${YELLOW}⚠️  Directorio $service no encontrado${NC}"
        fi
    done
    echo ""
}

# Función para compilar microservicios
compile_services() {
    print_header "🔨 COMPILANDO MICROSERVICIOS"
    
    local failed_services=()
    
    for service in "${SERVICES[@]}"; do
        if [ -d "$service" ]; then
            echo -e "${CYAN}Compilando $service...${NC}"
            cd "$service"
            
            if mvn compile test-compile -q; then
                echo -e "${GREEN}✅ $service compilado exitosamente${NC}"
            else
                echo -e "${RED}❌ Error compilando $service${NC}"
                failed_services+=("$service")
            fi
            cd ..
        else
            echo -e "${YELLOW}⚠️  Directorio $service no encontrado${NC}"
            failed_services+=("$service")
        fi
    done
    
    if [ ${#failed_services[@]} -ne 0 ]; then
        echo -e "${RED}❌ Servicios con errores de compilación: ${failed_services[*]}${NC}"
        echo -e "${YELLOW}⚠️  Continuando con los servicios disponibles...${NC}"
    fi
    echo ""
}

# Función para crear directorios de reportes
setup_test_reports() {
    print_header "📁 CONFIGURANDO REPORTES DE PRUEBAS"
    
    mkdir -p "$TEST_REPORT_DIR"
    echo -e "${GREEN}✅ Directorio de reportes creado: $TEST_REPORT_DIR${NC}"
    echo ""
}

# Función para ejecutar pruebas de integración por servicio
run_integration_tests() {
    print_header "🚀 EJECUTANDO PRUEBAS DE INTEGRACIÓN"
    
    local test_results=()
    local total_tests=0
    local passed_tests=0
    local failed_tests=0
    
    # User Service - UserAddressIntegrationTest
    echo -e "${CYAN}📋 Ejecutando pruebas de User Service...${NC}"
    if [ -d "user-service" ]; then
        cd user-service
        echo -e "${BLUE}  🔗 UserAddressIntegrationTest${NC}"
        if mvn test -Dtest=UserAddressIntegrationTest -Dspring.profiles.active=integration-test; then
            echo -e "${GREEN}  ✅ UserAddressIntegrationTest - PASADO${NC}"
            test_results+=("user-service:UserAddressIntegrationTest:PASSED")
            ((passed_tests++))
        else
            echo -e "${RED}  ❌ UserAddressIntegrationTest - FALLIDO${NC}"
            test_results+=("user-service:UserAddressIntegrationTest:FAILED")
            ((failed_tests++))
        fi
        ((total_tests++))
        cd ..
    fi
    
    # Order Service - UserOrderIntegrationTest
    echo -e "${CYAN}📋 Ejecutando pruebas de Order Service...${NC}"
    if [ -d "order-service" ]; then
        cd order-service
        echo -e "${BLUE}  🔗 UserOrderIntegrationTest${NC}"
        if mvn test -Dtest=UserOrderIntegrationTest -Dspring.profiles.active=integration-test; then
            echo -e "${GREEN}  ✅ UserOrderIntegrationTest - PASADO${NC}"
            test_results+=("order-service:UserOrderIntegrationTest:PASSED")
            ((passed_tests++))
        else
            echo -e "${RED}  ❌ UserOrderIntegrationTest - FALLIDO${NC}"
            test_results+=("order-service:UserOrderIntegrationTest:FAILED")
            ((failed_tests++))
        fi
        ((total_tests++))
        cd ..
    fi
    
    # Payment Service - OrderPaymentIntegrationTest
    echo -e "${CYAN}📋 Ejecutando pruebas de Payment Service...${NC}"
    if [ -d "payment-service" ]; then
        cd payment-service
        echo -e "${BLUE}  🔗 OrderPaymentIntegrationTest${NC}"
        if mvn test -Dtest=OrderPaymentIntegrationTest -Dspring.profiles.active=integration-test; then
            echo -e "${GREEN}  ✅ OrderPaymentIntegrationTest - PASADO${NC}"
            test_results+=("payment-service:OrderPaymentIntegrationTest:PASSED")
            ((passed_tests++))
        else
            echo -e "${RED}  ❌ OrderPaymentIntegrationTest - FALLIDO${NC}"
            test_results+=("payment-service:OrderPaymentIntegrationTest:FAILED")
            ((failed_tests++))
        fi
        ((total_tests++))
        cd ..
    fi
    
    # Shipping Service - ProductShippingIntegrationTest
    echo -e "${CYAN}📋 Ejecutando pruebas de Shipping Service...${NC}"
    if [ -d "shipping-service" ]; then
        cd shipping-service
        echo -e "${BLUE}  🔗 ProductShippingIntegrationTest${NC}"
        if mvn test -Dtest=ProductShippingIntegrationTest -Dspring.profiles.active=integration-test; then
            echo -e "${GREEN}  ✅ ProductShippingIntegrationTest - PASADO${NC}"
            test_results+=("shipping-service:ProductShippingIntegrationTest:PASSED")
            ((passed_tests++))
        else
            echo -e "${RED}  ❌ ProductShippingIntegrationTest - FALLIDO${NC}"
            test_results+=("shipping-service:ProductShippingIntegrationTest:FAILED")
            ((failed_tests++))
        fi
        ((total_tests++))
        cd ..
    fi
    
    # API Gateway - ApiGatewayIntegrationTest
    echo -e "${CYAN}📋 Ejecutando pruebas de API Gateway...${NC}"
    if [ -d "api-gateway" ]; then
        cd api-gateway
        echo -e "${BLUE}  🔗 ApiGatewayIntegrationTest${NC}"
        if mvn test -Dtest=ApiGatewayIntegrationTest -Dspring.profiles.active=integration-test; then
            echo -e "${GREEN}  ✅ ApiGatewayIntegrationTest - PASADO${NC}"
            test_results+=("api-gateway:ApiGatewayIntegrationTest:PASSED")
            ((passed_tests++))
        else
            echo -e "${RED}  ❌ ApiGatewayIntegrationTest - FALLIDO${NC}"
            test_results+=("api-gateway:ApiGatewayIntegrationTest:FAILED")
            ((failed_tests++))
        fi
        ((total_tests++))
        cd ..
    fi
    
    echo ""
    echo -e "${PURPLE}📊 RESULTADOS DE PRUEBAS DE INTEGRACIÓN:${NC}"
    echo -e "${GREEN}✅ Pruebas Pasadas: $passed_tests${NC}"
    echo -e "${RED}❌ Pruebas Fallidas: $failed_tests${NC}"
    echo -e "${BLUE}📈 Total de Pruebas: $total_tests${NC}"
    echo ""
    
    # Mostrar detalles de cada prueba
    echo -e "${CYAN}📋 DETALLE DE RESULTADOS:${NC}"
    for result in "${test_results[@]}"; do
        IFS=':' read -r service test status <<< "$result"
        if [ "$status" = "PASSED" ]; then
            echo -e "${GREEN}  ✅ $service - $test${NC}"
        else
            echo -e "${RED}  ❌ $service - $test${NC}"
        fi
    done
    echo ""
    
    # Retornar código basado en resultados
    if [ $failed_tests -eq 0 ]; then
        return 0
    else
        return 1
    fi
}

# Función para generar reportes consolidados
generate_reports() {
    print_header "📄 GENERANDO REPORTES CONSOLIDADOS"
    
    local report_file="$TEST_REPORT_DIR/integration-test-summary.txt"
    local html_report="$TEST_REPORT_DIR/integration-test-report.html"
    
    # Reporte de texto
    {
        echo "=========================================="
        echo "REPORTE DE PRUEBAS DE INTEGRACIÓN"
        echo "=========================================="
        echo "Fecha: $(date)"
        echo "Microservicios probados: ${SERVICES[*]}"
        echo ""
        echo "RESUMEN:"
        echo "- Pruebas Totales: $total_tests"
        echo "- Pruebas Pasadas: $passed_tests"
        echo "- Pruebas Fallidas: $failed_tests"
        echo ""
        echo "DETALLES:"
        for result in "${test_results[@]}"; do
            echo "  $result"
        done
        echo ""
        echo "Tiempo total de ejecución: $(($(date +%s) - START_TIME)) segundos"
    } > "$report_file"
    
    # Reporte HTML básico
    {
        echo "<!DOCTYPE html>"
        echo "<html><head><title>Integration Test Report</title></head><body>"
        echo "<h1>Integration Test Report</h1>"
        echo "<p><strong>Fecha:</strong> $(date)</p>"
        echo "<p><strong>Pruebas Totales:</strong> $total_tests</p>"
        echo "<p><strong>Pruebas Pasadas:</strong> <span style='color:green'>$passed_tests</span></p>"
        echo "<p><strong>Pruebas Fallidas:</strong> <span style='color:red'>$failed_tests</span></p>"
        echo "<h2>Detalles</h2><ul>"
        for result in "${test_results[@]}"; do
            IFS=':' read -r service test status <<< "$result"
            if [ "$status" = "PASSED" ]; then
                echo "<li style='color:green'>✅ $service - $test</li>"
            else
                echo "<li style='color:red'>❌ $service - $test</li>"
            fi
        done
        echo "</ul></body></html>"
    } > "$html_report"
    
    echo -e "${GREEN}✅ Reporte de texto generado: $report_file${NC}"
    echo -e "${GREEN}✅ Reporte HTML generado: $html_report${NC}"
    echo ""
}

# Función para copiar reportes de Surefire
collect_surefire_reports() {
    print_header "📋 RECOLECTANDO REPORTES DE SUREFIRE"
    
    for service in "${SERVICES[@]}"; do
        if [ -d "$service/target/surefire-reports" ]; then
            echo -e "${CYAN}Copiando reportes de $service...${NC}"
            mkdir -p "$TEST_REPORT_DIR/$service"
            cp -r "$service/target/surefire-reports/"* "$TEST_REPORT_DIR/$service/" 2>/dev/null || true
        fi
    done
    
    echo -e "${GREEN}✅ Reportes de Surefire recolectados en $TEST_REPORT_DIR${NC}"
    echo ""
}

# Función para mostrar resumen final
show_final_summary() {
    local end_time=$(date +%s)
    local execution_time=$((end_time - START_TIME))
    
    print_header "🎯 RESUMEN FINAL"
    
    echo -e "${BLUE}Tiempo total de ejecución: ${execution_time}s${NC}"
    echo -e "${BLUE}Servicios procesados: ${#SERVICES[@]}${NC}"
    echo -e "${BLUE}Directorio de reportes: $TEST_REPORT_DIR${NC}"
    echo ""
    
    if [ $failed_tests -eq 0 ]; then
        echo -e "${GREEN}🎉 ¡TODAS LAS PRUEBAS DE INTEGRACIÓN PASARON!${NC}"
        echo -e "${GREEN}✅ Sistema listo para despliegue${NC}"
    else
        echo -e "${RED}⚠️  ALGUNAS PRUEBAS FALLARON${NC}"
        echo -e "${YELLOW}🔍 Revisar reportes en: $TEST_REPORT_DIR${NC}"
        echo -e "${YELLOW}🛠️  Correcciones necesarias antes del despliegue${NC}"
    fi
    
    echo ""
    echo -e "${BLUE}===============================================${NC}"
    echo -e "${BLUE}🏁 EJECUCIÓN DE PRUEBAS COMPLETADA${NC}"
    echo -e "${BLUE}===============================================${NC}"
}

# Función para limpiar al salir
cleanup() {
    echo -e "${YELLOW}🧹 Limpiando procesos en segundo plano...${NC}"
    # Matar procesos de WireMock si existen
    pkill -f "wiremock" 2>/dev/null || true
    exit 0
}

# Configurar trap para limpieza
trap cleanup EXIT INT TERM

# EJECUCIÓN PRINCIPAL
main() {
    # Verificar que estamos en el directorio correcto
    if [ ! -f "pom.xml" ]; then
        echo -e "${RED}❌ No se encontró pom.xml. Ejecute desde el directorio raíz del proyecto.${NC}"
        exit 1
    fi
    
    check_prerequisites
    clean_previous_builds
    compile_services
    setup_test_reports
    
    # Ejecutar pruebas y capturar resultado
    if run_integration_tests; then
        TEST_SUCCESS=true
    else
        TEST_SUCCESS=false
    fi
    
    collect_surefire_reports
    generate_reports
    show_final_summary
    
    # Salir con código apropiado
    if [ "$TEST_SUCCESS" = true ]; then
        exit 0
    else
        exit 1
    fi
}

# Verificar argumentos de línea de comandos
if [[ $# -gt 0 ]]; then
    case $1 in
        --help|-h)
            echo "Uso: $0 [opciones]"
            echo ""
            echo "Opciones:"
            echo "  --help, -h     Mostrar esta ayuda"
            echo "  --clean-only   Solo limpiar sin ejecutar pruebas"
            echo "  --compile-only Solo compilar sin ejecutar pruebas"
            echo ""
            echo "Microservicios incluidos:"
            for service in "${SERVICES[@]}"; do
                echo "  - $service"
            done
            exit 0
            ;;
        --clean-only)
            check_prerequisites
            clean_previous_builds
            echo -e "${GREEN}✅ Limpieza completada${NC}"
            exit 0
            ;;
        --compile-only)
            check_prerequisites
            clean_previous_builds
            compile_services
            echo -e "${GREEN}✅ Compilación completada${NC}"
            exit 0
            ;;
        *)
            echo -e "${RED}❌ Opción desconocida: $1${NC}"
            echo "Use --help para ver las opciones disponibles"
            exit 1
            ;;
    esac
fi

# Ejecutar función principal
main