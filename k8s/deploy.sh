#!/bin/bash

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}🔹 Iniciando Minikube...${NC}"
minikube start --driver=docker --cpus=6 --memory=6144

echo -e "${BLUE}🐳 Configurando Docker para usar el Docker daemon de Minikube...${NC}"
eval $(minikube docker-env)

echo -e "${BLUE}📁 Creando namespace para ecommerce...${NC}"
kubectl create namespace ecommerce --dry-run=client -o yaml | kubectl apply -f -

echo -e "${BLUE}📝 Aplicando configuración...${NC}"
if [ -f "ecommerce-config.yaml" ]; then
    kubectl apply -f ecommerce-config.yaml
    echo -e "${GREEN}✅ ConfigMap aplicado${NC}"
else
    echo -e "${RED}❌ Error: ecommerce-config.yaml no encontrado${NC}"
    exit 1
fi

echo -e "${BLUE}🔍 Desplegando servicios core (Zipkin, Eureka, Config Server)...${NC}"
if [ -f "core-services.yaml" ]; then
    kubectl apply -f core-services.yaml
    echo -e "${GREEN}✅ Servicios core desplegados${NC}"
else
    echo -e "${RED}❌ Error: core-services.yaml no encontrado${NC}"
    exit 1
fi

# echo -e "${YELLOW}⏳ Esperando a que los servicios core estén listos...${NC}"
# echo "Esperando Zipkin..."
# kubectl wait --for=condition=ready pod -l app=zipkin -n ecommerce --timeout=300s

# echo "Esperando Service Discovery..."
# kubectl wait --for=condition=ready pod -l app=service-discovery -n ecommerce --timeout=300s

# echo "Esperando Cloud Config..."
# kubectl wait --for=condition=ready pod -l app=cloud-config -n ecommerce --timeout=300s

echo -e "${BLUE}🚀 Desplegando microservicios...${NC}"
if [ -f "microservices.yaml" ]; then
    kubectl apply -f microservices.yaml
    echo -e "${GREEN}✅ Microservicios desplegados${NC}"
else
    echo -e "${RED}❌ Error: microservices.yaml no encontrado${NC}"
    exit 1
fi

echo -e "${YELLOW}⏳ Esperando a que todos los microservicios estén listos...${NC}"
echo "Esperando API Gateway..."
kubectl wait --for=condition=ready pod -l app=api-gateway -n ecommerce --timeout=300s

echo "Esperando Order Service..."
kubectl wait --for=condition=ready pod -l app=order-service -n ecommerce --timeout=300s

echo "Esperando Payment Service..."
kubectl wait --for=condition=ready pod -l app=payment-service -n ecommerce --timeout=300s

echo "Esperando Product Service..."
kubectl wait --for=condition=ready pod -l app=product-service -n ecommerce --timeout=300s

echo "Esperando Shipping Service..."
kubectl wait --for=condition=ready pod -l app=shipping-service -n ecommerce --timeout=300s

echo "Esperando User Service..."
kubectl wait --for=condition=ready pod -l app=user-service -n ecommerce --timeout=300s

echo -e "${GREEN}🎉 ¡Despliegue completado!${NC}"
echo -e "${BLUE}📊 Estado de los pods:${NC}"
kubectl get pods -n ecommerce

echo -e "${BLUE}🌐 Servicios disponibles:${NC}"
kubectl get services -n ecommerce

echo -e "${BLUE}🔗 Para acceder al API Gateway:${NC}"
echo "minikube service api-gateway -n ecommerce"

echo -e "${BLUE}🔍 Para ver logs de un servicio específico:${NC}"
echo "kubectl logs -f deployment/[nombre-servicio] -n ecommerce"

echo -e "${BLUE}📈 Para monitorear el estado:${NC}"
echo "kubectl get pods -n ecommerce -w"