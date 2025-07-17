# Library Management System - Frontend

This is a simple HTML/CSS/JavaScript frontend for the Library Management System backend API.

## Features

- **User Authentication**: Login with username/email and password
- **Books Management**: View, add, borrow, and manage books
- **Transactions**: View borrowing history and return books
- **User Management**: Register new users (admin/librarian only)
- **Responsive Design**: Works on desktop and mobile devices

## How to Use

### Prerequisites

1. **Backend Running**: Make sure the Spring Boot backend is running on `http://localhost:8080`
2. **Python**: Required for the simple HTTP server (usually pre-installed on most systems)

### Starting the Frontend

#### Option 1: Using the Batch Script (Windows)
```bash
start-frontend.bat
```

#### Option 2: Using PowerShell Script
```powershell
.\start-frontend.ps1
```

#### Option 3: Manual Start
```bash
cd frontend
python -m http.server 8000
```

### Accessing the Application

1. Open your web browser
2. Go to: `http://localhost:8000`
3. You'll see the login page

### Default User Accounts

The system comes with these default accounts:

- **Admin User**:
  - Username: `admin`
  - Password: `admin123`
  - Can manage users, books, and view all transactions

- **Librarian User**:
  - Username: `librarian`
  - Password: `librarian123`
  - Can manage books and view transactions

- **Regular User**:
  - Username: `user`
  - Password: `user123`
  - Can borrow/return books and view own transactions

## Features by User Role

### All Users
- Login/Logout
- View available books
- Borrow available books
- View own transaction history
- Return borrowed books

### Librarian + Admin
- Add new books
- Edit book information
- Delete books
- View all transactions
- Register new users

### Admin Only
- View all users
- Manage user roles
- Access admin endpoints

## API Integration

The frontend communicates with the backend using REST API calls:

- **Authentication**: JWT token-based authentication
- **CORS**: Configured to allow cross-origin requests
- **Error Handling**: User-friendly error messages
- **Auto-logout**: On authentication errors

## Technology Stack

- **HTML5**: Structure and markup
- **CSS3**: Styling with Bootstrap 5
- **JavaScript (ES6+)**: Frontend logic and API calls
- **Bootstrap 5**: Responsive UI framework
- **Font Awesome**: Icons

## Browser Compatibility

- Chrome (recommended)
- Firefox
- Safari
- Edge

## Development

### File Structure
```
frontend/
├── index.html          # Main HTML file
├── app.js             # JavaScript application logic
└── README.md          # This file
```

### Customization

You can customize the frontend by:

1. **Styling**: Modify CSS in `index.html` or add external stylesheets
2. **Functionality**: Edit `app.js` to add new features
3. **API Endpoints**: Update `API_BASE_URL` in `app.js` if backend URL changes

### Security Features

- **Token Storage**: JWT tokens stored in localStorage
- **Auto-logout**: On token expiration or authentication errors
- **Input Validation**: Client-side validation with server-side backup
- **CSRF Protection**: Not needed due to JWT authentication

## Troubleshooting

### Frontend Won't Start
- Make sure Python is installed
- Check if port 8000 is available
- Try using a different port: `python -m http.server 3000`

### Can't Login
- Verify backend is running on `http://localhost:8080`
- Check browser console for error messages
- Ensure CORS is properly configured in backend

### API Errors
- Check backend logs for detailed error messages
- Verify API endpoints in `app.js` match backend routes
- Check network tab in browser developer tools

### CORS Issues
- Make sure backend SecurityConfig includes CORS configuration
- Check if `management.endpoints.web.cors.allowed-origins=*` is set in application.properties

## Future Enhancements

Possible improvements for the frontend:

1. **Advanced Search**: Search books by title, author, category
2. **Pagination**: For large lists of books/transactions
3. **Book Covers**: Display book cover images
4. **Due Date Reminders**: Visual indicators for overdue books
5. **Dark Mode**: Theme switching capability
6. **Offline Support**: Service worker for basic offline functionality
7. **Real-time Updates**: WebSocket integration for live updates
8. **Mobile App**: React Native or Flutter version
9. **Advanced Filters**: Filter books by availability, category, etc.
10. **User Profiles**: Extended user information and preferences

## License

This frontend is part of the Library Management System project and follows the same license as the backend application.
