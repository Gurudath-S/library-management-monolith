package com.library.dto;

import com.fasterxml.jackson.annotation.JsonFormat;

import java.time.LocalDateTime;
import java.util.List;
import java.util.Map;

public class AnalyticsDashboardDto {
    
    @JsonFormat(pattern = "yyyy-MM-dd HH:mm:ss")
    private LocalDateTime generatedAt;
    
    private UserAnalyticsDto userAnalytics;
    private BookAnalyticsDto bookAnalytics;
    private TransactionAnalyticsDto transactionAnalytics;
    private InventoryAnalyticsDto inventoryAnalytics;
    private SystemHealthDto systemHealth;
    
    // Constructors
    public AnalyticsDashboardDto() {
        this.generatedAt = LocalDateTime.now();
    }
    
    public AnalyticsDashboardDto(UserAnalyticsDto userAnalytics, 
                                BookAnalyticsDto bookAnalytics,
                                TransactionAnalyticsDto transactionAnalytics,
                                InventoryAnalyticsDto inventoryAnalytics,
                                SystemHealthDto systemHealth) {
        this();
        this.userAnalytics = userAnalytics;
        this.bookAnalytics = bookAnalytics;
        this.transactionAnalytics = transactionAnalytics;
        this.inventoryAnalytics = inventoryAnalytics;
        this.systemHealth = systemHealth;
    }
    
    // Getters and Setters
    public LocalDateTime getGeneratedAt() {
        return generatedAt;
    }
    
    public void setGeneratedAt(LocalDateTime generatedAt) {
        this.generatedAt = generatedAt;
    }
    
    public UserAnalyticsDto getUserAnalytics() {
        return userAnalytics;
    }
    
    public void setUserAnalytics(UserAnalyticsDto userAnalytics) {
        this.userAnalytics = userAnalytics;
    }
    
    public BookAnalyticsDto getBookAnalytics() {
        return bookAnalytics;
    }
    
    public void setBookAnalytics(BookAnalyticsDto bookAnalytics) {
        this.bookAnalytics = bookAnalytics;
    }
    
    public TransactionAnalyticsDto getTransactionAnalytics() {
        return transactionAnalytics;
    }
    
    public void setTransactionAnalytics(TransactionAnalyticsDto transactionAnalytics) {
        this.transactionAnalytics = transactionAnalytics;
    }
    
    public InventoryAnalyticsDto getInventoryAnalytics() {
        return inventoryAnalytics;
    }
    
    public void setInventoryAnalytics(InventoryAnalyticsDto inventoryAnalytics) {
        this.inventoryAnalytics = inventoryAnalytics;
    }
    
    public SystemHealthDto getSystemHealth() {
        return systemHealth;
    }
    
    public void setSystemHealth(SystemHealthDto systemHealth) {
        this.systemHealth = systemHealth;
    }
    
    // Nested DTOs
    public static class UserAnalyticsDto {
        private long totalUsers;
        private long activeUsers;
        private long newUsersThisMonth;
        private double userGrowthRate;
        private Map<String, Long> usersByRole;
        private List<UserActivityDto> topActiveUsers;
        
        // Constructors
        public UserAnalyticsDto() {}
        
        public UserAnalyticsDto(long totalUsers, long activeUsers, long newUsersThisMonth, 
                               double userGrowthRate, Map<String, Long> usersByRole, 
                               List<UserActivityDto> topActiveUsers) {
            this.totalUsers = totalUsers;
            this.activeUsers = activeUsers;
            this.newUsersThisMonth = newUsersThisMonth;
            this.userGrowthRate = userGrowthRate;
            this.usersByRole = usersByRole;
            this.topActiveUsers = topActiveUsers;
        }
        
        // Getters and Setters
        public long getTotalUsers() { return totalUsers; }
        public void setTotalUsers(long totalUsers) { this.totalUsers = totalUsers; }
        
        public long getActiveUsers() { return activeUsers; }
        public void setActiveUsers(long activeUsers) { this.activeUsers = activeUsers; }
        
