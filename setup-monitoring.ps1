# Library Management System - Monitoring Setup Script

Write-Host "=== Library Management System Monitoring Setup ===" -ForegroundColor Green
Write-Host ""

# Check if Docker is running
try {
    docker --version | Out-Null
    Write-Host "✓ Docker is available" -ForegroundColor Green
} catch {
    Write-Host "✗ Docker is not available. Please install Docker Desktop first." -ForegroundColor Red
    exit 1
}

# Check if docker-compose is available
try {
    docker-compose --version | Out-Null
    Write-Host "✓ Docker Compose is available" -ForegroundColor Green
} catch {
    Write-Host "✗ Docker Compose is not available. Please install Docker Compose first." -ForegroundColor Red
    exit 1
}

Write-Host ""

# Start monitoring stack
Write-Host "Starting monitoring stack..." -ForegroundColor Yellow
Write-Host "This will start:"
Write-Host "- Prometheus (port 9090)"
Write-Host "- Grafana (port 3000)"
Write-Host "- Zipkin (port 9411)"
Write-Host ""

try {
    docker-compose -f docker-compose.monitoring.yml up -d
    Write-Host "✓ Monitoring stack started successfully!" -ForegroundColor Green
} catch {
    Write-Host "✗ Failed to start monitoring stack" -ForegroundColor Red
    exit 1
}

Write-Host ""
Write-Host "Waiting for services to be ready..." -ForegroundColor Yellow
Start-Sleep -Seconds 10

# Check if services are running
$services = @(
    @{Name="Prometheus"; Port=9090; Url="http://localhost:9090"},
    @{Name="Grafana"; Port=3000; Url="http://localhost:3000"},
    @{Name="Zipkin"; Port=9411; Url="http://localhost:9411"}
)

foreach ($service in $services) {
    try {
        $response = Invoke-WebRequest -Uri $service.Url -TimeoutSec 5 -UseBasicParsing
        Write-Host "✓ $($service.Name) is running on port $($service.Port)" -ForegroundColor Green
    } catch {
        Write-Host "⚠ $($service.Name) might not be ready yet (port $($service.Port))" -ForegroundColor Yellow
    }
}

Write-Host ""
Write-Host "=== Access Information ===" -ForegroundColor Cyan
Write-Host ""
Write-Host "Grafana Dashboard:" -ForegroundColor White
Write-Host "  URL: http://localhost:3000" -ForegroundColor Cyan
Write-Host "  Username: admin" -ForegroundColor Cyan
Write-Host "  Password: admin" -ForegroundColor Cyan
Write-Host ""
Write-Host "Prometheus:" -ForegroundColor White
Write-Host "  URL: http://localhost:9090" -ForegroundColor Cyan
Write-Host ""
Write-Host "Zipkin Tracing:" -ForegroundColor White
Write-Host "  URL: http://localhost:9411" -ForegroundColor Cyan
Write-Host ""
Write-Host "Application Metrics:" -ForegroundColor White
Write-Host "  Actuator: http://localhost:8080/actuator" -ForegroundColor Cyan
Write-Host "  Health: http://localhost:8080/actuator/health" -ForegroundColor Cyan
Write-Host "  Metrics: http://localhost:8080/actuator/metrics" -ForegroundColor Cyan
Write-Host "  Prometheus: http://localhost:8080/actuator/prometheus" -ForegroundColor Cyan
Write-Host ""

Write-Host "=== Next Steps ===" -ForegroundColor Yellow
Write-Host "1. Start your Library Management application: mvn spring-boot:run"
Write-Host "2. Open Grafana and import the pre-configured dashboard"
Write-Host "3. Run load tests: .\load-test.ps1"
Write-Host "4. Monitor performance metrics in real-time"
Write-Host ""

Write-Host "=== Performance Testing Commands ===" -ForegroundColor Yellow
Write-Host "Basic load test:"
Write-Host "  .\load-test.ps1"
Write-Host ""
Write-Host "Custom load test:"
Write-Host "  .\load-test.ps1 -TotalRequests 2000 -ConcurrentUsers 20"
Write-Host ""

Write-Host "=== Useful Docker Commands ===" -ForegroundColor Yellow
Write-Host "View logs:"
Write-Host "  docker-compose -f docker-compose.monitoring.yml logs -f"
Write-Host ""
Write-Host "Stop monitoring stack:"
Write-Host "  docker-compose -f docker-compose.monitoring.yml down"
Write-Host ""
Write-Host "Restart monitoring stack:"
Write-Host "  docker-compose -f docker-compose.monitoring.yml restart"
Write-Host ""

Write-Host "Setup completed successfully! 🚀" -ForegroundColor Green
