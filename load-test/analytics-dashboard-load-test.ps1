# Analytics Dashboard Load Test Script
# This script tests the monolithic architecture performance for the analytics dashboard endpoint
# Usage: .\analytics-dashboard-load-test.ps1 -ConcurrentUsers 10 -TestDurationMinutes 5

param(
    [int]$ConcurrentUsers = 10,
    [int]$TestDurationMinutes = 2,
    [string]$BaseUrl = "http://localhost:8080",
    [string]$Username = "admin",
    [string]$Password = "admin123",
    [int]$WarmupRequests = 5
)

# Colors for output
$Green = "Green"
$Yellow = "Yellow"
$Red = "Red"
$Cyan = "Cyan"

Write-Host "=== Analytics Dashboard Load Test for Monolithic Architecture ===" -ForegroundColor $Cyan
Write-Host "Target URL: $BaseUrl/api/analytics/dashboard" -ForegroundColor $Green
Write-Host "Concurrent Users: $ConcurrentUsers" -ForegroundColor $Green
Write-Host "Test Duration: $TestDurationMinutes minutes" -ForegroundColor $Green
Write-Host "Warmup Requests: $WarmupRequests" -ForegroundColor $Green
Write-Host ""

# Global variables for metrics
$Global:Results = @()
$Global:ErrorCount = 0
$Global:SuccessCount = 0
$Global:ResponseTimes = @()

# Function to authenticate and get JWT token
function Get-AuthToken {
    param([string]$BaseUrl, [string]$Username, [string]$Password)
    
    try {
        $loginPayload = @{
            usernameOrEmail = $Username
            password = $Password
        } | ConvertTo-Json
        
        $response = Invoke-RestMethod -Uri "$BaseUrl/api/auth/login" -Method POST -ContentType "application/json" -Body $loginPayload -TimeoutSec 30
        
        if ($response.token) {
            Write-Host "[+] Authentication successful" -ForegroundColor $Green
            return $response.token
        } else {
            Write-Host "[-] Authentication failed - no token received" -ForegroundColor $Red
            return $null
        }
    } catch {
        Write-Host "[-] Authentication failed: $($_.Exception.Message)" -ForegroundColor $Red
        return $null
    }
}

# Function to test dashboard endpoint
function Test-DashboardEndpoint {
    param([string]$BaseUrl, [string]$Token, $RequestId)
    
    $headers = @{
        "Authorization" = "Bearer $Token"
        "Accept" = "application/json"
    }
    
    $stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
    
    try {
        $response = Invoke-RestMethod -Uri "$BaseUrl/api/analytics/dashboard" -Method GET -Headers $headers -TimeoutSec 60
        $stopwatch.Stop()
        
        $responseTime = $stopwatch.ElapsedMilliseconds
        
        # Validate response structure
        $isValid = $response.dashboard -and $response.metadata -and $response.dashboard.userAnalytics -and $response.dashboard.bookAnalytics
        
        if ($isValid) {
            $Global:SuccessCount++
            $Global:ResponseTimes += $responseTime
            
            $result = [PSCustomObject]@{
                RequestId = $RequestId
                Timestamp = Get-Date
                ResponseTime = $responseTime
                Status = "Success"
                DataSize = ($response | ConvertTo-Json -Depth 10).Length
                UserCount = $response.dashboard.userAnalytics.totalUsers
                BookCount = $response.dashboard.bookAnalytics.totalBooks
                TransactionCount = $response.dashboard.transactionAnalytics.totalTransactions
                ExecutionTime = $response.metadata.executionTimeMs
            }
            
            $Global:Results += $result
            return $result
        } else {
            throw "Invalid response structure"
        }
    } catch {
        $stopwatch.Stop()
        $Global:ErrorCount++
        
        $result = [PSCustomObject]@{
            RequestId = $RequestId
            Timestamp = Get-Date
            ResponseTime = $stopwatch.ElapsedMilliseconds
            Status = "Error"
            Error = $_.Exception.Message
            DataSize = 0
            UserCount = 0
            BookCount = 0
            TransactionCount = 0
            ExecutionTime = 0
        }
        
        $Global:Results += $result
        return $result
    }
}