        public long getNewUsersThisMonth() { return newUsersThisMonth; }
        public void setNewUsersThisMonth(long newUsersThisMonth) { this.newUsersThisMonth = newUsersThisMonth; }
        
        public double getUserGrowthRate() { return userGrowthRate; }
        public void setUserGrowthRate(double userGrowthRate) { this.userGrowthRate = userGrowthRate; }
        
        public Map<String, Long> getUsersByRole() { return usersByRole; }
        public void setUsersByRole(Map<String, Long> usersByRole) { this.usersByRole = usersByRole; }
        
        public List<UserActivityDto> getTopActiveUsers() { return topActiveUsers; }
        public void setTopActiveUsers(List<UserActivityDto> topActiveUsers) { this.topActiveUsers = topActiveUsers; }
    }
    
    public static class BookAnalyticsDto {
        private long totalBooks;
        private long availableBooks;
        private long borrowedBooks;
        private Map<String, Long> booksByCategory;
        private List<PopularBookDto> mostBorrowedBooks;
        private List<PopularBookDto> leastBorrowedBooks;
        private double averageBooksPerUser;
        
        // Constructors
        public BookAnalyticsDto() {}
        
        public BookAnalyticsDto(long totalBooks, long availableBooks, long borrowedBooks,
                               Map<String, Long> booksByCategory, List<PopularBookDto> mostBorrowedBooks,
                               List<PopularBookDto> leastBorrowedBooks, double averageBooksPerUser) {
            this.totalBooks = totalBooks;
            this.availableBooks = availableBooks;
            this.borrowedBooks = borrowedBooks;
            this.booksByCategory = booksByCategory;
            this.mostBorrowedBooks = mostBorrowedBooks;
            this.leastBorrowedBooks = leastBorrowedBooks;
            this.averageBooksPerUser = averageBooksPerUser;
        }
        
        // Getters and Setters
        public long getTotalBooks() { return totalBooks; }
        public void setTotalBooks(long totalBooks) { this.totalBooks = totalBooks; }
        
        public long getAvailableBooks() { return availableBooks; }
        public void setAvailableBooks(long availableBooks) { this.availableBooks = availableBooks; }
        
        public long getBorrowedBooks() { return borrowedBooks; }
        public void setBorrowedBooks(long borrowedBooks) { this.borrowedBooks = borrowedBooks; }
        
        public Map<String, Long> getBooksByCategory() { return booksByCategory; }
        public void setBooksByCategory(Map<String, Long> booksByCategory) { this.booksByCategory = booksByCategory; }
        
        public List<PopularBookDto> getMostBorrowedBooks() { return mostBorrowedBooks; }
        public void setMostBorrowedBooks(List<PopularBookDto> mostBorrowedBooks) { this.mostBorrowedBooks = mostBorrowedBooks; }
        
        public List<PopularBookDto> getLeastBorrowedBooks() { return leastBorrowedBooks; }
        public void setLeastBorrowedBooks(List<PopularBookDto> leastBorrowedBooks) { this.leastBorrowedBooks = leastBorrowedBooks; }
        
        public double getAverageBooksPerUser() { return averageBooksPerUser; }
        public void setAverageBooksPerUser(double averageBooksPerUser) { this.averageBooksPerUser = averageBooksPerUser; }
    }
    
    public static class TransactionAnalyticsDto {
        private long totalTransactions;
        private long activeTransactions;
        private long overdueTransactions;
        private long transactionsToday;
        private long transactionsThisWeek;
        private long transactionsThisMonth;
        private double averageReturnTime;
        private Map<String, Long> transactionsByType;
        private List<DailyTransactionDto> recentActivity;
        
        // Constructors
        public TransactionAnalyticsDto() {}
        
