# AWS EC2 Load Test Script for Library Management System
# Use this script to test the deployed application on AWS EC2

param(
    [Parameter(Mandatory=$true)]
    [string]$EC2_PUBLIC_IP,
    
    [Parameter(Mandatory=$false)]
    [int]$TotalRequests = 500,
    
    [Parameter(Mandatory=$false)]
    [int]$ConcurrentUsers = 5
)

$BaseUrl = "http://${EC2_PUBLIC_IP}:8080/api"

Write-Host "AWS EC2 Library Management System Load Test" -ForegroundColor Green
Write-Host "EC2 Instance: $EC2_PUBLIC_IP"
Write-Host "Base URL: $BaseUrl"
Write-Host "Total Requests: $TotalRequests"
Write-Host "Simulating $ConcurrentUsers concurrent users"
Write-Host ""

# Check if application is running on EC2
Write-Host "Checking application health on EC2..." -ForegroundColor Yellow
try {
    $health = Invoke-RestMethod -Uri "$BaseUrl/actuator/health" -TimeoutSec 10
    Write-Host "✅ Application Status: $($health.status)" -ForegroundColor Green
} catch {
    Write-Host "❌ ERROR: Cannot connect to application on EC2" -ForegroundColor Red
    Write-Host "Please ensure:" -ForegroundColor Yellow
    Write-Host "  1. EC2 instance is running" -ForegroundColor Yellow
    Write-Host "  2. Application is started on EC2" -ForegroundColor Yellow
    Write-Host "  3. Security group allows inbound traffic on port 8080" -ForegroundColor Yellow
    Write-Host "  4. IP address is correct: $EC2_PUBLIC_IP" -ForegroundColor Yellow
    exit 1
}

# Test authentication with default users
Write-Host "Testing authentication..." -ForegroundColor Yellow

$authTokens = @{}
$users = @(
    @{Username="admin"; Password="admin123"; Role="ADMIN"},
    @{Username="librarian"; Password="librarian123"; Role="LIBRARIAN"},
    @{Username="user"; Password="user123"; Role="USER"}
)

foreach ($user in $users) {
    try {
        $loginBody = @{
            usernameOrEmail = $user.Username
            password = $user.Password
        } | ConvertTo-Json
        
        $login = Invoke-RestMethod -Uri "$BaseUrl/auth/login" -Method POST -Body $loginBody -ContentType "application/json" -TimeoutSec 10
        $authTokens[$user.Role] = $login.token
        Write-Host "✅ $($user.Role) authentication successful" -ForegroundColor Green
    } catch {
        Write-Host "❌ $($user.Role) authentication failed: $($_.Exception.Message)" -ForegroundColor Red
    }
}

# Define realistic endpoint test scenarios
$scenarios = @(
    # High frequency scenarios (public endpoints)
    @{Name="Browse Books"; Url="$BaseUrl/books"; AuthLevel="PUBLIC"; Weight=30},
    @{Name="View Available Books"; Url="$BaseUrl/books/available"; AuthLevel="PUBLIC"; Weight=25},
    @{Name="Browse Categories"; Url="$BaseUrl/books/categories"; AuthLevel="PUBLIC"; Weight=15},
    @{Name="Health Check"; Url="$BaseUrl/actuator/health"; AuthLevel="PUBLIC"; Weight=10},
    
    # Medium frequency scenarios (user actions)
    @{Name="User Profile"; Url="$BaseUrl/users/profile"; AuthLevel="USER"; Weight=8},
    @{Name="My Transactions"; Url="$BaseUrl/transactions/my-history"; AuthLevel="USER"; Weight=7},
    
    # Low frequency scenarios (admin/librarian actions)
    @{Name="All Users"; Url="$BaseUrl/users"; AuthLevel="LIBRARIAN"; Weight=3},
    @{Name="All Transactions"; Url="$BaseUrl/transactions/all"; AuthLevel="LIBRARIAN"; Weight=2}
)

# Build weighted endpoint list
$weightedEndpoints = @()
foreach ($scenario in $scenarios) {
    for ($i = 0; $i -lt $scenario.Weight; $i++) {
        $weightedEndpoints += $scenario
    }
}

