#!/bin/bash
# Quick start script for development - starts only the application without monitoring

set -e

echo "🚀 Starting Library Management System (Development Mode)..."

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
WHITE='\033[1;37m'
GRAY='\033[0;37m'
NC='\033[0m'

# Check if Docker is running
if ! docker info >/dev/null 2>&1; then
    echo -e "${RED}❌ Docker is not running. Please start Docker first.${NC}"
    exit 1
fi

echo -e "${YELLOW}📚 Building and starting application...${NC}"

if docker-compose up --build -d; then
    echo -e "${GREEN}✅ Application started successfully!${NC}"
    
    # Wait for health check
    echo -e "${YELLOW}⏳ Waiting for application to be ready...${NC}"
    sleep 10
    
    if curl -f http://localhost:8080/health >/dev/null 2>&1; then
        echo -e "${GREEN}💓 Application is healthy!${NC}"
    else
        echo -e "${YELLOW}⚠️  Health check pending...${NC}"
    fi
    
    echo ""
    echo -e "${CYAN}📋 Application Access:${NC}"
    echo -e "${WHITE}📚 Library App:    ${GRAY}http://localhost:8080${NC}"
    echo -e "${WHITE}💓 Health Check:   ${GRAY}http://localhost:8080/health${NC}"
    echo -e "${WHITE}🏥 H2 Console:     ${GRAY}http://localhost:8080/h2-console${NC}"
    echo ""
    echo -e "${GRAY}📝 Commands:${NC}"
    echo -e "${GRAY}   View logs:  docker-compose logs -f library-app${NC}"
    echo -e "${GRAY}   Stop app:   docker-compose down${NC}"
    
else
    echo -e "${RED}❌ Failed to start application${NC}"
    exit 1
fi
