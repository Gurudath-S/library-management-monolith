#!/bin/bash
# Windows-compatible startup script for Library Management System
# This version removes trap commands for better Windows compatibility

echo "🚀 Starting Library Management System - Full Stack Deployment"
echo "   Frontend + Backend + Monitoring + Tracing"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
WHITE='\033[1;37m'
GRAY='\033[0;37m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Check prerequisites
check_prerequisites() {
    echo -e "${YELLOW}🔍 Checking prerequisites...${NC}"
    
    if ! command -v docker >/dev/null 2>&1; then
        echo -e "${RED}❌ Docker is not installed${NC}"
        exit 1
    fi
    
    if ! command -v docker-compose >/dev/null 2>&1; then
        echo -e "${RED}❌ Docker Compose is not installed${NC}"
        exit 1
    fi
    
    if ! docker info >/dev/null 2>&1; then
        echo -e "${RED}❌ Docker is not running. Please start Docker first.${NC}"
        exit 1
    fi
    
    echo -e "${GREEN}✅ Prerequisites check passed${NC}"
}

# Create necessary directories
setup_directories() {
    echo -e "${YELLOW}📁 Setting up directories...${NC}"
    
    mkdir -p logs
    mkdir -p monitoring/grafana/provisioning/datasources
    mkdir -p monitoring/grafana/provisioning/dashboards
    mkdir -p monitoring/grafana/dashboards
    
    echo -e "${GREEN}✅ Directories created${NC}"
}

# Clean up any existing containers
cleanup_existing() {
    echo -e "${YELLOW}🧹 Cleaning up existing containers...${NC}"
    
    # Stop and remove containers
    docker-compose -f docker-compose.full.yml down 2>/dev/null || true
    
    # Remove any orphaned containers
    docker container prune -f >/dev/null 2>&1 || true
    
    echo -e "${GREEN}✅ Cleanup completed${NC}"
}

# Start all services
start_services() {
    echo -e "${YELLOW}🚀 Starting all services...${NC}"
    echo -e "${GRAY}   This includes: Application, Prometheus, Grafana, Zipkin, Nginx${NC}"
    
    if ! docker-compose -f docker-compose.full.yml up --build -d; then
        echo -e "${RED}❌ Failed to start services${NC}"
        echo -e "${GRAY}   Trying cleanup and restart...${NC}"
        docker-compose -f docker-compose.full.yml down 2>/dev/null || true
        return 1
    fi
    
    echo -e "${GREEN}✅ All services started successfully${NC}"
    return 0
}

# Wait for services to be healthy
wait_for_services() {
    echo -e "${YELLOW}⏳ Waiting for services to be ready...${NC}"
    
    local services=("library-app:8080/actuator/health" "prometheus:9090/-/ready" "grafana:3000/api/health" "zipkin:9411/health")
    local service_names=("Library App" "Prometheus" "Grafana" "Zipkin")
    local max_attempts=60
    
    for i in "${!services[@]}"; do
        local service="${services[$i]}"
        local name="${service_names[$i]}"
        local attempt=1
        
        echo -e "${GRAY}   Checking ${name}...${NC}"
        
        while [ $attempt -le $max_attempts ]; do
            if curl -f "http://localhost:${service}" >/dev/null 2>&1; then
                echo -e "${GREEN}   ✅ ${name} is healthy!${NC}"
                break
            fi
            
            if [ $attempt -eq $max_attempts ]; then
                echo -e "${YELLOW}   ⚠️  ${name} health check timed out${NC}"
                break
            fi
            
            sleep 2
            ((attempt++))
        done
    done
    
    # Special check for Nginx
    echo -e "${GRAY}   Checking Nginx frontend...${NC}"
    sleep 5  # Give Nginx more time
    if curl -f "http://localhost:80" >/dev/null 2>&1; then
        echo -e "${GREEN}   ✅ Nginx frontend is ready!${NC}"
    else
        echo -e "${YELLOW}   ⚠️  Nginx frontend might still be starting${NC}"
    fi
}

# Test the complete setup
test_setup() {
    echo -e "${YELLOW}🧪 Testing the complete setup...${NC}"
    
    # Test API endpoint
    echo -e "${GRAY}   Testing API endpoint...${NC}"
    if curl -f "http://localhost:8080/api/books" >/dev/null 2>&1; then
        echo -e "${GREEN}   ✅ API endpoint responding${NC}"
    else
        echo -e "${YELLOW}   ⚠️  API endpoint not ready yet${NC}"
    fi
    
    # Test metrics endpoint
    echo -e "${GRAY}   Testing metrics endpoint...${NC}"
    if curl -f "http://localhost:8080/actuator/prometheus" >/dev/null 2>&1; then
        echo -e "${GREEN}   ✅ Metrics endpoint responding${NC}"
    else
        echo -e "${YELLOW}   ⚠️  Metrics endpoint not ready yet${NC}"
    fi
    
    # Test if Prometheus can scrape metrics
    echo -e "${GRAY}   Testing Prometheus targets...${NC}"
    sleep 5  # Give Prometheus time to scrape
    if curl -s "http://localhost:9090/api/v1/targets" | grep -q "library-management"; then
        echo -e "${GREEN}   ✅ Prometheus is scraping application metrics${NC}"
    else
        echo -e "${YELLOW}   ⚠️  Prometheus targets might still be initializing${NC}"
    fi
}

