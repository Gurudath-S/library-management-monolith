#!/bin/sh
# Universal shell script for Library Management System
# Compatible with sh, bash, zsh, dash, etc.

echo "🚀 Starting Library Management System - Full Stack Deployment"
echo "   Frontend + Backend + Monitoring + Tracing"

# Check prerequisites
check_prerequisites() {
    echo "🔍 Checking prerequisites..."
    
    if ! command -v docker >/dev/null 2>&1; then
        echo "❌ Docker is not installed"
        exit 1
    fi
    
    if ! command -v docker-compose >/dev/null 2>&1; then
        echo "❌ Docker Compose is not installed"
        exit 1
    fi
    
    if ! docker info >/dev/null 2>&1; then
        echo "❌ Docker is not running. Please start Docker first."
        exit 1
    fi
    
    echo "✅ Prerequisites check passed"
}

# Create necessary directories
setup_directories() {
    echo "📁 Setting up directories..."
    
    mkdir -p logs
    mkdir -p monitoring/grafana/provisioning/datasources
    mkdir -p monitoring/grafana/provisioning/dashboards
    mkdir -p monitoring/grafana/dashboards
    
    echo "✅ Directories created"
}

# Clean up any existing containers
cleanup_existing() {
    echo "🧹 Cleaning up existing containers..."
    
    # Stop and remove containers
    docker-compose -f docker-compose.full.yml down >/dev/null 2>&1 || true
    
    # Remove any orphaned containers
    docker container prune -f >/dev/null 2>&1 || true
    
    echo "✅ Cleanup completed"
}

# Start all services
start_services() {
    echo "🚀 Starting all services..."
    echo "   This includes: Application, Prometheus, Grafana, Zipkin, Nginx"
    
    if ! docker-compose -f docker-compose.full.yml up --build -d; then
        echo "❌ Failed to start services"
        echo "   Trying cleanup and restart..."
        docker-compose -f docker-compose.full.yml down >/dev/null 2>&1 || true
        return 1
    fi
    
    echo "✅ All services started successfully"
    return 0
}

# Wait for a single service to be ready
wait_for_service() {
    service_name="$1"
    service_url="$2"
    max_attempts=30
    attempt=1
    
    echo "   Checking ${service_name}..."
    
    while [ $attempt -le $max_attempts ]; do
        if curl -f "$service_url" >/dev/null 2>&1; then
            echo "   ✅ ${service_name} is healthy!"
            return 0
        fi
        
        if [ $attempt -eq $max_attempts ]; then
            echo "   ⚠️  ${service_name} health check timed out"
            return 1
        fi
        
        sleep 2
        attempt=$((attempt + 1))
    done
}

# Wait for all services to be healthy
wait_for_services() {
    echo "⏳ Waiting for services to be ready..."
    
    wait_for_service "Library App" "http://localhost:8080/actuator/health"
    wait_for_service "Prometheus" "http://localhost:9090/-/ready"
    wait_for_service "Grafana" "http://localhost:3000/api/health"
    wait_for_service "Zipkin" "http://localhost:9411/health"
    
    # Special check for Nginx
    echo "   Checking Nginx frontend..."
    sleep 5  # Give Nginx more time
    if curl -f "http://localhost:80" >/dev/null 2>&1; then
        echo "   ✅ Nginx frontend is ready!"
    else
        echo "   ⚠️  Nginx frontend might still be starting"
    fi
}

# Test the complete setup
test_setup() {
    echo "🧪 Testing the complete setup..."
    
    # Test API endpoint
    echo "   Testing API endpoint..."
    if curl -f "http://localhost:8080/api/books" >/dev/null 2>&1; then
        echo "   ✅ API endpoint responding"
    else
        echo "   ⚠️  API endpoint not ready yet"
    fi
    
    # Test metrics endpoint
    echo "   Testing metrics endpoint..."
    if curl -f "http://localhost:8080/actuator/prometheus" >/dev/null 2>&1; then
        echo "   ✅ Metrics endpoint responding"
    else
        echo "   ⚠️  Metrics endpoint not ready yet"
    fi
    
    # Test if Prometheus can scrape metrics
    echo "   Testing Prometheus targets..."
    sleep 5  # Give Prometheus time to scrape
    if curl -s "http://localhost:9090/api/v1/targets" | grep -q "library-management"; then
        echo "   ✅ Prometheus is scraping application metrics"
    else
        echo "   ⚠️  Prometheus targets might still be initializing"
    fi
}

