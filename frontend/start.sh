#!/bin/bash

# Library Management System - Frontend Development Server
# This script starts a simple HTTP server to serve the frontend files

PORT=3000
FRONTEND_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "==============================================="
echo "  Library Management System - Frontend"
echo "==============================================="
echo ""
echo "Starting development server..."
echo "Frontend directory: $FRONTEND_DIR"
echo "Server port: $PORT"
echo ""

# Check if Python is available
if command -v python3 &> /dev/null; then
    echo "Using Python 3 HTTP server"
    cd "$FRONTEND_DIR"
    python3 -m http.server $PORT
elif command -v python &> /dev/null; then
    echo "Using Python HTTP server"
    cd "$FRONTEND_DIR"
    python -m http.server $PORT
elif command -v node &> /dev/null && command -v npx &> /dev/null; then
    echo "Using Node.js HTTP server"
    cd "$FRONTEND_DIR"
    npx http-server -p $PORT -c-1
else
    echo "Error: No suitable HTTP server found."
    echo "Please install one of the following:"
    echo "  - Python 3: python3 -m http.server"
    echo "  - Python 2: python -m SimpleHTTPServer"
    echo "  - Node.js: npm install -g http-server"
    exit 1
fi
