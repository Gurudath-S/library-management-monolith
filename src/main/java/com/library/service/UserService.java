package com.library.service;

import com.library.dto.UserRegistrationDto;
import com.library.entity.User;
import com.library.repository.UserRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.security.core.userdetails.UserDetails;
import org.springframework.security.core.userdetails.UserDetailsService;
import org.springframework.security.core.userdetails.UsernameNotFoundException;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;
import java.util.Optional;

@Service
@Transactional
public class UserService implements UserDetailsService {
    
    private final UserRepository userRepository;
    private final PasswordEncoder passwordEncoder;
    private final MetricsService metricsService;
    
    @Autowired
    public UserService(UserRepository userRepository, PasswordEncoder passwordEncoder, MetricsService metricsService) {
        this.userRepository = userRepository;
        this.passwordEncoder = passwordEncoder;
        this.metricsService = metricsService;
    }
    
    @Override
    public UserDetails loadUserByUsername(String usernameOrEmail) throws UsernameNotFoundException {
        User user = userRepository.findByUsername(usernameOrEmail)
                .or(() -> userRepository.findByEmail(usernameOrEmail))
                .orElseThrow(() -> new UsernameNotFoundException("User not found: " + usernameOrEmail));
        
        return user;
    }
      public User registerUser(UserRegistrationDto registrationDto) {
        if (userRepository.existsByUsername(registrationDto.getUsername())) {
            throw new RuntimeException("Username is already taken!");
        }
        
        if (userRepository.existsByEmail(registrationDto.getEmail())) {
            throw new RuntimeException("Email is already registered!");
        }
        
        User user = new User();
        user.setUsername(registrationDto.getUsername());
        user.setPassword(passwordEncoder.encode(registrationDto.getPassword()));
        user.setEmail(registrationDto.getEmail());
        user.setFirstName(registrationDto.getFirstName());
        user.setLastName(registrationDto.getLastName());
        user.setPhoneNumber(registrationDto.getPhoneNumber());
        user.setAddress(registrationDto.getAddress());
        user.setRole(User.Role.USER);
        user.setEnabled(true);
        
        User savedUser = userRepository.save(user);
        
        // Record metrics
        metricsService.incrementUserRegistration();
        
        return savedUser;
    }
    
    public Optional<User> findById(Long id) {
        return userRepository.findById(id);
    }
    
    public Optional<User> findByUsername(String username) {
        return userRepository.findByUsername(username);
    }
    
    public Optional<User> findByEmail(String email) {
        return userRepository.findByEmail(email);
    }
    
    public List<User> findAllUsers() {
        return userRepository.findAll();
    }
    
    public List<User> findActiveUsers() {
        return userRepository.findAllActiveUsers();
    }
    
    public List<User> searchUsers(String searchTerm) {
        return userRepository.searchUsers(searchTerm);
    }
    
    public User updateUser(Long id, User updatedUser) {
        return userRepository.findById(id)
                .map(user -> {
                    user.setFirstName(updatedUser.getFirstName());
                    user.setLastName(updatedUser.getLastName());
                    user.setEmail(updatedUser.getEmail());
                    user.setPhoneNumber(updatedUser.getPhoneNumber());
                    user.setAddress(updatedUser.getAddress());
                    return userRepository.save(user);
                })
                .orElseThrow(() -> new RuntimeException("User not found with id: " + id));
    }
    
    public User updateUserRole(Long id, User.Role role) {
        return userRepository.findById(id)
                .map(user -> {
                    user.setRole(role);
                    return userRepository.save(user);
                })
                .orElseThrow(() -> new RuntimeException("User not found with id: " + id));
    }
    
    public void enableUser(Long id) {
        userRepository.findById(id)
                .ifPresentOrElse(
                    user -> {
                        user.setEnabled(true);
                        userRepository.save(user);
                    },
                    () -> { throw new RuntimeException("User not found with id: " + id); }
                );
    }
    
    public void disableUser(Long id) {
        userRepository.findById(id)
                .ifPresentOrElse(
                    user -> {
                        user.setEnabled(false);
                        userRepository.save(user);
                    },
                    () -> { throw new RuntimeException("User not found with id: " + id); }
                );
    }
    
    public void deleteUser(Long id) {
        if (!userRepository.existsById(id)) {
            throw new RuntimeException("User not found with id: " + id);
        }
        userRepository.deleteById(id);
    }
    
    public boolean existsByUsername(String username) {
        return userRepository.existsByUsername(username);
    }
    
    public boolean existsByEmail(String email) {
        return userRepository.existsByEmail(email);
    }
}
