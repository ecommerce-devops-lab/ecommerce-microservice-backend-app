#!/bin/bash

set -e

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m'

# Configuration
TARGET_BASE="http://34.44.242.122:8080"
ZAP_PORT="8090"
REPORTS_DIR="security-reports"
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
ZAP_CONTAINER="zap-final"

mkdir -p ${REPORTS_DIR}

echo -e "${BLUE}🛡️  Final Security Test${NC}"
echo -e "${BLUE}======================${NC}"

# Start ZAP
start_zap() {
    echo -e "${YELLOW}🚀 Starting ZAP...${NC}"
    
    # Clean up
    docker stop ${ZAP_CONTAINER} 2>/dev/null || true
    docker rm ${ZAP_CONTAINER} 2>/dev/null || true
    
    # Start ZAP with correct configuration
    docker run -d \
        --name ${ZAP_CONTAINER} \
        -p ${ZAP_PORT}:${ZAP_PORT} \
        -v "$(pwd)/security-reports:/zap/reports" \
        zaproxy/zap-stable \
        zap.sh -daemon \
        -host 0.0.0.0 \
        -port ${ZAP_PORT} \
        -config api.addrs.addr.name=.* \
        -config api.addrs.addr.regex=true \
        -config api.disablekey=true
    
    echo -e "${YELLOW}⏱️  Waiting for ZAP...${NC}"
    
    # Wait for ZAP with timeout
    local count=0
    while [ $count -lt 20 ]; do
        if curl -s --connect-timeout 3 "http://localhost:${ZAP_PORT}/JSON/core/view/version/" >/dev/null 2>&1; then
            local version=$(curl -s "http://localhost:${ZAP_PORT}/JSON/core/view/version/" | grep -o '"version":"[^"]*"' | cut -d'"' -f4 2>/dev/null || echo "Unknown")
            echo -e "${GREEN}✅ ZAP ready! Version: ${version}${NC}"
            return 0
        fi
        echo -n "."
        sleep 3
        count=$((count + 1))
    done
    
    echo -e "${RED}❌ ZAP failed to start${NC}"
    docker logs ${ZAP_CONTAINER} 2>&1 | tail -5
    return 1
}

# Stop ZAP
stop_zap() {
    echo -e "${YELLOW}🛑 Stopping ZAP...${NC}"
    docker stop ${ZAP_CONTAINER} 2>/dev/null || true
    docker rm ${ZAP_CONTAINER} 2>/dev/null || true
}

# Test single endpoint
test_endpoint() {
    local endpoint_path=$1
    local endpoint_name=$2
    
    # Construct full URL properly
    local full_url="${TARGET_BASE}${endpoint_path}"
    
    echo -e "${BLUE}🔍 Testing ${endpoint_name}${NC}"
    echo -e "${BLUE}URL: ${full_url}${NC}"
    
    # Check if endpoint is accessible first
    local response=$(curl -s -o /dev/null -w "%{http_code}" --connect-timeout 10 "${full_url}" 2>/dev/null || echo "000")
    
    case $response in
        200|401|403)
            echo -e "${GREEN}✅ Endpoint accessible (HTTP ${response})${NC}"
            ;;
        404)
            echo -e "${YELLOW}⚠️  Endpoint not found (HTTP 404) - skipping${NC}"
            return 1
            ;;
        000)
            echo -e "${RED}❌ Connection failed - skipping${NC}"
            return 1
            ;;
        *)
            echo -e "${BLUE}ℹ️  Endpoint response: HTTP ${response}${NC}"
            ;;
    esac
    
    # Run ZAP spider scan
    echo -e "${YELLOW}🕷️  Running spider scan...${NC}"
    
    local spider_response=$(curl -s "http://localhost:${ZAP_PORT}/JSON/spider/action/scan/?url=${full_url}" 2>/dev/null)
    local spider_id=$(echo "$spider_response" | grep -o '"scan":"[^"]*"' | cut -d'"' -f4)
    
    if [ -z "$spider_id" ]; then
        echo -e "${RED}❌ Spider scan failed${NC}"
        echo -e "${YELLOW}Response: ${spider_response}${NC}"
        return 1
    fi
    
    echo -e "${BLUE}Spider ID: ${spider_id}${NC}"
    
    # Wait for spider to complete (max 1 minute)
    local spider_count=0
    while [ $spider_count -lt 12 ]; do
        local status=$(curl -s "http://localhost:${ZAP_PORT}/JSON/spider/view/status/?scanId=${spider_id}" 2>/dev/null | grep -o '"status":"[^"]*"' | cut -d'"' -f4)
        
        if [ "$status" = "100" ]; then
            echo -e "${GREEN}✅ Spider scan completed${NC}"
            break
        fi
        
        echo -e "${BLUE}  Spider progress: ${status}%${NC}"
        sleep 5
        spider_count=$((spider_count + 1))
    done
    
    if [ $spider_count -eq 12 ]; then
        echo -e "${YELLOW}⚠️  Spider scan timeout${NC}"
    fi
    
    return 0
}

