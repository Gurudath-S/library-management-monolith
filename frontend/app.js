// Enhanced Library Management System Frontend JavaScript

const API_BASE_URL = 'http://localhost:8080/api';
let authToken = null;
let currentUser = null;
let allBooks = [];
let filteredBooks = [];
let allTransactions = [];
let filteredTransactions = [];
let allUsers = [];
let filteredUsers = [];
let dashboardData = null;

// Charts
let categoryChart = null;
let transactionChart = null;

// Initialize the application
document.addEventListener('DOMContentLoaded', function() {
    console.log('Library Management System loading...');
    
    // Check if user is already logged in
    const savedToken = localStorage.getItem('authToken');
    const savedUser = localStorage.getItem('currentUser');
    
    if (savedToken && savedUser) {
        try {
            authToken = savedToken;
            currentUser = JSON.parse(savedUser);
            console.log('Restored user session:', currentUser);
            showMainSection();
            loadDashboard();
        } catch (error) {
            console.error('Error restoring session:', error);
            localStorage.removeItem('authToken');
            localStorage.removeItem('currentUser');
        }
    } else {
        console.log('No saved session found');
    }

    // Set up event listeners
    const loginForm = document.getElementById('loginForm');
    if (loginForm) {
        loginForm.addEventListener('submit', handleLogin);
    } else {
        console.error('Login form not found!');
    }
    
    // Tab event listeners
    const tabTriggerList = [].slice.call(document.querySelectorAll('#mainTabs button'));
    console.log('Found tabs:', tabTriggerList.length);
    tabTriggerList.forEach(function (tabTrigger) {
        tabTrigger.addEventListener('click', function (event) {
            const target = event.target.getAttribute('data-bs-target');
            console.log('Tab clicked:', target);
            handleTabSwitch(target);
        });
    });
    
    // Search and filter event listeners with error checking
    const bookSearch = document.getElementById('bookSearch');
    const categoryFilter = document.getElementById('categoryFilter');
    const availabilityFilter = document.getElementById('availabilityFilter');
    
    if (bookSearch && categoryFilter && availabilityFilter) {
        bookSearch.addEventListener('input', applyFilters);
        categoryFilter.addEventListener('change', applyFilters);
        availabilityFilter.addEventListener('change', applyFilters);
        console.log('Book filters initialized');
    }
    
    const transactionSearch = document.getElementById('transactionSearch');
    const statusFilter = document.getElementById('statusFilter');
    
    if (transactionSearch && statusFilter) {
        transactionSearch.addEventListener('input', applyTransactionFilters);
        statusFilter.addEventListener('change', applyTransactionFilters);
        console.log('Transaction filters initialized');
    }
    
    const userSearch = document.getElementById('userSearch');
    const roleFilter = document.getElementById('roleFilter');
    
    if (userSearch && roleFilter) {
        userSearch.addEventListener('input', applyUserFilters);
        roleFilter.addEventListener('change', applyUserFilters);
        console.log('User filters initialized');
    }
    
    // Test Chart.js availability
    if (typeof Chart !== 'undefined') {
        console.log('Chart.js loaded successfully, version:', Chart.version);
    } else {
        console.error('Chart.js not loaded!');
        showAlert('Charts library not loaded. Some features may not work.', 'warning');
    }
    
    console.log('Application initialization complete');
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
            
            console.log('Login successful, user data:', currentUser);
            
            // Save to localStorage
            localStorage.setItem('authToken', authToken);
            localStorage.setItem('currentUser', JSON.stringify(currentUser));
            
            showAlert('Login successful!', 'success');
            showMainSection();
            loadDashboard();
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
    
    // Show/hide tabs based on role
    setupRoleBasedUI();
}

function setupRoleBasedUI() {
    const isAdmin = currentUser.role === 'ADMIN';
    const isLibrarian = currentUser.role === 'LIBRARIAN' || isAdmin;
    
    // Show/hide tabs
    const usersTab = document.getElementById('usersTabLi');
    const inventoryTab = document.getElementById('inventoryTabLi');
    
    if (usersTab) usersTab.style.display = isLibrarian ? 'block' : 'none';
    if (inventoryTab) inventoryTab.style.display = isLibrarian ? 'block' : 'none';
    
    // Show/hide buttons
    const adminButtons = document.querySelectorAll('#addBookBtn, #csvImportBtn, #exportBtn');
    adminButtons.forEach(btn => {
        if (btn) btn.style.display = isLibrarian ? 'inline-block' : 'none';
    });
}

// API Helper Functions
async function apiRequest(url, options = {}) {
    const defaultOptions = {
        headers: {
            'Content-Type': 'application/json'
        }
    };
    
    if (authToken) {
        defaultOptions.headers['Authorization'] = `Bearer ${authToken}`;
    }
    
    const mergedOptions = {
        ...defaultOptions,
        ...options,
        headers: {
            ...defaultOptions.headers,
            ...(options.headers || {})
        }
    };
    
    console.log(`Making API request to: ${API_BASE_URL}${url}`);
    console.log('Request options:', { ...mergedOptions, headers: { ...mergedOptions.headers, Authorization: authToken ? 'Bearer [HIDDEN]' : 'None' } });
    
    try {
        const response = await fetch(`${API_BASE_URL}${url}`, mergedOptions);
        console.log(`API response status: ${response.status}`);
        
        if (response.status === 401) {
            console.warn('Authentication failed, logging out user');
            logout();
            throw new Error('Authentication required');
        }
        
        return response;
    } catch (error) {
        console.error(`API request failed for ${url}:`, error);
        
        // Check if it's a network error
        if (error.name === 'TypeError' && error.message.includes('fetch')) {
            showAlert('Cannot connect to server. Please check if the backend is running.', 'danger');
        }
        
        throw error;
    }
}

// Tab Switching
function handleTabSwitch(target) {
    console.log('Tab switch requested:', target);
    switch (target) {
        case '#dashboard':
            console.log('Loading dashboard tab');
            loadDashboard();
            break;
        case '#books':
            console.log('Loading books tab');
            loadBooks();
            break;
        case '#transactions':
            console.log('Loading transactions tab');
            loadTransactions();
            break;
        case '#users':
            if (currentUser.role === 'ADMIN' || currentUser.role === 'LIBRARIAN') {
                console.log('Loading users tab');
                loadUsers();
            } else {
                console.log('Access denied to users tab');
            }
            break;
        case '#inventory':
            if (currentUser.role === 'ADMIN' || currentUser.role === 'LIBRARIAN') {
                console.log('Loading inventory tab');
                loadInventoryData();
            } else {
                console.log('Access denied to inventory tab');
            }
            break;
        default:
            console.log('Unknown tab:', target);
    }
}

// Dashboard Functions
async function loadDashboard() {
    try {
        console.log('Loading dashboard for user:', currentUser?.role);
        showAlert('Loading dashboard...', 'info');
        
        // Check if user has access to analytics dashboard
        if (currentUser?.role === 'ADMIN' || currentUser?.role === 'LIBRARIAN') {
            const response = await apiRequest('/analytics/dashboard');
            console.log('Dashboard response status:', response.status);
            if (response.ok) {
                dashboardData = await response.json();
                console.log('Dashboard data received:', dashboardData);
                
                // The backend returns the data, pass it directly to display function
                displayDashboard(dashboardData);
                showAlert('Dashboard loaded successfully!', 'success');
            } else {
                const errorText = await response.text();
                console.error('Dashboard error response:', errorText);
                showAlert(`Failed to load dashboard: ${response.status} - ${errorText}`, 'warning');
                // Load basic dashboard for non-admin users
                loadBasicDashboard();
            }
        } else {
            // Load basic dashboard for regular users
            console.log('Loading basic dashboard for regular user');
            loadBasicDashboard();
        }
    } catch (error) {
        console.error('Dashboard error:', error);
        showAlert(`Error loading dashboard: ${error.message}`, 'danger');
        // Fallback to basic dashboard
        loadBasicDashboard();
    }
}

async function loadBasicDashboard() {
    try {
        // Load basic data that all users can access
        const booksResponse = await apiRequest('/books');
        const transactionsResponse = await apiRequest('/transactions');
        
        if (booksResponse.ok && transactionsResponse.ok) {
            const books = await booksResponse.json();
            const transactions = await transactionsResponse.json();
            
            // Create basic dashboard data
            const basicData = {
                bookAnalytics: {
                    totalBooks: books.length,
                    availableBooks: books.filter(book => book.availableCopies > 0).length,
                    booksByCategory: [],
                    mostBorrowedBooks: []
                },
                userAnalytics: {
                    activeBorrowers: 0
                },
                transactionAnalytics: {
                    overdueTransactions: transactions.filter(t => t.status === 'OVERDUE').length,
                    recentTransactions: transactions.slice(0, 5),
                    transactionTrends: []
                }
            };
            
            displayDashboard(basicData);
            showAlert('Dashboard loaded!', 'success');
        } else {
            // Even more basic fallback
            displayDashboard({
                bookAnalytics: { totalBooks: 0, availableBooks: 0, booksByCategory: [], mostBorrowedBooks: [] },
                userAnalytics: { activeBorrowers: 0 },
                transactionAnalytics: { overdueTransactions: 0, recentTransactions: [], transactionTrends: [] }
            });
            showAlert('Basic dashboard loaded', 'info');
        }
    } catch (error) {
        console.error('Basic dashboard error:', error);
        // Ultra basic fallback
        displayDashboard({
            bookAnalytics: { totalBooks: 0, availableBooks: 0, booksByCategory: [], mostBorrowedBooks: [] },
            userAnalytics: { activeBorrowers: 0 },
            transactionAnalytics: { overdueTransactions: 0, recentTransactions: [], transactionTrends: [] }
        });
        showAlert('Dashboard initialized', 'info');
    }
}

function displayDashboard(data) {
    console.log('Displaying dashboard with data:', data);
    
    // Update stats cards with correct property mapping
    const totalBooksEl = document.getElementById('totalBooksCount');
    const availableBooksEl = document.getElementById('availableBooksCount');
    const activeBorrowersEl = document.getElementById('activeBorrowersCount');
    const overdueEl = document.getElementById('overdueCount');
    
    // Map the backend data structure to frontend elements
    if (totalBooksEl) totalBooksEl.textContent = data?.dashboard?.bookAnalytics?.totalBooks || data?.bookAnalytics?.totalBooks || 0;
    if (availableBooksEl) availableBooksEl.textContent = data?.dashboard?.bookAnalytics?.availableBooks || data?.bookAnalytics?.availableBooks || 0;
    if (activeBorrowersEl) activeBorrowersEl.textContent = data?.dashboard?.userAnalytics?.activeUsers || data?.userAnalytics?.activeBorrowers || 0;
    if (overdueEl) overdueEl.textContent = data?.dashboard?.transactionAnalytics?.overdueTransactions || data?.transactionAnalytics?.overdueTransactions || 0;
    
    // Prepare chart data from backend response
    const categoryData = prepareChartData(data?.dashboard?.bookAnalytics?.booksByCategory || data?.bookAnalytics?.booksByCategory);
    const trendData = prepareTrendData(data?.dashboard?.transactionAnalytics?.recentActivity || data?.transactionAnalytics?.transactionTrends);
    
    // Create charts with processed data
    createCategoryChart(categoryData);
    createTransactionChart(trendData);
    
    // Display popular books
    displayPopularBooks(data?.dashboard?.bookAnalytics?.mostBorrowedBooks || data?.bookAnalytics?.mostBorrowedBooks || []);
    
    // Display recent activities (convert from backend format)
    const recentActivities = convertToRecentActivities(data?.dashboard?.transactionAnalytics?.recentActivity || []);
    displayRecentActivities(recentActivities);
}

// Helper function to convert backend category data to chart format
function prepareChartData(categoryData) {
    if (!categoryData) return [];
    
    // If it's an object (backend format), convert to array
    if (typeof categoryData === 'object' && !Array.isArray(categoryData)) {
        return Object.entries(categoryData).map(([category, count]) => ({
            category,
            count
        }));
    }
    
    // If it's already an array, return as is
    return categoryData;
}

// Helper function to convert backend trend data to chart format
function prepareTrendData(trendData) {
    if (!trendData) return [];
    
    return trendData.map(item => ({
        date: item.date,
        borrowed: item.borrowings || item.borrowed || 0,
        returned: item.returns || item.returned || 0
    }));
}

// Helper function to convert recent activity data
function convertToRecentActivities(recentActivity) {
    if (!recentActivity || recentActivity.length === 0) return [];
    
    // Convert the recent activity format to what the UI expects
    return recentActivity.slice(0, 5).map((activity, index) => ({
        bookTitle: `Recent Activity ${index + 1}`,
        action: `${activity.borrowings || 0} borrowed, ${activity.returns || 0} returned`,
        userName: 'System',
        date: activity.date
    }));
}

function createCategoryChart(categoryData) {
    const chartEl = document.getElementById('categoryChart');
    if (!chartEl) {
        console.warn('categoryChart element not found');
        return;
    }
    
    if (typeof Chart === 'undefined') {
        console.warn('Chart.js not loaded');
        return;
    }
    
    try {
        const ctx = chartEl.getContext('2d');
        
        if (categoryChart) {
            categoryChart.destroy();
        }
        
        if (!categoryData || categoryData.length === 0) {
            // Display empty state
            ctx.clearRect(0, 0, chartEl.width, chartEl.height);
            ctx.font = '16px Arial';
            ctx.fillStyle = '#666';
            ctx.textAlign = 'center';
            ctx.fillText('No category data available', chartEl.width / 2, chartEl.height / 2);
            return;
        }
        
        categoryChart = new Chart(ctx, {
            type: 'doughnut',
            data: {
                labels: categoryData.map(item => item.category),
                datasets: [{
                    data: categoryData.map(item => item.count),
                    backgroundColor: [
                        '#3498db', '#e74c3c', '#f39c12', '#27ae60', 
                        '#9b59b6', '#34495e', '#1abc9c', '#e67e22'
                    ]
                }]
            },
            options: {
                responsive: true,
                maintainAspectRatio: false,
                plugins: {
                    legend: {
                        position: 'bottom'
                    }
                }
            }
        });
    } catch (error) {
        console.error('Error creating category chart:', error);
    }
}

function createTransactionChart(trendData) {
    const chartEl = document.getElementById('transactionChart');
    if (!chartEl) {
        console.warn('transactionChart element not found');
        return;
    }
    
    if (typeof Chart === 'undefined') {
        console.warn('Chart.js not loaded');
        return;
    }
    
    try {
        const ctx = chartEl.getContext('2d');
        
        if (transactionChart) {
            transactionChart.destroy();
        }
        
        if (!trendData || trendData.length === 0) {
            // Display empty state
            ctx.clearRect(0, 0, chartEl.width, chartEl.height);
            ctx.font = '16px Arial';
            ctx.fillStyle = '#666';
            ctx.textAlign = 'center';
            ctx.fillText('No transaction data available', chartEl.width / 2, chartEl.height / 2);
            return;
        }
        
        transactionChart = new Chart(ctx, {
            type: 'line',
            data: {
                labels: trendData.map(item => item.date),
                datasets: [{
                    label: 'Books Borrowed',
                    data: trendData.map(item => item.borrowed),
                    borderColor: '#3498db',
                    backgroundColor: 'rgba(52, 152, 219, 0.1)',
                    tension: 0.4
                }, {
                    label: 'Books Returned',
                    data: trendData.map(item => item.returned),
                    borderColor: '#27ae60',
                    backgroundColor: 'rgba(39, 174, 96, 0.1)',
                    tension: 0.4
                }]
            },
            options: {
                responsive: true,
                maintainAspectRatio: false,
                plugins: {
                    legend: {
                        position: 'top'
                    }
                },
                scales: {
                    y: {
                        beginAtZero: true
                    }
                }
            }
        });
    } catch (error) {
        console.error('Error creating transaction chart:', error);
    }
}

function displayPopularBooks(books) {
    const container = document.getElementById('popularBooksContainer');
    if (!container) return;
    
    if (books.length === 0) {
        container.innerHTML = '<p class="text-muted">No data available</p>';
        return;
    }
    
    container.innerHTML = books.map((book, index) => `
        <div class="d-flex justify-content-between align-items-center mb-2 p-2 bg-light rounded">
            <div>
                <span class="badge bg-primary me-2">${index + 1}</span>
                <strong>${escapeHtml(book.title)}</strong>
                <small class="text-muted d-block">by ${escapeHtml(book.author)}</small>
            </div>
            <span class="badge bg-success">${book.borrowCount} borrows</span>
        </div>
    `).join('');
}

function displayRecentActivities(activities) {
    const container = document.getElementById('recentActivitiesContainer');
    if (!container) return;
    
    if (!activities || activities.length === 0) {
        container.innerHTML = '<p class="text-muted">No recent activities</p>';
        return;
    }
    
    container.innerHTML = activities.map(activity => `
        <div class="d-flex justify-content-between align-items-center mb-2 p-2 bg-light rounded">
            <div>
                <strong>${escapeHtml(activity.bookTitle || 'System Activity')}</strong>
                <small class="text-muted d-block">${activity.action || 'Activity'} ${activity.userName ? 'by ' + escapeHtml(activity.userName) : ''}</small>
            </div>
            <small class="text-muted">${formatDate(activity.date)}</small>
        </div>
    `).join('');
}

function refreshDashboard() {
    loadDashboard();
    showAlert('Dashboard refreshed', 'success');
}

// Books Functions
async function loadBooks() {
    try {
        console.log('Loading books...');
        showAlert('Loading books...', 'info');
        const response = await apiRequest('/books');
        console.log('Books response status:', response.status);
        if (response.ok) {
            allBooks = await response.json();
            filteredBooks = [...allBooks];
            console.log(`Loaded ${allBooks.length} books`);
            displayBooks(filteredBooks);
            populateFilterOptions();
            showAlert(`${allBooks.length} books loaded successfully!`, 'success');
        } else {
            const errorText = await response.text();
            console.error('Books error response:', errorText);
            showAlert(`Failed to load books: ${response.status} - ${errorText}`, 'warning');
        }
    } catch (error) {
        console.error('Books loading error:', error);
        showAlert(`Error loading books: ${error.message}`, 'danger');
    }
}

function displayBooks(books) {
    const tbody = document.getElementById('booksTableBody');
    if (!tbody) return;
    
    if (books.length === 0) {
        tbody.innerHTML = '<tr><td colspan="7" class="text-center">No books found</td></tr>';
        return;
    }
    
    tbody.innerHTML = books.map(book => `
        <tr>
            <td>${book.id}</td>
            <td><strong>${escapeHtml(book.title)}</strong></td>
            <td>${escapeHtml(book.author)}</td>
            <td>${escapeHtml(book.category || 'N/A')}</td>
            <td>${escapeHtml(book.isbn || 'N/A')}</td>
            <td><span class="badge ${book.availableCopies > 0 ? 'bg-success' : 'bg-danger'}">${book.availableCopies}/${book.totalCopies}</span></td>
            <td>
                ${canBorrowBook(book) ? `<button class="btn btn-sm btn-primary me-1" onclick="showQuickBorrowModal(${book.id})">Quick Borrow</button>` : ''}
                ${canManageBooks() ? `<button class="btn btn-sm btn-warning me-1" onclick="showEditBookModal(${book.id})">Edit</button>` : ''}
                ${canManageBooks() && book.totalCopies === book.availableCopies ? `<button class="btn btn-sm btn-danger" onclick="deleteBook(${book.id})">Delete</button>` : ''}
            </td>
        </tr>
    `).join('');
}

function populateFilterOptions() {
    const categoryFilter = document.getElementById('categoryFilter');
    if (!categoryFilter) return;
    
    // Get unique categories
    const categories = [...new Set(allBooks.map(book => book.category).filter(Boolean))];
    categoryFilter.innerHTML = '<option value="">All Categories</option>' + 
        categories.map(cat => `<option value="${escapeHtml(cat)}">${escapeHtml(cat)}</option>`).join('');
}

function applyFilters() {
    const searchInput = document.getElementById('bookSearch');
    const categoryFilter = document.getElementById('categoryFilter');
    const availabilityFilter = document.getElementById('availabilityFilter');
    
    if (!searchInput || !categoryFilter || !availabilityFilter) return;
    
    const searchTerm = searchInput.value.toLowerCase();
    const categoryValue = categoryFilter.value;
    const availabilityValue = availabilityFilter.value;
    
    filteredBooks = allBooks.filter(book => {
        const matchesSearch = !searchTerm || 
            book.title.toLowerCase().includes(searchTerm) ||
            book.author.toLowerCase().includes(searchTerm) ||
            (book.isbn && book.isbn.toLowerCase().includes(searchTerm));
        
        const matchesCategory = !categoryValue || book.category === categoryValue;
        
        const matchesAvailability = availabilityValue === '' || 
            (availabilityValue === 'available' && book.availableCopies > 0) ||
            (availabilityValue === 'unavailable' && book.availableCopies === 0);
        
        return matchesSearch && matchesCategory && matchesAvailability;
    });
    
    displayBooks(filteredBooks);
}

function clearFilters() {
    const searchInput = document.getElementById('bookSearch');
    const categoryFilter = document.getElementById('categoryFilter');
    const availabilityFilter = document.getElementById('availabilityFilter');
    
    if (searchInput) searchInput.value = '';
    if (categoryFilter) categoryFilter.value = '';
    if (availabilityFilter) availabilityFilter.value = '';
    
    filteredBooks = [...allBooks];
    displayBooks(filteredBooks);
}

// Transactions Functions
async function loadTransactions() {
    try {
        const response = await apiRequest('/transactions');
        if (response.ok) {
            allTransactions = await response.json();
            filteredTransactions = [...allTransactions];
            displayTransactions(filteredTransactions);
        } else {
            showAlert('Failed to load transactions', 'warning');
        }
    } catch (error) {
        showAlert(`Error loading transactions: ${error.message}`, 'danger');
    }
}

function displayTransactions(transactions) {
    const tbody = document.getElementById('transactionsTableBody');
    if (!tbody) return;
    
    if (transactions.length === 0) {
        tbody.innerHTML = '<tr><td colspan="7" class="text-center">No transactions found</td></tr>';
        return;
    }
    
    tbody.innerHTML = transactions.map(transaction => `
        <tr>
            <td>${transaction.id}</td>
            <td>${escapeHtml(transaction.bookTitle)}</td>
            <td>${escapeHtml(transaction.userName)}</td>
            <td>${formatDate(transaction.borrowDate)}</td>
            <td>${transaction.returnDate ? formatDate(transaction.returnDate) : 'Not returned'}</td>
            <td><span class="badge ${getStatusBadgeClass(transaction.status)}">${transaction.status}</span></td>
            <td>
                ${transaction.status === 'BORROWED' && canManageBooks() ? 
                    `<button class="btn btn-sm btn-success" onclick="returnBook(${transaction.id})">Return</button>` : 
                    ''}
            </td>
        </tr>
    `).join('');
}

function applyTransactionFilters() {
    const searchInput = document.getElementById('transactionSearch');
    const statusFilter = document.getElementById('statusFilter');
    
    if (!searchInput || !statusFilter) return;
    
    const searchTerm = searchInput.value.toLowerCase();
    const statusValue = statusFilter.value;
    
    filteredTransactions = allTransactions.filter(transaction => {
        const matchesSearch = !searchTerm || 
            transaction.bookTitle.toLowerCase().includes(searchTerm) ||
            transaction.userName.toLowerCase().includes(searchTerm);
        
        const matchesStatus = !statusValue || transaction.status === statusValue;
        
        return matchesSearch && matchesStatus;
    });
    
    displayTransactions(filteredTransactions);
}

function clearTransactionFilters() {
    const searchInput = document.getElementById('transactionSearch');
    const statusFilter = document.getElementById('statusFilter');
    
    if (searchInput) searchInput.value = '';
    if (statusFilter) statusFilter.value = '';
    
    filteredTransactions = [...allTransactions];
    displayTransactions(filteredTransactions);
}

// Users Functions (Admin/Librarian only)
async function loadUsers() {
    if (!canManageUsers()) return;
    
    try {
        const response = await apiRequest('/admin/users');
        if (response.ok) {
            allUsers = await response.json();
            filteredUsers = [...allUsers];
            displayUsers(filteredUsers);
        } else {
            showAlert('Failed to load users', 'warning');
        }
    } catch (error) {
        showAlert(`Error loading users: ${error.message}`, 'danger');
    }
}

function displayUsers(users) {
    const tbody = document.getElementById('usersTableBody');
    if (!tbody) return;
    
    if (users.length === 0) {
        tbody.innerHTML = '<tr><td colspan="6" class="text-center">No users found</td></tr>';
        return;
    }
    
    tbody.innerHTML = users.map(user => `
        <tr>
            <td>${user.id}</td>
            <td>${escapeHtml(user.username)}</td>
            <td>${escapeHtml(user.email)}</td>
            <td><span class="badge ${getRoleBadgeClass(user.role)}">${user.role}</span></td>
            <td>${user.activeBorrows || 0}</td>
            <td>
                ${currentUser.role === 'ADMIN' && user.username !== currentUser.username ? 
                    `<button class="btn btn-sm btn-warning me-1" onclick="editUserRole(${user.id}, '${user.role}')">Edit Role</button>
                     <button class="btn btn-sm btn-danger" onclick="deleteUser(${user.id})">Delete</button>` : 
                    ''}
            </td>
        </tr>
    `).join('');
}

function applyUserFilters() {
    const searchInput = document.getElementById('userSearch');
    const roleFilter = document.getElementById('roleFilter');
    
    if (!searchInput || !roleFilter) return;
    
    const searchTerm = searchInput.value.toLowerCase();
    const roleValue = roleFilter.value;
    
    filteredUsers = allUsers.filter(user => {
        const matchesSearch = !searchTerm || 
            user.username.toLowerCase().includes(searchTerm) ||
            user.email.toLowerCase().includes(searchTerm);
        
        const matchesRole = !roleValue || user.role === roleValue;
        
        return matchesSearch && matchesRole;
    });
    
    displayUsers(filteredUsers);
}

function clearUserFilters() {
    const searchInput = document.getElementById('userSearch');
    const roleFilter = document.getElementById('roleFilter');
    
    if (searchInput) searchInput.value = '';
    if (roleFilter) roleFilter.value = '';
    
    filteredUsers = [...allUsers];
    displayUsers(filteredUsers);
}

// Inventory Functions
async function loadInventoryData() {
    if (!canManageBooks()) return;
    
    try {
        const response = await apiRequest('/analytics/inventory');
        if (response.ok) {
            const inventoryData = await response.json();
            displayInventoryData(inventoryData);
        } else {
            showAlert('Failed to load inventory data', 'warning');
        }
    } catch (error) {
        showAlert(`Error loading inventory: ${error.message}`, 'danger');
    }
}

function displayInventoryData(data) {
    const tbody = document.getElementById('inventoryTableBody');
    if (!tbody) return;
    
    if (!data.books || data.books.length === 0) {
        tbody.innerHTML = '<tr><td colspan="6" class="text-center">No inventory data found</td></tr>';
        return;
    }
    
    tbody.innerHTML = data.books.map(book => `
        <tr class="${book.availableCopies === 0 ? 'table-danger' : book.availableCopies <= 2 ? 'table-warning' : ''}">
            <td>${book.id}</td>
            <td><strong>${escapeHtml(book.title)}</strong></td>
            <td>${escapeHtml(book.author)}</td>
            <td>${book.totalCopies}</td>
            <td>${book.availableCopies}</td>
            <td>
                <button class="btn btn-sm btn-primary" onclick="showInventoryUpdateModal(${book.id}, ${book.totalCopies})">
                    Update Copies
                </button>
            </td>
        </tr>
    `).join('');
}

// Modal Functions
function showAddBookModal() {
    const modal = new bootstrap.Modal(document.getElementById('addBookModal'));
    modal.show();
}

function showEditBookModal(bookId) {
    const book = allBooks.find(b => b.id === bookId);
    if (!book) return;
    
    document.getElementById('editBookId').value = book.id;
    document.getElementById('editBookTitle').value = book.title;
    document.getElementById('editBookAuthor').value = book.author;
    document.getElementById('editBookCategory').value = book.category || '';
    document.getElementById('editBookIsbn').value = book.isbn || '';
    document.getElementById('editBookTotalCopies').value = book.totalCopies;
    
    const modal = new bootstrap.Modal(document.getElementById('editBookModal'));
    modal.show();
}

function showQuickBorrowModal(bookId) {
    document.getElementById('quickBorrowBookId').value = bookId;
    const modal = new bootstrap.Modal(document.getElementById('quickBorrowModal'));
    modal.show();
}

function showInventoryUpdateModal(bookId, currentCopies) {
    document.getElementById('inventoryBookId').value = bookId;
    document.getElementById('inventoryCurrentCopies').value = currentCopies;
    document.getElementById('inventoryNewCopies').value = currentCopies;
    
    const modal = new bootstrap.Modal(document.getElementById('inventoryUpdateModal'));
    modal.show();
}

function showCsvImportModal() {
    const modal = new bootstrap.Modal(document.getElementById('csvImportModal'));
    modal.show();
}

function showProfileModal() {
    document.getElementById('profileUsername').value = currentUser.username;
    document.getElementById('profileEmail').value = currentUser.email;
    
    const modal = new bootstrap.Modal(document.getElementById('profileModal'));
    modal.show();
}

// Book Management Functions
async function addBook() {
    const title = document.getElementById('addBookTitle').value;
    const author = document.getElementById('addBookAuthor').value;
    const category = document.getElementById('addBookCategory').value;
    const isbn = document.getElementById('addBookIsbn').value;
    const totalCopies = parseInt(document.getElementById('addBookTotalCopies').value);
    
    try {
        const response = await apiRequest('/books', {
            method: 'POST',
            body: JSON.stringify({
                title,
                author,
                category,
                isbn,
                totalCopies
            })
        });
        
        if (response.ok) {
            showAlert('Book added successfully!', 'success');
            loadBooks();
            bootstrap.Modal.getInstance(document.getElementById('addBookModal')).hide();
            document.getElementById('addBookForm').reset();
        } else {
            const error = await response.text();
            showAlert(`Failed to add book: ${error}`, 'danger');
        }
    } catch (error) {
        showAlert(`Error adding book: ${error.message}`, 'danger');
    }
}

async function editBook() {
    const id = document.getElementById('editBookId').value;
    const title = document.getElementById('editBookTitle').value;
    const author = document.getElementById('editBookAuthor').value;
    const category = document.getElementById('editBookCategory').value;
    const isbn = document.getElementById('editBookIsbn').value;
    const totalCopies = parseInt(document.getElementById('editBookTotalCopies').value);
    
    try {
        const response = await apiRequest(`/books/${id}`, {
            method: 'PUT',
            body: JSON.stringify({
                title,
                author,
                category,
                isbn,
                totalCopies
            })
        });
        
        if (response.ok) {
            showAlert('Book updated successfully!', 'success');
            loadBooks();
            bootstrap.Modal.getInstance(document.getElementById('editBookModal')).hide();
        } else {
            const error = await response.text();
            showAlert(`Failed to update book: ${error}`, 'danger');
        }
    } catch (error) {
        showAlert(`Error updating book: ${error.message}`, 'danger');
    }
}

async function deleteBook(bookId) {
    if (!confirm('Are you sure you want to delete this book?')) return;
    
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

// Transaction Functions
async function quickBorrow() {
    const bookId = document.getElementById('quickBorrowBookId').value;
    
    try {
        const response = await apiRequest('/transactions/borrow', {
            method: 'POST',
            body: JSON.stringify({ bookId: parseInt(bookId) })
        });
        
        if (response.ok) {
            showAlert('Book borrowed successfully!', 'success');
            loadBooks();
            loadTransactions();
            bootstrap.Modal.getInstance(document.getElementById('quickBorrowModal')).hide();
        } else {
            const error = await response.text();
            showAlert(`Failed to borrow book: ${error}`, 'danger');
        }
    } catch (error) {
        showAlert(`Error borrowing book: ${error.message}`, 'danger');
    }
}

async function returnBook(transactionId) {
    if (!confirm('Are you sure you want to return this book?')) return;
    
    try {
        const response = await apiRequest(`/transactions/return/${transactionId}`, {
            method: 'POST'
        });
        
        if (response.ok) {
            showAlert('Book returned successfully!', 'success');
            loadBooks();
            loadTransactions();
        } else {
            const error = await response.text();
            showAlert(`Failed to return book: ${error}`, 'danger');
        }
    } catch (error) {
        showAlert(`Error returning book: ${error.message}`, 'danger');
    }
}

// User Management Functions
async function editUserRole(userId, currentRole) {
    const newRole = prompt(`Enter new role for user (current: ${currentRole}):`, currentRole);
    if (!newRole || newRole === currentRole) return;
    
    try {
        const response = await apiRequest(`/admin/users/${userId}/role`, {
            method: 'PUT',
            body: JSON.stringify({ role: newRole })
        });
        
        if (response.ok) {
            showAlert('User role updated successfully!', 'success');
            loadUsers();
        } else {
            const error = await response.text();
            showAlert(`Failed to update user role: ${error}`, 'danger');
        }
    } catch (error) {
        showAlert(`Error updating user role: ${error.message}`, 'danger');
    }
}

async function deleteUser(userId) {
    if (!confirm('Are you sure you want to delete this user?')) return;
    
    try {
        const response = await apiRequest(`/admin/users/${userId}`, {
            method: 'DELETE'
        });
        
        if (response.ok) {
            showAlert('User deleted successfully!', 'success');
            loadUsers();
        } else {
            const error = await response.text();
            showAlert(`Failed to delete user: ${error}`, 'danger');
        }
    } catch (error) {
        showAlert(`Error deleting user: ${error.message}`, 'danger');
    }
}

// Inventory Management
async function updateInventory() {
    const bookId = document.getElementById('inventoryBookId').value;
    const newCopies = parseInt(document.getElementById('inventoryNewCopies').value);
    
    try {
        const response = await apiRequest(`/books/${bookId}/inventory`, {
            method: 'PUT',
            body: JSON.stringify({ totalCopies: newCopies })
        });
        
        if (response.ok) {
            showAlert('Inventory updated successfully!', 'success');
            loadInventoryData();
            loadBooks();
            bootstrap.Modal.getInstance(document.getElementById('inventoryUpdateModal')).hide();
        } else {
            const error = await response.text();
            showAlert(`Failed to update inventory: ${error}`, 'danger');
        }
    } catch (error) {
        showAlert(`Error updating inventory: ${error.message}`, 'danger');
    }
}

// CSV Functions
async function importCsv() {
    const fileInput = document.getElementById('csvFile');
    if (!fileInput.files[0]) {
        showAlert('Please select a CSV file', 'warning');
        return;
    }
    
    const formData = new FormData();
    formData.append('file', fileInput.files[0]);
    
    try {
        const response = await fetch(`${API_BASE_URL}/books/import-csv`, {
            method: 'POST',
            headers: {
                'Authorization': `Bearer ${authToken}`
            },
            body: formData
        });
        
        if (response.ok) {
            const result = await response.json();
            showAlert(`CSV imported successfully! ${result.importedCount} books added.`, 'success');
            loadBooks();
            bootstrap.Modal.getInstance(document.getElementById('csvImportModal')).hide();
        } else {
            const error = await response.text();
            showAlert(`Failed to import CSV: ${error}`, 'danger');
        }
    } catch (error) {
        showAlert(`Error importing CSV: ${error.message}`, 'danger');
    }
}

async function exportBooks() {
    try {
        const response = await apiRequest('/books/export');
        if (response.ok) {
            const blob = await response.blob();
            const url = window.URL.createObjectURL(blob);
            const a = document.createElement('a');
            a.href = url;
            a.download = 'books_export.csv';
            document.body.appendChild(a);
            a.click();
            window.URL.revokeObjectURL(url);
            document.body.removeChild(a);
            showAlert('Books exported successfully!', 'success');
        } else {
            showAlert('Failed to export books', 'danger');
        }
    } catch (error) {
        showAlert(`Error exporting books: ${error.message}`, 'danger');
    }
}

// Profile Management
async function updateProfile() {
    const newPassword = document.getElementById('profileNewPassword').value;
    const confirmPassword = document.getElementById('profileConfirmPassword').value;
    
    if (newPassword !== confirmPassword) {
        showAlert('Passwords do not match', 'danger');
        return;
    }
    
    try {
        const response = await apiRequest('/auth/change-password', {
            method: 'POST',
            body: JSON.stringify({ newPassword })
        });
        
        if (response.ok) {
            showAlert('Password updated successfully!', 'success');
            bootstrap.Modal.getInstance(document.getElementById('profileModal')).hide();
            document.getElementById('profileForm').reset();
        } else {
            const error = await response.text();
            showAlert(`Failed to update password: ${error}`, 'danger');
        }
    } catch (error) {
        showAlert(`Error updating password: ${error.message}`, 'danger');
    }
}

// Utility Functions
function canManageBooks() {
    return currentUser && (currentUser.role === 'ADMIN' || currentUser.role === 'LIBRARIAN');
}

function canManageUsers() {
    return currentUser && (currentUser.role === 'ADMIN' || currentUser.role === 'LIBRARIAN');
}

function canBorrowBook(book) {
    return currentUser && book.availableCopies > 0;
}

function escapeHtml(text) {
    const div = document.createElement('div');
    div.textContent = text;
    return div.innerHTML;
}

function formatDate(dateString) {
    return new Date(dateString).toLocaleDateString();
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

function showAlert(message, type = 'info') {
    console.log(`Alert [${type.toUpperCase()}]: ${message}`);
    
    const alertContainer = document.getElementById('alertContainer');
    if (!alertContainer) {
        console.warn('Alert container not found, using console only');
        return;
    }
    
    const alertDiv = document.createElement('div');
    alertDiv.className = `alert alert-${type} alert-dismissible fade show`;
    alertDiv.innerHTML = `
        ${message}
        <button type="button" class="btn-close" data-bs-dismiss="alert"></button>
    `;
    
    alertContainer.appendChild(alertDiv);
    
    // Auto remove after 5 seconds
    setTimeout(() => {
        if (alertDiv.parentNode) {
            alertDiv.remove();
        }
    }, 5000);
}
