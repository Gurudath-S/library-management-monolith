# Library Management System API Documentation

## Authentication

All API endpoints (except auth endpoints) require JWT authentication. Include the JWT token in the Authorization header:

```
Authorization: Bearer <your-jwt-token>
```

## Authentication Endpoints

### Register User
```http
POST /api/auth/register
Content-Type: application/json

{
    "username": "newuser",
    "password": "password123",
    "email": "user@example.com",
    "firstName": "John",
    "lastName": "Doe",
    "phoneNumber": "123-456-7890",
    "address": "123 Main St"
}
```

### Login
```http
POST /api/auth/login
Content-Type: application/json

{
    "usernameOrEmail": "admin",
    "password": "admin123"
}
```

**Response:**
```json
{
    "token": "eyJhbGciOiJIUzI1NiJ9...",
    "type": "Bearer",
    "username": "admin",
    "email": "admin@library.com",
    "role": "ADMIN"
}
```

## User Management Endpoints

### Get Current User Profile
```http
GET /api/users/profile
Authorization: Bearer <token>
```

### Update Current User Profile
```http
PUT /api/users/profile
Authorization: Bearer <token>
Content-Type: application/json

{
    "firstName": "Updated Name",
    "lastName": "Updated Last",
    "email": "updated@email.com",
    "phoneNumber": "987-654-3210",
    "address": "456 New St"
}
```

### Get All Users (Admin/Librarian only)
```http
GET /api/users
Authorization: Bearer <admin-or-librarian-token>
```

### Search Users (Admin/Librarian only)
```http
GET /api/users/search?searchTerm=john
Authorization: Bearer <admin-or-librarian-token>
```

### Update User Role (Admin only)
```http
PUT /api/users/1/role?role=LIBRARIAN
Authorization: Bearer <admin-token>
```

## Book Management Endpoints

### Get All Books
```http
GET /api/books
```

### Get Available Books
```http
GET /api/books/available
```

### Search Books
```http
GET /api/books/search?searchTerm=java
```

### Get Books by Category
```http
GET /api/books/category/Programming
```

### Get Books by Author
```http
GET /api/books/author/Joshua%20Bloch
```

### Create New Book (Admin/Librarian only)
```http
POST /api/books
Authorization: Bearer <admin-or-librarian-token>
Content-Type: application/json

{
    "isbn": "978-1234567890",
    "title": "New Programming Book",
    "author": "Author Name",
    "category": "Programming",
    "publisher": "Tech Publications",
    "publicationYear": 2024,
    "description": "A comprehensive guide to programming",
    "totalCopies": 5,
    "price": 49.99,
    "pages": 300,
    "language": "English"
}
```

### Upload Books from CSV (Admin/Librarian only)
```http
POST /api/books/upload
Authorization: Bearer <admin-or-librarian-token>
Content-Type: multipart/form-data

file: [CSV file]
```

**CSV Format:**
```csv
ISBN,Title,Author,Category,Publisher,TotalCopies,Price,PublicationYear,Pages,Language,Description
978-0134685991,Effective Java,Joshua Bloch,Programming,Addison-Wesley Professional,10,45.99,2017,412,English,The definitive guide to Java programming
```

### Update Book (Admin/Librarian only)
```http
PUT /api/books/1
Authorization: Bearer <admin-or-librarian-token>
Content-Type: application/json

{
    "isbn": "978-1234567890",
    "title": "Updated Book Title",
    "author": "Updated Author",
    "category": "Updated Category",
    "totalCopies": 10,
    "availableCopies": 8
}
```

### Update Book Inventory (Admin/Librarian only)
```http
PUT /api/books/1/inventory?totalCopies=15&availableCopies=12
Authorization: Bearer <admin-or-librarian-token>
```

## Transaction Management Endpoints

### Borrow a Book
```http
POST /api/transactions/borrow?bookId=1
Authorization: Bearer <user-token>
```

### Return a Book
```http
POST /api/transactions/return?bookId=1
Authorization: Bearer <user-token>
```

### Get My Transaction History
```http
GET /api/transactions/my-history
Authorization: Bearer <user-token>
```

### Get My Active Transactions
```http
GET /api/transactions/my-active
Authorization: Bearer <user-token>
```