# Function to run concurrent load test
function Start-LoadTest {
    param([string]$BaseUrl, [string]$Token, [int]$ConcurrentUsers, [int]$DurationMinutes)
    
    $endTime = (Get-Date).AddMinutes($DurationMinutes)
    $requestId = 0
    $jobs = @()
    
    Write-Host "Starting load test..." -ForegroundColor $Yellow
    Write-Host "Test will run until: $endTime" -ForegroundColor $Yellow
    Write-Host ""
    
    while ((Get-Date) -lt $endTime) {
        # Start concurrent requests
        for ($i = 0; $i -lt $ConcurrentUsers; $i++) {
            $requestId++
            
            $job = Start-Job -ScriptBlock {
                param($BaseUrl, $Token, $RequestId)
                
                # Re-define the function in the job scope
                function Test-DashboardEndpoint {
                    param([string]$BaseUrl, [string]$Token, $RequestId)
                    
                    $headers = @{
                        "Authorization" = "Bearer $Token"
                        "Accept" = "application/json"
                    }
                    
                    $stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
                    
                    try {
                        $response = Invoke-RestMethod -Uri "$BaseUrl/api/analytics/dashboard" -Method GET -Headers $headers -TimeoutSec 60
                        $stopwatch.Stop()
                        
                        $responseTime = $stopwatch.ElapsedMilliseconds
                        
                        $isValid = $response.dashboard -and $response.metadata
                        
                        if ($isValid) {
                            return [PSCustomObject]@{
                                RequestId = $RequestId
                                Timestamp = Get-Date
                                ResponseTime = $responseTime
                                Status = "Success"
                                DataSize = ($response | ConvertTo-Json -Depth 10).Length
                                UserCount = $response.dashboard.userAnalytics.totalUsers
                                BookCount = $response.dashboard.bookAnalytics.totalBooks
                                TransactionCount = $response.dashboard.transactionAnalytics.totalTransactions
                                ExecutionTime = $response.metadata.executionTimeMs
                            }
                        } else {
                            throw "Invalid response structure"
                        }
                    } catch {
                        $stopwatch.Stop()
                        return [PSCustomObject]@{
                            RequestId = $RequestId
                            Timestamp = Get-Date
                            ResponseTime = $stopwatch.ElapsedMilliseconds
                            Status = "Error"
                            Error = $_.Exception.Message
                            DataSize = 0
                            UserCount = 0
                            BookCount = 0
                            TransactionCount = 0
                            ExecutionTime = 0
                        }
                    }
                }
                
                return Test-DashboardEndpoint -BaseUrl $BaseUrl -Token $Token -RequestId $RequestId
                
            } -ArgumentList $BaseUrl, $Token, $requestId
            
            $jobs += $job
        }
        
        # Wait for jobs to complete and collect results
        $completedJobs = $jobs | Where-Object { $_.State -eq "Completed" }
        foreach ($job in $completedJobs) {
            $result = Receive-Job $job
            Remove-Job $job
            
            if ($result.Status -eq "Success") {
                $Global:SuccessCount++
                $Global:ResponseTimes += $result.ResponseTime
            } else {
                $Global:ErrorCount++
            }
            
            $Global:Results += $result
            
            # Real-time progress indicator
            $totalRequests = $Global:SuccessCount + $Global:ErrorCount
            if ($totalRequests % 10 -eq 0) {
                $avgResponseTime = if ($Global:ResponseTimes.Count -gt 0) { 
                    [math]::Round(($Global:ResponseTimes | Measure-Object -Average).Average, 2) 
                } else { 0 }
                
                Write-Host "Progress: $totalRequests requests completed | Avg Response Time: ${avgResponseTime}ms | Errors: $($Global:ErrorCount)" -ForegroundColor $Cyan
            }
        }
        
        # Remove completed jobs from the list
        $jobs = $jobs | Where-Object { $_.State -ne "Completed" }
        
        # Small delay to prevent overwhelming the server
        Start-Sleep -Milliseconds 100
    }
    
    # Wait for any remaining jobs to complete
    Write-Host "Waiting for remaining requests to complete..." -ForegroundColor $Yellow
    $jobs | Wait-Job | ForEach-Object {
        $result = Receive-Job $_
        Remove-Job $_
        
        if ($result.Status -eq "Success") {
            $Global:SuccessCount++
            $Global:ResponseTimes += $result.ResponseTime
        } else {
            $Global:ErrorCount++
        }
        
        $Global:Results += $result
    }
}

