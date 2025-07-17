<!-- Use this file to provide workspace-specific custom instructions to Copilot. For more details, visit https://code.visualstudio.com/docs/copilot/copilot-customization#_use-a-githubcopilotinstructionsmd-file -->

# Library Management System - Copilot Instructions

This is a Java Spring Boot monolithic library management application with the following key characteristics:

## Architecture & Technology Stack
- **Framework**: Spring Boot 3.2.0 with Java 17
- **Database**: H2 (in-memory) with JPA/Hibernate
- **Security**: Spring Security with JWT authentication
- **Build Tool**: Maven
- **CSV Processing**: OpenCSV for bulk book imports

## Code Style & Conventions
- Follow Java naming conventions (camelCase for variables/methods, PascalCase for classes)
- Use Spring annotations appropriately (@RestController, @Service, @Repository, @Entity)
- Implement proper error handling with try-catch blocks and meaningful error messages
- Use validation annotations (@Valid, @NotBlank, @Email, etc.)
- Follow REST API conventions for endpoint naming

## Key Entities
- **User**: Authentication entity with roles (USER, LIBRARIAN, ADMIN)
- **Book**: Catalog entity with inventory tracking
- **Transaction**: Lending/return operations entity

## Security Implementation
- JWT-based authentication with role-based access control
- Different permission levels: USER < LIBRARIAN < ADMIN
- Secure password encoding with BCrypt
- Protected endpoints with @PreAuthorize annotations

## Business Logic Guidelines
- Maintain inventory consistency (available copies <= total copies)
- Enforce borrowing limits (max 5 books per user)
- Default 14-day borrowing period
- Prevent duplicate borrowing of same book by same user
- Proper transaction status management

## Database Patterns
- Use proper JPA relationships (@ManyToOne, @OneToMany)
- Implement audit fields (createdAt, updatedAt) with @PrePersist/@PreUpdate
- Use repository pattern with Spring Data JPA
- Implement custom queries for complex searches

## API Design Patterns
- Use DTOs for request/response objects
- Implement proper HTTP status codes
- Return meaningful error messages
- Support search and filtering functionality
- Implement pagination for large datasets where needed

## Testing Considerations
- Write unit tests for service layer business logic
- Test security configurations and role-based access
- Test CSV import functionality with various file formats
- Validate API endpoints with different user roles

When generating code for this project, ensure compatibility with the existing architecture and follow the established patterns.