# Generate some test data for monitoring
generate_test_data() {
    echo "📊 Generating test data for monitoring..."
    
    # Wait a bit for application to be fully ready
    sleep 10
    
    echo "   Making test API calls to generate metrics and traces..."
    
    # Make several API calls to generate data
    i=1
    while [ $i -le 5 ]; do
        curl -s "http://localhost:8080/api/books" >/dev/null 2>&1 || true
        curl -s "http://localhost:8080/actuator/health" >/dev/null 2>&1 || true
        curl -s "http://localhost:8080/actuator/info" >/dev/null 2>&1 || true
        sleep 1
        i=$((i + 1))
    done
    
    echo "   ✅ Test data generated"
}

# Show container status
show_container_status() {
    echo "📦 Container Status:"
    docker-compose -f docker-compose.full.yml ps
    echo ""
}

# Display access information
show_access_info() {
    echo ""
    echo "🎉 SUCCESS! Library Management System is fully deployed!"
    echo ""
    echo "📋 Service Access URLs:"
    echo "🌐 Frontend (Nginx):   http://localhost"
    echo "📚 Library API:       http://localhost:8080/api"
    echo "💓 Health Check:      http://localhost:8080/actuator/health"
    echo "🗄️  H2 Console:        http://localhost:8080/h2-console"
    echo "📊 Prometheus:        http://localhost:9090"
    echo "📈 Grafana:           http://localhost:3000 (admin/admin)"
    echo "🔍 Zipkin:            http://localhost:9411"
    echo ""
    echo "💡 Quick Start:"
    echo "1. Frontend:          Access the web UI at http://localhost"
    echo "2. API Testing:       Use http://localhost:8080/api/auth/login"
    echo "3. Monitoring:        Check Grafana dashboard for metrics"
    echo "4. Tracing:           View request traces in Zipkin"
    echo ""
    echo "📊 Default Credentials:"
    echo "Admin:    username=admin, password=admin123"
    echo "Librarian: username=librarian, password=librarian123"
    echo "User:     username=user, password=user123"
    echo ""
    echo "📝 Management Commands:"
    echo "   View logs:          docker-compose -f docker-compose.full.yml logs -f"
    echo "   Stop services:      ./stop-services.sh"
    echo "   View containers:    docker-compose -f docker-compose.full.yml ps"
    echo "   Restart service:    docker-compose -f docker-compose.full.yml restart <service-name>"
    echo ""
}

# Main execution function
main() {
    echo "╔══════════════════════════════════════════════════════════════╗"
    echo "║           Library Management System - Full Deployment       ║"
    echo "║   Frontend + Backend + Monitoring + Tracing + Load Balancer ║"
    echo "╚══════════════════════════════════════════════════════════════╝"
    echo ""
    
    check_prerequisites
    setup_directories
    cleanup_existing
    
    if ! start_services; then
        echo "❌ Failed to start services. Troubleshooting:"
        echo ""
        echo "🔧 Try these steps:"
        echo "1. Check Docker Desktop is running"
        echo "2. Run: docker system prune -f"
        echo "3. Run: docker-compose -f docker-compose.full.yml down"
        echo "4. Check port availability: netstat -ano | findstr \":8080\""
        echo "5. Restart Docker Desktop and try again"
        exit 1
    fi
    
    wait_for_services
    test_setup
    generate_test_data
    show_container_status
    show_access_info
}

# Run main function
main "$@"