# Function to generate performance report
function Generate-PerformanceReport {
    $totalRequests = $Global:SuccessCount + $Global:ErrorCount
    $successRate = if ($totalRequests -gt 0) { [math]::Round(($Global:SuccessCount / $totalRequests) * 100, 2) } else { 0 }
    
    if ($Global:ResponseTimes.Count -gt 0) {
        $avgResponseTime = [math]::Round(($Global:ResponseTimes | Measure-Object -Average).Average, 2)
        $minResponseTime = ($Global:ResponseTimes | Measure-Object -Minimum).Minimum
        $maxResponseTime = ($Global:ResponseTimes | Measure-Object -Maximum).Maximum
        $medianResponseTime = [math]::Round(($Global:ResponseTimes | Sort-Object)[[math]::Floor($Global:ResponseTimes.Count / 2)], 2)
        
        # Calculate percentiles
        $sortedTimes = $Global:ResponseTimes | Sort-Object
        $p90 = [math]::Round($sortedTimes[[math]::Floor($sortedTimes.Count * 0.9)], 2)
        $p95 = [math]::Round($sortedTimes[[math]::Floor($sortedTimes.Count * 0.95)], 2)
        $p99 = [math]::Round($sortedTimes[[math]::Floor($sortedTimes.Count * 0.99)], 2)
    } else {
        $avgResponseTime = $minResponseTime = $maxResponseTime = $medianResponseTime = $p90 = $p95 = $p99 = 0
    }
    
    # Calculate throughput
    $testDurationSeconds = $TestDurationMinutes * 60
    $throughput = if ($testDurationSeconds -gt 0) { [math]::Round($totalRequests / $testDurationSeconds, 2) } else { 0 }
    
    Write-Host ""
    Write-Host "=== MONOLITHIC ARCHITECTURE PERFORMANCE REPORT ===" -ForegroundColor $Cyan
    Write-Host ""
    Write-Host "Test Configuration:" -ForegroundColor $Yellow
    Write-Host "  Concurrent Users: $ConcurrentUsers"
    Write-Host "  Test Duration: $TestDurationMinutes minutes"
    Write-Host "  Target Endpoint: /api/analytics/dashboard"
    Write-Host ""
    Write-Host "Request Statistics:" -ForegroundColor $Yellow
    Write-Host "  Total Requests: $totalRequests"
    Write-Host "  Successful Requests: $($Global:SuccessCount)"
    Write-Host "  Failed Requests: $($Global:ErrorCount)"
    Write-Host "  Success Rate: $successRate%"
    Write-Host "  Throughput: $throughput requests/second"
    Write-Host ""
    Write-Host "Response Time Analysis:" -ForegroundColor $Yellow
    Write-Host "  Average Response Time: ${avgResponseTime}ms"
    Write-Host "  Median Response Time: ${medianResponseTime}ms"
    Write-Host "  Minimum Response Time: ${minResponseTime}ms"
    Write-Host "  Maximum Response Time: ${maxResponseTime}ms"
    Write-Host ""
    Write-Host "Response Time Percentiles:" -ForegroundColor $Yellow
    Write-Host "  90th Percentile: ${p90}ms"
    Write-Host "  95th Percentile: ${p95}ms"
    Write-Host "  99th Percentile: ${p99}ms"
    Write-Host ""
    
    # Sample data analysis
    $successfulResults = $Global:Results | Where-Object { $_.Status -eq "Success" }
    if ($successfulResults.Count -gt 0) {
        $avgDataSize = [math]::Round(($successfulResults | Measure-Object -Property DataSize -Average).Average, 2)
        $avgExecutionTime = [math]::Round(($successfulResults | Measure-Object -Property ExecutionTime -Average).Average, 2)
        $sampleResult = $successfulResults[0]
        
        Write-Host "Data Analysis:" -ForegroundColor $Yellow
        Write-Host "  Average Response Data Size: $avgDataSize bytes"
        Write-Host "  Average Server Execution Time: ${avgExecutionTime}ms"
        Write-Host "  Sample Data Counts:"
        Write-Host "    Users: $($sampleResult.UserCount)"
        Write-Host "    Books: $($sampleResult.BookCount)"
        Write-Host "    Transactions: $($sampleResult.TransactionCount)"
        Write-Host ""
    }
    
    # Performance assessment
    Write-Host "Performance Assessment:" -ForegroundColor $Yellow
    if ($avgResponseTime -lt 500) {
        Write-Host "  [+] Excellent response time (< 500ms)" -ForegroundColor $Green
    } elseif ($avgResponseTime -lt 1000) {
        Write-Host "  [!] Good response time (500-1000ms)" -ForegroundColor $Yellow
    } elseif ($avgResponseTime -lt 2000) {
        Write-Host "  [!] Acceptable response time (1-2s)" -ForegroundColor $Yellow
    } else {
        Write-Host "  [-] Poor response time (> 2s)" -ForegroundColor $Red
    }
    
    if ($successRate -gt 95) {
        Write-Host "  [+] Excellent reliability (> 95 percent success rate)" -ForegroundColor $Green
    } elseif ($successRate -gt 90) {
        Write-Host "  [!] Good reliability (90-95 percent success rate)" -ForegroundColor $Yellow
    } else {
        Write-Host "  [-] Poor reliability (< 90 percent success rate)" -ForegroundColor $Red
    }
    
    # Save detailed results to CSV
    $csvPath = "analytics-dashboard-load-test-results-$(Get-Date -Format 'yyyyMMdd-HHmmss').csv"
    $Global:Results | Export-Csv -Path $csvPath -NoTypeInformation
    Write-Host ""
    Write-Host "Detailed results saved to: $csvPath" -ForegroundColor $Green
    
    # Return summary for potential comparison with microservices
    return @{
        TotalRequests = $totalRequests
        SuccessfulRequests = $Global:SuccessCount
        FailedRequests = $Global:ErrorCount
        SuccessRate = $successRate
        AverageResponseTime = $avgResponseTime
        MedianResponseTime = $medianResponseTime
        P90ResponseTime = $p90
        P95ResponseTime = $p95
        P99ResponseTime = $p99
        Throughput = $throughput
        MinResponseTime = $minResponseTime
        MaxResponseTime = $maxResponseTime
    }
}

