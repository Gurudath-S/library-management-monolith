// Library Management System Frontend JavaScript

const API_BASE_URL = 'http://localhost:8080/api';
let authToken = null;
let currentUser = null;

// Initialize the application
document.addEventListener('DOMContentLoaded', function() {
    // Check if user is already logged in
    const savedToken = localStorage.getItem('authToken');
    const savedUser = localStorage.getItem('currentUser');
    
    if (savedToken && savedUser) {
        authToken = savedToken;
        currentUser = JSON.parse(savedUser);
        showMainSection();
        loadBooks();
    }

    // Set up event listeners
    document.getElementById('loginForm').addEventListener('submit', handleLogin);
});

// Authentication Functions
async function handleLogin(event) {
    event.preventDefault();
    
    const usernameOrEmail = document.getElementById('usernameOrEmail').value;
    const password = document.getElementById('password').value;
    
    try {
        showAlert('Logging in...', 'info');
        
        const response = await fetch(`${API_BASE_URL}/auth/login`, {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json'
            },
            body: JSON.stringify({
                usernameOrEmail: usernameOrEmail,
                password: password
            })
        });
        
        if (response.ok) {
            const data = await response.json();
            authToken = data.token;
            currentUser = {
                username: data.username,
                email: data.email,
                role: data.role
            };
            
            // Save to localStorage
            localStorage.setItem('authToken', authToken);
            localStorage.setItem('currentUser', JSON.stringify(currentUser));
            
            showAlert('Login successful!', 'success');
            showMainSection();
            loadBooks();
        } else {
            const error = await response.text();
            showAlert(`Login failed: ${error}`, 'danger');
        }
    } catch (error) {
        showAlert(`Login error: ${error.message}`, 'danger');
    }
}

function logout() {
    authToken = null;
    currentUser = null;
    localStorage.removeItem('authToken');
    localStorage.removeItem('currentUser');
    
    document.getElementById('loginSection').classList.remove('hidden');
    document.getElementById('mainSection').classList.add('hidden');
    document.getElementById('userInfo').classList.add('hidden');
    
    // Clear form
    document.getElementById('loginForm').reset();
    
    showAlert('Logged out successfully', 'info');
}

function showMainSection() {
    document.getElementById('loginSection').classList.add('hidden');
    document.getElementById('mainSection').classList.remove('hidden');
    document.getElementById('userInfo').classList.remove('hidden');
    
    // Update user info
    document.getElementById('currentUser').textContent = currentUser.username;
    document.getElementById('userDetails').textContent = 
        `${currentUser.username} (${currentUser.email}) - Role: ${currentUser.role}`;
}

// API Helper Functions
async function apiRequest(url, options = {}) {
    const defaultOptions = {
        headers: {
            'Content-Type': 'application/json',
            ...(authToken && { 'Authorization': `Bearer ${authToken}` })
        }
    };
    
    const mergedOptions = {
        ...defaultOptions,
        ...options,
        headers: {
            ...defaultOptions.headers,
            ...options.headers
        }
    };
    
    const response = await fetch(`${API_BASE_URL}${url}`, mergedOptions);
    
    if (response.status === 401) {
        logout();
        throw new Error('Authentication required');
    }
    
    return response;
}

// Books Functions
async function loadBooks() {
    try {
        const response = await apiRequest('/books');
        if (response.ok) {
            const books = await response.json();
            displayBooks(books);
        } else {
            showAlert('Failed to load books', 'warning');
        }
    } catch (error) {
        showAlert(`Error loading books: ${error.message}`, 'danger');
    }
}

function displayBooks(books) {
    const container = document.getElementById('booksContainer');
    
    if (books.length === 0) {
        container.innerHTML = '<div class="col-12"><div class="alert alert-info">No books found</div></div>';
        return;
    }
    
    container.innerHTML = books.map(book => `
        <div class="col-md-4 mb-3">
            <div class="card book-card h-100">
                <div class="card-body">
                    <h5 class="card-title">${escapeHtml(book.title)}</h5>
                    <p class="card-text">
                        <strong>Author:</strong> ${escapeHtml(book.author)}<br>
                        <strong>ISBN:</strong> ${escapeHtml(book.isbn)}<br>
                        <strong>Category:</strong> ${escapeHtml(book.category)}<br>
                        <strong>Available:</strong> ${book.availableCopies}/${book.totalCopies}
                    </p>
                    <div class="d-flex gap-2">
                        ${book.availableCopies > 0 ? 
                            `<button class="btn btn-primary btn-sm" onclick="borrowBook(${book.id})">
                                <i class="fas fa-book-reader"></i> Borrow
                            </button>` : 
                            '<span class="badge bg-secondary">Not Available</span>'
                        }
                        ${(currentUser.role === 'ADMIN' || currentUser.role === 'LIBRARIAN') ? 
                            `<button class="btn btn-warning btn-sm" onclick="editBook(${book.id})">
                                <i class="fas fa-edit"></i> Edit
                            </button>
                            <button class="btn btn-danger btn-sm" onclick="deleteBook(${book.id})">
                                <i class="fas fa-trash"></i> Delete
                            </button>` : ''
                        }
                    </div>
                </div>
            </div>
        </div>
    `).join('');
}