### Get All Transactions (Admin/Librarian only)
```http
GET /api/transactions/all
Authorization: Bearer <admin-or-librarian-token>
```

### Get Overdue Transactions (Admin/Librarian only)
```http
GET /api/transactions/overdue
Authorization: Bearer <admin-or-librarian-token>
```

### Get User's Transaction History (Admin/Librarian only)
```http
GET /api/transactions/user/1
Authorization: Bearer <admin-or-librarian-token>
```

### Get Book's Transaction History (Admin/Librarian only)
```http
GET /api/transactions/book/1
Authorization: Bearer <admin-or-librarian-token>
```

### Extend Due Date (Admin/Librarian only)
```http
PUT /api/transactions/1/extend?newDueDate=2024-07-15T10:00:00
Authorization: Bearer <admin-or-librarian-token>
```

### Cancel Transaction (Admin/Librarian only)
```http
PUT /api/transactions/1/cancel
Authorization: Bearer <admin-or-librarian-token>
```

## Utility Endpoints

### Get All Categories
```http
GET /api/books/categories
```

### Get All Authors
```http
GET /api/books/authors
```

### Get All Publishers
```http
GET /api/books/publishers
```

### Get Low Stock Books (Admin/Librarian only)
```http
GET /api/books/low-stock?threshold=5
Authorization: Bearer <admin-or-librarian-token>
```

### Get Out of Stock Books (Admin/Librarian only)
```http
GET /api/books/out-of-stock
Authorization: Bearer <admin-or-librarian-token>
```

## Error Responses

All endpoints return appropriate HTTP status codes and error messages:

### 400 Bad Request
```json
{
    "error": "Book is not available for borrowing"
}
```

### 401 Unauthorized
```json
{
    "error": "JWT token is expired"
}
```

### 403 Forbidden
```json
{
    "error": "Access denied"
}
```

### 404 Not Found
```json
{
    "error": "Book not found with id: 999"
}
```

## Business Rules

### User Borrowing Limits
- Maximum 5 books per user
- 14-day default borrowing period
- Cannot borrow the same book twice
- Must return overdue books before borrowing new ones

### Role Permissions
- **USER**: Borrow/return books, view own profile and history
- **LIBRARIAN**: All user permissions + manage books, view all transactions
- **ADMIN**: All permissions + manage users and roles

### Book Management Rules
- Available copies cannot exceed total copies
- Books must have unique ISBN
- Required fields: ISBN, Title, Author, Category, Total Copies

## Monitoring & Metrics Endpoints

### Health Check
```http
GET /api/actuator/health
```

**Response:**
```json
{
    "status": "UP",
    "components": {
        "db": {
            "status": "UP",
            "details": {
                "database": "H2",
                "validationQuery": "SELECT 1"
            }
        },
        "diskSpace": {
            "status": "UP",
            "details": {
                "total": 250685575168,
                "free": 137438953472,
                "threshold": 10485760,
                "path": "C:\\Users\\..."
            }
        }
    }
}
```

### Application Metrics
```http
GET /api/actuator/metrics
```

**Response:** List of available metrics

### Prometheus Metrics
```http
GET /api/actuator/prometheus
```

**Response:** Metrics in Prometheus format for scraping

### Application Information
```http
GET /api/actuator/info
```

### Custom Business Metrics

Access specific business metrics:

```http
GET /api/actuator/metrics/library.users.registered
GET /api/actuator/metrics/library.books.created
GET /api/actuator/metrics/library.transactions.borrowed
GET /api/actuator/metrics/library.transactions.returned
GET /api/actuator/metrics/library.csv.imports
```

### HTTP Request Metrics

View endpoint performance metrics:

```http
GET /api/actuator/metrics/http.server.requests?tag=uri:/api/books
GET /api/actuator/metrics/http.server.requests?tag=method:POST
GET /api/actuator/metrics/http.server.requests?tag=status:200
```

### External Monitoring Tools

- **Grafana Dashboard**: http://localhost:3000
  - Pre-configured dashboard with throughput, latency, and error metrics
  - Login: admin/admin
  
- **Prometheus**: http://localhost:9090
  - Metrics storage and querying interface
  
- **Zipkin Tracing**: http://localhost:9411
  - Distributed tracing for request flow analysis
