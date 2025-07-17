# Library Management System

A comprehensive Java Spring Boot monolithic application for managing library operations including book cataloging, user management, and lending transactions.

## Features

### User Management
- **User Registration & Authentication**: Secure user registration and JWT-based authentication
- **Role-based Access Control**: Support for User, Librarian, and Admin roles
- **User Profile Management**: Users can update their profiles and view transaction history
- **Admin Controls**: Admins can manage user roles, enable/disable accounts

### Book Catalog Management
- **Book CRUD Operations**: Create, read, update, and delete books
- **CSV Import**: Bulk import books from CSV files
- **Advanced Search**: Search books by title, author, ISBN, category, or publisher
- **Category & Author Management**: Browse books by categories and authors
- **Inventory Tracking**: Track total and available copies

### Transaction Management
- **Book Lending**: Users can borrow available books
- **Book Returns**: Return borrowed books to update inventory
- **Transaction History**: Complete history of all lending transactions
- **Overdue Management**: Track and manage overdue books
- **Due Date Extensions**: Librarians can extend due dates

### Security Features
- **JWT Authentication**: Secure token-based authentication
- **Role-based Authorization**: Different access levels for users, librarians, and admins
- **Password Encryption**: Secure password storage using BCrypt
- **CORS Configuration**: Cross-origin resource sharing support

## Technology Stack

### Core Application
- **Framework**: Spring Boot 3.3.0
- **Database**: H2 (in-memory for development)
- **Security**: Spring Security with JWT
- **ORM**: Spring Data JPA
- **Build Tool**: Maven
- **Java Version**: 22
- **CSV Processing**: OpenCSV
- **API Documentation**: REST endpoints

### Frontend
- **Web Interface**: HTML5/CSS3/JavaScript frontend
- **UI Framework**: Bootstrap 5 for responsive design
- **Icons**: Font Awesome
- **API Integration**: Fetch API for REST communication
- **Authentication**: JWT token management
- **Browser Support**: Modern browsers (Chrome, Firefox, Safari, Edge)

### Monitoring & Metrics
- **Actuator**: Spring Boot Actuator for health checks and metrics
- **Metrics**: Micrometer with Prometheus integration
- **Visualization**: Grafana with pre-built dashboards
- **Tracing**: Zipkin for distributed request tracing
- **Load Testing**: Custom PowerShell and Bash scripts
- **Containerization**: Docker Compose for monitoring stack

## Getting Started

### Prerequisites
- Java 22 or higher
- Maven 3.6 or higher

### Installation

1. **Clone the repository**
   ```bash
   git clone <repository-url>
   cd library-management
   ```

2. **Build the project**
   ```bash
   mvn clean compile
   ```

3. **Run the application**
   ```bash
   mvn spring-boot:run
   ```

The application will start on `http://localhost:8080/api`

## Quick Start with Monitoring

Want to see the application with full monitoring capabilities? Follow these steps:

### 1. Start Everything
```powershell
# Start the monitoring stack (Prometheus, Grafana, Zipkin)
.\setup-monitoring.ps1

# In a new terminal, start the application
mvn spring-boot:run
```

### 2. Access the Dashboards
- **Application**: http://localhost:8080/api
- **Grafana Dashboard**: http://localhost:3000 (admin/admin)
- **Prometheus Metrics**: http://localhost:9090
- **Zipkin Tracing**: http://localhost:9411

### 3. Generate Load and View Metrics
```powershell
# Run performance tests to see metrics in action
.\load-test.ps1
```

Then check the Grafana dashboard to see real-time performance metrics!

### Default Users

The application comes with pre-configured users:

| Username  | Password      | Role      | Email                |
|-----------|---------------|-----------|----------------------|
| admin     | admin123      | ADMIN     | admin@library.com    |
| librarian | librarian123  | LIBRARIAN | librarian@library.com|
| user      | user123       | USER      | user@library.com     |

### H2 Database Console

For development, you can access the H2 database console at:
- URL: `http://localhost:8080/api/h2-console`
- JDBC URL: `jdbc:h2:mem:library_db`
- Username: `sa`
- Password: `password`

## API Endpoints

### Authentication Endpoints
- `POST /api/auth/register` - Register a new user
- `POST /api/auth/login` - Login and get JWT token

### User Endpoints
- `GET /api/users/profile` - Get current user profile
- `PUT /api/users/profile` - Update current user profile
- `GET /api/users` - Get all users (Admin/Librarian only)
- `GET /api/users/search?searchTerm=term` - Search users
- `PUT /api/users/{id}/role?role=ADMIN` - Update user role (Admin only)

