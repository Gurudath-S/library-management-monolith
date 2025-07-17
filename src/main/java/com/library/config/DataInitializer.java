package com.library.config;

import com.library.entity.Book;
import com.library.entity.User;
import com.library.repository.BookRepository;
import com.library.repository.UserRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.CommandLineRunner;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Component;

import java.math.BigDecimal;

@Component
public class DataInitializer implements CommandLineRunner {
    
    @Autowired
    private UserRepository userRepository;
    
    @Autowired
    private BookRepository bookRepository;
    
    @Autowired
    private PasswordEncoder passwordEncoder;
    
    @Override
    public void run(String... args) throws Exception {
        initializeUsers();
        initializeBooks();
    }
    
    private void initializeUsers() {
        if (userRepository.count() == 0) {
            // Create admin user
            User admin = new User();
            admin.setUsername("admin");
            admin.setPassword(passwordEncoder.encode("admin123"));
            admin.setEmail("admin@library.com");
            admin.setFirstName("Library");
            admin.setLastName("Administrator");
            admin.setRole(User.Role.ADMIN);
            admin.setEnabled(true);
            userRepository.save(admin);
            
            // Create librarian user
            User librarian = new User();
            librarian.setUsername("librarian");
            librarian.setPassword(passwordEncoder.encode("librarian123"));
            librarian.setEmail("librarian@library.com");
            librarian.setFirstName("John");
            librarian.setLastName("Librarian");
            librarian.setRole(User.Role.LIBRARIAN);
            librarian.setEnabled(true);
            userRepository.save(librarian);
            
            // Create regular user
            User user = new User();
            user.setUsername("user");
            user.setPassword(passwordEncoder.encode("user123"));
            user.setEmail("user@library.com");
            user.setFirstName("Jane");
            user.setLastName("Doe");
            user.setRole(User.Role.USER);
            user.setEnabled(true);
            userRepository.save(user);
            
            // System.out.println("Sample users created:");
            // System.out.println("Admin - Username: admin, Password: admin123");
            // System.out.println("Librarian - Username: librarian, Password: librarian123");
            // System.out.println("User - Username: user, Password: user123");
        }
    }
    
    private void initializeBooks() {
        if (bookRepository.count() == 0) {
            // Create sample books
            Book book1 = new Book();
            book1.setIsbn("978-0134685991");
            book1.setTitle("Effective Java");
            book1.setAuthor("Joshua Bloch");
            book1.setCategory("Programming");
            book1.setPublisher("Addison-Wesley Professional");
            book1.setPublicationYear(2017);
            book1.setDescription("The definitive guide to Java programming language best practices");
            book1.setTotalCopies(10);
            book1.setAvailableCopies(10);
            book1.setPrice(new BigDecimal("45.99"));
            book1.setPages(412);
            book1.setLanguage("English");
            book1.setStatus(Book.BookStatus.AVAILABLE);
            bookRepository.save(book1);
            
            Book book2 = new Book();
            book2.setIsbn("978-0596009205");
            book2.setTitle("Head First Design Patterns");
            book2.setAuthor("Eric Freeman");
            book2.setCategory("Programming");
            book2.setPublisher("O'Reilly Media");
            book2.setPublicationYear(2004);
            book2.setDescription("A brain-friendly guide to design patterns");
            book2.setTotalCopies(8);
            book2.setAvailableCopies(8);
            book2.setPrice(new BigDecimal("39.99"));
            book2.setPages(694);
            book2.setLanguage("English");
            book2.setStatus(Book.BookStatus.AVAILABLE);
            bookRepository.save(book2);
            
            Book book3 = new Book();
            book3.setIsbn("978-0321356680");
            book3.setTitle("Clean Code");
            book3.setAuthor("Robert C. Martin");
            book3.setCategory("Programming");
            book3.setPublisher("Prentice Hall");
            book3.setPublicationYear(2008);
            book3.setDescription("A handbook of agile software craftsmanship");
            book3.setTotalCopies(12);
            book3.setAvailableCopies(12);
            book3.setPrice(new BigDecimal("42.99"));
            book3.setPages(464);
            book3.setLanguage("English");
            book3.setStatus(Book.BookStatus.AVAILABLE);
            bookRepository.save(book3);
            
            Book book4 = new Book();
            book4.setIsbn("978-0131103627");
            book4.setTitle("The C Programming Language");
            book4.setAuthor("Brian Kernighan");
            book4.setCategory("Programming");
            book4.setPublisher("Prentice Hall");
            book4.setPublicationYear(1988);
            book4.setDescription("The classic reference for C programming");
            book4.setTotalCopies(6);
            book4.setAvailableCopies(6);
            book4.setPrice(new BigDecimal("35.99"));
            book4.setPages(272);
            book4.setLanguage("English");
            book4.setStatus(Book.BookStatus.AVAILABLE);
            bookRepository.save(book4);
            
            Book book5 = new Book();
            book5.setIsbn("978-0132350884");
            book5.setTitle("Clean Architecture");
            book5.setAuthor("Robert C. Martin");
            book5.setCategory("Software Engineering");
            book5.setPublisher("Prentice Hall");
            book5.setPublicationYear(2017);
            book5.setDescription("A craftsman's guide to software structure and design");
            book5.setTotalCopies(9);
            book5.setAvailableCopies(9);
            book5.setPrice(new BigDecimal("44.99"));
            book5.setPages(432);
            book5.setLanguage("English");
            book5.setStatus(Book.BookStatus.AVAILABLE);
            bookRepository.save(book5);
            
            System.out.println("Sample books created: " + bookRepository.count() + " books");
        }
    }
}
