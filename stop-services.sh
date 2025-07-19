#!/bin/bash
# Enhanced script to stop all Library Management System services

set -e

echo "🛑 Stopping Library Management System - Full Stack"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
GRAY='\033[0;37m'
NC='\033[0m'

stop_services() {
    echo -e "${YELLOW}� Stopping all services...${NC}"
    
    # Stop full stack
    if docker-compose -f docker-compose.full.yml down; then
        echo -e "${GREEN}✅ Full stack services stopped${NC}"
    else
        echo -e "${RED}⚠️  Error stopping full stack services${NC}"
    fi
    
    # Also try stopping individual compose files in case they're running
    echo -e "${YELLOW}🧹 Cleaning up individual service stacks...${NC}"
    
    docker-compose down 2>/dev/null || true
    docker-compose -f docker-compose.monitoring.yml down 2>/dev/null || true
    
    echo -e "${GREEN}✅ Cleanup completed${NC}"
}

show_cleanup_options() {
    echo ""
    echo -e "${CYAN}🧹 Additional Cleanup Options:${NC}"
    echo -e "${GRAY}   Remove unused containers:  docker container prune -f${NC}"
    echo -e "${GRAY}   Remove unused images:      docker image prune -f${NC}"
    echo -e "${GRAY}   Remove unused volumes:     docker volume prune -f${NC}"
    echo -e "${GRAY}   Remove unused networks:    docker network prune -f${NC}"
    echo -e "${GRAY}   Remove everything unused:  docker system prune -a -f${NC}"
    echo ""
    echo -e "${CYAN}🔧 Restart Options:${NC}"
    echo -e "${GRAY}   Start full stack:          ./start-with-monitoring.sh${NC}"
    echo -e "${GRAY}   Start app only:            ./start-app-only.sh${NC}"
    echo ""
}

show_status() {
    echo -e "${YELLOW}📊 Current Docker Status:${NC}"
    echo ""
    
    # Show running containers
    local containers=$(docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}" | grep -E "(library|prometheus|grafana|zipkin|nginx)" || true)
    
    if [ -n "$containers" ]; then
        echo -e "${RED}⚠️  Some Library Management containers are still running:${NC}"
        echo "$containers"
        echo ""
        echo -e "${GRAY}Run: docker stop \$(docker ps -q --filter name=library) to force stop${NC}"
    else
        echo -e "${GREEN}✅ No Library Management containers running${NC}"
    fi
    
    echo ""
}

# Main execution
main() {
    echo -e "${CYAN}╔══════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║              Library Management System - Shutdown           ║${NC}"
    echo -e "${CYAN}╚══════════════════════════════════════════════════════════════╝${NC}"
    echo ""
    
    # Check if Docker is running
    if ! docker info >/dev/null 2>&1; then
        echo -e "${RED}❌ Docker is not running.${NC}"
        exit 1
    fi
    
    # Stop services
    stop_services
    
    # Show current status
    show_status
    
    echo -e "${GREEN}✅ All Library Management services stopped successfully!${NC}"
    
    # Show cleanup options
    show_cleanup_options
}

# Run main function
main "$@"