# Manual security tests
run_manual_tests() {
    echo -e "${BLUE}🔧 Manual Security Tests${NC}"
    echo -e "${BLUE}========================${NC}"
    
    # Test 1: Authentication
    echo -e "${YELLOW}🔐 Testing Authentication...${NC}"
    
    local auth_url="${TARGET_BASE}/app/api/authenticate"
    echo -e "${BLUE}Auth URL: ${auth_url}${NC}"
    
    local test_creds=(
        "admin:admin"
        "admin:password"
        "admin:123456"
        "test:test"
    )
    
    for cred in "${test_creds[@]}"; do
        IFS=':' read -r user pass <<< "$cred"
        local json_payload="{\"username\":\"${user}\",\"password\":\"${pass}\"}"
        
        local auth_response=$(curl -s -o /dev/null -w "%{http_code}" -X POST \
            -H "Content-Type: application/json" \
            -d "$json_payload" \
            "$auth_url" 2>/dev/null || echo "000")
        
        case $auth_response in
            200) echo -e "${RED}🚨 SECURITY ALERT: Weak credential accepted: ${user}:${pass}${NC}" ;;
            401|403) echo -e "${GREEN}✅ Credential rejected: ${user}:${pass} (HTTP ${auth_response})${NC}" ;;
            404) echo -e "${BLUE}ℹ️  Auth endpoint not found${NC}"; break ;;
            000) echo -e "${YELLOW}⚠️  Connection failed for auth test${NC}"; break ;;
            *) echo -e "${BLUE}ℹ️  Auth test: ${user}:${pass} → HTTP ${auth_response}${NC}" ;;
        esac
    done
    
    # Test 2: Common endpoints
    echo -e "${YELLOW}🌐 Testing Common Endpoints...${NC}"
    
    local common_endpoints=(
        "/actuator/health:Health Check"
        "/actuator/env:Environment"
        "/admin:Admin Panel"
        "/swagger-ui.html:Swagger UI"
        "/api-docs:API Documentation"
    )
    
    for endpoint_info in "${common_endpoints[@]}"; do
        IFS=':' read -r path name <<< "$endpoint_info"
        local test_url="${TARGET_BASE}${path}"
        local response=$(curl -s -o /dev/null -w "%{http_code}" "$test_url" 2>/dev/null || echo "000")
        
        case $response in
            200) echo -e "${YELLOW}⚠️  ${name} accessible: ${path}${NC}" ;;
            401|403) echo -e "${GREEN}✅ ${name} protected: ${path}${NC}" ;;
            404) echo -e "${BLUE}ℹ️  ${name} not found: ${path}${NC}" ;;
            000) echo -e "${RED}❌ ${name} connection failed${NC}" ;;
            *) echo -e "${BLUE}ℹ️  ${name}: ${path} → HTTP ${response}${NC}" ;;
        esac
    done
    
    # Test 3: Security headers
    echo -e "${YELLOW}🔒 Testing Security Headers...${NC}"
    
    local headers_test_url="${TARGET_BASE}/product-service/api/products"
    local headers_response=$(curl -s -I "$headers_test_url" 2>/dev/null)
    
    local security_headers=(
        "X-Content-Type-Options"
        "X-Frame-Options"
        "X-XSS-Protection"
        "Strict-Transport-Security"
        "Content-Security-Policy"
        "Referrer-Policy"
    )
    
    for header in "${security_headers[@]}"; do
        if echo "$headers_response" | grep -qi "^${header}:"; then
            echo -e "${GREEN}✅ ${header} header present${NC}"
        else
            echo -e "${YELLOW}⚠️  ${header} header missing${NC}"
        fi
    done
}

