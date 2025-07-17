# Library Management System API Test Script
# This script demonstrates how to login and make authenticated API calls

Write-Host "=== Library Management System API Test ===" -ForegroundColor Green
Write-Host ""

# Check if application is running
Write-Host "1. Checking if application is running..." -ForegroundColor Yellow
try {
    $healthCheck = Invoke-RestMethod -Uri "http://localhost:8080/api/actuator/health" -Method GET -TimeoutSec 5
    Write-Host "✓ Application is running - Status: $($healthCheck.status)" -ForegroundColor Green
} catch {
    Write-Host "✗ Application is not running or not accessible" -ForegroundColor Red
    Write-Host "Please start the application first using: mvn spring-boot:run" -ForegroundColor Yellow
    exit 1
}

Write-Host ""

# Login as admin
Write-Host "2. Logging in as admin..." -ForegroundColor Yellow
try {
    $loginData = @{
        usernameOrEmail = "admin"
        password = "admin123"
    } | ConvertTo-Json

    $loginResponse = Invoke-RestMethod -Uri "http://localhost:8080/api/auth/login" -Method POST -Headers @{"Content-Type"="application/json"} -Body $loginData
    $token = $loginResponse.token
    Write-Host "✓ Login successful! Token received." -ForegroundColor Green
    Write-Host "  Username: $($loginResponse.username)" -ForegroundColor Cyan
    Write-Host "  Email: $($loginResponse.email)" -ForegroundColor Cyan
    Write-Host "  Role: $($loginResponse.role)" -ForegroundColor Cyan
} catch {
    Write-Host "✗ Login failed: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}

Write-Host ""

# Set up headers for authenticated requests
$headers = @{
    "Authorization" = "Bearer $token"
    "Content-Type" = "application/json"
}

# Test getting all books
Write-Host "3. Getting all books..." -ForegroundColor Yellow
try {
    $books = Invoke-RestMethod -Uri "http://localhost:8080/api/books" -Method GET -Headers $headers
    Write-Host "✓ Found $($books.Count) books in the library" -ForegroundColor Green
    if ($books.Count -gt 0) {
        Write-Host "  First book: '$($books[0].title)' by $($books[0].author)" -ForegroundColor Cyan
    }
} catch {
    Write-Host "✗ Failed to get books: $($_.Exception.Message)" -ForegroundColor Red
}

Write-Host ""

# Test getting user profile
Write-Host "4. Getting user profile..." -ForegroundColor Yellow
try {
    $profile = Invoke-RestMethod -Uri "http://localhost:8080/api/users/profile" -Method GET -Headers $headers
    Write-Host "✓ Profile retrieved successfully" -ForegroundColor Green
    Write-Host "  Name: $($profile.firstName) $($profile.lastName)" -ForegroundColor Cyan
    Write-Host "  Email: $($profile.email)" -ForegroundColor Cyan
} catch {
    Write-Host "✗ Failed to get profile: $($_.Exception.Message)" -ForegroundColor Red
}

Write-Host ""

# Test getting available books
Write-Host "5. Getting available books..." -ForegroundColor Yellow
try {
    $availableBooks = Invoke-RestMethod -Uri "http://localhost:8080/api/books/available" -Method GET -Headers $headers
    Write-Host "✓ Found $($availableBooks.Count) available books" -ForegroundColor Green
} catch {
    Write-Host "✗ Failed to get available books: $($_.Exception.Message)" -ForegroundColor Red
}

Write-Host ""

# Test metrics endpoint
Write-Host "6. Checking metrics..." -ForegroundColor Yellow
try {
    $metrics = Invoke-RestMethod -Uri "http://localhost:8080/api/actuator/metrics" -Method GET
    Write-Host "✓ Metrics endpoint is working - $($metrics.names.Count) metrics available" -ForegroundColor Green
} catch {
    Write-Host "✗ Failed to get metrics: $($_.Exception.Message)" -ForegroundColor Red
}

Write-Host ""
Write-Host "=== API Test Complete ===" -ForegroundColor Green
Write-Host ""
Write-Host "Your JWT Token (valid for 24 hours):" -ForegroundColor Yellow
Write-Host $token -ForegroundColor White
Write-Host ""
Write-Host "You can now use this token in curl commands like:" -ForegroundColor Yellow
Write-Host "curl -X GET http://localhost:8080/api/books -H `"Authorization: Bearer $token`"" -ForegroundColor White
Write-Host ""
Write-Host "Available endpoints:" -ForegroundColor Yellow
Write-Host "- GET  /api/books                    - Get all books" -ForegroundColor Cyan
Write-Host "- GET  /api/books/available          - Get available books" -ForegroundColor Cyan
Write-Host "- GET  /api/books/search?searchTerm=term - Search books" -ForegroundColor Cyan
Write-Host "- POST /api/transactions/borrow?bookId=1 - Borrow a book" -ForegroundColor Cyan
Write-Host "- GET  /api/users/profile            - Get your profile" -ForegroundColor Cyan
Write-Host "- GET  /api/actuator/health          - Health check" -ForegroundColor Cyan
Write-Host "- GET  /api/actuator/metrics         - Application metrics" -ForegroundColor Cyan
