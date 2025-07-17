package com.library.service;

import com.library.entity.Book;
import com.library.entity.Transaction;
import com.library.entity.User;
import com.library.repository.BookRepository;
import com.library.repository.TransactionRepository;
import com.library.repository.UserRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDateTime;
import java.util.List;
import java.util.Optional;

@Service
@Transactional
public class TransactionService {
      private final TransactionRepository transactionRepository;
    private final BookRepository bookRepository;
    private final UserRepository userRepository;
    private final MetricsService metricsService;
    
    @Autowired
    public TransactionService(TransactionRepository transactionRepository, 
                            BookRepository bookRepository, 
                            UserRepository userRepository,
                            MetricsService metricsService) {
        this.transactionRepository = transactionRepository;
        this.bookRepository = bookRepository;
        this.userRepository = userRepository;
        this.metricsService = metricsService;
    }
    
    public Transaction borrowBook(Long userId, Long bookId) {
        User user = userRepository.findById(userId)
                .orElseThrow(() -> new RuntimeException("User not found with id: " + userId));
        
        Book book = bookRepository.findById(bookId)
                .orElseThrow(() -> new RuntimeException("Book not found with id: " + bookId));
        
        // Check if book is available
        if (!book.isAvailable()) {
            throw new RuntimeException("Book is not available for borrowing");
        }
        
        // Check if user already has this book borrowed
        Optional<Transaction> existingTransaction = transactionRepository
                .findActiveTransactionByUserAndBook(user, book);
        
        if (existingTransaction.isPresent()) {
            throw new RuntimeException("User already has this book borrowed");
        }
        
        // Check borrowing limit (e.g., max 5 books per user)
        long activeTransactions = transactionRepository.countActiveTransactionsByUser(user);
        if (activeTransactions >= 5) {
            throw new RuntimeException("User has reached the maximum borrowing limit");
        }
          // Create transaction
        Transaction transaction = new Transaction(user, book, Transaction.TransactionType.BORROW);
        transaction.setStatus(Transaction.TransactionStatus.ACTIVE);
        
        // Update book inventory
        book.borrowCopy();
        bookRepository.save(book);
        
        Transaction savedTransaction = transactionRepository.save(transaction);
        
        // Record metrics
        metricsService.incrementBookBorrowed();
        
        return savedTransaction;
    }
    
    public Transaction returnBook(Long userId, Long bookId) {
        User user = userRepository.findById(userId)
                .orElseThrow(() -> new RuntimeException("User not found with id: " + userId));
        
        Book book = bookRepository.findById(bookId)
                .orElseThrow(() -> new RuntimeException("Book not found with id: " + bookId));
        
        // Find active transaction
        Transaction transaction = transactionRepository
                .findActiveTransactionByUserAndBook(user, book)
                .orElseThrow(() -> new RuntimeException("No active borrowing found for this book and user"));
          // Mark transaction as returned
        transaction.markAsReturned();
        
        // Update book inventory
        book.returnCopy();
        bookRepository.save(book);
        
        Transaction savedTransaction = transactionRepository.save(transaction);
        
        // Record metrics
        metricsService.incrementBookReturned();
        
        return savedTransaction;
    }
    
    public List<Transaction> getUserTransactionHistory(Long userId) {
        User user = userRepository.findById(userId)
                .orElseThrow(() -> new RuntimeException("User not found with id: " + userId));
        
        return transactionRepository.findUserTransactionHistory(user);
    }
    
    public List<Transaction> getActiveTransactionsByUser(Long userId) {
        User user = userRepository.findById(userId)
                .orElseThrow(() -> new RuntimeException("User not found with id: " + userId));
        
        return transactionRepository.findByUserAndStatus(user, Transaction.TransactionStatus.ACTIVE);
    }
    
    public List<Transaction> getBookTransactionHistory(Long bookId) {
        Book book = bookRepository.findById(bookId)
                .orElseThrow(() -> new RuntimeException("Book not found with id: " + bookId));
        
        return transactionRepository.findBookTransactionHistory(book);
    }
    
    public List<Transaction> getAllTransactions() {
        return transactionRepository.findAll();
    }
    
    public List<Transaction> getOverdueTransactions() {
        return transactionRepository.findOverdueTransactions(LocalDateTime.now());
    }
    
    public List<Transaction> getTransactionsByDateRange(LocalDateTime startDate, LocalDateTime endDate) {
        return transactionRepository.findTransactionsByDateRange(startDate, endDate);
    }
    
    public Optional<Transaction> findById(Long id) {
        return transactionRepository.findById(id);
    }
    
    public Transaction updateTransaction(Long id, Transaction updatedTransaction) {
        return transactionRepository.findById(id)
                .map(transaction -> {
                    transaction.setStatus(updatedTransaction.getStatus());
                    transaction.setNotes(updatedTransaction.getNotes());
                    transaction.setDueDate(updatedTransaction.getDueDate());
                    return transactionRepository.save(transaction);
                })
                .orElseThrow(() -> new RuntimeException("Transaction not found with id: " + id));
    }
    
    public void cancelTransaction(Long id) {
        Transaction transaction = transactionRepository.findById(id)
                .orElseThrow(() -> new RuntimeException("Transaction not found with id: " + id));
        
        if (transaction.getStatus() == Transaction.TransactionStatus.ACTIVE) {
            transaction.setStatus(Transaction.TransactionStatus.CANCELLED);
            
            // If it was a borrow transaction, return the book to inventory
            if (transaction.getType() == Transaction.TransactionType.BORROW) {
                Book book = transaction.getBook();
                book.returnCopy();
                bookRepository.save(book);
            }
            
            transactionRepository.save(transaction);
        } else {
            throw new RuntimeException("Only active transactions can be cancelled");
        }
    }
    
    public void markTransactionOverdue(Long id) {
        Transaction transaction = transactionRepository.findById(id)
                .orElseThrow(() -> new RuntimeException("Transaction not found with id: " + id));
        
        if (transaction.getStatus() == Transaction.TransactionStatus.ACTIVE) {
            transaction.setStatus(Transaction.TransactionStatus.OVERDUE);
            transactionRepository.save(transaction);
        }
    }
    
    public void extendDueDate(Long id, LocalDateTime newDueDate) {
        Transaction transaction = transactionRepository.findById(id)
                .orElseThrow(() -> new RuntimeException("Transaction not found with id: " + id));
        
        if (transaction.getStatus() == Transaction.TransactionStatus.ACTIVE) {
            transaction.setDueDate(newDueDate);
            transactionRepository.save(transaction);
        } else {
            throw new RuntimeException("Only active transactions can have their due date extended");
        }
    }
}
