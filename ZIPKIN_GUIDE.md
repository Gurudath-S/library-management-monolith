# Zipkin Tracing Guide for Library Management System

## Overview
Zipkin is a distributed tracing system that helps you gather timing data needed to troubleshoot latency problems in your microservices architecture. Even in a monolithic application like this, it's useful for understanding request flows.

## How to View Zipkin Logs/Traces

### Method 1: Using Docker (Recommended)

1. **Start Zipkin using Docker:**
   ```powershell
   # Run the start-zipkin.ps1 script
   .\start-zipkin.ps1
   
   # Or manually:
   docker run -d -p 9411:9411 --name library-zipkin openzipkin/zipkin
   ```

2. **Start your application:**
   ```powershell
   mvn spring-boot:run
   ```

3. **Access Zipkin UI:**
   - Open browser and go to: http://localhost:9411
   - You'll see the Zipkin web interface

### Method 2: Using Docker Compose (Full Monitoring Stack)

1. **Start the full monitoring stack:**
   ```powershell
   docker-compose -f docker-compose.monitoring.yml up -d
   ```

2. **Access services:**
   - Zipkin: http://localhost:9411
   - Grafana: http://localhost:3000 (admin/admin)
   - Prometheus: http://localhost:9090

### Method 3: Download JAR (If Docker not available)

1. **Download Zipkin JAR:**
   - Go to: https://search.maven.org/remote_content?g=io.zipkin&a=zipkin-server&v=LATEST&c=exec
   - Save as `zipkin-server.jar`

2. **Run Zipkin:**
   ```powershell
   java -jar zipkin-server.jar
   ```

## Generating Traces

### Automatic Traces
Your application automatically generates traces for:
- All HTTP requests
- Database queries (JPA/Hibernate)
- Security filter processing
- Internal service calls

### Manual Testing
Run the test script to generate sample traces:
```powershell
.\test-tracing.ps1
```

Or make manual API calls:
```powershell
# Health check
Invoke-WebRequest -Uri "http://localhost:8080/api/actuator/health"

# Try login (will generate security traces)
Invoke-WebRequest -Uri "http://localhost:8080/api/auth/login" -Method POST
```

## Using Zipkin UI

### Finding Traces
1. **Open Zipkin UI:** http://localhost:9411
2. **Set criteria:**
   - Service Name: `library-management`
   - Lookback: Last 15 minutes (or desired time range)
   - Limit: 10 (or desired number)
3. **Click "Find Traces"**

### Viewing Trace Details
Click on any trace to see:
- **Timeline view:** Shows when each operation occurred
- **Span details:** Individual operations within the trace
- **Tags:** Metadata like HTTP status, method, URL
- **Logs:** Any logged events during the span

### Understanding Spans
Each trace contains multiple spans:
- **HTTP spans:** Web requests
- **DB spans:** Database queries  
- **Security spans:** Authentication/authorization
- **Custom spans:** Any manual instrumentation

### Useful Filters
- **Duration:** Find slow requests
  ```
  minDuration=100ms
  maxDuration=5s
  ```
- **Status codes:** Find errors
  ```
  http.status_code=500
  http.status_code=401
  ```
- **Specific endpoints:**
  ```
  http.url=/api/books
  ```

## Trace Information Available

### HTTP Request Information
- Method (GET, POST, etc.)
- URL path
- Status code
- Request duration
- Query parameters
- Headers (if configured)

### Database Information
- SQL queries executed
- Query duration
- Connection pool stats
- Transaction boundaries

### Security Information
- Authentication attempts
- Authorization decisions
- JWT token processing
- Security filter chain execution

### Custom Metrics
The application also sends custom metrics visible in traces:
- Book operations (create, update, delete)
- User registrations
- Transaction processing
- CSV import operations

## Troubleshooting

### Traces Not Appearing
1. **Check Zipkin is running:**
   ```powershell
   Invoke-WebRequest -Uri "http://localhost:9411/health"
   ```

2. **Check application logs for Zipkin connection:**
   Look for messages about Zipkin reporter in the console

3. **Verify configuration:**
   Ensure `management.tracing.sampling.probability=1.0` in application.properties

4. **Make requests to generate traces:**
   The application only sends traces when requests are made

### Performance Impact
- Sampling is set to 100% (1.0) for development
- In production, consider reducing to 0.1 (10%) or lower
- Tracing adds minimal overhead but avoid 100% sampling in production

## Integration with Other Tools

### Grafana Dashboards
- Traces can be correlated with metrics in Grafana
- Use trace IDs to link metrics and logs

### Log Correlation
- Application logs include trace and span IDs
- Format: `[library-management,traceId,spanId]`
- Use these IDs to correlate logs with traces

## Advanced Features

### Custom Spans
You can add custom spans in your code:
```java
@NewSpan("custom-operation")
public void customOperation() {
    // Your code here
}
```

### Span Tags
Add custom tags to spans:
```java
@GetMapping("/books/{id}")
public ResponseEntity<Book> getBook(@PathVariable String id, Span span) {
    span.tag("book.id", id);
    // Your code here
}
```

This guide should help you effectively use Zipkin for monitoring and debugging your Library Management System!
