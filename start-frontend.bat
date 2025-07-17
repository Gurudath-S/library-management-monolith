@echo off
echo ===== Library Management System Frontend =====
echo.
echo Starting frontend server...
echo.
echo Frontend will be available at: http://localhost:8000
echo Backend API should be running at: http://localhost:8080/api
echo.
echo Make sure your Spring Boot application is running!
echo.
echo To start the backend:
echo   mvn spring-boot:run
echo.
echo Press Ctrl+C to stop the frontend server
echo.

cd frontend
python -m http.server 8000

pause