# Function to get appropriate auth header
function Get-AuthHeader {
    param($AuthLevel)
    
    if ($AuthLevel -eq "PUBLIC") {
        return @{}
    }
    
    $token = $authTokens[$AuthLevel]
    if (-not $token) {
        # Fallback to admin token if specific role not available
        if ($authTokens.ContainsKey("ADMIN")) {
            $token = $authTokens["ADMIN"]
        }
    }
    
    if ($token) {
        return @{"Authorization" = "Bearer $token"}
    }
    
    return @{}
}

# Run load test with realistic patterns
$results = @()
$startTime = Get-Date
$random = New-Object System.Random

Write-Host "Starting AWS EC2 load test with realistic usage patterns..." -ForegroundColor Yellow
Write-Host ""

# Simulate concurrent users
$jobs = @()
for ($user = 1; $user -le $ConcurrentUsers; $user++) {
    $job = Start-Job -ScriptBlock {
        param($BaseUrl, $UserRequests, $WeightedEndpoints, $AuthTokens, $UserNum)
        
        $userResults = @()
        
        function Get-AuthHeaderInJob {
            param($AuthLevel, $Tokens)
            
            if ($AuthLevel -eq "PUBLIC") {
                return @{}
            }
            
            $token = $Tokens[$AuthLevel]
            if (-not $token -and $Tokens.ContainsKey("ADMIN")) {
                $token = $Tokens["ADMIN"]
            }
            
            if ($token) {
                return @{"Authorization" = "Bearer $token"}
            }
            
            return @{}
        }
        
        $random = New-Object System.Random($UserNum)
        
        for ($req = 1; $req -le $UserRequests; $req++) {
            # Random delay between requests (0.5-2 seconds)
            Start-Sleep -Milliseconds ($random.Next(500, 2000))
            
            # Select random endpoint based on weights
            $endpoint = $WeightedEndpoints[$random.Next(0, $WeightedEndpoints.Count)]
            $headers = Get-AuthHeaderInJob -AuthLevel $endpoint.AuthLevel -Tokens $AuthTokens
            
            $stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
            try {
                $response = Invoke-WebRequest -Uri $endpoint.Url -Headers $headers -TimeoutSec 15
                $stopwatch.Stop()
                
                $userResults += [PSCustomObject]@{
                    User = $UserNum
                    Request = $req
                    Endpoint = $endpoint.Name
                    AuthLevel = $endpoint.AuthLevel
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
                }
                
                $userResults += [PSCustomObject]@{
                    User = $UserNum
                    Request = $req
                    Endpoint = $endpoint.Name
                    AuthLevel = $endpoint.AuthLevel
                    Success = $false
                    StatusCode = $statusCode
                    ResponseTime = $stopwatch.ElapsedMilliseconds
                    ErrorMessage = $errorMessage
                }
            }
        }
        
        return $userResults
    } -ArgumentList $BaseUrl, ($TotalRequests / $ConcurrentUsers), $weightedEndpoints, $authTokens, $user
    
    $jobs += $job
}

# Monitor progress
Write-Host "Monitoring concurrent user simulation..." -ForegroundColor Cyan
do {
    Start-Sleep -Seconds 5
    $completed = ($jobs | Where-Object { $_.State -eq "Completed" }).Count
    $running = ($jobs | Where-Object { $_.State -eq "Running" }).Count
    
    Write-Host "Users: $completed completed, $running running" -ForegroundColor Cyan
} while ($running -gt 0)

# Collect results from all jobs
Write-Host "Collecting results from all users..." -ForegroundColor Yellow
foreach ($job in $jobs) {
    $userResults = Receive-Job -Job $job
    $results += $userResults
    Remove-Job -Job $job
}

$endTime = Get-Date
$duration = ($endTime - $startTime).TotalSeconds

# Calculate comprehensive statistics
$successful = ($results | Where-Object { $_.Success }).Count
$failed = ($results | Where-Object { -not $_.Success }).Count
$successRate = [math]::Round(($successful / $results.Count) * 100, 1)

