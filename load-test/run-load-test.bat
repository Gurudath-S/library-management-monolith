@echo off
echo ===== Analytics Dashboard Load Test Runner =====
echo.
echo This script will run load tests against the monolithic analytics dashboard.
echo Make sure the Spring Boot application is running on http://localhost:8080
echo.

:menu
echo Select a test configuration:
echo 1. Quick Test (5 users, 1 minute)
echo 2. Standard Test (10 users, 2 minutes)
echo 3. Stress Test (20 users, 5 minutes)
echo 4. Custom Test (specify your own parameters)
echo 5. Exit
echo.
set /p choice="Enter your choice (1-5): "

if "%choice%"=="1" goto quick
if "%choice%"=="2" goto standard
if "%choice%"=="3" goto stress
if "%choice%"=="4" goto custom
if "%choice%"=="5" goto exit

echo Invalid choice. Please try again.
goto menu

:quick
echo Running Quick Test...
powershell -ExecutionPolicy Bypass -File "analytics-dashboard-load-test.ps1" -ConcurrentUsers 5 -TestDurationMinutes 1
goto end

:standard
echo Running Standard Test...
powershell -ExecutionPolicy Bypass -File "analytics-dashboard-load-test.ps1" -ConcurrentUsers 10 -TestDurationMinutes 2
goto end

:stress
echo Running Stress Test...
powershell -ExecutionPolicy Bypass -File "analytics-dashboard-load-test.ps1" -ConcurrentUsers 20 -TestDurationMinutes 5
goto end

:custom
echo Custom Test Configuration
set /p users="Enter number of concurrent users: "
set /p duration="Enter test duration in minutes: "
echo Running Custom Test with %users% users for %duration% minutes...
powershell -ExecutionPolicy Bypass -File "analytics-dashboard-load-test.ps1" -ConcurrentUsers %users% -TestDurationMinutes %duration%
goto end

:end
echo.
echo Load test completed!
echo Check the generated CSV file for detailed results.
echo.
pause
goto menu

:exit
echo Goodbye!
pause
