package com.library.service;

import com.library.dto.AnalyticsDashboardDto;
import com.library.entity.Book;
import com.library.entity.Transaction;
import com.library.entity.User;
import com.library.repository.BookRepository;
import com.library.repository.TransactionRepository;
import com.library.repository.UserRepository;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDateTime;
import java.time.format.DateTimeFormatter;
import java.time.temporal.ChronoUnit;
import java.util.*;
import java.util.stream.Collectors;

@Service
@Transactional(readOnly = true)
public class AnalyticsService {
    
    private static final Logger logger = LoggerFactory.getLogger(AnalyticsService.class);
    
    @Autowired
    private UserRepository userRepository;
    
    @Autowired
    private BookRepository bookRepository;
    
    @Autowired
    private TransactionRepository transactionRepository;
    
    @Autowired
    private UserService userService;
    
    @Autowired
    private BookService bookService;
    
    @Autowired
    private TransactionService transactionService;
    
    /**
     * Generate comprehensive analytics dashboard
     * This method demonstrates cross-module communication that will become
     * inter-service communication in microservices architecture
     */
    public AnalyticsDashboardDto generateDashboard() {
        logger.info("Generating comprehensive analytics dashboard");
        
        long startTime = System.currentTimeMillis();
        
        try {
            // Collect analytics from all modules in parallel fashion
            // In microservices, these would be separate service calls
            AnalyticsDashboardDto.UserAnalyticsDto userAnalytics = generateUserAnalytics();
            AnalyticsDashboardDto.BookAnalyticsDto bookAnalytics = generateBookAnalytics();
            AnalyticsDashboardDto.TransactionAnalyticsDto transactionAnalytics = generateTransactionAnalytics();
            AnalyticsDashboardDto.InventoryAnalyticsDto inventoryAnalytics = generateInventoryAnalytics();
            AnalyticsDashboardDto.SystemHealthDto systemHealth = generateSystemHealth();
            
            AnalyticsDashboardDto dashboard = new AnalyticsDashboardDto(
                userAnalytics, bookAnalytics, transactionAnalytics, 
                inventoryAnalytics, systemHealth
            );
            
            long executionTime = System.currentTimeMillis() - startTime;
            logger.info("Analytics dashboard generated successfully in {} ms", executionTime);
            
            return dashboard;
            
        } catch (Exception e) {
            logger.error("Error generating analytics dashboard", e);
            throw new RuntimeException("Failed to generate analytics dashboard", e);
        }
    }
    
    /**
     * Generate user-focused analytics
     * In microservices: This would be a call to User Service
     */
    private AnalyticsDashboardDto.UserAnalyticsDto generateUserAnalytics() {
        logger.debug("Generating user analytics");
        
        // Total users count
        long totalUsers = userRepository.count();
        
        // Active users (users with active transactions)
        long activeUsers = userRepository.countUsersWithActiveTransactions();
        
        // New users this month
        LocalDateTime monthStart = LocalDateTime.now().withDayOfMonth(1).withHour(0).withMinute(0).withSecond(0);
        long newUsersThisMonth = userRepository.countUsersByCreatedAtAfter(monthStart);
        
        // Calculate growth rate
        LocalDateTime lastMonthStart = monthStart.minusMonths(1);
        long newUsersLastMonth = userRepository.countUsersByCreatedAtBetween(lastMonthStart, monthStart);
        double userGrowthRate = calculateGrowthRate(newUsersLastMonth, newUsersThisMonth);
        
        // Users by role
        Map<String, Long> usersByRole = Arrays.stream(User.Role.values())
            .collect(Collectors.toMap(
                Enum::name,
                role -> userRepository.countByRole(role)
            ));
        
        // Top active users
        List<AnalyticsDashboardDto.UserActivityDto> topActiveUsers = getTopActiveUsers();
        
        return new AnalyticsDashboardDto.UserAnalyticsDto(
            totalUsers, activeUsers, newUsersThisMonth, userGrowthRate, 
            usersByRole, topActiveUsers
        );
    }
    
    /**
     * Generate book-focused analytics
     * In microservices: This would be a call to Book Service
     */
    private AnalyticsDashboardDto.BookAnalyticsDto generateBookAnalytics() {
        logger.debug("Generating book analytics");
        
        // Total books
        long totalBooks = bookRepository.count();
        
        // Available books
        long availableBooks = bookRepository.countByAvailableCopiesGreaterThan(0);
        
        // Borrowed books (total copies - available copies)
        long borrowedBooks = bookRepository.getTotalCopies() - bookRepository.getTotalAvailableCopies();
        
        // Books by category
        List<Map<String, Object>> categoryResults = bookRepository.getBookCountByCategory();
        Map<String, Long> booksByCategory = categoryResults.stream()
            .collect(Collectors.toMap(
                result -> (String) result.get("category"),
                result -> ((Number) result.get("count")).longValue()
            ));
        
        // Most borrowed books
        List<AnalyticsDashboardDto.PopularBookDto> mostBorrowedBooks = getMostBorrowedBooks();
        
        // Least borrowed books
        List<AnalyticsDashboardDto.PopularBookDto> leastBorrowedBooks = getLeastBorrowedBooks();
        
        // Average books per user
        long totalUsersCount = userRepository.count();
        double averageBooksPerUser = totalUsersCount > 0 ? (double) totalBooks / totalUsersCount : 0;
        
        return new AnalyticsDashboardDto.BookAnalyticsDto(
            totalBooks, availableBooks, borrowedBooks, booksByCategory,
            mostBorrowedBooks, leastBorrowedBooks, averageBooksPerUser
        );
    }
    
