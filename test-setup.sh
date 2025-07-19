#!/bin/bash
# Test script to verify the complete setup is working

set -e

echo "🧪 Testing Library Management System - Complete Setup Verification"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
WHITE='\033[1;37m'
GRAY='\033[0;37m'
NC='\033[0m'

# Test results
TESTS_PASSED=0
TESTS_FAILED=0

# Function to run a test
run_test() {
    local test_name="$1"
    local test_command="$2"
    local expected_result="$3"
    
    echo -e "${YELLOW}🔬 Testing: ${test_name}${NC}"
    
    if eval "$test_command" >/dev/null 2>&1; then
        if [ -n "$expected_result" ]; then
            local result=$(eval "$test_command" 2>/dev/null)
            if echo "$result" | grep -q "$expected_result"; then
                echo -e "${GREEN}   ✅ PASS${NC}"
                ((TESTS_PASSED++))
                return 0
            else
                echo -e "${RED}   ❌ FAIL - Expected: $expected_result${NC}"
                ((TESTS_FAILED++))
                return 1
            fi
        else
            echo -e "${GREEN}   ✅ PASS${NC}"
            ((TESTS_PASSED++))
            return 0
        fi
    else
        echo -e "${RED}   ❌ FAIL${NC}"
        ((TESTS_FAILED++))
        return 1
    fi
}

# Test container status
test_containers() {
    echo -e "${CYAN}📦 Testing Container Status${NC}"
    
    run_test "Library App Container" "docker ps | grep library-app" "library-app"
    run_test "Prometheus Container" "docker ps | grep library-prometheus" "library-prometheus"
    run_test "Grafana Container" "docker ps | grep library-grafana" "library-grafana"
    run_test "Zipkin Container" "docker ps | grep library-zipkin" "library-zipkin"
    run_test "Nginx Container" "docker ps | grep library-nginx" "library-nginx"
}

# Test service endpoints
test_endpoints() {
    echo -e "${CYAN}🌐 Testing Service Endpoints${NC}"
    
    run_test "Frontend (Nginx)" "curl -s -o /dev/null -w '%{http_code}' http://localhost:80" "200"
    run_test "Library App Health" "curl -s http://localhost:8080/actuator/health" '"status":"UP"'
    run_test "Library App API" "curl -s -o /dev/null -w '%{http_code}' http://localhost:8080/api/books" "200"
    run_test "Prometheus" "curl -s -o /dev/null -w '%{http_code}' http://localhost:9090/-/ready" "200"
    run_test "Grafana" "curl -s -o /dev/null -w '%{http_code}' http://localhost:3000/api/health" "200"
    run_test "Zipkin" "curl -s -o /dev/null -w '%{http_code}' http://localhost:9411/health" "200"
}

# Test metrics and monitoring
test_monitoring() {
    echo -e "${CYAN}📊 Testing Monitoring Integration${NC}"
    
    run_test "Prometheus Metrics" "curl -s http://localhost:8080/actuator/prometheus" "http_server_requests"
    run_test "Prometheus Targets" "curl -s http://localhost:9090/api/v1/targets" "library-management"
    run_test "JVM Metrics" "curl -s http://localhost:8080/actuator/prometheus" "jvm_memory_used_bytes"
}

