package com.library.controller;

import com.library.dto.BookDto;
import com.library.entity.Book;
import com.library.service.BookService;
import com.opencsv.exceptions.CsvException;
import jakarta.validation.Valid;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.multipart.MultipartFile;

import java.io.IOException;
import java.util.List;

@RestController
@RequestMapping("/api/books")
@CrossOrigin(origins = "*")
public class BookController {
    
    @Autowired
    private BookService bookService;
    
    @GetMapping
    public ResponseEntity<List<Book>> getAllBooks() {
        List<Book> books = bookService.findAllBooks();
        return ResponseEntity.ok(books);
    }
    
    @GetMapping("/available")
    public ResponseEntity<List<Book>> getAvailableBooks() {
        List<Book> books = bookService.findAvailableBooks();
        return ResponseEntity.ok(books);
    }
    
    @GetMapping("/search")
    public ResponseEntity<List<Book>> searchBooks(@RequestParam String searchTerm) {
        List<Book> books = bookService.searchBooks(searchTerm);
        return ResponseEntity.ok(books);
    }
    
    @GetMapping("/category/{category}")
    public ResponseEntity<List<Book>> getBooksByCategory(@PathVariable String category) {
        List<Book> books = bookService.findBooksByCategory(category);
        return ResponseEntity.ok(books);
    }
    
    @GetMapping("/author/{author}")
    public ResponseEntity<List<Book>> getBooksByAuthor(@PathVariable String author) {
        List<Book> books = bookService.findBooksByAuthor(author);
        return ResponseEntity.ok(books);
    }
    
    @GetMapping("/categories")
    public ResponseEntity<List<String>> getAllCategories() {
        List<String> categories = bookService.getAllCategories();
        return ResponseEntity.ok(categories);
    }
    
    @GetMapping("/authors")
    public ResponseEntity<List<String>> getAllAuthors() {
        List<String> authors = bookService.getAllAuthors();
        return ResponseEntity.ok(authors);
    }
    
    @GetMapping("/publishers")
    public ResponseEntity<List<String>> getAllPublishers() {
        List<String> publishers = bookService.getAllPublishers();
        return ResponseEntity.ok(publishers);
    }
    
    @GetMapping("/{id}")
    public ResponseEntity<Book> getBookById(@PathVariable Long id) {
        return bookService.findById(id)
                .map(book -> ResponseEntity.ok().body(book))
                .orElse(ResponseEntity.notFound().build());
    }
    
    @GetMapping("/isbn/{isbn}")
    public ResponseEntity<Book> getBookByIsbn(@PathVariable String isbn) {
        return bookService.findByIsbn(isbn)
                .map(book -> ResponseEntity.ok().body(book))
                .orElse(ResponseEntity.notFound().build());
    }
    
    @PostMapping
    @PreAuthorize("hasRole('ADMIN') or hasRole('LIBRARIAN')")
    public ResponseEntity<?> createBook(@Valid @RequestBody BookDto bookDto) {
        try {
            Book book = bookService.createBook(bookDto);
            return ResponseEntity.ok(book);
        } catch (RuntimeException e) {
            return ResponseEntity.badRequest().body(e.getMessage());
        }
    }
    
    @PostMapping("/upload")
    @PreAuthorize("hasRole('ADMIN') or hasRole('LIBRARIAN')")
    public ResponseEntity<?> uploadBooksFromCsv(@RequestParam("file") MultipartFile file) {
        if (file.isEmpty()) {
            return ResponseEntity.badRequest().body("Please select a CSV file to upload.");
        }
        
        if (!file.getOriginalFilename().toLowerCase().endsWith(".csv")) {
            return ResponseEntity.badRequest().body("Only CSV files are allowed.");
        }
        
        try {
            List<Book> books = bookService.createBooksFromCsv(file);
            return ResponseEntity.ok()
                    .body("Successfully imported " + books.size() + " books from CSV file.");
        } catch (IOException e) {
            return ResponseEntity.badRequest().body("Error reading CSV file: " + e.getMessage());
        } catch (CsvException e) {
            return ResponseEntity.badRequest().body("Error parsing CSV file: " + e.getMessage());
        } catch (Exception e) {
            return ResponseEntity.badRequest().body("Error importing books: " + e.getMessage());
        }
    }
    
    @PutMapping("/{id}")
    @PreAuthorize("hasRole('ADMIN') or hasRole('LIBRARIAN')")
    public ResponseEntity<?> updateBook(@PathVariable Long id, @Valid @RequestBody BookDto bookDto) {
        try {
            Book book = bookService.updateBook(id, bookDto);
            return ResponseEntity.ok(book);
        } catch (RuntimeException e) {
            return ResponseEntity.badRequest().body(e.getMessage());
        }
    }
    
    @PutMapping("/{id}/inventory")
    @PreAuthorize("hasRole('ADMIN') or hasRole('LIBRARIAN')")
    public ResponseEntity<?> updateInventory(@PathVariable Long id, 
                                           @RequestParam Integer totalCopies, 
                                           @RequestParam Integer availableCopies) {
        try {
            Book book = bookService.updateInventory(id, totalCopies, availableCopies);
            return ResponseEntity.ok(book);
        } catch (RuntimeException e) {
            return ResponseEntity.badRequest().body(e.getMessage());
        }
    }
    
    @DeleteMapping("/{id}")
    @PreAuthorize("hasRole('ADMIN')")
    public ResponseEntity<?> deleteBook(@PathVariable Long id) {
        try {
            bookService.deleteBook(id);
            return ResponseEntity.ok().body("Book deleted successfully!");
        } catch (RuntimeException e) {
            return ResponseEntity.badRequest().body(e.getMessage());
        }
    }
    
    @GetMapping("/low-stock")
    @PreAuthorize("hasRole('ADMIN') or hasRole('LIBRARIAN')")
    public ResponseEntity<List<Book>> getLowStockBooks(@RequestParam(defaultValue = "5") Integer threshold) {
        List<Book> books = bookService.getLowStockBooks(threshold);
        return ResponseEntity.ok(books);
    }
    
    @GetMapping("/out-of-stock")
    @PreAuthorize("hasRole('ADMIN') or hasRole('LIBRARIAN')")
    public ResponseEntity<List<Book>> getOutOfStockBooks() {
        List<Book> books = bookService.getOutOfStockBooks();
        return ResponseEntity.ok(books);
    }
}
