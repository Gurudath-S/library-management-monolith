package com.library.config;

import com.library.entity.Book;
import com.library.entity.Transaction;
import com.library.entity.User;
import com.library.repository.BookRepository;
import com.library.repository.TransactionRepository;
import com.library.repository.UserRepository;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.CommandLineRunner;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Component;

import java.math.BigDecimal;
import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.List;
import java.util.Random;

@Component
public class DataInitializer implements CommandLineRunner {
    
    private static final Logger logger = LoggerFactory.getLogger(DataInitializer.class);
    
    @Autowired
    private UserRepository userRepository;
    
    @Autowired
    private BookRepository bookRepository;
    
    @Autowired
    private TransactionRepository transactionRepository;
    
    @Autowired
    private PasswordEncoder passwordEncoder;
    
    private final Random random = new Random();
    
    @Override
    public void run(String... args) throws Exception {
        logger.info("Starting data initialization for analytics testing...");
        
        initializeUsers();
        initializeBooks();
        initializeTransactions();
        
        logDataSummary();
        logger.info("Data initialization completed successfully!");
    }
    
    private void initializeUsers() {
        if (userRepository.count() > 0) {
            logger.info("Users already exist, skipping user initialization");
            return;
        }
        
        logger.info("Creating test users...");
        
        // Create admin user
        User admin = createUser("admin", "admin123", "admin@library.com", 
                               "Library", "Administrator", "555-0001", 
                               "123 Admin Street", User.Role.ADMIN);
        userRepository.save(admin);
        
        // Create librarian users
        User librarian1 = createUser("librarian", "librarian123", "librarian@library.com", 
                                   "John", "Librarian", "555-0002", 
                                   "456 Library Ave", User.Role.LIBRARIAN);
        userRepository.save(librarian1);
        
        User librarian2 = createUser("sarah.jones", "librarian123", "sarah.jones@library.com", 
                                   "Sarah", "Jones", "555-0003", 
                                   "789 Book Boulevard", User.Role.LIBRARIAN);
        userRepository.save(librarian2);
        
        // Create regular users with diverse data for analytics
        String[] firstNames = {"Alice", "Bob", "Charlie", "Diana", "Edward", "Fiona", "George", "Hannah", 
                              "Ian", "Julia", "Kevin", "Laura", "Michael", "Nancy", "Oscar", "Patricia",
                              "Quinn", "Rachel", "Samuel", "Teresa", "Ulysses", "Victoria", "William", "Xena",
                              "Yusuf", "Zoe", "Aaron", "Bella", "Carlos", "Deborah", "Elena", "Frank",
                              "Grace", "Henry", "Iris", "Jack", "Karen", "Luis", "Maria", "Nathan"};
        
        String[] lastNames = {"Smith", "Johnson", "Williams", "Brown", "Jones", "Garcia", "Miller", "Davis",
                             "Rodriguez", "Martinez", "Hernandez", "Lopez", "Gonzalez", "Wilson", "Anderson", "Thomas",
                             "Taylor", "Moore", "Jackson", "Martin", "Lee", "Perez", "Thompson", "White",
                             "Harris", "Sanchez", "Clark", "Ramirez", "Lewis", "Robinson", "Walker", "Young",
                             "Allen", "King", "Wright", "Scott", "Torres", "Nguyen", "Hill", "Flores"};
        
        List<User> users = new ArrayList<>();
        
        for (int i = 0; i < 45; i++) { // Create 45 regular users + 3 system users = 48 total
            String firstName = firstNames[i % firstNames.length];
            String lastName = lastNames[i % lastNames.length];
            String username = (firstName + "." + lastName + (i + 1)).toLowerCase();
            String email = username + "@email.com";
            String phone = "555-" + String.format("%04d", 1000 + i);
            String address = (100 + i) + " " + firstName + " Street";
            
            // Set creation dates over the past 12 months for growth analytics
            LocalDateTime createdAt = LocalDateTime.now().minusMonths(random.nextInt(12))
                                                        .minusDays(random.nextInt(30))
                                                        .minusHours(random.nextInt(24));
            
            User user = createUser(username, "user123", email, firstName, lastName, phone, address, User.Role.USER);
            user.setCreatedAt(createdAt);
            user.setUpdatedAt(createdAt);
            
            // Randomly disable some users for analytics
            if (random.nextDouble() < 0.05) { // 5% disabled users
                user.setEnabled(false);
            }
            
            users.add(user);
        }
        
        userRepository.saveAll(users);
        logger.info("Created {} users successfully", users.size() + 3);
    }
    