### Book Endpoints
- `GET /api/books` - Get all books
- `GET /api/books/available` - Get available books
- `GET /api/books/search?searchTerm=term` - Search books
- `GET /api/books/category/{category}` - Get books by category
- `GET /api/books/author/{author}` - Get books by author
- `POST /api/books` - Create new book (Admin/Librarian only)
- `POST /api/books/upload` - Upload books from CSV (Admin/Librarian only)
- `PUT /api/books/{id}` - Update book (Admin/Librarian only)
- `PUT /api/books/{id}/inventory` - Update inventory (Admin/Librarian only)

### Transaction Endpoints
- `POST /api/transactions/borrow?bookId={id}` - Borrow a book
- `POST /api/transactions/return?bookId={id}` - Return a book
- `GET /api/transactions/my-history` - Get user's transaction history
- `GET /api/transactions/my-active` - Get user's active transactions
- `GET /api/transactions/all` - Get all transactions (Admin/Librarian only)
- `GET /api/transactions/overdue` - Get overdue transactions (Admin/Librarian only)

## CSV Import Format

To import books via CSV, use the following format:

```csv
ISBN,Title,Author,Category,Publisher,TotalCopies,Price,PublicationYear,Pages,Language,Description
978-0134685991,Effective Java,Joshua Bloch,Programming,Addison-Wesley Professional,10,45.99,2017,412,English,The definitive guide to Java programming
```

**Required Fields**: ISBN, Title, Author, Category, TotalCopies
**Optional Fields**: Publisher, Price, PublicationYear, Pages, Language, Description

## Configuration

### Database Configuration
The application uses H2 in-memory database by default. To use a different database, update `application.properties`:

```properties
# For MySQL
spring.datasource.url=jdbc:mysql://localhost:3306/library_db
spring.datasource.username=your_username
spring.datasource.password=your_password
spring.jpa.database-platform=org.hibernate.dialect.MySQL8Dialect
```

### JWT Configuration
```properties
jwt.secret=your_secret_key
jwt.expiration=86400000
```

### File Upload Configuration
```properties
spring.servlet.multipart.max-file-size=10MB
spring.servlet.multipart.max-request-size=10MB
```

## Business Rules

### Borrowing Rules
- Users can borrow up to 5 books simultaneously
- Default borrowing period is 14 days
- Books must be available (copies > 0)
- Users cannot borrow the same book twice

### User Roles
- **USER**: Can borrow/return books, view their profile and history
- **LIBRARIAN**: All user permissions + manage books, view all transactions
- **ADMIN**: All permissions + manage users, user roles, delete books

## Monitoring & Metrics

This application includes comprehensive monitoring and metrics collection for performance analysis, making it ideal for comparing different architectural approaches (monolithic vs microservices).

### Monitoring Stack

The application integrates with the following monitoring tools:

- **Spring Boot Actuator**: Health checks and application metrics
- **Micrometer + Prometheus**: Metrics collection and storage
- **Grafana**: Metrics visualization and dashboards
- **Zipkin**: Distributed tracing for request tracking

### Metrics Collected

#### System Metrics
- **HTTP Request Metrics**: Latency, throughput, error rates for all API endpoints
- **JVM Metrics**: Memory usage, garbage collection, thread pools
- **Database Metrics**: Connection pool, query performance
- **Application Health**: Service availability and dependencies

#### Business Metrics
- **User Operations**: Registration count, login attempts, active users
- **Book Operations**: Book creation, searches, inventory updates
- **Transaction Operations**: Borrow/return rates, overdue books
- **CSV Import Operations**: Import success/failure rates, processing time

### Quick Start with Monitoring

#### 1. Start the Monitoring Stack
```powershell
# Using the automated setup script (Windows)
.\setup-monitoring.ps1

# Or manually with Docker Compose
docker-compose -f docker-compose.monitoring.yml up -d
```

#### 2. Start the Application
```bash
# Start the Spring Boot application
mvn spring-boot:run
```

#### 3. Access Monitoring Tools

| Tool | URL | Default Credentials |
|------|-----|-------------------|
| **Application** | http://localhost:8080/api | - |
| **Grafana Dashboard** | http://localhost:3000 | admin/admin |
| **Prometheus** | http://localhost:9090 | - |
| **Zipkin Tracing** | http://localhost:9411 | - |
| **Application Metrics** | http://localhost:8080/api/actuator/prometheus | - |

#### 4. View Pre-built Dashboard

1. Open Grafana at http://localhost:3000
2. Login with `admin/admin`
3. Navigate to **Dashboards** → **Library Management System**
4. View real-time metrics including:
   - Request throughput (requests/second)
   - Response latency (percentiles: 50th, 90th, 95th, 99th)
   - Error rates by endpoint
   - Database connection metrics
   - JVM performance metrics

### Performance Testing

#### Load Testing Scripts

Run performance tests to generate metrics:

