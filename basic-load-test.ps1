# Basic Load Test Script for Library Management System

$BaseUrl = "http://13.235.83.165:8080"
$TotalRequests = 200

Write-Host "Library Management System Load Test" -ForegroundColor Green
Write-Host "Base URL: $BaseUrl"
Write-Host "Total Requests: $TotalRequests"
Write-Host ""

# Check if application is running
Write-Host "Checking application health..." -ForegroundColor Yellow
try {
    $health = Invoke-RestMethod -Uri "http://13.235.83.165:8080/actuator/health" -TimeoutSec 5
    Write-Host "Application Status: $($health.status)" -ForegroundColor Green
} catch {
    Write-Host "ERROR: Cannot connect to application" -ForegroundColor Red
    Write-Host "Please start the application first: mvn spring-boot:run"
    exit 1
}

# Get auth token
Write-Host "Getting authentication token..." -ForegroundColor Yellow
try {
    $loginBody = '{"usernameOrEmail":"admin","password":"admin123"}'
    $login = Invoke-RestMethod -Uri "$BaseUrl/api/auth/login" -Method POST -Body $loginBody -ContentType "application/json"
    $token = $login.token
    Write-Host "Authentication successful" -ForegroundColor Green
} catch {
    Write-Host "Authentication failed" -ForegroundColor Yellow
    $token = $null
}

# Prepare headers
$authHeaders = @{}
if ($token) {
    $authHeaders["Authorization"] = "Bearer $token"
    Write-Host "Using authentication token for requests" -ForegroundColor Green
}

# Test endpoints
$endpoints = @(
    @{Name="Health"; Url="$BaseUrl/actuator/health"; UseAuth=$false},
    @{Name="Books (Public)"; Url="$BaseUrl/api/books"; UseAuth=$true},
    @{Name="Available Books"; Url="$BaseUrl/api/books/available"; UseAuth=$true},
    @{Name="Categories"; Url="$BaseUrl/api/books/categories"; UseAuth=$true},
    @{Name="Metrics"; Url="$BaseUrl/actuator/metrics"; UseAuth=$false},
    @{Name="Prometheus"; Url="$BaseUrl/actuator/prometheus"; UseAuth=$false}
)

# Run tests
$results = @()
$startTime = Get-Date

Write-Host "Starting load test..." -ForegroundColor Yellow
Write-Host ""

for ($i = 1; $i -le $TotalRequests; $i++) {
    $endpoint = $endpoints[($i - 1) % $endpoints.Count]
    
    $headers = @{}
    if ($endpoint.UseAuth -and $token) {
        $headers = $authHeaders
    }
    
    $stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
    try {
        $response = Invoke-WebRequest -Uri $endpoint.Url -Headers $headers -TimeoutSec 10
        $stopwatch.Stop()
        
        $results += [PSCustomObject]@{
            RequestId = $i
            Endpoint = $endpoint.Name
            Success = $true
            StatusCode = $response.StatusCode
            ResponseTime = $stopwatch.ElapsedMilliseconds
            ErrorMessage = $null
        }
    } catch {
        $stopwatch.Stop()
        $statusCode = 0
        $errorMessage = $_.Exception.Message
        if ($_.Exception.Response) {
            $statusCode = $_.Exception.Response.StatusCode.value__
            try {
                $errorContent = $_.Exception.Response.GetResponseStream()
                $reader = New-Object System.IO.StreamReader($errorContent)
                $errorMessage = $reader.ReadToEnd()
                $reader.Close()
            } catch {
                # Ignore errors reading response content
            }
        }
        
        $results += [PSCustomObject]@{
            RequestId = $i
            Endpoint = $endpoint.Name
            Success = $false
            StatusCode = $statusCode
            ResponseTime = $stopwatch.ElapsedMilliseconds
            ErrorMessage = $errorMessage
        }
    }
    
    if ($i % 25 -eq 0) {
        $percent = [math]::Round(($i / $TotalRequests) * 100)
        Write-Host "Progress: $percent% complete ($i/$TotalRequests)" -ForegroundColor Cyan
    }
}

$endTime = Get-Date
$duration = ($endTime - $startTime).TotalSeconds

# Calculate statistics
$successful = ($results | Where-Object { $_.Success }).Count
$failed = ($results | Where-Object { -not $_.Success }).Count
$successRate = [math]::Round(($successful / $results.Count) * 100, 1)

$responseTimes = ($results | Where-Object { $_.Success }).ResponseTime
$avgTime = 0
$minTime = 0
$maxTime = 0

if ($responseTimes.Count -gt 0) {
    $avgTime = [math]::Round(($responseTimes | Measure-Object -Average).Average, 1)
    $minTime = ($responseTimes | Measure-Object -Minimum).Minimum
    $maxTime = ($responseTimes | Measure-Object -Maximum).Maximum
}

$throughput = [math]::Round($successful / $duration, 1)