    private void initializeBooks() {
        if (bookRepository.count() > 0) {
            logger.info("Books already exist, skipping book initialization");
            return;
        }
        
        logger.info("Creating test books...");
        
        // Book data for comprehensive analytics
        Object[][] bookData = {
            // {ISBN, Title, Author, Category, Publisher, Year, Copies, Price, Pages}
            {"978-0134685991", "Effective Java", "Joshua Bloch", "Programming", "Addison-Wesley", 2017, 5, "45.99", 412},
            {"978-0321356680", "Effective C++", "Scott Meyers", "Programming", "Addison-Wesley", 2005, 3, "42.99", 320},
            {"978-0596009205", "Head First Design Patterns", "Eric Freeman", "Programming", "O'Reilly", 2004, 4, "39.99", 694},
            {"978-0132350884", "Clean Code", "Robert Martin", "Programming", "Prentice Hall", 2008, 6, "44.99", 464},
            {"978-0201633610", "Design Patterns", "Gang of Four", "Programming", "Addison-Wesley", 1994, 2, "54.99", 395},
            
            {"978-0061120084", "To Kill a Mockingbird", "Harper Lee", "Fiction", "Harper Perennial", 1960, 8, "14.99", 376},
            {"978-0451524935", "1984", "George Orwell", "Fiction", "Signet Classics", 1949, 7, "13.99", 328},
            {"978-0547928227", "The Hobbit", "J.R.R. Tolkien", "Fantasy", "Houghton Mifflin", 1937, 5, "16.99", 310},
            {"978-0439708180", "Harry Potter and the Sorcerer's Stone", "J.K. Rowling", "Fantasy", "Scholastic", 1997, 10, "8.99", 309},
            {"978-0316769174", "The Catcher in the Rye", "J.D. Salinger", "Fiction", "Little Brown", 1951, 4, "15.99", 234},
            
            {"978-0486284736", "The Adventures of Sherlock Holmes", "Arthur Conan Doyle", "Mystery", "Dover Publications", 1892, 6, "12.99", 307},
            {"978-0345339706", "The Lion, the Witch and the Wardrobe", "C.S. Lewis", "Fantasy", "HarperCollins", 1950, 5, "8.99", 208},
            {"978-0743273565", "The Great Gatsby", "F. Scott Fitzgerald", "Fiction", "Scribner", 1925, 7, "15.99", 180},
            {"978-0525478812", "The Fault in Our Stars", "John Green", "Romance", "Dutton Books", 2012, 8, "12.99", 313},
            {"978-0060935467", "One Hundred Years of Solitude", "Gabriel García Márquez", "Fiction", "Harper Perennial", 1967, 3, "17.99", 417},
            
            {"978-0199536566", "Oxford History of the World", "J.M. Roberts", "History", "Oxford University Press", 2013, 2, "29.99", 984},
            {"978-0143036531", "The Immortal Life of Henrietta Lacks", "Rebecca Skloot", "Science", "Broadway Books", 2010, 4, "16.99", 381},
            {"978-0385537859", "Freakonomics", "Steven Levitt", "Economics", "William Morrow", 2005, 5, "16.99", 315},
            {"978-1400063515", "The Tipping Point", "Malcolm Gladwell", "Psychology", "Little Brown", 2000, 6, "17.99", 301},
            {"978-0062316097", "Sapiens", "Yuval Noah Harari", "History", "Harper", 2015, 9, "22.99", 443},
            
            {"978-0446310789", "To Kill a Mockingbird", "Harper Lee", "Fiction", "Grand Central", 1960, 3, "14.99", 281},
            {"978-0062073488", "Gone Girl", "Gillian Flynn", "Thriller", "Crown Publishers", 2012, 7, "15.99", 419},
            {"978-0385514231", "Water for Elephants", "Sara Gruen", "Fiction", "Algonquin Books", 2006, 4, "15.99", 331},
            {"978-0062315007", "The Alchemist", "Paulo Coelho", "Fiction", "HarperOne", 1988, 6, "14.99", 163},
            {"978-0553296983", "Dune", "Frank Herbert", "Science Fiction", "Ace", 1965, 5, "16.99", 688},
            
            {"978-0553213119", "Jurassic Park", "Michael Crichton", "Science Fiction", "Ballantine Books", 1990, 4, "15.99", 399},
            {"978-0307277671", "The Da Vinci Code", "Dan Brown", "Thriller", "Doubleday", 2003, 8, "15.99", 454},
            {"978-0307269751", "The Girl with the Dragon Tattoo", "Stieg Larsson", "Thriller", "Knopf", 2005, 6, "14.99", 644},
            {"978-0439655484", "The Hunger Games", "Suzanne Collins", "Young Adult", "Scholastic", 2008, 9, "13.99", 374},
            {"978-0439139595", "Harry Potter and the Goblet of Fire", "J.K. Rowling", "Fantasy", "Scholastic", 2000, 8, "10.99", 734},
            
            {"978-0060850524", "Brave New World", "Aldous Huxley", "Science Fiction", "Harper Perennial", 1932, 5, "15.99", 311},
            {"978-0140449136", "The Count of Monte Cristo", "Alexandre Dumas", "Adventure", "Penguin Classics", 1844, 2, "18.99", 1276},
            {"978-0486411095", "Frankenstein", "Mary Shelley", "Horror", "Dover Publications", 1818, 4, "12.99", 166},
            {"978-0486406510", "Dracula", "Bram Stoker", "Horror", "Dover Publications", 1897, 3, "13.99", 418},
            {"978-0140283334", "Les Misérables", "Victor Hugo", "Fiction", "Penguin Classics", 1862, 2, "22.99", 1463},
            
            {"978-0553382563", "A Game of Thrones", "George R.R. Martin", "Fantasy", "Bantam", 1996, 7, "16.99", 694},
            {"978-0345391803", "The Hitchhiker's Guide to the Galaxy", "Douglas Adams", "Science Fiction", "Del Rey", 1979, 6, "14.99", 224},
            {"978-0441013593", "Neuromancer", "William Gibson", "Cyberpunk", "Ace", 1984, 3, "15.99", 271},
            {"978-0553573404", "A Clash of Kings", "George R.R. Martin", "Fantasy", "Bantam", 1999, 5, "16.99", 761},
            {"978-0765326355", "The Way of Kings", "Brandon Sanderson", "Fantasy", "Tor Books", 2010, 4, "28.99", 1007},
            
            {"978-0316015844", "Twilight", "Stephenie Meyer", "Romance", "Little Brown", 2005, 6, "12.99", 498},
            {"978-0439023481", "The Giver", "Lois Lowry", "Young Adult", "Houghton Mifflin", 1993, 5, "8.99", 180},
            {"978-0062024039", "Divergent", "Veronica Roth", "Young Adult", "Katherine Tegen", 2011, 7, "17.99", 487},
            {"978-0385737951", "The Maze Runner", "James Dashner", "Young Adult", "Delacorte Press", 2009, 6, "9.99", 375},
            {"978-0545010221", "The Lightning Thief", "Rick Riordan", "Young Adult", "Disney-Hyperion", 2005, 8, "7.99", 377},
            
            {"978-0590353427", "Hatchet", "Gary Paulsen", "Adventure", "Scholastic", 1987, 4, "8.99", 195},
            {"978-0064401944", "Where the Red Fern Grows", "Wilson Rawls", "Adventure", "Yearling", 1961, 3, "8.99", 245},
            {"978-0394800011", "The Cat in the Hat", "Dr. Seuss", "Children", "Random House", 1957, 5, "8.99", 61},
            {"978-0064430937", "Charlotte's Web", "E.B. White", "Children", "HarperCollins", 1952, 6, "7.99", 184},
            {"978-0439064873", "Captain Underpants", "Dav Pilkey", "Children", "Blue Sky Press", 1997, 4, "5.99", 125},
            
            {"978-0061353246", "Coraline", "Neil Gaiman", "Fantasy", "HarperCollins", 2002, 4, "8.99", 162},
            {"978-0142407332", "The Kite Runner", "Khaled Hosseini", "Fiction", "Riverhead Books", 2003, 5, "15.99", 371}
        };
        
        List<Book> books = new ArrayList<>();
        
        for (Object[] data : bookData) {
            Book book = new Book();
            book.setIsbn((String) data[0]);
            book.setTitle((String) data[1]);
            book.setAuthor((String) data[2]);
            book.setCategory((String) data[3]);
            book.setPublisher((String) data[4]);
            book.setPublicationYear((Integer) data[5]);
            book.setTotalCopies((Integer) data[6]);
            book.setAvailableCopies((Integer) data[6]); // Start with all copies available
            book.setPrice(new BigDecimal((String) data[7]));
            book.setPages((Integer) data[8]);
            book.setLanguage("English");
            book.setStatus(Book.BookStatus.AVAILABLE);
            book.setDescription("A great book in the " + data[3] + " category by " + data[2]);
            
            books.add(book);
        }
        
        bookRepository.saveAll(books);
        logger.info("Created {} books successfully", books.size());
    }
    