    /**
     * Generate transaction-focused analytics
     * In microservices: This would be a call to Transaction Service
     */
    private AnalyticsDashboardDto.TransactionAnalyticsDto generateTransactionAnalytics() {
        logger.debug("Generating transaction analytics");
        
        // Total transactions
        long totalTransactions = transactionRepository.count();
        
        // Active transactions
        long activeTransactions = transactionRepository.countByStatus(Transaction.TransactionStatus.ACTIVE);
        
        // Overdue transactions
        LocalDateTime now = LocalDateTime.now();
        long overdueTransactions = transactionRepository.findOverdueTransactions(now).size();
        
        // Transactions by time periods
        LocalDateTime todayStart = now.withHour(0).withMinute(0).withSecond(0);
        LocalDateTime weekStart = now.minusWeeks(1);
        LocalDateTime monthStart = now.withDayOfMonth(1).withHour(0).withMinute(0).withSecond(0);
        
        long transactionsToday = transactionRepository.findTransactionsByDateRange(todayStart, now).size();
        long transactionsThisWeek = transactionRepository.findTransactionsByDateRange(weekStart, now).size();
        long transactionsThisMonth = transactionRepository.findTransactionsByDateRange(monthStart, now).size();
        
        // Average return time
        double averageReturnTime = calculateAverageReturnTime();
        
        // Transactions by type
        Map<String, Long> transactionsByType = Arrays.stream(Transaction.TransactionType.values())
            .collect(Collectors.toMap(
                Enum::name,
                type -> (long) transactionRepository.findByType(type).size()
            ));
        
        // Recent activity
        List<AnalyticsDashboardDto.DailyTransactionDto> recentActivity = getRecentTransactionActivity();
        
        return new AnalyticsDashboardDto.TransactionAnalyticsDto(
            totalTransactions, activeTransactions, overdueTransactions,
            transactionsToday, transactionsThisWeek, transactionsThisMonth,
            averageReturnTime, transactionsByType, recentActivity
        );
    }
    
    /**
     * Generate inventory-focused analytics
     * In microservices: This would combine data from Book and Transaction services
     */
    private AnalyticsDashboardDto.InventoryAnalyticsDto generateInventoryAnalytics() {
        logger.debug("Generating inventory analytics");
        
        // Total copies in system
        long totalCopies = bookRepository.getTotalCopies();
        
        // Available copies
        long availableCopies = bookRepository.getTotalAvailableCopies();
        
        // Borrowed copies
        long borrowedCopies = totalCopies - availableCopies;
        
        // Utilization rate
        double utilizationRate = totalCopies > 0 ? ((double) borrowedCopies / totalCopies) * 100 : 0;
        
        // Low stock books (less than 2 available copies)
        List<String> lowStockBooks = bookRepository.findByAvailableCopiesLessThan(2)
            .stream()
            .map(Book::getTitle)
            .collect(Collectors.toList());
        
        // High demand books (utilization > 80%)
        List<String> highDemandBooks = getHighDemandBooks();
        
        // Category utilization
        Map<String, Double> categoryUtilization = getCategoryUtilization();
        
        return new AnalyticsDashboardDto.InventoryAnalyticsDto(
            totalCopies, availableCopies, borrowedCopies, utilizationRate,
            lowStockBooks, highDemandBooks, categoryUtilization
        );
    }
    
    /**
     * Generate system health metrics
     * In microservices: This would aggregate health from all services
     */
    private AnalyticsDashboardDto.SystemHealthDto generateSystemHealth() {
        logger.debug("Generating system health metrics");
        
        // Overall system status
        String status = "HEALTHY";
        
        // Response time (simulated - in real system would measure actual response times)
        double responseTime = Math.random() * 100 + 50; // 50-150ms
        
        // Uptime (simulated)
        long uptime = System.currentTimeMillis() / 1000; // seconds since start
        
        // Module status (in microservices, these would be actual service health checks)
        Map<String, String> moduleStatus = new HashMap<>();
        moduleStatus.put("UserService", "HEALTHY");
        moduleStatus.put("BookService", "HEALTHY");
        moduleStatus.put("TransactionService", "HEALTHY");
        moduleStatus.put("Database", "HEALTHY");
        moduleStatus.put("Authentication", "HEALTHY");
        
        // Recent errors (in real system, would come from logs or monitoring)
        List<String> recentErrors = new ArrayList<>();
        
        return new AnalyticsDashboardDto.SystemHealthDto(
            status, responseTime, uptime, moduleStatus, recentErrors
        );
    }
    
    // Helper methods for complex calculations
    