async function borrowBook(bookId) {
    try {
        const response = await apiRequest('/transactions/borrow', {
            method: 'POST',
            body: JSON.stringify({ bookId: bookId })
        });
        
        if (response.ok) {
            showAlert('Book borrowed successfully!', 'success');
            loadBooks();
            loadTransactions();
        } else {
            const error = await response.text();
            showAlert(`Failed to borrow book: ${error}`, 'danger');
        }
    } catch (error) {
        showAlert(`Error borrowing book: ${error.message}`, 'danger');
    }
}

function showAddBookModal() {
    const modal = new bootstrap.Modal(document.getElementById('addBookModal'));
    modal.show();
}

async function addBook() {
    const title = document.getElementById('bookTitle').value;
    const author = document.getElementById('bookAuthor').value;
    const isbn = document.getElementById('bookIsbn').value;
    const category = document.getElementById('bookCategory').value;
    const totalCopies = document.getElementById('bookTotalCopies').value;
    
    try {
        const response = await apiRequest('/books', {
            method: 'POST',
            body: JSON.stringify({
                title,
                author,
                isbn,
                category,
                totalCopies: parseInt(totalCopies),
                availableCopies: parseInt(totalCopies)
            })
        });
        
        if (response.ok) {
            showAlert('Book added successfully!', 'success');
            bootstrap.Modal.getInstance(document.getElementById('addBookModal')).hide();
            document.getElementById('addBookForm').reset();
            loadBooks();
        } else {
            const error = await response.text();
            showAlert(`Failed to add book: ${error}`, 'danger');
        }
    } catch (error) {
        showAlert(`Error adding book: ${error.message}`, 'danger');
    }
}

async function deleteBook(bookId) {
    if (!confirm('Are you sure you want to delete this book?')) {
        return;
    }
    
    try {
        const response = await apiRequest(`/books/${bookId}`, {
            method: 'DELETE'
        });
        
        if (response.ok) {
            showAlert('Book deleted successfully!', 'success');
            loadBooks();
        } else {
            const error = await response.text();
            showAlert(`Failed to delete book: ${error}`, 'danger');
        }
    } catch (error) {
        showAlert(`Error deleting book: ${error.message}`, 'danger');
    }
}

// Transactions Functions
async function loadTransactions() {
    try {
        const response = await apiRequest('/transactions/my-transactions');
        if (response.ok) {
            const transactions = await response.json();
            displayTransactions(transactions);
        } else {
            showAlert('Failed to load transactions', 'warning');
        }
    } catch (error) {
        showAlert(`Error loading transactions: ${error.message}`, 'danger');
    }
}

function displayTransactions(transactions) {
    const container = document.getElementById('transactionsContainer');
    
    if (transactions.length === 0) {
        container.innerHTML = '<div class="alert alert-info">No transactions found</div>';
        return;
    }
    
    container.innerHTML = `
        <div class="table-responsive">
            <table class="table table-striped">
                <thead>
                    <tr>
                        <th>Book</th>
                        <th>Borrowed Date</th>
                        <th>Due Date</th>
                        <th>Return Date</th>
                        <th>Status</th>
                        <th>Actions</th>
                    </tr>
                </thead>
                <tbody>
                    ${transactions.map(transaction => `
                        <tr>
                            <td>${escapeHtml(transaction.book.title)}</td>
                            <td>${new Date(transaction.borrowDate).toLocaleDateString()}</td>
                            <td>${new Date(transaction.dueDate).toLocaleDateString()}</td>
                            <td>${transaction.returnDate ? new Date(transaction.returnDate).toLocaleDateString() : '-'}</td>
                            <td>
                                <span class="badge ${getStatusBadgeClass(transaction.status)}">
                                    ${transaction.status}
                                </span>
                            </td>
                            <td>
                                ${transaction.status === 'BORROWED' ? 
                                    `<button class="btn btn-success btn-sm" onclick="returnBook(${transaction.id})">
                                        <i class="fas fa-undo"></i> Return
                                    </button>` : 
                                    '-'
                                }
                            </td>
                        </tr>
                    `).join('')}
                </tbody>
            </table>
        </div>
    `;
}

