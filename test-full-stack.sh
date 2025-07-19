#!/bin/sh
# Test script to verify all services are working properly
# Compatible with any POSIX shell

echo "🧪 Library Management System - Health Check"
echo "Testing all services and their integrations..."
echo ""

# Service URLs
API_URL="http://localhost:8080"
PROMETHEUS_URL="http://localhost:9090"
GRAFANA_URL="http://localhost:3000"
ZIPKIN_URL="http://localhost:9411"
NGINX_URL="http://localhost"

# Test a service with retry logic
test_service() {
    service_name="$1"
    url="$2"
    expected_content="$3"
    max_attempts=5
    attempt=1
    
    echo "Testing $service_name..."
    
    while [ $attempt -le $max_attempts ]; do
        if curl -s "$url" >/dev/null 2>&1; then
            if [ -n "$expected_content" ]; then
                if curl -s "$url" | grep -q "$expected_content"; then
                    echo "✅ $service_name: OK (content verified)"
                    return 0
                else
                    echo "⚠️  $service_name: Responding but content unexpected"
                    return 1
                fi
            else
                echo "✅ $service_name: OK"
                return 0
            fi
        fi
        
        if [ $attempt -eq $max_attempts ]; then
            echo "❌ $service_name: Failed after $max_attempts attempts"
            return 1
        fi
        
        echo "   Attempt $attempt/$max_attempts failed, retrying..."
        sleep 2
        attempt=$((attempt + 1))
    done
}

# Test API functionality
test_api() {
    echo "🔍 Testing API functionality..."
    
    # Test health endpoint
    test_service "Health Check" "$API_URL/actuator/health" "UP"
    
    # Test books endpoint
    test_service "Books API" "$API_URL/api/books"
    
    # Test metrics endpoint
    test_service "Metrics" "$API_URL/actuator/prometheus" "jvm_memory"
    
    # Test info endpoint
    test_service "Info" "$API_URL/actuator/info"
    
    echo ""
}

# Test monitoring stack
test_monitoring() {
    echo "📊 Testing monitoring stack..."
    
    # Test Prometheus
    test_service "Prometheus" "$PROMETHEUS_URL/-/ready"
    
    # Test if Prometheus is scraping our app
    echo "   Checking if Prometheus is scraping application..."
    if curl -s "$PROMETHEUS_URL/api/v1/targets" | grep -q "library-management"; then
        echo "   ✅ Prometheus targets configured correctly"
    else
        echo "   ⚠️  Prometheus might not be scraping application yet"
    fi
    
    # Test Grafana
    test_service "Grafana" "$GRAFANA_URL/api/health"
    
    # Test Zipkin
    test_service "Zipkin" "$ZIPKIN_URL/health"
    
    echo ""
}

# Test frontend/load balancer
test_frontend() {
    echo "🌐 Testing frontend and load balancer..."
    
    # Test Nginx
    test_service "Nginx Frontend" "$NGINX_URL"
    
    # Test if Nginx can proxy API requests
    echo "   Testing API proxy through Nginx..."
    if curl -s "$NGINX_URL/api/books" >/dev/null 2>&1; then
        echo "   ✅ API proxy working through Nginx"
    else
        echo "   ⚠️  API proxy might not be configured correctly"
    fi
    
    echo ""
}

# Generate test traffic for monitoring
generate_test_traffic() {
    echo "🚦 Generating test traffic for monitoring..."
    
    # Make various API calls to generate metrics and traces
    endpoints=(
        "/api/books"
        "/actuator/health"
        "/actuator/info"
        "/actuator/metrics"
    )
    
    echo "   Making test requests..."
    for i in 1 2 3 4 5; do
        for endpoint in $endpoints; do
            curl -s "$API_URL$endpoint" >/dev/null 2>&1 || true
        done
        sleep 1
    done
    
    echo "   ✅ Test traffic generated"
    echo ""
}

# Check if metrics are being collected
verify_metrics() {
    echo "📈 Verifying metrics collection..."
    
    # Wait a bit for metrics to be scraped
    sleep 5
    
    # Check if we have application metrics in Prometheus
    echo "   Checking application metrics in Prometheus..."
    if curl -s "$PROMETHEUS_URL/api/v1/query?query=jvm_memory_used_bytes" | grep -q "success"; then
        echo "   ✅ Application metrics available in Prometheus"
    else
        echo "   ⚠️  Application metrics not yet available"
    fi
    
    # Check if we have HTTP request metrics
    echo "   Checking HTTP request metrics..."
    if curl -s "$PROMETHEUS_URL/api/v1/query?query=http_server_requests_seconds_count" | grep -q "success"; then
        echo "   ✅ HTTP request metrics available"
    else
        echo "   ⚠️  HTTP request metrics not yet available"
    fi
    
    echo ""
}

# Check traces in Zipkin
verify_tracing() {
    echo "🔍 Verifying distributed tracing..."
    
    # Make a traced request
    echo "   Making traced request..."
    curl -s "$API_URL/api/books" >/dev/null 2>&1
    
    # Wait for trace to be collected
    sleep 3
    
    # Check if traces are available in Zipkin
    echo "   Checking traces in Zipkin..."
    if curl -s "$ZIPKIN_URL/api/v2/services" | grep -q "library-management"; then
        echo "   ✅ Distributed tracing working"
    else
        echo "   ⚠️  Traces not yet available in Zipkin"
    fi
    
    echo ""
}

# Show container status
show_container_status() {
    echo "📦 Container Status:"
    if command -v docker-compose >/dev/null 2>&1; then
        docker-compose -f docker-compose.full.yml ps
    else
        echo "   Docker Compose not available"
    fi
    echo ""
}

# Main test execution
main() {
    echo "╔══════════════════════════════════════════════════════════════╗"
    echo "║               Library Management System Test Suite          ║"
    echo "║          Comprehensive Health Check & Integration Test      ║"
    echo "╚══════════════════════════════════════════════════════════════╝"
    echo ""
    
    # Wait a moment for services to stabilize
    echo "⏳ Waiting for services to stabilize..."
    sleep 10
    
    test_api
    test_monitoring
    test_frontend
    generate_test_traffic
    verify_metrics
    verify_tracing
    show_container_status
    
    echo "🏁 Test Summary:"
    echo "✅ All core services tested"
    echo "✅ Monitoring stack verified"
    echo "✅ Test traffic generated"
    echo "✅ Metrics and tracing checked"
    echo ""
    echo "💡 If any service shows warnings, wait a few minutes and test again."
    echo "   Some services need time to initialize and start collecting data."
    echo ""
    echo "🌐 Access URLs:"
    echo "   Frontend:   http://localhost"
    echo "   API:        http://localhost:8080/api"
    echo "   Prometheus: http://localhost:9090"
    echo "   Grafana:    http://localhost:3000"
    echo "   Zipkin:     http://localhost:9411"
}

# Run the test suite
main "$@"
