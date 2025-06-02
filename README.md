# eCommerce Microservices Platform

**Juan Manuel Díaz Moreno**

## Project Overview

This project implements a modern eCommerce platform built with Spring Boot microservices architecture, enhanced with comprehensive CI/CD pipelines, testing strategies, and cloud-native deployment practices. The application demonstrates enterprise-level software development practices including automated testing, continuous integration, and container orchestration.

### eCommerce Platform Features

The platform provides a complete online shopping experience with the following business capabilities:

- **User Management**: Customer registration, authentication, and profile management
- **Product Catalog**: Comprehensive product browsing, search, and inventory management
- **Shopping Experience**: Wishlist functionality and personalized recommendations
- **Order Processing**: Complete order lifecycle from cart to fulfillment
- **Payment Integration**: Secure payment processing and transaction management
- **Shipping & Delivery**: Order tracking and shipping management
- **Administrative Tools**: Backend management for products, orders, and users

### Microservices Architecture

The application follows cloud-native principles with the following service composition:

#### Core Services
- **API Gateway**: Centralized routing, load balancing, and request filtering
- **Service Discovery**: Eureka-based service registration and discovery
- **Configuration Server**: Centralized configuration management across environments
- **Authentication Service**: OAuth2-based security with JWT token management

#### Business Services
- **User Service**: Customer and admin user management
- **Product Service**: Product catalog, categories, and inventory
- **Favorites Service**: User wishlist and product recommendations
- **Order Service**: Order creation, management, and lifecycle tracking
- **Payment Service**: Payment processing and financial transactions
- **Shipping Service**: Delivery management and order fulfillment

### DevOps & Quality Practices

This project emphasizes modern software development practices including:

#### Continuous Integration & Delivery
- **Automated Build Pipelines**: Jenkins-based CI/CD for consistent and reliable deployments
- **Multi-Environment Strategy**: Development, staging, and production deployment workflows
- **Container Orchestration**: Kubernetes-based deployment with Docker containerization
- **Infrastructure as Code**: Automated environment provisioning and configuration

#### Comprehensive Testing Strategy
- **Unit Testing**: Component-level validation ensuring code quality and reliability
- **Integration Testing**: Service-to-service communication and API contract validation
- **End-to-End Testing**: Complete user workflow validation across the entire platform
- **Performance Testing**: Load testing and system capacity analysis using modern tools

#### Quality Assurance
- **Automated Code Analysis**: Static code analysis and quality gate enforcement
- **Test Coverage Monitoring**: Comprehensive test coverage tracking and reporting
- **Performance Monitoring**: Application metrics, distributed tracing, and observability
- **Release Management**: Automated release notes and change management practices

### Technology Stack

#### Backend Technologies
- **Java 11**: Core development platform
- **Spring Boot & Cloud**: Microservices framework with cloud-native features
- **Maven**: Build automation and dependency management
- **H2 & MySQL**: Multi-database strategy for different service requirements

#### DevOps & Infrastructure
- **Docker**: Application containerization and packaging
- **Kubernetes**: Container orchestration and cluster management
- **Jenkins**: Continuous integration and deployment automation
- **Prometheus & Zipkin**: Monitoring, metrics collection, and distributed tracing

#### Testing & Quality Tools
- **JUnit & Spring Boot Test**: Unit and integration testing frameworks
- **Locust**: Performance and load testing platform
- **SonarQube**: Code quality analysis and technical debt management

### System Architecture

The platform implements several enterprise patterns:

- **API Gateway Pattern**: Single entry point for all client requests
- **Service Registry Pattern**: Dynamic service discovery and registration
- **Circuit Breaker Pattern**: Fault tolerance and system resilience
- **Event-Driven Architecture**: Asynchronous communication between services
- **Database per Service**: Data isolation and service autonomy

### Getting Started

#### Prerequisites
- Java 11 JDK
- Docker Desktop
- Kubernetes cluster (minikube for development)
- Jenkins CI/CD server
- Git version control

#### Quick Start
```bash
# Clone the repository
git clone https://github.com/SelimHorri/ecommerce-microservice-backend-app.git

# Build all services
./mvnw clean package

# Start the platform
docker-compose -f compose.yml up -d
```

#### Service Access Points
- **API Gateway**: https://localhost:8900/swagger-ui.html
- **Service Registry**: http://localhost:8761/eureka
- **User Management**: https://localhost:8700/swagger-ui.html
- **Distributed Tracing**: http://localhost:9411/zipkin

### Key Features

#### For Developers
- Comprehensive testing suite with multiple testing levels
- Automated code quality checks and reporting
- Containerized development environment
- Hot-reload capabilities for rapid development

#### For Operations
- Kubernetes-ready deployment configurations
- Automated scaling and load balancing
- Health checks and monitoring dashboards
- Centralized logging and error tracking

#### For Business
- Scalable architecture supporting growth
- High availability and fault tolerance
- Performance optimization and monitoring
- Secure payment and user data handling

This project serves as a reference implementation for building production-ready microservices platforms with enterprise-grade DevOps practices, demonstrating how modern software development methodologies can be applied to create robust, scalable, and maintainable eCommerce solutions.