$responseTimes = ($results | Where-Object { $_.Success }).ResponseTime
$avgTime = 0
$minTime = 0
$maxTime = 0
$p95Time = 0
$p99Time = 0

if ($responseTimes.Count -gt 0) {
    $sortedTimes = $responseTimes | Sort-Object
    $avgTime = [math]::Round(($responseTimes | Measure-Object -Average).Average, 1)
    $minTime = ($responseTimes | Measure-Object -Minimum).Minimum
    $maxTime = ($responseTimes | Measure-Object -Maximum).Maximum
    $p95Time = $sortedTimes[[math]::Floor($sortedTimes.Count * 0.95)]
    $p99Time = $sortedTimes[[math]::Floor($sortedTimes.Count * 0.99)]
}

$throughput = [math]::Round($successful / $duration, 1)

# Display comprehensive results
Write-Host ""
Write-Host "🚀 AWS EC2 LOAD TEST RESULTS" -ForegroundColor Green
Write-Host "==============================" -ForegroundColor Green
Write-Host ""

Write-Host "📊 Test Summary:" -ForegroundColor Cyan
Write-Host "  EC2 Instance: $EC2_PUBLIC_IP"
Write-Host "  Total Requests: $($results.Count)"
Write-Host "  Successful: $successful ($successRate%)"
Write-Host "  Failed: $failed"
Write-Host "  Duration: $([math]::Round($duration, 1)) seconds"
Write-Host "  Throughput: $throughput requests/sec"
Write-Host "  Concurrent Users: $ConcurrentUsers"
Write-Host ""

Write-Host "⏱️  Response Time Analysis:" -ForegroundColor Cyan
Write-Host "  Average: $avgTime ms"
Write-Host "  Minimum: $minTime ms"
Write-Host "  Maximum: $maxTime ms"
Write-Host "  95th Percentile: $p95Time ms"
Write-Host "  99th Percentile: $p99Time ms"
Write-Host ""

# User concurrency analysis
Write-Host "👥 Concurrent User Performance:" -ForegroundColor Cyan
for ($user = 1; $user -le $ConcurrentUsers; $user++) {
    $userResults = $results | Where-Object { $_.User -eq $user }
    $userSuccess = ($userResults | Where-Object { $_.Success }).Count
    $userTotal = $userResults.Count
    $userRate = if ($userTotal -gt 0) { [math]::Round(($userSuccess / $userTotal) * 100) } else { 0 }
    
    Write-Host "  User $user`: $userSuccess/$userTotal ($userRate%)"
}
Write-Host ""

# Endpoint performance breakdown
Write-Host "🎯 Endpoint Performance:" -ForegroundColor Cyan
$endpointGroups = $results | Group-Object Endpoint
foreach ($group in ($endpointGroups | Sort-Object Name)) {
    $endpointSuccess = ($group.Group | Where-Object { $_.Success }).Count
    $endpointTotal = $group.Group.Count
    $endpointRate = [math]::Round(($endpointSuccess / $endpointTotal) * 100)
    $endpointAvg = if ($endpointSuccess -gt 0) {
        [math]::Round((($group.Group | Where-Object { $_.Success }).ResponseTime | Measure-Object -Average).Average, 1)
    } else { 0 }
    
    Write-Host "  $($group.Name): $endpointSuccess/$endpointTotal ($endpointRate%) - $endpointAvg ms avg"
}

# Error analysis
$errorResults = $results | Where-Object { -not $_.Success }
if ($errorResults.Count -gt 0) {
    Write-Host ""
    Write-Host "❌ Error Analysis:" -ForegroundColor Red
    $errorGroups = $errorResults | Group-Object StatusCode
    foreach ($group in $errorGroups) {
        Write-Host "  HTTP $($group.Name): $($group.Count) occurrences" -ForegroundColor Red
        
        # Show most common error endpoints
        $errorEndpoints = $group.Group | Group-Object Endpoint | Sort-Object Count -Descending
        foreach ($errorEndpoint in ($errorEndpoints | Select-Object -First 3)) {
            Write-Host "    - $($errorEndpoint.Name): $($errorEndpoint.Count) errors" -ForegroundColor Gray
        }
    }
}