    private void initializeTransactions() {
        if (transactionRepository.count() > 0) {
            logger.info("Transactions already exist, skipping transaction initialization");
            return;
        }
        
        logger.info("Creating test transactions...");
        
        List<User> users = userRepository.findAll();
        List<Book> books = bookRepository.findAll();
        
        if (users.isEmpty() || books.isEmpty()) {
            logger.warn("Cannot create transactions - no users or books found");
            return;
        }
        
        List<Transaction> transactions = new ArrayList<>();
        
        // Create realistic transaction patterns over the past 6 months
        LocalDateTime now = LocalDateTime.now();
        
        // Create 80-100 transactions with realistic patterns
        for (int i = 0; i < 85; i++) {
            User user = users.get(random.nextInt(users.size()));
            Book book = books.get(random.nextInt(books.size()));
            
            // Create transactions over past 6 months
            LocalDateTime transactionDate = now.minusMonths(random.nextInt(6))
                                             .minusDays(random.nextInt(30))
                                             .minusHours(random.nextInt(24));
            
            Transaction transaction = new Transaction();
            transaction.setUser(user);
            transaction.setBook(book);
            transaction.setType(Transaction.TransactionType.BORROW);
            transaction.setBorrowedAt(transactionDate);
            transaction.setCreatedAt(transactionDate);
            transaction.setUpdatedAt(transactionDate);
            
            // Set due date (14 days from borrow)
            transaction.setDueDate(transactionDate.plusDays(14));
            
            // Randomly determine if book has been returned
            double returnProbability = 0.7; // 70% of books are returned
            if (random.nextDouble() < returnProbability) {
                // Book is returned
                LocalDateTime returnDate = transactionDate.plusDays(random.nextInt(20) + 1); // Return within 1-20 days
                if (returnDate.isAfter(now)) {
                    returnDate = now.minusDays(1); // Ensure return date is in the past
                }
                
                transaction.setReturnedAt(returnDate);
                transaction.setStatus(Transaction.TransactionStatus.RETURNED);
                transaction.setUpdatedAt(returnDate);
                
                // Create corresponding return transaction
                Transaction returnTransaction = new Transaction();
                returnTransaction.setUser(user);
                returnTransaction.setBook(book);
                returnTransaction.setType(Transaction.TransactionType.RETURN);
                returnTransaction.setBorrowedAt(transactionDate);
                returnTransaction.setReturnedAt(returnDate);
                returnTransaction.setDueDate(transaction.getDueDate());
                returnTransaction.setStatus(Transaction.TransactionStatus.RETURNED);
                returnTransaction.setCreatedAt(returnDate);
                returnTransaction.setUpdatedAt(returnDate);
                
                transactions.add(returnTransaction);
            } else {
                // Book is still borrowed
                transaction.setStatus(Transaction.TransactionStatus.ACTIVE);
                
                // Some active transactions are overdue
                if (transaction.getDueDate().isBefore(now)) {
                    // This is an overdue transaction
                    transaction.setStatus(Transaction.TransactionStatus.ACTIVE); // Still active but overdue
                }
                
                // Update book availability
                if (book.getAvailableCopies() > 0) {
                    book.setAvailableCopies(book.getAvailableCopies() - 1);
                }
            }
            
            transactions.add(transaction);
        }
        
        transactionRepository.saveAll(transactions);
        
        // Update book availability based on active transactions
        for (Book book : books) {
            long activeBorrows = transactions.stream()
                .filter(t -> t.getBook().getId().equals(book.getId()))
                .filter(t -> t.getStatus() == Transaction.TransactionStatus.ACTIVE)
                .count();
            
            int newAvailableCopies = (int) Math.max(0, book.getTotalCopies() - activeBorrows);
            book.setAvailableCopies(newAvailableCopies);
        }
        
        bookRepository.saveAll(books);
        
        logger.info("Created {} transactions successfully", transactions.size());
    }
    