        public TransactionAnalyticsDto(long totalTransactions, long activeTransactions, long overdueTransactions,
                                      long transactionsToday, long transactionsThisWeek, long transactionsThisMonth,
                                      double averageReturnTime, Map<String, Long> transactionsByType,
                                      List<DailyTransactionDto> recentActivity) {
            this.totalTransactions = totalTransactions;
            this.activeTransactions = activeTransactions;
            this.overdueTransactions = overdueTransactions;
            this.transactionsToday = transactionsToday;
            this.transactionsThisWeek = transactionsThisWeek;
            this.transactionsThisMonth = transactionsThisMonth;
            this.averageReturnTime = averageReturnTime;
            this.transactionsByType = transactionsByType;
            this.recentActivity = recentActivity;
        }
        
        // Getters and Setters
        public long getTotalTransactions() { return totalTransactions; }
        public void setTotalTransactions(long totalTransactions) { this.totalTransactions = totalTransactions; }
        
        public long getActiveTransactions() { return activeTransactions; }
        public void setActiveTransactions(long activeTransactions) { this.activeTransactions = activeTransactions; }
        
        public long getOverdueTransactions() { return overdueTransactions; }
        public void setOverdueTransactions(long overdueTransactions) { this.overdueTransactions = overdueTransactions; }
        
        public long getTransactionsToday() { return transactionsToday; }
        public void setTransactionsToday(long transactionsToday) { this.transactionsToday = transactionsToday; }
        
        public long getTransactionsThisWeek() { return transactionsThisWeek; }
        public void setTransactionsThisWeek(long transactionsThisWeek) { this.transactionsThisWeek = transactionsThisWeek; }
        
        public long getTransactionsThisMonth() { return transactionsThisMonth; }
        public void setTransactionsThisMonth(long transactionsThisMonth) { this.transactionsThisMonth = transactionsThisMonth; }
        
        public double getAverageReturnTime() { return averageReturnTime; }
        public void setAverageReturnTime(double averageReturnTime) { this.averageReturnTime = averageReturnTime; }
        
        public Map<String, Long> getTransactionsByType() { return transactionsByType; }
        public void setTransactionsByType(Map<String, Long> transactionsByType) { this.transactionsByType = transactionsByType; }
        
        public List<DailyTransactionDto> getRecentActivity() { return recentActivity; }
        public void setRecentActivity(List<DailyTransactionDto> recentActivity) { this.recentActivity = recentActivity; }
    }
    
    public static class InventoryAnalyticsDto {
        private long totalCopies;
        private long availableCopies;
        private long borrowedCopies;
        private double utilizationRate;
        private List<String> lowStockBooks;
        private List<String> highDemandBooks;
        private Map<String, Double> categoryUtilization;
        
        // Constructors
        public InventoryAnalyticsDto() {}
        
        public InventoryAnalyticsDto(long totalCopies, long availableCopies, long borrowedCopies,
                                    double utilizationRate, List<String> lowStockBooks,
                                    List<String> highDemandBooks, Map<String, Double> categoryUtilization) {
            this.totalCopies = totalCopies;
            this.availableCopies = availableCopies;
            this.borrowedCopies = borrowedCopies;
            this.utilizationRate = utilizationRate;
            this.lowStockBooks = lowStockBooks;
            this.highDemandBooks = highDemandBooks;
            this.categoryUtilization = categoryUtilization;
        }
        
        // Getters and Setters
        public long getTotalCopies() { return totalCopies; }
        public void setTotalCopies(long totalCopies) { this.totalCopies = totalCopies; }
        
        public long getAvailableCopies() { return availableCopies; }
        public void setAvailableCopies(long availableCopies) { this.availableCopies = availableCopies; }
        
        public long getBorrowedCopies() { return borrowedCopies; }
        public void setBorrowedCopies(long borrowedCopies) { this.borrowedCopies = borrowedCopies; }
        
        public double getUtilizationRate() { return utilizationRate; }
        public void setUtilizationRate(double utilizationRate) { this.utilizationRate = utilizationRate; }
        
        public List<String> getLowStockBooks() { return lowStockBooks; }
        public void setLowStockBooks(List<String> lowStockBooks) { this.lowStockBooks = lowStockBooks; }
        
