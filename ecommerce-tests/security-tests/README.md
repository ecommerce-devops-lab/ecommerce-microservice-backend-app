# Security Testing Guide

## Overview

This comprehensive security testing suite provides automated vulnerability assessment for the e-commerce microservices architecture using OWASP ZAP (Zed Attack Proxy) and custom Python security tests. The suite covers all microservices and implements industry-standard security testing practices.

## Prerequisites

- Docker and Docker Compose installed
- Python 3.7+ with pip
- Network connectivity to the target deployment
- At least 4GB available RAM for ZAP container

## Architecture Coverage

The security testing suite covers all microservices:

- **Product Service** (`/product-service/api/*`)
- **User Service** (`/user-service/api/*`)
- **Order Service** (`/order-service/api/*`)
- **Payment Service** (`/payment-service/api/*`)
- **Favourite Service** (`/favourite-service/api/*`)
- **Shipping Service** (`/shipping-service/api/*`)
- **Proxy Client** (`/app/api/*`)

## Setup Instructions

### 1. Install Python Dependencies

```bash
cd security-tests
pip install -r requirements.txt
```

### 2. Grant Script Permissions

```bash
chmod +x run-security-tests.sh
```

### 3. Create Required Directories

```bash
mkdir -p security-reports zap-sessions dependency-reports ssl-reports nikto-reports nuclei-reports
```

### 4. Pull Required Docker Images

```bash
# OWASP ZAP (Primary security scanner)
docker pull zaproxy/zap-stable:latest

# Additional security tools (optional)
docker pull owasp/dependency-check:latest
docker pull sullo/nikto:latest
docker pull projectdiscovery/nuclei:latest
docker pull drwetter/testssl.sh:latest
```

## Configuration

### Target Configuration

Update the target URL in the following files:

**For Local Testing:**
```bash
# Update in run-security-tests.sh
TARGET_BASE="http://localhost:8080"

# Update in security_test_suite.py
SecurityTestSuite(base_url="http://localhost:8080")
```

**For Cloud Testing:**
```bash
# Update in run-security-tests.sh  
TARGET_BASE="http://34.44.242.122:8080"

# Update in security_test_suite.py
SecurityTestSuite(base_url="http://34.44.242.122:8080")
```

**Update ZAP Automation Config:**
```yaml
# Edit zap-config/automation.yml
env:
  contexts:
    - name: "E-commerce-Context"
      urls:
        - "http://your-target-url:port"
```

## Execution Methods

### Method 1: Quick Security Scan

Execute the comprehensive security testing script:

```bash
./run-security-tests.sh
```

This script will:
- ✅ Start OWASP ZAP in daemon mode
- 🕷️ Perform web crawling on all microservices  
- 🔍 Execute vulnerability scans
- 🔐 Test authentication bypass attempts
- 🛡️ Check security headers
- 📊 Generate comprehensive HTML and JSON reports
- 🧹 Clean up containers automatically

### Method 2: Python Security Test Suite

Run specific security tests:

```bash
# Run all security tests
python security_test_suite.py --url http://34.44.242.122:8080

# Run specific test categories
python security_test_suite.py --test sql --url http://34.44.242.122:8080
python security_test_suite.py --test xss --url http://34.44.242.122:8080
python security_test_suite.py --test auth --url http://34.44.242.122:8080
python security_test_suite.py --test cors --url http://34.44.242.122:8080
python security_test_suite.py --test headers --url http://34.44.242.122:8080
```

### Method 3: Docker Compose Security Suite

Run multiple security tools simultaneously:

```bash
# Start all security testing containers
docker-compose -f docker-compose.security.yml up -d

# Check container status
docker-compose -f docker-compose.security.yml ps

# View logs
docker-compose -f docker-compose.security.yml logs zap
docker-compose -f docker-compose.security.yml logs dependency-check

# Stop all containers
docker-compose -f docker-compose.security.yml down
```

### Method 4: Manual ZAP Setup

For advanced users who want manual control:

