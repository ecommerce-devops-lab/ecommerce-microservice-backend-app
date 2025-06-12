#!/bin/bash

set -e

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m'

# Configuration
HOST_URL="http://localhost:8765"
REPORTS_DIR="reports"
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
LOCUST_FILE="locustfile.py"
CONFIG_FILE="locust.conf"

# Create reports directory
mkdir -p ${REPORTS_DIR}

echo -e "${BLUE}🚀 E-commerce Microservices Performance Testing Suite${NC}"
echo -e "${BLUE}=================================================${NC}"

# Function to check system health
check_system_health() {
    echo -e "${YELLOW}🔍 Checking system availability...${NC}"
    
    # Check API Gateway
    if ! curl -f -s "${HOST_URL}/product-service/api/products" > /dev/null 2>&1; then
        echo -e "${RED}❌ API Gateway not accessible at ${HOST_URL}${NC}"
        echo "Make sure your e-commerce application is running"
        exit 1
    fi
    
    # Check individual microservices through proxy
    services=("users" "products" "categories" "orders" "carts" "payments" "favourites" "credentials")
    for service in "${services[@]}"; do
        if curl -f -s "${HOST_URL}/app/api/${service}" > /dev/null 2>&1; then
            echo -e "${GREEN}✅ ${service} service accessible${NC}"
        else
            echo -e "${YELLOW}⚠️  ${service} service check failed (may require auth)${NC}"
        fi
    done
    
    echo -e "${GREEN}✅ System health check completed${NC}"
}

# Function to run a specific test configuration
run_test() {
    local test_name=$1
    local config_section=$2
    
    echo -e "${BLUE}📊 Running ${test_name}...${NC}"
    
    locust \
        --config=${CONFIG_FILE} \
        --config-section=${config_section} \
        --headless \
        --html="${REPORTS_DIR}/${test_name}_${TIMESTAMP}.html" \
        --csv="${REPORTS_DIR}/${test_name}_${TIMESTAMP}" \
        --logfile="${REPORTS_DIR}/${test_name}_${TIMESTAMP}.log" \
        -f ${LOCUST_FILE}
    
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✅ ${test_name} completed successfully${NC}"
    else
        echo -e "${RED}❌ ${test_name} failed${NC}"
        return 1
    fi
}

# Function to run performance tests
run_performance_tests() {
    echo -e "${YELLOW}🧪 Starting Performance Tests...${NC}"
    
    # 1. Debug test (small scale)
    run_test "01_debug_test" "debug-test"
    sleep 5
    
    # 2. Performance test (normal load)
    run_test "02_performance_test" "performance-test"
    sleep 10
    
    # 3. Load test (sustained load)
    run_test "03_load_test" "load-test"
    sleep 15
    
    echo -e "${GREEN}✅ Performance tests completed${NC}"
}

# Function to run stress tests
run_stress_tests() {
    echo -e "${YELLOW}💪 Starting Stress Tests...${NC}"
    
    # 1. Stress test
    run_test "04_stress_test" "stress-test"
    sleep 20
    
    # 2. High stress test
    run_test "05_high_stress_test" "high-stress-test"
    sleep 20
    
    # 3. Spike test
    run_test "06_spike_test" "spike-test"
    sleep 15
    
    echo -e "${GREEN}✅ Stress tests completed${NC}"
}

# Function to run specialized tests
run_specialized_tests() {
    echo -e "${YELLOW}🎯 Starting Specialized Tests...${NC}"
    
    # 1. Checkout flow test
    run_test "07_checkout_flow_test" "checkout-flow-test"
    sleep 10
    
    # 2. Catalog browsing test
    run_test "08_catalog_test" "catalog-browsing-test"
    sleep 10
    
    echo -e "${GREEN}✅ Specialized tests completed${NC}"
}

# Function to run scalability tests
run_scalability_tests() {
    echo -e "${YELLOW}📈 Starting Scalability Tests...${NC}"
    
    for i in {1..4}; do
        run_test "09_scalability_step_${i}" "scalability-step-${i}"
        sleep 10
    done
    
    echo -e "${GREEN}✅ Scalability tests completed${NC}"
}

# Function to generate summary report
generate_summary() {
    echo -e "${BLUE}📋 Generating Summary Report...${NC}"
    
    summary_file="${REPORTS_DIR}/test_summary_${TIMESTAMP}.txt"
    
    cat > ${summary_file} << EOF
E-commerce Microservices Performance Test Summary
=================================================
Test Date: $(date)
Host: ${HOST_URL}

Test Files Generated:
EOF
    
    find ${REPORTS_DIR} -name "*${TIMESTAMP}*" -type f | sort >> ${summary_file}
    
    echo -e "${GREEN}✅ Summary report generated: ${summary_file}${NC}"
}

# Main execution function
main() {
    echo -e "${BLUE}Starting comprehensive performance testing suite...${NC}"
    
    # Check if required files exist
    if [ ! -f ${LOCUST_FILE} ]; then
        echo -e "${RED}❌ ${LOCUST_FILE} not found${NC}"
        exit 1
    fi
    
    if [ ! -f ${CONFIG_FILE} ]; then
        echo -e "${RED}❌ ${CONFIG_FILE} not found${NC}"
        exit 1
    fi
    
    # System health check
    check_system_health
    
    # Parse command line arguments
    case "${1:-all}" in
        "performance")
            run_performance_tests
            ;;
        "stress")
            run_stress_tests
            ;;
        "specialized")
            run_specialized_tests
            ;;
        "scalability")
            run_scalability_tests
            ;;
        "quick")
            echo -e "${YELLOW}🚀 Running quick test suite...${NC}"
            run_test "quick_performance" "performance-test"
            run_test "quick_stress" "stress-test"
            ;;
        "endurance")
            echo -e "${YELLOW}⏱️  Running endurance test...${NC}"
            run_test "endurance_test" "microservices-endurance"
            ;;
        "all"|*)
            run_performance_tests
            run_stress_tests
            run_specialized_tests
            ;;
    esac
    
    # Generate summary
    generate_summary
    
    echo -e "${GREEN}🎉 All tests completed! Check the reports directory for results.${NC}"
    echo -e "${BLUE}Reports location: ${REPORTS_DIR}${NC}"
    
    # Show quick stats if available
    if command -v ls > /dev/null 2>&1; then
        echo -e "${YELLOW}Generated files:${NC}"
        ls -la ${REPORTS_DIR}/*${TIMESTAMP}* 2>/dev/null || echo "No files found with timestamp ${TIMESTAMP}"
    fi
}

# Show usage information
show_usage() {
    echo "Usage: $0 [performance|stress|specialized|scalability|quick|endurance|all]"
    echo ""
    echo "Test Types:"
    echo "  performance  - Run only performance tests (normal load)"
    echo "  stress       - Run only stress tests (high load)"
    echo "  specialized  - Run checkout and catalog specific tests"
    echo "  scalability  - Run progressive load tests"
    echo "  quick        - Run a quick subset of tests"
    echo "  endurance    - Run long-duration endurance test"
    echo "  all          - Run comprehensive test suite (default)"
    echo ""
}

# Handle help flag
if [[ "${1}" == "-h" || "${1}" == "--help" ]]; then
    show_usage
    exit 0
fi

# Execute main function
main "$@"