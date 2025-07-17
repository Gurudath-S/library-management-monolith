package com.library.repository;

import com.library.entity.Transaction;
import com.library.entity.User;
import com.library.entity.Book;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.time.LocalDateTime;
import java.util.List;
import java.util.Optional;

@Repository
public interface TransactionRepository extends JpaRepository<Transaction, Long> {
    
    List<Transaction> findByUser(User user);
    
    List<Transaction> findByBook(Book book);
    
    List<Transaction> findByType(Transaction.TransactionType type);
    
    List<Transaction> findByStatus(Transaction.TransactionStatus status);
    
    List<Transaction> findByUserAndStatus(User user, Transaction.TransactionStatus status);
    
    List<Transaction> findByBookAndStatus(Book book, Transaction.TransactionStatus status);
    
    @Query("SELECT t FROM Transaction t WHERE t.user = :user AND t.book = :book AND t.status = 'ACTIVE'")
    Optional<Transaction> findActiveTransactionByUserAndBook(@Param("user") User user, @Param("book") Book book);
    
    @Query("SELECT t FROM Transaction t WHERE t.dueDate < :currentDate AND t.status = 'ACTIVE'")
    List<Transaction> findOverdueTransactions(@Param("currentDate") LocalDateTime currentDate);
    
    @Query("SELECT t FROM Transaction t WHERE t.user = :user ORDER BY t.createdAt DESC")
    List<Transaction> findUserTransactionHistory(@Param("user") User user);
    
    @Query("SELECT t FROM Transaction t WHERE t.book = :book ORDER BY t.createdAt DESC")
    List<Transaction> findBookTransactionHistory(@Param("book") Book book);
    
    @Query("SELECT t FROM Transaction t WHERE t.createdAt BETWEEN :startDate AND :endDate")
    List<Transaction> findTransactionsByDateRange(@Param("startDate") LocalDateTime startDate, 
                                                 @Param("endDate") LocalDateTime endDate);
    
    @Query("SELECT COUNT(t) FROM Transaction t WHERE t.user = :user AND t.status = 'ACTIVE'")
    long countActiveTransactionsByUser(@Param("user") User user);
    
    @Query("SELECT COUNT(t) FROM Transaction t WHERE t.book = :book AND t.status = 'ACTIVE'")
    long countActiveTransactionsByBook(@Param("book") Book book);
}
