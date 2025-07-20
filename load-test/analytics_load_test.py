#!/usr/bin/env python3
"""
Analytics Dashboard Load Test Script for Monolithic Architecture
This script generates load against the analytics dashboard endpoint to measure performance.

Usage:
    python analytics_load_test.py --users 10 --duration 120 --url http://localhost:8080

Requirements:
    pip install requests statistics
"""

import argparse
import asyncio
import aiohttp
import json
import time
import statistics
from datetime import datetime, timedelta
from dataclasses import dataclass
from typing import List, Dict, Any
import csv

@dataclass
class TestResult:
    request_id: int
    timestamp: datetime
    response_time_ms: float
    status: str
    status_code: int = 0
    data_size: int = 0
    error_message: str = ""
    user_count: int = 0
    book_count: int = 0
    transaction_count: int = 0
    execution_time_ms: float = 0

class AnalyticsLoadTester:
    def __init__(self, base_url: str, username: str = "admin", password: str = "admin123"):
        self.base_url = base_url
        self.username = username
        self.password = password
        self.token = None
        self.results: List[TestResult] = []
        
    async def authenticate(self, session: aiohttp.ClientSession) -> bool:
        """Authenticate and get JWT token"""
        try:
            login_data = {
                "usernameOrEmail": self.username,
                "password": self.password
            }
            
            async with session.post(
                f"{self.base_url}/api/auth/login",
                json=login_data,
                timeout=aiohttp.ClientTimeout(total=30)
            ) as response:
                if response.status == 200:
                    data = await response.json()
                    self.token = data.get("token")
                    print(f"✓ Authentication successful")
                    return True
                else:
                    print(f"✗ Authentication failed with status {response.status}")
                    return False
        except Exception as e:
            print(f"✗ Authentication error: {str(e)}")
            return False
    
    async def test_dashboard_endpoint(self, session: aiohttp.ClientSession, request_id: int) -> TestResult:
        """Test the analytics dashboard endpoint"""
        headers = {
            "Authorization": f"Bearer {self.token}",
            "Accept": "application/json"
        }
        
        start_time = time.time()
        
        try:
            async with session.get(
                f"{self.base_url}/api/analytics/dashboard",
                headers=headers,
                timeout=aiohttp.ClientTimeout(total=60)
            ) as response:
                end_time = time.time()
                response_time = (end_time - start_time) * 1000  # Convert to milliseconds
                
                data = await response.json()
                data_size = len(json.dumps(data))
                
                if response.status == 200 and "dashboard" in data:
                    dashboard = data["dashboard"]
                    metadata = data.get("metadata", {})
                    
                    return TestResult(
                        request_id=request_id,
                        timestamp=datetime.now(),
                        response_time_ms=response_time,
                        status="Success",
                        status_code=response.status,
                        data_size=data_size,
                        user_count=dashboard.get("userAnalytics", {}).get("totalUsers", 0),
                        book_count=dashboard.get("bookAnalytics", {}).get("totalBooks", 0),
                        transaction_count=dashboard.get("transactionAnalytics", {}).get("totalTransactions", 0),
                        execution_time_ms=metadata.get("executionTimeMs", 0)
                    )
                else:
                    return TestResult(
                        request_id=request_id,
                        timestamp=datetime.now(),
                        response_time_ms=response_time,
                        status="Error",
                        status_code=response.status,
                        data_size=data_size,
                        error_message=f"HTTP {response.status}"
                    )
                    
        except Exception as e:
            end_time = time.time()
            response_time = (end_time - start_time) * 1000
            
            return TestResult(
                request_id=request_id,
                timestamp=datetime.now(),
                response_time_ms=response_time,
                status="Error",
                error_message=str(e)
            )
    
    async def run_concurrent_requests(self, session: aiohttp.ClientSession, concurrent_users: int, request_counter: int) -> List[TestResult]:
        """Run concurrent requests"""
        tasks = []
        for i in range(concurrent_users):
            task = self.test_dashboard_endpoint(session, request_counter + i)
            tasks.append(task)
        
        results = await asyncio.gather(*tasks, return_exceptions=True)
        
        # Filter out exceptions and return valid results
        valid_results = []
        for result in results:
            if isinstance(result, TestResult):
                valid_results.append(result)
        
        return valid_results
    
    async def run_load_test(self, concurrent_users: int, duration_seconds: int, warmup_requests: int = 5):
        """Run the complete load test"""
        print(f"=== Analytics Dashboard Load Test for Monolithic Architecture ===")
        print(f"Target URL: {self.base_url}/api/analytics/dashboard")
        print(f"Concurrent Users: {concurrent_users}")
        print(f"Test Duration: {duration_seconds} seconds")
        print(f"Warmup Requests: {warmup_requests}")
        print()
        
        # Configure aiohttp session
        connector = aiohttp.TCPConnector(limit=100, limit_per_host=50)
        timeout = aiohttp.ClientTimeout(total=60)
        
        async with aiohttp.ClientSession(connector=connector, timeout=timeout) as session:
            # Authenticate
            if not await self.authenticate(session):
                return
            
            # Warmup requests
            if warmup_requests > 0:
                print("Running warmup requests...")
                for i in range(warmup_requests):
                    result = await self.test_dashboard_endpoint(session, f"warmup-{i+1}")
                    print(f"Warmup {i+1}/{warmup_requests}: {result.response_time_ms:.2f}ms")
                
                print("Warmup completed. Starting actual load test...")
                print()
            
            # Main load test
            start_time = datetime.now()
            end_time = start_time + timedelta(seconds=duration_seconds)
            request_counter = 0
            
            print("Starting load test...")
            print(f"Test will run until: {end_time}")
            print()
            
            while datetime.now() < end_time:
                batch_results = await self.run_concurrent_requests(session, concurrent_users, request_counter)
                self.results.extend(batch_results)
                request_counter += len(batch_results)
                
                # Progress indicator
                if request_counter % 20 == 0:
                    success_count = len([r for r in self.results if r.status == "Success"])
                    error_count = len([r for r in self.results if r.status == "Error"])
                    avg_time = statistics.mean([r.response_time_ms for r in self.results if r.status == "Success"]) if success_count > 0 else 0
                    
                    print(f"Progress: {request_counter} requests | Success: {success_count} | Errors: {error_count} | Avg: {avg_time:.2f}ms")
                
                # Small delay to prevent overwhelming
                await asyncio.sleep(0.1)
    
    def generate_performance_report(self, duration_seconds: int, concurrent_users: int):
        """Generate comprehensive performance report"""
        successful_results = [r for r in self.results if r.status == "Success"]
        error_results = [r for r in self.results if r.status == "Error"]
        
        total_requests = len(self.results)
        success_count = len(successful_results)
        error_count = len(error_results)
        success_rate = (success_count / total_requests * 100) if total_requests > 0 else 0
        
        if successful_results:
            response_times = [r.response_time_ms for r in successful_results]
            avg_response_time = statistics.mean(response_times)
            median_response_time = statistics.median(response_times)
            min_response_time = min(response_times)
            max_response_time = max(response_times)
            
            # Calculate percentiles
            sorted_times = sorted(response_times)
            p90 = sorted_times[int(len(sorted_times) * 0.9)]
            p95 = sorted_times[int(len(sorted_times) * 0.95)]
            p99 = sorted_times[int(len(sorted_times) * 0.99)]
            
            # Data analysis
            avg_data_size = statistics.mean([r.data_size for r in successful_results])
            avg_execution_time = statistics.mean([r.execution_time_ms for r in successful_results if r.execution_time_ms > 0])
        else:
            avg_response_time = median_response_time = min_response_time = max_response_time = 0
            p90 = p95 = p99 = 0
            avg_data_size = avg_execution_time = 0
        
        # Throughput calculation
        throughput = total_requests / duration_seconds if duration_seconds > 0 else 0
        
        print("\n=== MONOLITHIC ARCHITECTURE PERFORMANCE REPORT ===")
        print()
        print("Test Configuration:")
        print(f"  Concurrent Users: {concurrent_users}")
        print(f"  Test Duration: {duration_seconds} seconds")
        print(f"  Target Endpoint: /api/analytics/dashboard")
        print()
        print("Request Statistics:")
        print(f"  Total Requests: {total_requests}")
        print(f"  Successful Requests: {success_count}")
        print(f"  Failed Requests: {error_count}")
        print(f"  Success Rate: {success_rate:.2f}%")
        print(f"  Throughput: {throughput:.2f} requests/second")
        print()
        print("Response Time Analysis:")
        print(f"  Average Response Time: {avg_response_time:.2f}ms")
        print(f"  Median Response Time: {median_response_time:.2f}ms")
        print(f"  Minimum Response Time: {min_response_time:.2f}ms")
        print(f"  Maximum Response Time: {max_response_time:.2f}ms")
        print()
        print("Response Time Percentiles:")
        print(f"  90th Percentile: {p90:.2f}ms")
        print(f"  95th Percentile: {p95:.2f}ms")
        print(f"  99th Percentile: {p99:.2f}ms")
        print()
        
        if successful_results:
            sample_result = successful_results[0]
            print("Data Analysis:")
            print(f"  Average Response Data Size: {avg_data_size:.2f} bytes")
            print(f"  Average Server Execution Time: {avg_execution_time:.2f}ms")
            print(f"  Sample Data Counts:")
            print(f"    Users: {sample_result.user_count}")
            print(f"    Books: {sample_result.book_count}")
            print(f"    Transactions: {sample_result.transaction_count}")
            print()
        
        # Performance assessment
        print("Performance Assessment:")
        if avg_response_time < 500:
            print("  ✓ Excellent response time (< 500ms)")
        elif avg_response_time < 1000:
            print("  ⚠ Good response time (500-1000ms)")
        elif avg_response_time < 2000:
            print("  ⚠ Acceptable response time (1-2s)")
        else:
            print("  ✗ Poor response time (> 2s)")
        
        if success_rate > 95:
            print("  ✓ Excellent reliability (> 95% success rate)")
        elif success_rate > 90:
            print("  ⚠ Good reliability (90-95% success rate)")
        else:
            print("  ✗ Poor reliability (< 90% success rate)")
        
        # Save detailed results to CSV
        timestamp = datetime.now().strftime('%Y%m%d-%H%M%S')
        csv_filename = f"analytics-dashboard-load-test-results-{timestamp}.csv"
        
        with open(csv_filename, 'w', newline='') as csvfile:
            fieldnames = [
                'request_id', 'timestamp', 'response_time_ms', 'status', 'status_code',
                'data_size', 'user_count', 'book_count', 'transaction_count',
                'execution_time_ms', 'error_message'
            ]
            writer = csv.DictWriter(csvfile, fieldnames=fieldnames)
            writer.writeheader()
            
            for result in self.results:
                writer.writerow({
                    'request_id': result.request_id,
                    'timestamp': result.timestamp.isoformat(),
                    'response_time_ms': result.response_time_ms,
                    'status': result.status,
                    'status_code': result.status_code,
                    'data_size': result.data_size,
                    'user_count': result.user_count,
                    'book_count': result.book_count,
                    'transaction_count': result.transaction_count,
                    'execution_time_ms': result.execution_time_ms,
                    'error_message': result.error_message
                })
        
        print(f"\nDetailed results saved to: {csv_filename}")
        print("\nLoad test completed successfully!")
        print("This data can be compared with microservices architecture performance.")
        
        return {
            "total_requests": total_requests,
            "successful_requests": success_count,
            "failed_requests": error_count,
            "success_rate": success_rate,
            "average_response_time": avg_response_time,
            "median_response_time": median_response_time,
            "p90_response_time": p90,
            "p95_response_time": p95,
            "p99_response_time": p99,
            "throughput": throughput,
            "min_response_time": min_response_time,
            "max_response_time": max_response_time
        }

async def main():
    parser = argparse.ArgumentParser(description='Analytics Dashboard Load Test for Monolithic Architecture')
    parser.add_argument('--users', type=int, default=10, help='Number of concurrent users (default: 10)')
    parser.add_argument('--duration', type=int, default=120, help='Test duration in seconds (default: 120)')
    parser.add_argument('--url', type=str, default='http://localhost:8080', help='Base URL (default: http://localhost:8080)')
    parser.add_argument('--username', type=str, default='admin', help='Username (default: admin)')
    parser.add_argument('--password', type=str, default='admin123', help='Password (default: admin123)')
    parser.add_argument('--warmup', type=int, default=5, help='Number of warmup requests (default: 5)')
    
    args = parser.parse_args()
    
    tester = AnalyticsLoadTester(args.url, args.username, args.password)
    
    try:
        await tester.run_load_test(args.users, args.duration, args.warmup)
        tester.generate_performance_report(args.duration, args.users)
    except KeyboardInterrupt:
        print("\nTest interrupted by user")
        if tester.results:
            tester.generate_performance_report(args.duration, args.users)
    except Exception as e:
        print(f"Test failed: {str(e)}")

if __name__ == "__main__":
    asyncio.run(main())
