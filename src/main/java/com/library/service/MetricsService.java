package com.library.service;

import io.micrometer.core.instrument.Counter;
import io.micrometer.core.instrument.Gauge;
import io.micrometer.core.instrument.MeterRegistry;
import io.micrometer.core.instrument.Timer;
import com.library.repository.BookRepository;
import com.library.repository.TransactionRepository;
import com.library.repository.UserRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

import java.util.concurrent.atomic.AtomicInteger;

@Service
public class MetricsService {

    private final MeterRegistry meterRegistry;
    private final BookRepository bookRepository;
    private final UserRepository userRepository;
    private final TransactionRepository transactionRepository;

    private final Counter bookBorrowCounter;
    private final Counter bookReturnCounter;
    private final Counter userRegistrationCounter;
    private final Counter bookCreatedCounter;
    private final Counter csvImportCounter;

    private final Timer authenticationTimer;
    private final Timer bookSearchTimer;
    private final Timer transactionProcessingTimer;

    private final AtomicInteger activeTransactions = new AtomicInteger(0);
    private final AtomicInteger errorCount = new AtomicInteger(0);    @Autowired
    public MetricsService(MeterRegistry meterRegistry,
                         BookRepository bookRepository,
                         UserRepository userRepository,
                         TransactionRepository transactionRepository) {
        
        this.meterRegistry = meterRegistry;
        this.bookRepository = bookRepository;
        this.userRepository = userRepository;
        this.transactionRepository = transactionRepository;
        
        // Create counters
        this.bookBorrowCounter = Counter.builder("library.books.borrowed")
                .description("Number of books borrowed")
                .register(meterRegistry);
        this.bookReturnCounter = Counter.builder("library.books.returned")
                .description("Number of books returned")
                .register(meterRegistry);
        this.userRegistrationCounter = Counter.builder("library.users.registered")
                .description("Number of users registered")
                .register(meterRegistry);
        this.bookCreatedCounter = Counter.builder("library.books.created")
                .description("Number of books created")
                .register(meterRegistry);
        this.csvImportCounter = Counter.builder("library.csv.imports")
                .description("Number of CSV imports processed")
                .register(meterRegistry);
        
        // Create timers
        this.authenticationTimer = Timer.builder("library.authentication.time")
                .description("Time taken for authentication operations")
                .register(meterRegistry);
        this.bookSearchTimer = Timer.builder("library.books.search.time")
                .description("Time taken for book search operations")
                .register(meterRegistry);
        this.transactionProcessingTimer = Timer.builder("library.transactions.processing.time")
                .description("Time taken for transaction processing")
                .register(meterRegistry);        // Register gauges for real-time metrics
        registerGauges();
    }

    private void registerGauges() {
        // Total counts
        Gauge.builder("library.books.total", this, MetricsService::getTotalBooks)
                .description("Total number of books in the library")
                .register(meterRegistry);

        Gauge.builder("library.books.available", this, MetricsService::getAvailableBooks)
                .description("Total number of available books")
                .register(meterRegistry);

        Gauge.builder("library.users.total", this, MetricsService::getTotalUsers)
                .description("Total number of registered users")
                .register(meterRegistry);

        Gauge.builder("library.transactions.active", this, MetricsService::getActiveTransactionsCount)
                .description("Number of active transactions")
                .register(meterRegistry);        Gauge.builder("library.transactions.overdue", this, MetricsService::getOverdueTransactions)
                .description("Number of overdue transactions")
                .register(meterRegistry);

        // Performance metrics
        Gauge.builder("library.performance.active.requests", activeTransactions, AtomicInteger::get)
                .description("Number of active requests being processed")
                .register(meterRegistry);

        Gauge.builder("library.errors.total", errorCount, AtomicInteger::get)
                .description("Total number of errors encountered")
                .register(meterRegistry);
    }

    // Custom metric methods
    public void incrementBookBorrowed() {
        bookBorrowCounter.increment();
    }

    public void incrementBookReturned() {
        bookReturnCounter.increment();
    }

    public void incrementUserRegistration() {
        userRegistrationCounter.increment();
    }

    public void incrementBookCreated() {
        bookCreatedCounter.increment();
    }    public void incrementCsvImport(int bookCount) {
        csvImportCounter.increment();
        meterRegistry.counter("library.csv.books.imported.total").increment(bookCount);
    }

    public void recordAuthenticationTime(Runnable operation) {
        try {
            authenticationTimer.recordCallable(() -> {
                operation.run();
                return null;
            });
        } catch (Exception e) {
            incrementErrorCount();
            operation.run(); // Execute operation anyway
        }
    }

    public void recordBookSearchTime(Runnable operation) {
        try {
            bookSearchTimer.recordCallable(() -> {
                operation.run();
                return null;
            });
        } catch (Exception e) {
            incrementErrorCount();
            operation.run(); // Execute operation anyway
        }
    }

    public void recordTransactionProcessingTime(Runnable operation) {
        try {
            transactionProcessingTimer.recordCallable(() -> {
                operation.run();
                return null;
            });
        } catch (Exception e) {
            incrementErrorCount();
            operation.run(); // Execute operation anyway
        }
    }

    public void incrementActiveRequests() {
        activeTransactions.incrementAndGet();
    }

    public void decrementActiveRequests() {
        activeTransactions.decrementAndGet();
    }

    public void incrementErrorCount() {
        errorCount.incrementAndGet();
    }

    // Gauge methods
    private double getTotalBooks() {
        return bookRepository.count();
    }

    private double getAvailableBooks() {
        return bookRepository.findAvailableBooks().size();
    }

    private double getTotalUsers() {
        return userRepository.count();
    }

    private double getActiveTransactionsCount() {
        return transactionRepository.findByStatus(
            com.library.entity.Transaction.TransactionStatus.ACTIVE).size();
    }

    private double getOverdueTransactions() {
        return transactionRepository.findOverdueTransactions(
            java.time.LocalDateTime.now()).size();
    }

    // Getter for MeterRegistry
    public MeterRegistry getMeterRegistry() {
        return meterRegistry;
    }

    // Utility methods for custom metrics
    public Timer.Sample startTimer() {
        return Timer.start(meterRegistry);
    }

    public void recordCustomMetric(String name, String description, double value) {
        meterRegistry.gauge(name, value);
    }    public void recordCustomCounter(String name, String description) {
        meterRegistry.counter(name).increment();
    }

    public void recordCustomTimer(String name, String description, Runnable operation) {
        try {
            Timer.builder(name)
                    .description(description)
                    .register(meterRegistry)
                    .recordCallable(() -> {
                        operation.run();
                        return null;
                    });
        } catch (Exception e) {
            incrementErrorCount();
            operation.run(); // Execute operation anyway
        }
    }
}