```bash
# Start ZAP in daemon mode
docker run -d --name zap-manual \
  -p 8090:8080 \
  -v $(pwd)/security-reports:/zap/reports \
  -v $(pwd)/zap-sessions:/zap/sessions \
  zaproxy/zap-stable \
  zap.sh -daemon -host 0.0.0.0 -port 8080 \
  -config api.disablekey=true

# Access ZAP Web UI (optional)
# http://localhost:8090

# Manual scan via API
curl "http://localhost:8090/JSON/spider/action/scan/?url=http://34.44.242.122:8080"

# Get scan status
curl "http://localhost:8090/JSON/spider/view/status/"

# Generate report
curl "http://localhost:8090/OTHER/core/other/htmlreport/" > security-reports/manual-report.html

# Stop container
docker stop zap-manual && docker rm zap-manual
```

## Security Test Categories

### Critical Security Tests

1. **SQL Injection Testing**
   - Tests authentication endpoints
   - Checks GET/POST parameters
   - Validates input sanitization

2. **Cross-Site Scripting (XSS)**
   - Reflected XSS in form fields
   - Stored XSS in user inputs
   - DOM-based XSS vulnerabilities

3. **Authentication Bypass**
   - Weak credential testing
   - Authentication logic flaws
   - Session management issues

4. **Authorization Testing**
   - Access control verification
   - Privilege escalation attempts
   - Protected endpoint access

### Additional Security Checks

5. **CORS Misconfiguration**
   - Cross-origin policy validation
   - Malicious origin testing

6. **Information Disclosure**
   - Sensitive file exposure
   - Debug information leakage
   - Configuration exposure

7. **HTTP Security Headers**
   - Content Security Policy
   - X-Frame-Options
   - HSTS implementation

8. **HTTP Methods Testing**
   - Dangerous method validation
   - TRACE/TRACK detection

## Understanding Reports

### HTML Security Report

The main security report (`security-reports/final_security_report_TIMESTAMP.html`) contains:

- **Executive Summary**: High-level security posture overview
- **Risk Statistics**: Categorized vulnerability counts
- **Detailed Findings**: Complete vulnerability descriptions
- **Recommendations**: Prioritized remediation guidance
- **Next Steps**: Implementation roadmap

### Report Severity Levels

- 🔴 **HIGH RISK**: Critical vulnerabilities requiring immediate attention
- 🟡 **MEDIUM RISK**: Important security issues to address within 30 days  
- 🔵 **LOW RISK**: Minor issues for next maintenance cycle
- 🟢 **INFORMATIONAL**: Security notes and best practices

### JSON Reports

Structured data reports for integration:
- `zap_alerts_TIMESTAMP.json`: Raw ZAP scan results
- `security_report_TIMESTAMP.json`: Processed findings

## Troubleshooting

### Common Issues and Solutions

**Issue: ZAP container fails to start**
```bash
# Check if port is in use
sudo netstat -tlnp | grep :8090

# Kill existing processes
sudo pkill -f zap

# Start with different port
docker run -d -p 8091:8080 zaproxy/zap-stable ...
```

**Issue: Target not accessible**
```bash
# Test connectivity
curl -I http://34.44.242.122:8080

# Check firewall/security groups
# Ensure target application is running
# Verify network routing
```

**Issue: Permission denied on scripts**
```bash
chmod +x run-security-tests.sh
chmod +x security_test_suite.py
```

**Issue: Python dependencies missing**
```bash
pip install --upgrade pip
pip install -r requirements.txt --no-cache-dir
```

**Issue: Docker out of memory**
```bash
# Increase Docker memory allocation to 4GB+
# Or run tests with reduced parallelism
docker run --memory=2g zaproxy/zap-stable ...
```

### Logs and Debugging

Enable verbose logging:
```bash
# Check ZAP container logs
docker logs zap-container-name

# Run Python tests with debug output
python security_test_suite.py --url http://target --test all -v

# Check detailed logs
tail -f security-tests.log
```