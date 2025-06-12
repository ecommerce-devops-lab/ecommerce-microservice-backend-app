#!/bin/bash

set -e

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m'

# Configuration
HOST_URL="http://34.44.242.122:8080"
REPORTS_DIR="reports"
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
LOCUST_FILE="locustfile.py"

mkdir -p ${REPORTS_DIR}

echo -e "${BLUE}🚀 E-commerce Performance Testing (Simplified)${NC}"
echo -e "${BLUE}=============================================${NC}"

# Function to check system health with correct endpoints
check_system_health() {
    echo -e "${YELLOW}🔍 Checking system availability...${NC}"
    
    # Check API Gateway health
    if curl -f -s --connect-timeout 10 --max-time 30 "${HOST_URL}/actuator/health" > /dev/null 2>&1; then
        echo -e "${GREEN}✅ API Gateway health endpoint accessible${NC}"
    else
        echo -e "${YELLOW}⚠️  Health endpoint not available, checking services...${NC}"
    fi
    
    # Check actual microservice endpoints (through API Gateway)
    services=(
        "product-service/api/products:Products"
        "product-service/api/categories:Categories" 
        "user-service/api/users:Users"
        "order-service/api/orders:Orders"
        "order-service/api/carts:Carts"
        "payment-service/api/payments:Payments"
        "favourite-service/api/favourites:Favourites"
        "shipping-service/api/shippings:Shipping"
    )
    
    for service_info in "${services[@]}"; do
        IFS=':' read -r endpoint name <<< "$service_info"
        
        response=$(curl -s -o /dev/null -w "%{http_code}" --connect-timeout 5 --max-time 15 "${HOST_URL}/${endpoint}")
        
        if [[ "$response" =~ ^[23] ]]; then
            echo -e "${GREEN}✅ ${name} service accessible (HTTP $response)${NC}"
        elif [[ "$response" == "401" || "$response" == "403" ]]; then
            echo -e "${GREEN}✅ ${name} service accessible but requires auth (HTTP $response)${NC}"
        else
            echo -e "${YELLOW}⚠️  ${name} service returned HTTP $response${NC}"
        fi
    done
    
    # Test proxy-client if available
    proxy_response=$(curl -s -o /dev/null -w "%{http_code}" --connect-timeout 5 --max-time 15 "${HOST_URL}/app/api/products")
    if [[ "$proxy_response" =~ ^[23] ]]; then
        echo -e "${GREEN}✅ Proxy client accessible${NC}"
    else
        echo -e "${YELLOW}⚠️  Proxy client not accessible (HTTP $proxy_response)${NC}"
    fi
    
    echo -e "${GREEN}✅ System health check completed${NC}"
}

# Function to run a test with specified parameters
run_test() {
    local test_name=$1
    local users=$2
    local spawn_rate=$3
    local duration=$4
    
    echo -e "${BLUE}📊 Running ${test_name}: ${users} users, ${spawn_rate} spawn rate, ${duration}${NC}"
    
    locust \
        --host="$HOST_URL" \
        --users=$users \
        --spawn-rate=$spawn_rate \
        --run-time=$duration \
        --headless \
        --html="${REPORTS_DIR}/${test_name}_${TIMESTAMP}.html" \
        --csv="${REPORTS_DIR}/${test_name}_${TIMESTAMP}" \
        --logfile="${REPORTS_DIR}/${test_name}_${TIMESTAMP}.log" \
        -f "$LOCUST_FILE"
    
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✅ ${test_name} completed successfully${NC}"
    else
        echo -e "${RED}❌ ${test_name} failed${NC}"
        return 1
    fi
}

# Test configurations
run_debug_test() {
    echo -e "${YELLOW}🐛 Running debug test...${NC}"
    run_test "debug_test" 5 1 "60s"
}

run_quick_test() {
    echo -e "${YELLOW}🚀 Running quick test...${NC}"
    run_test "quick_test" 20 5 "120s"
}

