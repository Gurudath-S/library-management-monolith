# PowerShell script to start the frontend

Write-Host "===== Library Management System Frontend =====" -ForegroundColor Green
Write-Host ""
Write-Host "Starting frontend server..." -ForegroundColor Yellow
Write-Host ""
Write-Host "Frontend will be available at: http://localhost:8000" -ForegroundColor Cyan
Write-Host "Backend API should be running at: http://localhost:8080/api" -ForegroundColor Cyan
Write-Host ""
Write-Host "Make sure your Spring Boot application is running!" -ForegroundColor Yellow
Write-Host ""
Write-Host "To start the backend:" -ForegroundColor Yellow
Write-Host "  mvn spring-boot:run" -ForegroundColor White
Write-Host ""
Write-Host "Press Ctrl+C to stop the frontend server" -ForegroundColor Yellow
Write-Host ""

# Check if Python is available
try {
    python --version | Out-Null
    Write-Host "✓ Python is available" -ForegroundColor Green
} catch {
    Write-Host "✗ Python is not available. Please install Python first." -ForegroundColor Red
    Write-Host "Download from: https://www.python.org/downloads/" -ForegroundColor Yellow
    Read-Host "Press Enter to exit"
    exit
}

# Check if backend is running
try {
    $response = Invoke-WebRequest -Uri "http://localhost:8080/api/actuator/health" -TimeoutSec 2
    Write-Host "✓ Backend is running" -ForegroundColor Green
} catch {
    Write-Host "⚠ Backend is not running. Please start it with: mvn spring-boot:run" -ForegroundColor Yellow
}

Write-Host ""
Write-Host "Starting HTTP server..." -ForegroundColor Yellow

# Change to frontend directory and start server
Set-Location -Path "frontend"
python -m http.server 8000
