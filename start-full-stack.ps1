# PowerShell script for Library Management System - Full Stack Deployment
# Compatible with PowerShell 5.1+ and PowerShell Core

param(
    [switch]$NoTest,
    [switch]$QuickStart
)

Write-Host "🚀 Starting Library Management System - Full Stack Deployment" -ForegroundColor Green
Write-Host "   Frontend + Backend + Monitoring + Tracing" -ForegroundColor Cyan

function Test-Prerequisites {
    Write-Host "🔍 Checking prerequisites..." -ForegroundColor Yellow
    
    if (-not (Get-Command docker -ErrorAction SilentlyContinue)) {
        Write-Host "❌ Docker is not installed" -ForegroundColor Red
        exit 1
    }
    
    if (-not (Get-Command docker-compose -ErrorAction SilentlyContinue)) {
        Write-Host "❌ Docker Compose is not installed" -ForegroundColor Red
        exit 1
    }
    
    try {
        docker info 2>$null | Out-Null
    }
    catch {
        Write-Host "❌ Docker is not running. Please start Docker Desktop first." -ForegroundColor Red
        exit 1
    }
    
    Write-Host "✅ Prerequisites check passed" -ForegroundColor Green
}
    
    # Create necessary directories
    Write-Host "📁 Setting up directories..." -ForegroundColor Yellow
    
    $directories = @(
        "logs",
        "monitoring\grafana\provisioning\datasources",
        "monitoring\grafana\provisioning\dashboards", 
        "monitoring\grafana\dashboards"
    )
    
    foreach ($dir in $directories) {
        if (-not (Test-Path $dir)) {
            New-Item -ItemType Directory -Path $dir -Force | Out-Null
        }
    }
    
    Write-Host "✅ Directories created" -ForegroundColor Green
    
    # Clean up any existing containers
    Write-Host "🧹 Cleaning up existing containers..." -ForegroundColor Yellow
    
    docker-compose -f docker-compose.full.yml down 2>$null
    docker container prune -f 2>$null | Out-Null
    
    Write-Host "✅ Cleanup completed" -ForegroundColor Green
    
    # Start all services
    Write-Host "🚀 Starting all services..." -ForegroundColor Yellow
    Write-Host "   This includes: Application, Prometheus, Grafana, Zipkin, Nginx" -ForegroundColor Gray
    
    docker-compose -f docker-compose.full.yml up --build -d
    
    if ($LASTEXITCODE -ne 0) {
        throw "Failed to start services"
    }
    
    Write-Host "✅ All services started successfully" -ForegroundColor Green
    
    # Wait for services to be ready
    Write-Host "⏳ Waiting for services to be ready..." -ForegroundColor Yellow
    
    $services = @(
        @{name="Library App"; url="http://localhost:8080/actuator/health"},
        @{name="Prometheus"; url="http://localhost:9090/-/ready"},
        @{name="Grafana"; url="http://localhost:3000/api/health"},
        @{name="Zipkin"; url="http://localhost:9411/health"}
    )
    
    foreach ($service in $services) {
        Write-Host "   Checking $($service.name)..." -ForegroundColor Gray
        
        $attempt = 1
        $maxAttempts = 30
        $ready = $false
        
        while ($attempt -le $maxAttempts -and -not $ready) {
            try {
                $response = Invoke-WebRequest -Uri $service.url -TimeoutSec 5 -UseBasicParsing 2>$null
                if ($response.StatusCode -eq 200) {
                    Write-Host "   ✅ $($service.name) is healthy!" -ForegroundColor Green
                    $ready = $true
                }
            } catch {
                # Service not ready yet
            }
            
            if (-not $ready) {
                Start-Sleep -Seconds 2
                $attempt++
            }
        }
        
        if (-not $ready) {
            Write-Host "   ⚠️  $($service.name) health check timed out" -ForegroundColor Yellow
        }
    }
    
    # Check Nginx
    Write-Host "   Checking Nginx frontend..." -ForegroundColor Gray
    Start-Sleep -Seconds 5
    
    try {
        $response = Invoke-WebRequest -Uri "http://localhost:80" -TimeoutSec 5 -UseBasicParsing 2>$null
        Write-Host "   ✅ Nginx frontend is ready!" -ForegroundColor Green
    } catch {
        Write-Host "   ⚠️  Nginx frontend might still be starting" -ForegroundColor Yellow
    }
    
    # Test the setup
    Write-Host "🧪 Testing the complete setup..." -ForegroundColor Yellow
    
    try {
        $response = Invoke-WebRequest -Uri "http://localhost:8080/api/books" -TimeoutSec 5 -UseBasicParsing 2>$null
        Write-Host "   ✅ API endpoint responding" -ForegroundColor Green
    } catch {
        Write-Host "   ⚠️  API endpoint not ready yet" -ForegroundColor Yellow
    }
    
    try {
        $response = Invoke-WebRequest -Uri "http://localhost:8080/actuator/prometheus" -TimeoutSec 5 -UseBasicParsing 2>$null
        Write-Host "   ✅ Metrics endpoint responding" -ForegroundColor Green
    } catch {
        Write-Host "   ⚠️  Metrics endpoint not ready yet" -ForegroundColor Yellow
    }
    
    # Generate test data
    Write-Host "📊 Generating test data for monitoring..." -ForegroundColor Yellow
    Start-Sleep -Seconds 10
    
    Write-Host "   Making test API calls to generate metrics and traces..." -ForegroundColor Gray
    
    $endpoints = @("/api/books", "/actuator/health", "/actuator/info")
    
    foreach ($endpoint in $endpoints) {
        for ($i = 1; $i -le 5; $i++) {
            try {
                Invoke-WebRequest -Uri "http://localhost:8080$endpoint" -TimeoutSec 5 -UseBasicParsing 2>$null | Out-Null
            } catch {
                # Ignore errors for test data generation
            }
            Start-Sleep -Seconds 1
        }
    }
    
    Write-Host "   ✅ Test data generated" -ForegroundColor Green
    
    # Show container status
    Write-Host ""
    Write-Host "📦 Container Status:" -ForegroundColor Cyan
    docker-compose -f docker-compose.full.yml ps
    Write-Host ""
    
    # Success message
    Write-Host ""
    Write-Host "🎉 SUCCESS! Library Management System is fully deployed!" -ForegroundColor Green
    Write-Host ""
    Write-Host "📋 Service Access URLs:" -ForegroundColor Cyan
    Write-Host "🌐 Frontend (Nginx):   http://localhost" -ForegroundColor White
    Write-Host "📚 Library API:       http://localhost:8080/api" -ForegroundColor White
    Write-Host "💓 Health Check:      http://localhost:8080/actuator/health" -ForegroundColor White
    Write-Host "🗄️  H2 Console:        http://localhost:8080/h2-console" -ForegroundColor White
    Write-Host "📊 Prometheus:        http://localhost:9090" -ForegroundColor White
    Write-Host "📈 Grafana:           http://localhost:3000 (admin/admin)" -ForegroundColor White
    Write-Host "🔍 Zipkin:            http://localhost:9411" -ForegroundColor White
    Write-Host ""
    Write-Host "💡 Quick Start:" -ForegroundColor Cyan
    Write-Host "1. Frontend:          Access the web UI at http://localhost" -ForegroundColor White
    Write-Host "2. API Testing:       Use http://localhost:8080/api/auth/login" -ForegroundColor White
    Write-Host "3. Monitoring:        Check Grafana dashboard for metrics" -ForegroundColor White
    Write-Host "4. Tracing:           View request traces in Zipkin" -ForegroundColor White
    Write-Host ""
    Write-Host "📊 Default Credentials:" -ForegroundColor Cyan
    Write-Host "Admin:    username=admin, password=admin123" -ForegroundColor White
    Write-Host "Librarian: username=librarian, password=librarian123" -ForegroundColor White
    Write-Host "User:     username=user, password=user123" -ForegroundColor White
    Write-Host ""
    Write-Host "📝 Management Commands:" -ForegroundColor Gray
    Write-Host "   View logs:          docker-compose -f docker-compose.full.yml logs -f" -ForegroundColor Gray
    Write-Host "   Stop services:      .\stop-services.ps1" -ForegroundColor Gray
    Write-Host "   View containers:    docker-compose -f docker-compose.full.yml ps" -ForegroundColor Gray
    Write-Host ""
    
} catch {
    Write-Host ""
    Write-Host "❌ ERROR: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host ""
    Write-Host "🔧 Troubleshooting:" -ForegroundColor Yellow
    Write-Host "1. Make sure Docker Desktop is running" -ForegroundColor White
    Write-Host "2. Try: docker system prune -f" -ForegroundColor White
    Write-Host "3. Try: docker-compose -f docker-compose.full.yml down" -ForegroundColor White
    Write-Host "4. Check port availability: netstat -ano | findstr `":8080`"" -ForegroundColor White
    Write-Host "5. Restart Docker Desktop and try again" -ForegroundColor White
    exit 1
}
