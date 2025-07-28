# Library Management System - Frontend Development Server
# This script starts a simple HTTP server to serve the frontend files

$Port = 3000
$FrontendDir = Split-Path -Parent $MyInvocation.MyCommand.Definition

Write-Host "===============================================" -ForegroundColor Cyan
Write-Host "  Library Management System - Frontend" -ForegroundColor Cyan
Write-Host "===============================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Starting development server..." -ForegroundColor Green
Write-Host "Frontend directory: $FrontendDir" -ForegroundColor Yellow
Write-Host "Server port: $Port" -ForegroundColor Yellow
Write-Host ""

Set-Location $FrontendDir

# Check if Python is available
try {
    $pythonVersion = python --version 2>&1
    if ($LASTEXITCODE -eq 0) {
        Write-Host "Using Python HTTP server" -ForegroundColor Green
        Write-Host ""
        Write-Host "Open your browser and navigate to: http://localhost:$Port" -ForegroundColor Cyan
        Write-Host "Press Ctrl+C to stop the server" -ForegroundColor Yellow
        Write-Host ""
        python -m http.server $Port
        exit
    }
} catch {
    # Python not found, continue to check Node.js
}

# Check if Node.js is available
try {
    $nodeVersion = node --version 2>&1
    if ($LASTEXITCODE -eq 0) {
        try {
            $npxVersion = npx --version 2>&1
            if ($LASTEXITCODE -eq 0) {
                Write-Host "Using Node.js HTTP server" -ForegroundColor Green
                Write-Host ""
                Write-Host "Open your browser and navigate to: http://localhost:$Port" -ForegroundColor Cyan
                Write-Host "Press Ctrl+C to stop the server" -ForegroundColor Yellow
                Write-Host ""
                npx http-server -p $Port -c-1
                exit
            }
        } catch {
            Write-Host "Node.js found but npx not available" -ForegroundColor Red
        }
    }
} catch {
    # Node.js not found
}

Write-Host "Error: No suitable HTTP server found." -ForegroundColor Red
Write-Host "Please install one of the following:" -ForegroundColor Yellow
Write-Host "  - Python: https://www.python.org/downloads/" -ForegroundColor White
Write-Host "  - Node.js: https://nodejs.org/" -ForegroundColor White
Write-Host ""
Read-Host "Press Enter to exit"