# Performance recommendations
Write-Host ""
Write-Host "💡 Performance Analysis:" -ForegroundColor Cyan

if ($successRate -ge 99 -and $avgTime -lt 200 -and $p95Time -lt 500) {
    Write-Host "  🌟 EXCELLENT - Production ready performance!" -ForegroundColor Green
    Write-Host "    - High success rate ($successRate%)" -ForegroundColor Green
    Write-Host "    - Fast response times (avg: $avgTime ms)" -ForegroundColor Green
    Write-Host "    - Good P95 performance ($p95Time ms)" -ForegroundColor Green
} elseif ($successRate -ge 95 -and $avgTime -lt 500) {
    Write-Host "  ✅ GOOD - Acceptable for production with monitoring" -ForegroundColor Yellow
    Write-Host "    - Decent success rate ($successRate%)" -ForegroundColor Yellow
    Write-Host "    - Acceptable response times (avg: $avgTime ms)" -ForegroundColor Yellow
} elseif ($successRate -ge 90) {
    Write-Host "  ⚠️  FAIR - Requires optimization before production" -ForegroundColor Yellow
    Write-Host "    - Consider increasing EC2 instance size" -ForegroundColor Yellow
    Write-Host "    - Review database performance" -ForegroundColor Yellow
    Write-Host "    - Check application logs for errors" -ForegroundColor Yellow
} else {
    Write-Host "  ❌ POOR - Not suitable for production" -ForegroundColor Red
    Write-Host "    - High error rate ($failed errors)" -ForegroundColor Red
    Write-Host "    - Review EC2 configuration and application setup" -ForegroundColor Red
}

# AWS specific recommendations
Write-Host ""
Write-Host "☁️  AWS Deployment Recommendations:" -ForegroundColor Cyan
if ($avgTime -gt 1000) {
    Write-Host "  ⚡ Consider upgrading EC2 instance type (more CPU/memory)" -ForegroundColor Yellow
}
if ($throughput -lt 10) {
    Write-Host "  📈 Consider implementing auto-scaling for higher load" -ForegroundColor Yellow
}
if ($failed -gt 0) {
    Write-Host "  🔍 Check CloudWatch logs for error details" -ForegroundColor Yellow
    Write-Host "  🛠️  Verify security group and network ACL configurations" -ForegroundColor Yellow
}

# Save comprehensive AWS report
$timestamp = Get-Date -Format "yyyyMMdd-HHmmss"
$reportFile = "aws-ec2-load-test-report-$timestamp.txt"

$report = @"
AWS EC2 Library Management System Load Test Report
Generated: $(Get-Date)
EC2 Instance: $EC2_PUBLIC_IP

TEST CONFIGURATION:
Base URL: $BaseUrl
Total Requests: $($results.Count)
Concurrent Users: $ConcurrentUsers
Test Duration: $([math]::Round($duration, 2)) seconds

PERFORMANCE METRICS:
Success Rate: $successRate%
Throughput: $throughput requests/second
Average Response Time: $avgTime ms
95th Percentile: $p95Time ms
99th Percentile: $p99Time ms

DETAILED RESULTS:
$(($results | ConvertTo-Csv -NoTypeInformation) -join "`n")
"@

$report | Out-File -FilePath $reportFile -Encoding UTF8

Write-Host ""
Write-Host "📄 Detailed report saved to: $reportFile" -ForegroundColor Green
Write-Host ""
Write-Host "Next Steps:" -ForegroundColor Cyan
Write-Host "  1. Review the performance metrics above" -ForegroundColor White
Write-Host "  2. Check CloudWatch metrics in AWS console" -ForegroundColor White
Write-Host "  3. Set up monitoring with Prometheus/Grafana" -ForegroundColor White
Write-Host "  4. Configure alerts for high error rates or slow responses" -ForegroundColor White
Write-Host ""
Write-Host "================================================================" -ForegroundColor Green
