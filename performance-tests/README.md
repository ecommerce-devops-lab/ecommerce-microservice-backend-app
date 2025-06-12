# Performance and Stress Testing Guide

## Overview

This performance testing suite provides comprehensive load testing for the e-commerce microservices architecture using Locust. It includes tests for all microservices with realistic user flows and scenarios.

## Prerequisites

- Python 3.7+
- E-commerce application running and accessible
- Network connectivity to the target deployment

## Setup Instructions

### 1. Install Dependencies

```bash
pip install -r requirements.txt
```

### 2. Initial Configuration

Grant execution permissions to the test script:

```bash
chmod +x run-performance-tests.sh
```

### 3. Environment Configuration

**For Local Testing:**
Update `locust.conf` with your local API Gateway URL:
```ini
host = http://localhost:8765
```

**For Cloud Testing:**
Update `locust.conf` with your cloud deployment URL:
```ini
host = http://your-api-gateway-url:port
```

## Test Execution

### Quick Start

Ensure your application is running and accessible before executing tests.

### Available Test Types

```bash
# Connectivity verification (recommended first run)
./run-performance-tests.sh debug

# Quick validation test
./run-performance-tests.sh quick

# Standard performance test
./run-performance-tests.sh performance

# Sustained load test
./run-performance-tests.sh load

# High stress test
./run-performance-tests.sh stress

# Traffic spike test
./run-performance-tests.sh spike

# Complete performance test suite
./run-performance-tests.sh suite

# Stress testing suite
./run-performance-tests.sh stress-suite
```

## Microservices Coverage

The testing suite covers all microservices through their correct API Gateway routes:

### 1. **Product Service**
- Product catalog (`/product-service/api/products`)
- Category management (`/product-service/api/categories`)
- Full CRUD operations

### 2. **User Service**
- User management (`/user-service/api/users`)
- Address management (`/user-service/api/address`)
- Credential management (`/user-service/api/credentials`)
- Verification tokens (`/user-service/api/verificationTokens`)

### 3. **Order Service**
- Order management (`/order-service/api/orders`)
- Cart management (`/order-service/api/carts`)
- Complete checkout flow

### 4. **Payment Service**
- Payment processing (`/payment-service/api/payments`)
- Payment status tracking (PENDING, COMPLETED, etc.)

### 5. **Favourite Service**
- Favorites management (`/favourite-service/api/favourites`)
- User-specific operations

### 6. **Shipping Service**
- Order items management (`/shipping-service/api/shippings`)
- Shipping coordination

### 7. **Proxy Client Service** (if available)
- Aggregated endpoints (`/app/api/*`)
- Authentication (`/app/api/authenticate`)

## Test Scenarios

### Performance Tests
- **Debug Test**: 5 users, 1 minute (connectivity verification)
- **Quick Test**: 20 users, 2 minutes (rapid validation)
- **Performance Test**: 50 users, 5 minutes (baseline performance)
- **Load Test**: 75 users, 10 minutes (sustained load)

### Stress Tests
- **Stress Test**: 150 users, 5 minutes (high load)
- **Spike Test**: 300 users, 3 minutes (traffic spikes)

### User Behavior Patterns

The tests simulate realistic e-commerce user behavior:

- **Catalog Browsing** (40% of activity): Product and category navigation
- **Order Management** (25% of activity): Cart and order operations
- **User Operations** (20% of activity): User profile and address management
- **Payment Processing** (10% of activity): Payment workflow
- **Checkout Flow** (5% of activity): Complete purchase process

### Recommended Test Sequence

1. **Start with Debug**: Verify system connectivity and basic functionality
   ```bash
   ./run-simple-tests.sh debug
   ```

2. **Development Phase**: Use performance and load tests
   ```bash
   ./run-simple-tests.sh performance
   ./run-simple-tests.sh load
   ```

3. **Pre-Production**: Execute stress tests to find limits
   ```bash
   ./run-simple-tests.sh stress
   ./run-simple-tests.sh spike
   ```

4. **Production Readiness**: Run complete test suite
   ```bash
   ./run-simple-tests.sh suite
   ```

### Configuration Files

- **`locustfile.py`**: Main test scenarios and user behaviors
- **`locust.conf`**: Basic Locust configuration
- **`run-performance-tests.sh`**: Test execution script
- **`requirements.txt`**: Python dependencies

### Environment-Specific Testing

The test suite supports multiple deployment environments:
- Local development
- Staging/testing environments  
- Production cloud deployments

Update the host URL in `locust.conf` according to your target environment.