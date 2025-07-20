# Analytics Dashboard Load Testing

This directory contains load testing scripts for the analytics dashboard endpoint in the monolithic library management system. These tests help measure performance characteristics that can be compared with microservices architecture.

## Files Overview

- `analytics-dashboard-load-test.ps1` - PowerShell-based load test script
- `analytics_load_test.py` - Python-based async load test script
- `run-load-test.bat` - Windows batch script for easy test execution
- `requirements.txt` - Python dependencies

## Prerequisites

1. **Application Running**: Ensure the Spring Boot application is running on `http://localhost:8080`
2. **Authentication**: Default admin credentials (`admin` / `admin123`) should be available

## PowerShell Script Usage

### Quick Start (Windows)
```batch
# Run the batch script for interactive testing
run-load-test.bat
```

### Manual PowerShell Execution
```powershell
# Standard test (10 users, 2 minutes)
.\analytics-dashboard-load-test.ps1

# Custom parameters
.\analytics-dashboard-load-test.ps1 -ConcurrentUsers 20 -TestDurationMinutes 5

# Full parameter list
.\analytics-dashboard-load-test.ps1 -ConcurrentUsers 15 -TestDurationMinutes 3 -BaseUrl "http://localhost:8080" -Username "admin" -Password "admin123" -WarmupRequests 10
```

### Parameters
- `ConcurrentUsers` - Number of concurrent users (default: 10)
- `TestDurationMinutes` - Test duration in minutes (default: 2)
- `BaseUrl` - Application base URL (default: http://localhost:8080)
- `Username` - Login username (default: admin)
- `Password` - Login password (default: admin123)
- `WarmupRequests` - Number of warmup requests (default: 5)

## Python Script Usage

### Installation
```bash
pip install -r requirements.txt
```

### Execution
```bash
# Standard test
python analytics_load_test.py

# Custom parameters
python analytics_load_test.py --users 20 --duration 300 --url http://localhost:8080

# Full parameter list
python analytics_load_test.py --users 15 --duration 180 --url http://localhost:8080 --username admin --password admin123 --warmup 10
```

### Parameters
- `--users` - Number of concurrent users (default: 10)
- `--duration` - Test duration in seconds (default: 120)
- `--url` - Base URL (default: http://localhost:8080)
- `--username` - Username (default: admin)
- `--password` - Password (default: admin123)
- `--warmup` - Number of warmup requests (default: 5)

## Test Scenarios

### 1. Quick Test
- **Users**: 5 concurrent
- **Duration**: 1 minute
- **Purpose**: Basic functionality verification

### 2. Standard Test
- **Users**: 10 concurrent
- **Duration**: 2 minutes
- **Purpose**: Typical load simulation

### 3. Stress Test
- **Users**: 20 concurrent
- **Duration**: 5 minutes
- **Purpose**: High load performance testing

### 4. Custom Test
- **Users**: User-defined
- **Duration**: User-defined
- **Purpose**: Specific scenario testing

## Metrics Collected

### Response Time Metrics
- Average response time
- Median response time
- Min/Max response times
- 90th, 95th, 99th percentiles

### Throughput Metrics
- Total requests processed
- Requests per second
- Success rate percentage
- Error rate

### Data Metrics
- Response data size
- Server execution time
- Analytics data counts (users, books, transactions)

### System Health
- Request success/failure rates
- Error categorization
- Performance assessment

## Output Files

Each test run generates:
- **Console Report**: Comprehensive performance summary displayed in terminal
- **CSV File**: Detailed per-request results with timestamp
- **Text Report**: Complete performance analysis saved to file

### File Naming Convention
- CSV filename: `analytics-dashboard-load-test-results-YYYYMMDD-HHMMSS.csv`
- Text report: `analytics-dashboard-performance-report-YYYYMMDD-HHMMSS.txt`

### Text Report Contents
The generated text report includes:
- Test configuration and environment details
- Complete performance statistics
- Response time analysis and percentiles
- Data analysis (payload sizes, execution times)
- Performance assessment with ratings
- Architecture-specific notes for comparison
- File references for detailed data

## Sample Output

```
=== MONOLITHIC ARCHITECTURE PERFORMANCE REPORT ===

Test Configuration:
  Concurrent Users: 10
  Test Duration: 2 minutes
  Target Endpoint: /api/analytics/dashboard

Request Statistics:
  Total Requests: 547
  Successful Requests: 543
  Failed Requests: 4
  Success Rate: 99.27%
  Throughput: 4.56 requests/second

Response Time Analysis:
  Average Response Time: 312.45ms
  Median Response Time: 298.12ms
  Minimum Response Time: 145.23ms
  Maximum Response Time: 1243.67ms

Response Time Percentiles:
  90th Percentile: 456.78ms
  95th Percentile: 567.89ms
  99th Percentile: 890.12ms

Performance Assessment:
  ✓ Excellent response time (< 500ms)
  ✓ Excellent reliability (> 95% success rate)
```

## Analysis for Architecture Comparison

This load test provides baseline performance metrics for the monolithic architecture that can be compared against:

1. **Microservices Architecture**: When implementing the same functionality as separate services
2. **API Gateway Patterns**: Comparing direct vs. gateway-mediated access
3. **Database Scaling**: Impact of distributed vs. centralized data access
4. **Service Communication**: Overhead of inter-service calls vs. in-process calls

## Key Performance Indicators (KPIs)

- **Response Time**: How quickly the system responds under load
- **Throughput**: How many requests the system can handle per second
- **Reliability**: Success rate under sustained load
- **Scalability**: Performance degradation as load increases
- **Resource Utilization**: Memory, CPU, and database load patterns

## Troubleshooting

### Common Issues

1. **Authentication Failed**
   - Verify application is running
   - Check admin credentials
   - Ensure `/api/auth/login` endpoint is accessible

2. **Connection Errors**
   - Verify application URL
   - Check firewall settings
   - Ensure application is fully started

3. **High Error Rates**
   - Reduce concurrent users
   - Increase timeout values
   - Check application logs for errors

4. **Poor Performance**
   - Verify adequate test data exists
   - Check database performance
   - Monitor system resources

### Performance Optimization Tips

1. **JVM Tuning**: Adjust heap size and garbage collection
2. **Connection Pooling**: Optimize database connections
3. **Caching**: Implement application-level caching
4. **Query Optimization**: Improve database query performance

## Next Steps

After collecting monolithic performance data:

1. **Baseline Establishment**: Use this data as your monolithic baseline
2. **Microservices Implementation**: Implement equivalent microservices architecture
3. **Comparative Testing**: Run identical tests against microservices
4. **Analysis**: Compare performance, complexity, and maintainability
5. **Decision Making**: Use data to inform architectural decisions