async function returnBook(transactionId) {
    try {
        const response = await apiRequest(`/transactions/${transactionId}/return`, {
            method: 'PUT'
        });
        
        if (response.ok) {
            showAlert('Book returned successfully!', 'success');
            loadTransactions();
            loadBooks();
        } else {
            const error = await response.text();
            showAlert(`Failed to return book: ${error}`, 'danger');
        }
    } catch (error) {
        showAlert(`Error returning book: ${error.message}`, 'danger');
    }
}

// Users Functions
async function loadUsers() {
    if (currentUser.role !== 'ADMIN' && currentUser.role !== 'LIBRARIAN') {
        document.getElementById('usersContainer').innerHTML = 
            '<div class="alert alert-warning">You do not have permission to view users</div>';
        return;
    }
    
    try {
        const response = await apiRequest('/admin/users');
        if (response.ok) {
            const users = await response.json();
            displayUsers(users);
        } else {
            showAlert('Failed to load users', 'warning');
        }
    } catch (error) {
        showAlert(`Error loading users: ${error.message}`, 'danger');
    }
}

function displayUsers(users) {
    const container = document.getElementById('usersContainer');
    
    container.innerHTML = `
        <div class="table-responsive">
            <table class="table table-striped">
                <thead>
                    <tr>
                        <th>Username</th>
                        <th>Email</th>
                        <th>Name</th>
                        <th>Role</th>
                        <th>Created</th>
                    </tr>
                </thead>
                <tbody>
                    ${users.map(user => `
                        <tr>
                            <td>${escapeHtml(user.username)}</td>
                            <td>${escapeHtml(user.email)}</td>
                            <td>${escapeHtml(user.firstName)} ${escapeHtml(user.lastName)}</td>
                            <td>
                                <span class="badge ${getRoleBadgeClass(user.role)}">
                                    ${user.role}
                                </span>
                            </td>
                            <td>${new Date(user.createdAt).toLocaleDateString()}</td>
                        </tr>
                    `).join('')}
                </tbody>
            </table>
        </div>
    `;
}

function showRegisterModal() {
    const modal = new bootstrap.Modal(document.getElementById('registerModal'));
    modal.show();
}

async function registerUser() {
    const username = document.getElementById('regUsername').value;
    const email = document.getElementById('regEmail').value;
    const password = document.getElementById('regPassword').value;
    const firstName = document.getElementById('regFirstName').value;
    const lastName = document.getElementById('regLastName').value;
    
    try {
        const response = await apiRequest('/auth/register', {
            method: 'POST',
            body: JSON.stringify({
                username,
                email,
                password,
                firstName,
                lastName
            })
        });
        
        if (response.ok) {
            showAlert('User registered successfully!', 'success');
            bootstrap.Modal.getInstance(document.getElementById('registerModal')).hide();
            document.getElementById('registerForm').reset();
            loadUsers();
        } else {
            const error = await response.text();
            showAlert(`Failed to register user: ${error}`, 'danger');
        }
    } catch (error) {
        showAlert(`Error registering user: ${error.message}`, 'danger');
    }
}

// Tab event listeners
document.addEventListener('DOMContentLoaded', function() {
    const tabTriggerList = [].slice.call(document.querySelectorAll('#mainTabs button'));
    tabTriggerList.forEach(function (tabTrigger) {
        tabTrigger.addEventListener('click', function (event) {
            const target = event.target.getAttribute('data-bs-target');
            if (target === '#transactions') {
                loadTransactions();
            } else if (target === '#users') {
                loadUsers();
            }
        });
    });
});

// Utility Functions
function showAlert(message, type) {
    const alertContainer = document.getElementById('alertContainer');
    const alertId = 'alert-' + Date.now();
    
    const alertHtml = `
        <div id="${alertId}" class="alert alert-${type} alert-dismissible fade show" role="alert">
            ${escapeHtml(message)}
            <button type="button" class="btn-close" data-bs-dismiss="alert"></button>
        </div>
    `;
    
    alertContainer.innerHTML = alertHtml;
    
    // Auto-remove after 5 seconds
    setTimeout(() => {
        const alert = document.getElementById(alertId);
        if (alert) {
            alert.remove();
        }
    }, 5000);
}

function escapeHtml(text) {
    const div = document.createElement('div');
    div.textContent = text;
    return div.innerHTML;
}

function getStatusBadgeClass(status) {
    switch (status) {
        case 'BORROWED': return 'bg-warning';
        case 'RETURNED': return 'bg-success';
        case 'OVERDUE': return 'bg-danger';
        default: return 'bg-secondary';
    }
}

function getRoleBadgeClass(role) {
    switch (role) {
        case 'ADMIN': return 'bg-danger';
        case 'LIBRARIAN': return 'bg-warning';
        case 'USER': return 'bg-primary';
        default: return 'bg-secondary';
    }
}
