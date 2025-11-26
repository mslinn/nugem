#!/bin/bash

# cleanup.sh - Clean up test environment

echo "=========================================="
echo "Cleanup Script"
echo "=========================================="
echo ""

# Step 1: Stop the demo Jekyll server if it is running
echo "Step 1: Stopping demo Jekyll server if running..."

# Check if Jekyll server is running
if pgrep -f "jekyll serve" > /dev/null; then
    echo "Found Jekyll server process, stopping it..."
    
    # Kill all Jekyll serve processes
    pkill -f "jekyll serve" || true
    
    # Wait for processes to terminate
    sleep 2
    
    # Force kill if still running
    if pgrep -f "jekyll serve" > /dev/null; then
        echo "Force killing Jekyll server processes..."
        pkill -9 -f "jekyll serve" || true
    fi
    
    echo "Jekyll server stopped."
else
    echo "No Jekyll server process found."
fi

# Step 2: Delete the generated project in /tmp/nugem_test/
echo ""
echo "Step 2: Deleting generated project in /tmp/nugem_test/..."

if [ -d "/tmp/nugem_test" ]; then
    echo "Removing /tmp/nugem_test directory..."
    rm -rf /tmp/nugem_test
    echo "Deleted /tmp/nugem_test directory."
else
    echo "Directory /tmp/nugem_test does not exist."
fi

# Clean up Jekyll server log if it exists
if [ -f "/tmp/jekyll_server.log" ]; then
    echo "Removing Jekyll server log file..."
    rm -f /tmp/jekyll_server.log
fi

echo ""
echo "=========================================="
echo "Cleanup completed!"
echo "=========================================="
