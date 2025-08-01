package com.library.repository;

import com.library.entity.User;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;

@Repository
public interface UserRepository extends JpaRepository<User, Long> {
    
    Optional<User> findByUsername(String username);
    
    Optional<User> findByEmail(String email);
    
    boolean existsByUsername(String username);
    
    boolean existsByEmail(String email);
    
    List<User> findByRole(User.Role role);
    
    @Query("SELECT u FROM User u WHERE u.enabled = true")
    List<User> findAllActiveUsers();
    
    @Query("SELECT u FROM User u WHERE " +
           "LOWER(u.firstName) LIKE LOWER(CONCAT('%', :searchTerm, '%')) OR " +
           "LOWER(u.lastName) LIKE LOWER(CONCAT('%', :searchTerm, '%')) OR " +
           "LOWER(u.username) LIKE LOWER(CONCAT('%', :searchTerm, '%')) OR " +
           "LOWER(u.email) LIKE LOWER(CONCAT('%', :searchTerm, '%'))")
    List<User> searchUsers(@Param("searchTerm") String searchTerm);
    
    // Analytics support methods
    @Query("SELECT COUNT(DISTINCT u) FROM User u JOIN Transaction t ON u = t.user WHERE t.status = 'ACTIVE'")
    long countUsersWithActiveTransactions();
    
    @Query("SELECT COUNT(u) FROM User u WHERE u.createdAt >= :date")
    long countUsersByCreatedAtAfter(@Param("date") java.time.LocalDateTime date);
    
    @Query("SELECT COUNT(u) FROM User u WHERE u.createdAt BETWEEN :startDate AND :endDate")
    long countUsersByCreatedAtBetween(@Param("startDate") java.time.LocalDateTime startDate, 
                                     @Param("endDate") java.time.LocalDateTime endDate);
    
    @Query("SELECT COUNT(u) FROM User u WHERE u.role = :role")
    long countByRole(@Param("role") User.Role role);
}