    private User createUser(String username, String password, String email, String firstName, 
                           String lastName, String phone, String address, User.Role role) {
        User user = new User();
        user.setUsername(username);
        user.setPassword(passwordEncoder.encode(password));
        user.setEmail(email);
        user.setFirstName(firstName);
        user.setLastName(lastName);
        user.setPhoneNumber(phone);
        user.setAddress(address);
        user.setRole(role);
        user.setEnabled(true);
        user.setCreatedAt(LocalDateTime.now());
        user.setUpdatedAt(LocalDateTime.now());
        return user;
    }
    
    private void logDataSummary() {
        long userCount = userRepository.count();
        long bookCount = bookRepository.count();
        long transactionCount = transactionRepository.count();
        long activeTransactions = transactionRepository.countByStatus(Transaction.TransactionStatus.ACTIVE);
        long overdueTransactions = transactionRepository.findOverdueTransactions(LocalDateTime.now()).size();
        
        logger.info("=== DATA INITIALIZATION SUMMARY ===");
        logger.info("Users created: {}", userCount);
        logger.info("Books created: {}", bookCount);
        logger.info("Transactions created: {}", transactionCount);
        logger.info("Active transactions: {}", activeTransactions);
        logger.info("Overdue transactions: {}", overdueTransactions);
        logger.info("=======================================");
        
        // Log sample login credentials
        logger.info("Sample login credentials:");
        logger.info("Admin: username=admin, password=admin123");
        logger.info("Librarian: username=librarian, password=librarian123");
        logger.info("Regular User: username=alice.smith1, password=user123");
    }
}