    private double calculateGrowthRate(long previous, long current) {
        if (previous == 0) return current > 0 ? 100.0 : 0.0;
        return ((double) (current - previous) / previous) * 100;
    }
    
    private List<AnalyticsDashboardDto.UserActivityDto> getTopActiveUsers() {
        return userRepository.findAll().stream()
            .map(user -> {
                long totalTransactions = transactionRepository.findByUser(user).size();
                long activeTransactions = transactionRepository.countActiveTransactionsByUser(user);
                return new AnalyticsDashboardDto.UserActivityDto(
                    user.getUsername(), user.getEmail(), totalTransactions, activeTransactions
                );
            })
            .sorted((a, b) -> Long.compare(b.getTotalTransactions(), a.getTotalTransactions()))
            .limit(5)
            .collect(Collectors.toList());
    }
    
    private List<AnalyticsDashboardDto.PopularBookDto> getMostBorrowedBooks() {
        return bookRepository.findAll().stream()
            .map(book -> {
                long borrowCount = transactionRepository.findByBook(book).size();
                return new AnalyticsDashboardDto.PopularBookDto(
                    book.getTitle(), book.getAuthor(), book.getCategory(), borrowCount
                );
            })
            .sorted((a, b) -> Long.compare(b.getBorrowCount(), a.getBorrowCount()))
            .limit(10)
            .collect(Collectors.toList());
    }
    
    private List<AnalyticsDashboardDto.PopularBookDto> getLeastBorrowedBooks() {
        return bookRepository.findAll().stream()
            .map(book -> {
                long borrowCount = transactionRepository.findByBook(book).size();
                return new AnalyticsDashboardDto.PopularBookDto(
                    book.getTitle(), book.getAuthor(), book.getCategory(), borrowCount
                );
            })
            .sorted(Comparator.comparing(AnalyticsDashboardDto.PopularBookDto::getBorrowCount))
            .limit(5)
            .collect(Collectors.toList());
    }
    
    private double calculateAverageReturnTime() {
        List<Transaction> completedTransactions = transactionRepository.findByStatus(Transaction.TransactionStatus.RETURNED);
        
        if (completedTransactions.isEmpty()) {
            return 0.0;
        }
        
        double totalDays = completedTransactions.stream()
            .filter(t -> t.getReturnedAt() != null)
            .mapToDouble(t -> ChronoUnit.DAYS.between(t.getBorrowedAt(), t.getReturnedAt()))
            .sum();
        
        return totalDays / completedTransactions.size();
    }
    
    private List<AnalyticsDashboardDto.DailyTransactionDto> getRecentTransactionActivity() {
        List<AnalyticsDashboardDto.DailyTransactionDto> activity = new ArrayList<>();
        DateTimeFormatter formatter = DateTimeFormatter.ofPattern("yyyy-MM-dd");
        
        for (int i = 6; i >= 0; i--) {
            LocalDateTime date = LocalDateTime.now().minusDays(i);
            LocalDateTime startOfDay = date.withHour(0).withMinute(0).withSecond(0);
            LocalDateTime endOfDay = date.withHour(23).withMinute(59).withSecond(59);
            
            List<Transaction> dayTransactions = transactionRepository.findTransactionsByDateRange(startOfDay, endOfDay);
            
            long borrowings = dayTransactions.stream()
                .filter(t -> t.getType() == Transaction.TransactionType.BORROW)
                .count();
            
            long returns = dayTransactions.stream()
                .filter(t -> t.getType() == Transaction.TransactionType.RETURN)
                .count();
            
            activity.add(new AnalyticsDashboardDto.DailyTransactionDto(
                date.format(formatter), borrowings, returns
            ));
        }
        
        return activity;
    }
    
    private List<String> getHighDemandBooks() {
        return bookRepository.findAll().stream()
            .filter(book -> {
                if (book.getTotalCopies() == 0) return false;
                double utilization = ((double) (book.getTotalCopies() - book.getAvailableCopies())) / book.getTotalCopies();
                return utilization > 0.8; // 80% utilization threshold
            })
            .map(Book::getTitle)
            .collect(Collectors.toList());
    }
    
    private Map<String, Double> getCategoryUtilization() {
        Map<String, Double> categoryUtilization = new HashMap<>();
        
        List<Map<String, Object>> categoryResults = bookRepository.getBookCountByCategory();
        Map<String, Long> booksByCategory = categoryResults.stream()
            .collect(Collectors.toMap(
                result -> (String) result.get("category"),
                result -> ((Number) result.get("count")).longValue()
            ));
        
        for (String category : booksByCategory.keySet()) {
            List<Book> categoryBooks = bookRepository.findByCategory(category);
            
            long totalCopies = categoryBooks.stream().mapToLong(Book::getTotalCopies).sum();
            long availableCopies = categoryBooks.stream().mapToLong(Book::getAvailableCopies).sum();
            
            double utilization = totalCopies > 0 ? 
                ((double) (totalCopies - availableCopies) / totalCopies) * 100 : 0;
            
            categoryUtilization.put(category, utilization);
        }
        
        return categoryUtilization;
    }
}