# Generate some test data for monitoring
generate_test_data() {
    echo -e "${YELLOW}📊 Generating test data for monitoring...${NC}"
    
    # Wait a bit for application to be fully ready
    sleep 10
    
    echo -e "${GRAY}   Making test API calls to generate metrics and traces...${NC}"
    
    # Make several API calls to generate data
    for i in {1..5}; do
        curl -s "http://localhost:8080/api/books" >/dev/null 2>&1 || true
        curl -s "http://localhost:8080/actuator/health" >/dev/null 2>&1 || true
        curl -s "http://localhost:8080/actuator/info" >/dev/null 2>&1 || true
        sleep 1
    done
    
    echo -e "${GREEN}   ✅ Test data generated${NC}"
}

# Display access information
show_access_info() {
    echo ""
    echo -e "${GREEN}🎉 SUCCESS! Library Management System is fully deployed!${NC}"
    echo ""
    echo -e "${CYAN}📋 Service Access URLs:${NC}"
    echo -e "${WHITE}🌐 Frontend (Nginx):   ${BLUE}http://localhost${NC}"
    echo -e "${WHITE}📚 Library API:       ${BLUE}http://localhost:8080/api${NC}"
    echo -e "${WHITE}💓 Health Check:      ${BLUE}http://localhost:8080/actuator/health${NC}"
    echo -e "${WHITE}🗄️  H2 Console:        ${BLUE}http://localhost:8080/h2-console${NC}"
    echo -e "${WHITE}📊 Prometheus:        ${BLUE}http://localhost:9090${NC}"
    echo -e "${WHITE}📈 Grafana:           ${BLUE}http://localhost:3000 ${GRAY}(admin/admin)${NC}"
    echo -e "${WHITE}🔍 Zipkin:            ${BLUE}http://localhost:9411${NC}"
    echo ""
    echo -e "${CYAN}💡 Quick Start:${NC}"
    echo -e "${WHITE}1. Frontend:          ${GRAY}Access the web UI at http://localhost${NC}"
    echo -e "${WHITE}2. API Testing:       ${GRAY}Use http://localhost:8080/api/auth/login${NC}"
    echo -e "${WHITE}3. Monitoring:        ${GRAY}Check Grafana dashboard for metrics${NC}"
    echo -e "${WHITE}4. Tracing:           ${GRAY}View request traces in Zipkin${NC}"
    echo ""
    echo -e "${CYAN}📊 Default Credentials:${NC}"
    echo -e "${WHITE}Admin:    ${GRAY}username=admin, password=admin123${NC}"
    echo -e "${WHITE}Librarian: ${GRAY}username=librarian, password=librarian123${NC}"
    echo -e "${WHITE}User:     ${GRAY}username=user, password=user123${NC}"
    echo ""
    echo -e "${GRAY}📝 Management Commands:${NC}"
    echo -e "${GRAY}   View logs:          docker-compose -f docker-compose.full.yml logs -f${NC}"
    echo -e "${GRAY}   Stop services:      ./stop-services.sh${NC}"
    echo -e "${GRAY}   View containers:    docker-compose -f docker-compose.full.yml ps${NC}"
    echo -e "${GRAY}   Restart service:    docker-compose -f docker-compose.full.yml restart <service-name>${NC}"
    echo ""
}

# Show container status
show_container_status() {
    echo -e "${CYAN}📦 Container Status:${NC}"
    docker-compose -f docker-compose.full.yml ps
    echo ""
}

# Main execution function
main() {
    echo -e "${BLUE}╔══════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${BLUE}║           Library Management System - Full Deployment       ║${NC}"
    echo -e "${BLUE}║   Frontend + Backend + Monitoring + Tracing + Load Balancer ║${NC}"
    echo -e "${BLUE}╚══════════════════════════════════════════════════════════════╝${NC}"
    echo ""
    
    check_prerequisites
    setup_directories
    cleanup_existing
    
    if ! start_services; then
        echo -e "${RED}❌ Failed to start services. Trying troubleshooting...${NC}"
        echo ""
        echo -e "${YELLOW}🔧 Troubleshooting:${NC}"
        echo -e "${GRAY}1. Check Docker Desktop is running${NC}"
        echo -e "${GRAY}2. Try: docker system prune -f${NC}"
        echo -e "${GRAY}3. Try: docker-compose -f docker-compose.full.yml down${NC}"
        echo -e "${GRAY}4. Check port availability: netstat -ano | findstr \":8080\"${NC}"
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