# Display results
Write-Host ""
Write-Host "LOAD TEST RESULTS" -ForegroundColor Green
Write-Host "=================" -ForegroundColor Green
Write-Host ""
Write-Host "Test Summary:" -ForegroundColor Cyan
Write-Host "  Total Requests: $($results.Count)"
Write-Host "  Successful: $successful"
Write-Host "  Failed: $failed"
Write-Host "  Success Rate: $successRate%"
Write-Host "  Duration: $([math]::Round($duration, 1)) seconds"
Write-Host "  Throughput: $throughput requests/sec"
Write-Host ""

Write-Host "Response Times:" -ForegroundColor Cyan
Write-Host "  Average: $avgTime ms"
Write-Host "  Minimum: $minTime ms"
Write-Host "  Maximum: $maxTime ms"
Write-Host ""

Write-Host "Endpoint Breakdown:" -ForegroundColor Cyan
foreach ($endpointName in ($endpoints.Name | Sort-Object)) {
    $endpointResults = $results | Where-Object { $_.Endpoint -eq $endpointName }
    $endpointSuccess = ($endpointResults | Where-Object { $_.Success }).Count
    $endpointTotal = $endpointResults.Count
    $endpointRate = if ($endpointTotal -gt 0) { [math]::Round(($endpointSuccess / $endpointTotal) * 100) } else { 0 }
    $endpointAvg = if ($endpointSuccess -gt 0) { 
        [math]::Round((($endpointResults | Where-Object { $_.Success }).ResponseTime | Measure-Object -Average).Average, 1) 
    } else { 0 }
    
    Write-Host "  $endpointName`: $endpointSuccess/$endpointTotal ($endpointRate%) - $endpointAvg ms avg"
}

# Show errors if any
$errorResults = $results | Where-Object { -not $_.Success }
if ($errorResults.Count -gt 0) {
    Write-Host ""
    Write-Host "Errors:" -ForegroundColor Red
    $errorGroups = $errorResults | Group-Object StatusCode
    foreach ($group in $errorGroups) {
        Write-Host "  HTTP $($group.Name): $($group.Count) occurrences"
        # Show first few error details
        $sampleErrors = $group.Group | Select-Object -First 3
        foreach ($error in $sampleErrors) {
            if ($error.ErrorMessage -and $error.ErrorMessage -ne "") {
                Write-Host "    - $($error.Endpoint): $($error.ErrorMessage)" -ForegroundColor Gray
            }
        }
    }
}

# Performance rating
Write-Host ""
Write-Host "Performance Rating:" -ForegroundColor Cyan
if ($successRate -gt 98 -and $avgTime -lt 100) {
    Write-Host "  EXCELLENT - High success rate and fast response times" -ForegroundColor Green
} elseif ($successRate -gt 95 -and $avgTime -lt 300) {
    Write-Host "  GOOD - Acceptable performance" -ForegroundColor Yellow
} elseif ($successRate -gt 90) {
    Write-Host "  FAIR - Some issues detected" -ForegroundColor Yellow
} else {
    Write-Host "  POOR - Significant performance issues" -ForegroundColor Red
}

# Save report
$timestamp = Get-Date -Format "yyyyMMdd-HHmmss"
$reportFile = "load-test-report-remote-$timestamp.txt"

$report = @"
Library Management System Load Test Report
Generated: $(Get-Date)

TEST CONFIGURATION:
Base URL: $BaseUrl
Total Requests: $($results.Count)
Test Duration: $([math]::Round($duration, 2)) seconds

RESULTS SUMMARY:
Total Requests: $($results.Count)
Successful Requests: $successful ($successRate%)
Failed Requests: $failed
Throughput: $throughput requests/second

RESPONSE TIME STATISTICS:
Average: $avgTime ms
Minimum: $minTime ms
Maximum: $maxTime ms

ENDPOINT PERFORMANCE:
"@

foreach ($endpointName in ($endpoints.Name | Sort-Object)) {
    $endpointResults = $results | Where-Object { $_.Endpoint -eq $endpointName }
    $endpointSuccess = ($endpointResults | Where-Object { $_.Success }).Count
    $endpointTotal = $endpointResults.Count
    $endpointRate = if ($endpointTotal -gt 0) { [math]::Round(($endpointSuccess / $endpointTotal) * 100) } else { 0 }
    $endpointAvg = if ($endpointSuccess -gt 0) { 
        [math]::Round((($endpointResults | Where-Object { $_.Success }).ResponseTime | Measure-Object -Average).Average, 1) 
    } else { 0 }
    
    $report += "`n$endpointName`: $endpointSuccess/$endpointTotal ($endpointRate%) - $endpointAvg ms average"
}

$report | Out-File -FilePath $reportFile -Encoding UTF8

Write-Host ""
Write-Host "Report saved to: $reportFile" -ForegroundColor Green
Write-Host "===============================================" -ForegroundColor Green