# Main execution
try {
    # Get authentication token
    Write-Host "Authenticating..." -ForegroundColor $Yellow
    $token = Get-AuthToken -BaseUrl $BaseUrl -Username $Username -Password $Password
    
    if (-not $token) {
        Write-Host "Failed to authenticate. Exiting." -ForegroundColor $Red
        exit 1
    }
    
    # Warmup requests
    if ($WarmupRequests -gt 0) {
        Write-Host "Running warmup requests..." -ForegroundColor $Yellow
        for ($i = 1; $i -le $WarmupRequests; $i++) {
            $warmupResult = Test-DashboardEndpoint -BaseUrl $BaseUrl -Token $token -RequestId "warmup-$i"
            Write-Host "Warmup $i of $WarmupRequests completed: $($warmupResult.ResponseTime)ms" -ForegroundColor $Cyan
        }
        
        # Reset counters after warmup
        $Global:Results = @()
        $Global:ErrorCount = 0
        $Global:SuccessCount = 0
        $Global:ResponseTimes = @()
        Write-Host "Warmup completed. Starting actual load test..." -ForegroundColor $Green
        Write-Host ""
    }
    
    # Run the load test
    Start-LoadTest -BaseUrl $BaseUrl -Token $token -ConcurrentUsers $ConcurrentUsers -DurationMinutes $TestDurationMinutes
    
    # Generate performance report
    $summary = Generate-PerformanceReport
    
    Write-Host ""
    Write-Host "Load test completed successfully!" -ForegroundColor $Green
    Write-Host "This data can be compared with microservices architecture performance." -ForegroundColor $Cyan
    
} catch {
    Write-Host "Load test failed: $($_.Exception.Message)" -ForegroundColor $Red
    exit 1
}