# Test authentication
test_authentication() {
    echo -e "${CYAN}🔐 Testing Authentication${NC}"
    
    # Test admin login
    local login_response=$(curl -s -X POST \
        -H "Content-Type: application/json" \
        -d '{"usernameOrEmail":"admin","password":"admin123"}' \
        http://localhost:8080/api/auth/login)
    
    if echo "$login_response" | grep -q '"token"'; then
        echo -e "${GREEN}   ✅ PASS - Admin login successful${NC}"
        ((TESTS_PASSED++))
        
        # Extract token for further tests
        local token=$(echo "$login_response" | grep -o '"token":"[^"]*"' | cut -d'"' -f4)
        
        # Test authenticated endpoint
        local books_response=$(curl -s -H "Authorization: Bearer $token" \
            http://localhost:8080/api/books)
        
        if [ $? -eq 0 ]; then
            echo -e "${GREEN}   ✅ PASS - Authenticated API access${NC}"
            ((TESTS_PASSED++))
        else
            echo -e "${RED}   ❌ FAIL - Authenticated API access${NC}"
            ((TESTS_FAILED++))
        fi
    else
        echo -e "${RED}   ❌ FAIL - Admin login failed${NC}"
        ((TESTS_FAILED++))
    fi
}

# Test tracing
test_tracing() {
    echo -e "${CYAN}🔍 Testing Distributed Tracing${NC}"
    
    # Make some API calls to generate traces
    echo -e "${GRAY}   Generating traces...${NC}"
    for i in {1..3}; do
        curl -s http://localhost:8080/api/books >/dev/null 2>&1 || true
        sleep 1
    done
    
    # Wait for traces to be collected
    sleep 5
    
    # Check if traces are available in Zipkin
    run_test "Zipkin Traces" "curl -s 'http://localhost:9411/api/v2/traces?serviceName=library-management&limit=1'" "library-management"
}

# Generate test data
generate_test_data() {
    echo -e "${CYAN}📊 Generating Test Data for Monitoring${NC}"
    
    echo -e "${GRAY}   Making API calls to generate metrics and traces...${NC}"
    
    # Generate various types of requests
    local endpoints=("/api/books" "/actuator/health" "/actuator/info" "/actuator/metrics")
    
    for endpoint in "${endpoints[@]}"; do
        for i in {1..5}; do
            curl -s "http://localhost:8080$endpoint" >/dev/null 2>&1 || true
            sleep 0.5
        done
    done
    
    echo -e "${GREEN}   ✅ Test data generated${NC}"
}

# Show test summary
show_summary() {
    echo ""
    echo -e "${CYAN}╔══════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║                        TEST SUMMARY                         ║${NC}"
    echo -e "${CYAN}╚══════════════════════════════════════════════════════════════╝${NC}"
    echo ""
    
    local total_tests=$((TESTS_PASSED + TESTS_FAILED))
    local success_rate=$((TESTS_PASSED * 100 / total_tests))
    
    echo -e "${WHITE}Total Tests:    ${GRAY}$total_tests${NC}"
    echo -e "${GREEN}Tests Passed:   $TESTS_PASSED${NC}"
    echo -e "${RED}Tests Failed:   $TESTS_FAILED${NC}"
    echo -e "${YELLOW}Success Rate:   $success_rate%${NC}"
    echo ""
    
    if [ $TESTS_FAILED -eq 0 ]; then
        echo -e "${GREEN}🎉 ALL TESTS PASSED! Your setup is working perfectly!${NC}"
    else
        echo -e "${YELLOW}⚠️  Some tests failed. Check the output above for details.${NC}"
    fi
    
    echo ""
    echo -e "${CYAN}🔗 Quick Access Links:${NC}"
    echo -e "${WHITE}Frontend:     ${BLUE}http://localhost${NC}"
    echo -e "${WHITE}API:          ${BLUE}http://localhost:8080/api${NC}"
    echo -e "${WHITE}Prometheus:   ${BLUE}http://localhost:9090${NC}"
    echo -e "${WHITE}Grafana:      ${BLUE}http://localhost:3000${NC}"
    echo -e "${WHITE}Zipkin:       ${BLUE}http://localhost:9411${NC}"
    echo ""
}

# Main execution
main() {
    echo -e "${BLUE}╔══════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${BLUE}║              Library Management System - Testing            ║${NC}"
    echo -e "${BLUE}╚══════════════════════════════════════════════════════════════╝${NC}"
    echo ""
    
    # Check if services are running
    if ! docker ps | grep -q "library-app"; then
        echo -e "${RED}❌ Library Management services are not running!${NC}"
        echo -e "${YELLOW}💡 Start services first: ./start-with-monitoring.sh${NC}"
        exit 1
    fi
    
    # Wait a moment for services to stabilize
    echo -e "${GRAY}⏳ Waiting for services to stabilize...${NC}"
    sleep 5
    
    # Run all tests
    test_containers
    echo ""
    test_endpoints
    echo ""
    test_monitoring
    echo ""
    test_authentication
    echo ""
    generate_test_data
    echo ""
    test_tracing
    
    # Show summary
    show_summary
    
    # Exit with appropriate code
    if [ $TESTS_FAILED -eq 0 ]; then
        exit 0
    else
        exit 1
    fi
}

# Run main function
main "$@"
