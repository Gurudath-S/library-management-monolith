package com.library.config;

import com.library.service.MetricsService;
import io.micrometer.core.instrument.Timer;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Component;
import org.springframework.web.servlet.HandlerInterceptor;

@Component
public class MetricsInterceptor implements HandlerInterceptor {

    @Autowired
    private MetricsService metricsService;

    private static final String START_TIME_ATTR = "startTime";
    private static final String TIMER_SAMPLE_ATTR = "timerSample";

    @Override
    public boolean preHandle(HttpServletRequest request, HttpServletResponse response, Object handler) {
        // Record start time and increment active requests
        long startTime = System.currentTimeMillis();
        request.setAttribute(START_TIME_ATTR, startTime);
        
        Timer.Sample timerSample = metricsService.startTimer();
        request.setAttribute(TIMER_SAMPLE_ATTR, timerSample);
        
        metricsService.incrementActiveRequests();
        
        // Log request details for debugging
        String endpoint = request.getRequestURI();
        String method = request.getMethod();
        
        System.out.println("Processing " + method + " request to " + endpoint + " at " + startTime);
        
        return true;
    }

    @Override
    public void afterCompletion(HttpServletRequest request, HttpServletResponse response, 
                               Object handler, Exception ex) {
        
        // Calculate request duration
        Long startTime = (Long) request.getAttribute(START_TIME_ATTR);
        Timer.Sample timerSample = (Timer.Sample) request.getAttribute(TIMER_SAMPLE_ATTR);
        
        if (startTime != null) {
            long duration = System.currentTimeMillis() - startTime;
            
            // Record metrics
            metricsService.decrementActiveRequests();
            
            if (timerSample != null) {
                timerSample.stop(Timer.builder("library.http.requests")
                    .description("HTTP request duration")
                    .tag("method", request.getMethod())
                    .tag("endpoint", getEndpointPattern(request.getRequestURI()))
                    .tag("status", String.valueOf(response.getStatus()))
                    .register(metricsService.getMeterRegistry()));
            }
            
            // Record error if status indicates error
            if (response.getStatus() >= 400) {
                metricsService.incrementErrorCount();
            }
            
            // Log completion
            System.out.println("Completed " + request.getMethod() + " " + 
                             request.getRequestURI() + " in " + duration + "ms with status " + 
                             response.getStatus());
        }
        
        // Record exception if present
        if (ex != null) {
            metricsService.incrementErrorCount();
            System.err.println("Exception in request processing: " + ex.getMessage());
        }
    }
    
    private String getEndpointPattern(String uri) {
        // Normalize URI patterns for better grouping in metrics
        if (uri.startsWith("/api/auth/")) return "/api/auth/**";
        if (uri.startsWith("/api/users/") && uri.matches(".*/\\d+.*")) return "/api/users/{id}/**";
        if (uri.startsWith("/api/books/") && uri.matches(".*/\\d+.*")) return "/api/books/{id}/**";
        if (uri.startsWith("/api/transactions/") && uri.matches(".*/\\d+.*")) return "/api/transactions/{id}/**";
        if (uri.startsWith("/api/books/")) return "/api/books/**";
        if (uri.startsWith("/api/users/")) return "/api/users/**";
        if (uri.startsWith("/api/transactions/")) return "/api/transactions/**";
        return uri;
    }
}