        public List<String> getHighDemandBooks() { return highDemandBooks; }
        public void setHighDemandBooks(List<String> highDemandBooks) { this.highDemandBooks = highDemandBooks; }
        
        public Map<String, Double> getCategoryUtilization() { return categoryUtilization; }
        public void setCategoryUtilization(Map<String, Double> categoryUtilization) { this.categoryUtilization = categoryUtilization; }
    }
    
    public static class SystemHealthDto {
        private String status;
        private double responseTime;
        private long uptime;
        private Map<String, String> moduleStatus;
        private List<String> recentErrors;
        
        // Constructors
        public SystemHealthDto() {}
        
        public SystemHealthDto(String status, double responseTime, long uptime,
                              Map<String, String> moduleStatus, List<String> recentErrors) {
            this.status = status;
            this.responseTime = responseTime;
            this.uptime = uptime;
            this.moduleStatus = moduleStatus;
            this.recentErrors = recentErrors;
        }
        
        // Getters and Setters
        public String getStatus() { return status; }
        public void setStatus(String status) { this.status = status; }
        
        public double getResponseTime() { return responseTime; }
        public void setResponseTime(double responseTime) { this.responseTime = responseTime; }
        
        public long getUptime() { return uptime; }
        public void setUptime(long uptime) { this.uptime = uptime; }
        
        public Map<String, String> getModuleStatus() { return moduleStatus; }
        public void setModuleStatus(Map<String, String> moduleStatus) { this.moduleStatus = moduleStatus; }
        
        public List<String> getRecentErrors() { return recentErrors; }
        public void setRecentErrors(List<String> recentErrors) { this.recentErrors = recentErrors; }
    }
    
    // Helper DTOs
    public static class UserActivityDto {
        private String username;
        private String email;
        private long totalTransactions;
        private long activeTransactions;
        
        public UserActivityDto(String username, String email, long totalTransactions, long activeTransactions) {
            this.username = username;
            this.email = email;
            this.totalTransactions = totalTransactions;
            this.activeTransactions = activeTransactions;
        }
        
        // Getters and Setters
        public String getUsername() { return username; }
        public void setUsername(String username) { this.username = username; }
        
        public String getEmail() { return email; }
        public void setEmail(String email) { this.email = email; }
        
        public long getTotalTransactions() { return totalTransactions; }
        public void setTotalTransactions(long totalTransactions) { this.totalTransactions = totalTransactions; }
        
        public long getActiveTransactions() { return activeTransactions; }
        public void setActiveTransactions(long activeTransactions) { this.activeTransactions = activeTransactions; }
    }
    
    public static class PopularBookDto {
        private String title;
        private String author;
        private String category;
        private long borrowCount;
        
        public PopularBookDto(String title, String author, String category, long borrowCount) {
            this.title = title;
            this.author = author;
            this.category = category;
            this.borrowCount = borrowCount;
        }
        
        // Getters and Setters
        public String getTitle() { return title; }
        public void setTitle(String title) { this.title = title; }
        
        public String getAuthor() { return author; }
        public void setAuthor(String author) { this.author = author; }
        
        public String getCategory() { return category; }
        public void setCategory(String category) { this.category = category; }
        
        public long getBorrowCount() { return borrowCount; }
        public void setBorrowCount(long borrowCount) { this.borrowCount = borrowCount; }
    }
    
    public static class DailyTransactionDto {
        private String date;
        private long borrowings;
        private long returns;
        
        public DailyTransactionDto(String date, long borrowings, long returns) {
            this.date = date;
            this.borrowings = borrowings;
            this.returns = returns;
        }
        
        // Getters and Setters
        public String getDate() { return date; }
        public void setDate(String date) { this.date = date; }
        
        public long getBorrowings() { return borrowings; }
        public void setBorrowings(long borrowings) { this.borrowings = borrowings; }
        
        public long getReturns() { return returns; }
        public void setReturns(long returns) { this.returns = returns; }
    }
}
