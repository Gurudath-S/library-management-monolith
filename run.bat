@echo off
echo Starting Library Management System...
echo.
echo Default users available:
echo - Admin: username=admin, password=admin123
echo - Librarian: username=librarian, password=librarian123  
echo - User: username=user, password=user123
echo.
echo Application endpoints:
echo - Main API: http://localhost:8080/api
echo - H2 Database Console: http://localhost:8080/api/h2-console
echo - Health Check: http://localhost:8080/api/actuator/health
echo - Metrics: http://localhost:8080/api/actuator/metrics
echo - Prometheus: http://localhost:8080/api/actuator/prometheus
echo.
echo Quick API Test:
echo 1. Login: curl -X POST http://localhost:8080/api/auth/login -H "Content-Type: application/json" -d "{\"usernameOrEmail\":\"admin\",\"password\":\"admin123\"}"
echo 2. Use token: curl -X GET http://localhost:8080/api/books -H "Authorization: Bearer YOUR_JWT_TOKEN"
echo 3. Or run: .\test-api.ps1 (for automated testing)
echo 4. Test metrics: .\test-metrics.ps1 (for metrics endpoints)
echo.
echo For full monitoring, run: .\setup-monitoring.ps1
echo Then access Grafana at: http://localhost:3000 (admin/admin)
echo.
mvn spring-boot:run