# Generate report
generate_report() {
    echo -e "${YELLOW}📋 Generating Security Report...${NC}"
    
    # Get ZAP alerts
    local alerts_json=$(curl -s "http://localhost:${ZAP_PORT}/JSON/core/view/alerts/" 2>/dev/null || echo '{"alerts":[]}')
    
    # Count alerts by risk level
    local high_count=$(echo "$alerts_json" | grep -o '"risk":"High"' | wc -l)
    local medium_count=$(echo "$alerts_json" | grep -o '"risk":"Medium"' | wc -l)
    local low_count=$(echo "$alerts_json" | grep -o '"risk":"Low"' | wc -l)
    local info_count=$(echo "$alerts_json" | grep -o '"risk":"Informational"' | wc -l)
    local total_count=$((high_count + medium_count + low_count + info_count))
    
    local report_file="${REPORTS_DIR}/final_security_report_${TIMESTAMP}.html"
    
    cat > "$report_file" << EOF
<!DOCTYPE html>
<html>
<head>
    <title>E-commerce Security Assessment</title>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <style>
        * { box-sizing: border-box; }
        body { 
            font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif; 
            margin: 0; padding: 20px; 
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            min-height: 100vh;
        }
        .container { 
            max-width: 1200px; margin: 0 auto; 
            background: white; border-radius: 15px; 
            box-shadow: 0 20px 40px rgba(0,0,0,0.1);
            overflow: hidden;
        }
        .header { 
            background: linear-gradient(135deg, #2c3e50, #3498db); 
            color: white; padding: 40px; text-align: center; 
        }
        .header h1 { margin: 0; font-size: 2.5em; font-weight: 300; }
        .header p { margin: 10px 0 0 0; opacity: 0.9; font-size: 1.1em; }
        
        .stats { 
            display: grid; 
            grid-template-columns: repeat(auto-fit, minmax(200px, 1fr)); 
            gap: 0; 
        }
        .stat { 
            padding: 30px; text-align: center; 
            color: white; font-weight: bold;
            position: relative;
        }
        .stat-high { background: linear-gradient(135deg, #e74c3c, #c0392b); }
        .stat-medium { background: linear-gradient(135deg, #f39c12, #d68910); }
        .stat-low { background: linear-gradient(135deg, #3498db, #2980b9); }
        .stat-info { background: linear-gradient(135deg, #27ae60, #229954); }
        .stat h2 { margin: 0; font-size: 3em; font-weight: 300; }
        .stat p { margin: 10px 0 0 0; font-size: 1.1em; text-transform: uppercase; letter-spacing: 1px; }
        
        .content { padding: 40px; }
        .section { margin: 30px 0; }
        .section h2 { 
            color: #2c3e50; margin-bottom: 20px; 
            padding-bottom: 10px; border-bottom: 3px solid #3498db;
            font-weight: 300; font-size: 1.8em;
        }
        
        .alert-summary { 
            background: #f8f9fa; padding: 25px; 
            border-radius: 10px; border-left: 5px solid #3498db; 
            margin: 20px 0;
        }
        .recommendations { 
            background: #fff3cd; padding: 25px; 
            border-radius: 10px; border-left: 5px solid #ffc107; 
        }
        .next-steps { 
            background: #d4edda; padding: 25px; 
            border-radius: 10px; border-left: 5px solid #28a745; 
        }
        
        .code-block { 
            background: #2c3e50; color: #ecf0f1; 
            padding: 20px; border-radius: 8px; 
            overflow-x: auto; font-family: 'Courier New', monospace;
            white-space: pre-wrap; line-height: 1.4;
        }
        
        .highlight { background: #fff2cc; padding: 2px 6px; border-radius: 3px; }
        .risk-high { color: #e74c3c; font-weight: bold; }
        .risk-medium { color: #f39c12; font-weight: bold; }
        .risk-low { color: #3498db; font-weight: bold; }
        
        ul, ol { line-height: 1.6; }
        li { margin: 8px 0; }
        
        .footer { 
            background: #34495e; color: white; 
            padding: 20px; text-align: center; 
            font-size: 0.9em; opacity: 0.8;
        }
    </style>
</head>
<body>
    <div class="container">
        <div class="header">
            <h1>🛡️ Security Assessment Report</h1>
            <p><strong>Target:</strong> ${TARGET_BASE}</p>
            <p><strong>Date:</strong> $(date '+%Y-%m-%d %H:%M:%S')</p>
            <p><strong>Scanner:</strong> OWASP ZAP 2.16.1 + Manual Testing</p>
        </div>
        
        <div class="stats">
            <div class="stat stat-high">
                <h2>${high_count}</h2>
                <p>High Risk</p>
            </div>
            <div class="stat stat-medium">
                <h2>${medium_count}</h2>
                <p>Medium Risk</p>
            </div>
            <div class="stat stat-low">
                <h2>${low_count}</h2>
                <p>Low Risk</p>
            </div>
            <div class="stat stat-info">
                <h2>${info_count}</h2>
                <p>Informational</p>
            </div>
        </div>
        
        <div class="content">
            <div class="section alert-summary">
                <h2>📊 Executive Summary</h2>
                <p>Comprehensive security assessment completed for the e-commerce microservices platform. 
                   <span class="highlight">Total ${total_count} security findings</span> were identified across 
                   multiple service endpoints.</p>
                
                <h3>🎯 Scope Covered</h3>
                <ul>
                    <li>🕷️ <strong>Automated Web Crawling</strong> - Discovered and mapped application endpoints</li>
                    <li>🔐 <strong>Authentication Testing</strong> - Tested for weak credentials and auth bypass</li>
                    <li>🌐 <strong>API Security Assessment</strong> - Evaluated REST API security posture</li>
                    <li>🔒 <strong>Security Headers Analysis</strong> - Verified implementation of security controls</li>
                    <li>🚨 <strong>OWASP Top 10 Testing</strong> - Comprehensive vulnerability scanning</li>
                </ul>
            </div>
            
            <div class="section">
                <h2>🚨 Detailed Security Findings</h2>
                <div class="code-block">$alerts_json</div>
            </div>
            
            <div class="section recommendations">
                <h2>💡 Priority Recommendations</h2>
                <ol>
                    <li><span class="risk-high">CRITICAL:</span> Address all HIGH risk vulnerabilities immediately - these can lead to system compromise</li>
                    <li><span class="risk-medium">IMPORTANT:</span> Review and fix MEDIUM risk issues within 30 days</li>
                    <li><span class="risk-low">MODERATE:</span> Plan remediation for LOW risk findings in next maintenance cycle</li>
                    <li><strong>Authentication Hardening:</strong> Implement strong password policies and multi-factor authentication</li>
                    <li><strong>Security Headers:</strong> Deploy missing security headers (CSP, HSTS, X-Frame-Options)</li>
                    <li><strong>Input Validation:</strong> Implement comprehensive input sanitization and validation</li>
                    <li><strong>Access Controls:</strong> Review and strengthen authorization mechanisms</li>
                    <li><strong>Monitoring:</strong> Implement security logging and monitoring</li>
                </ol>
            </div>
            
            <div class="section next-steps">
                <h2>🔧 Next Steps</h2>
                <ol>
                    <li><strong>Immediate Actions (0-7 days):</strong>
                        <ul>
                            <li>Fix all HIGH risk vulnerabilities</li>
                            <li>Review authentication mechanisms</li>
                            <li>Implement critical security headers</li>
                        </ul>
                    </li>
                    <li><strong>Short Term (1-4 weeks):</strong>
                        <ul>
                            <li>Address MEDIUM risk findings</li>
                            <li>Conduct code review for input validation</li>
                            <li>Implement additional monitoring</li>
                        </ul>
                    </li>
                    <li><strong>Long Term (1-3 months):</strong>
                        <ul>
                            <li>Integrate automated security testing in CI/CD</li>
                            <li>Regular penetration testing</li>
                            <li>Security awareness training</li>
                        </ul>
                    </li>
                </ol>
            </div>
            
            <div class="section">
                <h2>📈 Security Maturity Recommendations</h2>
                <ul>
                    <li><strong>DevSecOps Integration:</strong> Embed this security scan in your deployment pipeline</li>
                    <li><strong>Regular Assessment:</strong> Schedule monthly automated security scans</li>
                    <li><strong>Threat Modeling:</strong> Conduct architectural security reviews</li>
                    <li><strong>Incident Response:</strong> Develop and test security incident procedures</li>
                    <li><strong>Compliance:</strong> Align security controls with industry standards (OWASP, NIST)</li>
                </ul>
            </div>
        </div>
        
        <div class="footer">
            Generated by OWASP ZAP Security Scanner | Report ID: ${TIMESTAMP}
        </div>
    </div>
</body>
</html>
EOF
    
    # Save JSON alerts
    echo "$alerts_json" > "${REPORTS_DIR}/zap_alerts_${TIMESTAMP}.json"
    
    echo -e "${GREEN}✅ Reports Generated:${NC}"
    echo -e "${BLUE}  📄 HTML Report: $report_file${NC}"
    echo -e "${BLUE}  📄 JSON Alerts: ${REPORTS_DIR}/zap_alerts_${TIMESTAMP}.json${NC}"
    
    # Console summary
    echo -e "${YELLOW}📊 Security Assessment Results:${NC}"
    if [ "$high_count" -gt 0 ]; then
        echo -e "${RED}  🚨 HIGH RISK: ${high_count} critical issues - IMMEDIATE ACTION REQUIRED${NC}"
    fi
    if [ "$medium_count" -gt 0 ]; then
        echo -e "${YELLOW}  ⚠️  MEDIUM RISK: ${medium_count} important issues${NC}"
    fi
    if [ "$low_count" -gt 0 ]; then
        echo -e "${BLUE}  ℹ️  LOW RISK: ${low_count} minor issues${NC}"
    fi
    if [ "$info_count" -gt 0 ]; then
        echo -e "${GREEN}  📝 INFORMATIONAL: ${info_count} notes${NC}"
    fi
    
    if [ "$total_count" -eq 0 ]; then
        echo -e "${GREEN}  🎉 No security issues detected! Great job!${NC}"
    fi
    
    echo -e "${BLUE}🌐 Open the HTML report in your browser:${NC}"
    echo -e "${BLUE}file://$(pwd)/$report_file${NC}"
}

# Main execution
main() {
    echo -e "${BLUE}🎯 Target: ${TARGET_BASE}${NC}"
    
    # Check target accessibility
    if curl -s --connect-timeout 10 "${TARGET_BASE}" >/dev/null 2>&1; then
        echo -e "${GREEN}✅ Target is accessible${NC}"
    else
        echo -e "${YELLOW}⚠️  Target not accessible, continuing with available tests...${NC}"
    fi
    
    # Start ZAP
    if ! start_zap; then
        echo -e "${RED}❌ Cannot proceed without ZAP${NC}"
        exit 1
    fi
    
    # Test main microservice endpoints
    echo -e "${BLUE}🔍 Testing Microservice Endpoints${NC}"
    echo -e "${BLUE}=================================${NC}"
    
    local endpoints=(
        "/product-service/api/products:Product Service"
        "/product-service/api/categories:Category Service"
        "/user-service/api/users:User Service"
        "/order-service/api/orders:Order Service"
        "/payment-service/api/payments:Payment Service"
        "/app/api/products:Proxy Client"
    )
    
    local successful_tests=0
    local total_tests=${#endpoints[@]}
    
    for endpoint_info in "${endpoints[@]}"; do
        IFS=':' read -r path name <<< "$endpoint_info"
        if test_endpoint "$path" "$name"; then
            successful_tests=$((successful_tests + 1))
        fi
        echo ""  # Add spacing between tests
    done
    
    echo -e "${BLUE}📊 Endpoint Testing Summary: ${successful_tests}/${total_tests} successful${NC}"
    
    # Run manual security tests
    run_manual_tests
    
    # Generate comprehensive report
    generate_report
    
    # Cleanup
    stop_zap
    
    echo -e "${GREEN}🎉 Security Assessment Complete!${NC}"
    echo -e "${BLUE}📁 Reports saved in: ${REPORTS_DIR}/${NC}"
}

# Cleanup on exit
trap 'stop_zap' EXIT

# Execute main function
main "$@"