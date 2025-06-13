#!/bin/bash

SONAR_HOST="http://localhost:9000"
SONAR_TOKEN="squ_bec814e0c8b1ae1c0472ded4f0976aa7212b2dc8"
PROJECT_PREFIX="ecommerce"

declare -A microservices=(
    ["order-service"]="8300"
    ["payment-service"]="8400"
    ["product-service"]="8500"
    ["user-service"]="8700"
    ["shipping-service"]="8600"
)

# Colores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}🚀 Creando proyectos en SonarQube...${NC}"

for service in "${!microservices[@]}"; do
    port=${microservices[$service]}
    project_key="${PROJECT_PREFIX}-${service}"
    project_name="E-commerce ${service^}"
    
    echo -e "${YELLOW}📦 Creando proyecto: ${project_name}${NC}"
    
    # Crear proyecto
    response=$(curl -s -w "%{http_code}" \
        -u "${SONAR_TOKEN}:" \
        -X POST \
        "${SONAR_HOST}/api/projects/create" \
        -d "project=${project_key}" \
        -d "name=${project_name}")
    
    http_code="${response: -3}"
    
    if [[ "$http_code" == "200" ]]; then
        echo -e "${GREEN}✅ Proyecto ${project_key} creado exitosamente${NC}"
        
        # Configurar Quality Gate
        curl -s -u "${SONAR_TOKEN}:" \
            -X POST \
            "${SONAR_HOST}/api/qualitygates/select" \
            -d "projectKey=${project_key}" \
            -d "gateName=Sonar way"
        
        echo -e "${GREEN}✅ Quality Gate configurado para ${project_key}${NC}"
        
    elif [[ "$http_code" == "400" ]]; then
        echo -e "${YELLOW}⚠️  Proyecto ${project_key} ya existe${NC}"
    else
        echo -e "${RED}❌ Error creando proyecto ${project_key}. HTTP Code: ${http_code}${NC}"
    fi
    
    sleep 1
done

echo -e "${GREEN}🎉 Proceso completado${NC}"