run_performance_test() {
    echo -e "${YELLOW}🎯 Running performance test...${NC}"
    run_test "performance_test" 50 8 "300s"
}

run_load_test() {
    echo -e "${YELLOW}💪 Running load test...${NC}"
    run_test "load_test" 75 10 "600s"
}

run_stress_test() {
    echo -e "${YELLOW}🔥 Running stress test...${NC}"
    run_test "stress_test" 150 20 "300s"
}

run_spike_test() {
    echo -e "${YELLOW}⚡ Running spike test...${NC}"
    run_test "spike_test" 300 50 "180s"
}

# Generate summary
generate_summary() {
    echo -e "${BLUE}📋 Generating summary...${NC}"
    
    summary_file="${REPORTS_DIR}/test_summary_${TIMESTAMP}.txt"
    
    cat > ${summary_file} << EOF
E-commerce Performance Test Summary
==================================
Test Date: $(date)
Host: ${HOST_URL}
Locust Version: $(locust --version 2>/dev/null || echo "Unknown")

Generated Files:
EOF
    
    find ${REPORTS_DIR} -name "*${TIMESTAMP}*" -type f | sort >> ${summary_file}
    
    echo -e "${GREEN}✅ Summary generated: ${summary_file}${NC}"
}

# Main function
main() {
    echo -e "${BLUE}Starting performance testing...${NC}"
    
    # Check if locust file exists
    if [ ! -f ${LOCUST_FILE} ]; then
        echo -e "${RED}❌ ${LOCUST_FILE} not found${NC}"
        echo "Please make sure locustfile.py is in the current directory"
        exit 1
    fi
    
    # System health check
    check_system_health
    
    # Run tests based on argument
    case "${1:-quick}" in
        "debug")
            run_debug_test
            ;;
        "quick")
            run_quick_test
            ;;
        "performance")
            run_performance_test
            ;;
        "load")
            run_load_test
            ;;
        "stress")
            run_stress_test
            ;;
        "spike")
            run_spike_test
            ;;
        "suite")
            echo -e "${YELLOW}🎭 Running complete test suite...${NC}"
            run_debug_test
            sleep 10
            run_quick_test
            sleep 15
            run_performance_test
            sleep 20
            run_load_test
            ;;
        "stress-suite")
            echo -e "${YELLOW}💥 Running stress test suite...${NC}"
            run_performance_test
            sleep 15
            run_stress_test
            sleep 20
            run_spike_test
            ;;
        *)
            echo "Usage: $0 [debug|quick|performance|load|stress|spike|suite|stress-suite]"
            echo ""
            echo "Test Types:"
            echo "  debug       - 5 users, 1 min (connectivity test)"
            echo "  quick       - 20 users, 2 min (quick validation)"
            echo "  performance - 50 users, 5 min (performance baseline)"
            echo "  load        - 75 users, 10 min (sustained load)"
            echo "  stress      - 150 users, 5 min (stress test)"
            echo "  spike       - 300 users, 3 min (spike test)"
            echo "  suite       - Complete performance suite"
            echo "  stress-suite - Stress testing suite"
            echo ""
            exit 1
            ;;
    esac
    
    # Generate summary
    generate_summary
    
    echo -e "${GREEN}🎉 Testing completed!${NC}"
    echo -e "${BLUE}Reports in: ${REPORTS_DIR}${NC}"
    echo -e "${BLUE}Host tested: ${HOST_URL}${NC}"
    
    # Show generated files
    if ls ${REPORTS_DIR}/*${TIMESTAMP}* > /dev/null 2>&1; then
        echo -e "${YELLOW}Generated files:${NC}"
        ls -la ${REPORTS_DIR}/*${TIMESTAMP}*
    fi
}

# Show help
if [[ "${1}" == "-h" || "${1}" == "--help" ]]; then
    echo "E-commerce Performance Testing Script"
    echo "Host: ${HOST_URL}"
    echo ""
    main "help"
    exit 0
fi

# Execute
main "$@"