```powershell
# Windows PowerShell
.\load-test.ps1

# Linux/Mac Bash
./load-test.sh
```

The load test will:
- Create 1000+ requests across different endpoints
- Test user registration, authentication, book operations
- Generate CSV import operations
- Report latency and throughput statistics

#### Custom Metrics Endpoints

- **Health Check**: `GET /api/actuator/health`
- **All Metrics**: `GET /api/actuator/metrics`
- **Prometheus Format**: `GET /api/actuator/prometheus`
- **Application Info**: `GET /api/actuator/info`

### Monitoring Configuration

The monitoring is configured through `application.properties`:

```properties
# Actuator Endpoints
management.endpoints.web.exposure.include=*
management.endpoint.health.show-details=always
management.endpoint.metrics.enabled=true
management.endpoint.prometheus.enabled=true

# Metrics Configuration
management.metrics.export.prometheus.enabled=true
management.metrics.distribution.percentiles-histogram.http.server.requests=true
management.metrics.distribution.percentiles.http.server.requests=0.5,0.9,0.95,0.99

# Tracing Configuration
management.tracing.sampling.probability=1.0
management.zipkin.tracing.endpoint=http://localhost:9411/api/v2/spans
```

### Architecture Comparison Ready

This monolithic implementation is fully instrumented for performance comparison with:
- **Microservices Architecture**: Compare latency, throughput, and complexity
- **Hybrid Monolith**: Analyze modular vs traditional monolithic approaches
- **Different Deployment Strategies**: Compare containerized vs traditional deployment

The metrics collected will enable detailed analysis of:
- Response times under load
- Resource utilization patterns
- Error handling effectiveness
- Scalability characteristics

### Troubleshooting Monitoring

#### Common Issues and Solutions

1. **Grafana Dashboard Not Loading**
   ```bash
   # Check if Grafana is running
   docker ps | grep grafana
   
   # Restart Grafana if needed
   docker-compose -f docker-compose.monitoring.yml restart grafana
   ```

2. **Prometheus Not Collecting Metrics**
   ```bash
   # Verify Prometheus can reach the application
   curl http://localhost:8080/api/actuator/prometheus
   
   # Check Prometheus targets at http://localhost:9090/targets
   ```

3. **Zipkin Traces Not Appearing**
   ```bash
   # Ensure tracing is enabled in application.properties
   management.tracing.sampling.probability=1.0
   
   # Check Zipkin service status
   docker-compose -f docker-compose.monitoring.yml logs zipkin
   ```

4. **Load Test Scripts Failing**
   ```powershell
   # Windows: Ensure execution policy allows scripts
   Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
   
   # Verify application is running before load test
   curl http://localhost:8080/api/actuator/health
   ```

## Development

### Running Tests
```bash
mvn test
```

### Building for Production
```bash
mvn clean package
java -jar target/library-management-1.0.0.jar
```

### Project Structure
```
├── src/
│   ├── main/
│   │   ├── java/com/library/
│   │   │   ├── config/          # Configuration classes (Security, JWT, Metrics)
│   │   │   ├── controller/      # REST controllers
│   │   │   ├── dto/            # Data Transfer Objects
│   │   │   ├── entity/         # JPA entities
│   │   │   ├── repository/     # Data repositories
│   │   │   └── service/        # Business logic
│   │   └── resources/
│   │       └── application.properties
│   └── test/
│       └── java/com/library/    # Test classes
├── monitoring/
│   ├── grafana/
│   │   ├── dashboards/         # Pre-built Grafana dashboards
│   │   └── provisioning/       # Grafana configuration
│   └── prometheus.yml          # Prometheus configuration
├── docker-compose.monitoring.yml  # Monitoring stack setup
├── load-test.ps1              # PowerShell load testing script
├── load-test.sh               # Bash load testing script
├── setup-monitoring.ps1       # Automated monitoring setup
└── sample_books.csv           # Sample data for CSV import
```

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Add tests for new functionality
5. Submit a pull request

## License

This project is licensed under the MIT License.

## Support

For support and questions, please create an issue in the repository or contact the development team.

## Quick Start with Frontend

For the complete experience with a web interface:

### 1. Start the Backend
```powershell
mvn spring-boot:run
```

### 2. Start the Frontend
```powershell
# Option 1: Using PowerShell script
.\start-frontend.ps1

# Option 2: Using batch file
start-frontend.bat

# Option 3: Manual start
cd frontend
python -m http.server 8000
```

### 3. Access the Web Application
- **Frontend**: http://localhost:8000
- **Backend API**: http://localhost:8080/api
- **Admin Dashboard**: Login with admin/admin123

The web interface provides:
- User-friendly login page
- Books catalog with search and filtering
- Transaction management
- User administration (for librarians/admins)
- Responsive design for mobile and desktop
