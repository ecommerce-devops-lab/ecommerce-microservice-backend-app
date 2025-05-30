# Kubernetes Deployment Documentation

## Overview

This directory contains the complete Kubernetes deployment configuration for an ecommerce microservices architecture. The implementation supports multiple environments (development, staging, production) with proper service discovery, configuration management, and monitoring capabilities.

## Architecture

### Microservices Components

The system consists of the following microservices:

1. **API Gateway** (`api-gateway`) - Port 8080
   - Entry point for all external requests
   - Routes traffic to appropriate microservices
   - Exposed via NodePort for external access

2. **Order Service** (`order-service`) - Port 8300
   - Handles order management and processing
   - Communicates with other services for order fulfillment

3. **Payment Service** (`payment-service`) - Port 8400
   - Manages payment processing and transactions
   - Higher resource allocation due to processing requirements

4. **Product Service** (`product-service`) - Port 8500
   - Product catalog and inventory management
   - Core service for product information

5. **Shipping Service** (`shipping-service`) - Port 8600
   - Handles shipping logistics and tracking
   - Integrates with order and payment services

6. **User Service** (`user-service`) - Port 8700
   - User management and authentication
   - Central service for user-related operations

### Core Infrastructure Services

1. **Service Discovery (Eureka)** - Port 8761
   - Service registration and discovery
   - Enables dynamic service communication

2. **Cloud Config Server** - Port 9296
   - Centralized configuration management
   - Provides environment-specific configurations

3. **Zipkin** - Port 9411
   - Distributed tracing and monitoring
   - Performance analysis and debugging

## File Structure

```
k8s/
├── README.md                    # This documentation
├── namespaces.yaml             # Environment namespaces
├── ecommerce-config.yaml       # Main configuration
├── environments-config.yaml    # Environment-specific configs
├── core-services.yaml          # Infrastructure services
├── microservices.yaml          # Application services
├── dev-deployment.yaml         # Development environment template
├── stage-deployment.yaml       # Staging environment template
├── prod-deployment.yaml        # Production environment template
├── deploy.sh                   # Automated deployment script
└── kubeconfig.yaml            # Minikube cluster configuration
```

## Environment Configuration

### Development Environment
- **Namespace**: `ecommerce-dev`
- **Replicas**: 1 per service
- **Resources**: Minimal allocation for development
- **Profile**: `dev` with DEBUG logging
- **Purpose**: Local development and testing

### Staging Environment
- **Namespace**: `ecommerce-stage`
- **Replicas**: 2 per service
- **Resources**: Medium allocation for integration testing
- **Profile**: `stage` with INFO logging
- **Purpose**: Pre-production testing and validation

### Production Environment
- **Namespace**: `ecommerce-prod`
- **Replicas**: 3 per service (with blue-green deployment support)
- **Resources**: High allocation for production workloads
- **Profile**: `prod` with WARN logging
- **Security**: Enhanced security context and read-only filesystem
- **Purpose**: Live production environment

## Configuration Management

### ConfigMaps

1. **ecommerce-config**: Main configuration containing:
   - Service discovery endpoints
   - Inter-service communication URLs
   - Spring profiles and JVM options
   - Zipkin tracing configuration

2. **Environment-specific configs**:
   - `app-config-dev`: Development settings
   - `app-config-stage`: Staging settings
   - `app-config-prod`: Production settings

### Secrets

- **app-secrets**: Contains sensitive data
  - Database credentials
  - JWT secrets
  - Other sensitive configuration

## Resource Management

### Resource Allocation Strategy

| Service | Environment | CPU Request | CPU Limit | Memory Request | Memory Limit |
|---------|-------------|-------------|-----------|----------------|--------------|
| API Gateway | Dev | 250m | 500m | 384Mi | 512Mi |
| API Gateway | Prod | 500m | 1000m | 512Mi | 1Gi |
| Payment Service | All | 250m | 500m | 512Mi | 768Mi |
| Other Services | Dev | 250m | 500m | 384Mi | 512Mi |
| Other Services | Prod | 500m | 1000m | 512Mi | 1Gi |

### Health Checks

All services implement comprehensive health monitoring:

- **Readiness Probes**: 
  - Initial delay: 60-120 seconds
  - Period: 10-15 seconds
  - Endpoint: `/actuator/health`

- **Liveness Probes**:
  - Initial delay: 120-180 seconds
  - Period: 30 seconds
  - Endpoint: `/actuator/health`

## Deployment Strategies

### Blue-Green Deployment (Production)

The production environment supports blue-green deployments:
- Services are labeled with color tags (`blue`/`green`)
- Traffic switching via service selector updates
- Zero-downtime deployments

### Rolling Updates (Staging)

Staging environment uses rolling update strategy:
- Gradual replacement of instances
- Ensures continuous availability during updates

## Network Architecture

### Service Communication

- **Internal Communication**: ClusterIP services for inter-service calls
- **External Access**: NodePort for API Gateway
- **Service Discovery**: Eureka-based service registration

### Network Policies

Services communicate using Kubernetes DNS:
```
http://service-name.namespace.svc.cluster.local:port
```

Example:
```
http://user-service.ecommerce.svc.cluster.local:8700
```

## Deployment Instructions

### Prerequisites

- Minikube installed and configured
- Docker installed
- kubectl configured
- Minimum 6GB RAM and 6 CPU cores allocated to Minikube

### Quick Start

1. **Start Minikube**:
   ```bash
   minikube start --driver=docker --cpus=6 --memory=6144
   ```

2. **Deploy All Services**:
   ```bash
   chmod +x deploy.sh
   ./deploy.sh
   ```

3. **Access Services**:
   ```bash
   # API Gateway
   minikube service api-gateway -n ecommerce
   
   # Zipkin Dashboard
   minikube service zipkin -n ecommerce
   ```

### Manual Deployment

1. **Create Namespaces**:
   ```bash
   kubectl apply -f namespaces.yaml
   ```

2. **Apply Configuration**:
   ```bash
   kubectl apply -f ecommerce-config.yaml
   kubectl apply -f environments-config.yaml
   ```

3. **Deploy Core Services**:
   ```bash
   kubectl apply -f core-services.yaml
   ```

4. **Deploy Microservices**:
   ```bash
   kubectl apply -f microservices.yaml
   ```

### Environment-Specific Deployment

For specific environments, use the template files with environment variables:

```bash
# Development
export SERVICE_NAME=api-gateway
export SERVICE_PORT=8080
export DOCKER_REGISTRY=juanmadiaz45
export IMAGE_TAG=latest
envsubst < dev-deployment.yaml | kubectl apply -f -
```

## Monitoring and Observability

### Service Monitoring

- **Health Endpoints**: All services expose `/actuator/health`
- **Distributed Tracing**: Zipkin integration for request tracing
- **Logging**: Structured logging with environment-specific levels

### Debugging Commands

```bash
# Check pod status
kubectl get pods -n ecommerce

# View logs
kubectl logs -f deployment/api-gateway -n ecommerce

# Monitor pod status
kubectl get pods -n ecommerce -w

# Describe service issues
kubectl describe pod <pod-name> -n ecommerce
```
