#!/bin/bash

# driver.sh - Test Jekyll plugin-related Nugem options interactively

set -e

# Function to test a Jekyll plugin option
test_jekyll_option() {
    local option_name="$1"
    local option_flag="$2"

    echo ""
    echo "=== Testing Jekyll plugin option: $option_name ==="
    echo ""

    # Clean up any previous test
    echo "Cleaning up previous test..."
    if [ -d "/tmp/nugem_test" ]; then
        rm -rf /tmp/nugem_test
    fi

    # Run the nugem command with the option
    echo "Running nugem jekyll test_plugin command with $option_name option..."
    echo "Command: nugem jekyll test_plugin -o /tmp/nugem_test $option_flag"
    echo ""

    # Run the nugem command - user needs to interact with this
    # Use unbuffer to create a pseudo-terminal for proper stdin/stdout handling
    nugem jekyll test_plugin -o /tmp/nugem_test "$option_flag"

    # Verify the generated project
    echo ""
    echo "Verifying generated project in /tmp/nugem_test..."
    echo ""

    # Change to the generated project directory
    cd /tmp/nugem_test

    # Step 1: Run bin/setup
    echo "Step 1: Running bin/setup..."
    if [ -f "bin/setup" ]; then
        bin/setup
    else
        echo "Warning: bin/setup not found"
    fi

    # Step 2: Run unit tests
    echo ""
    echo "Step 2: Running unit tests (binstub/rspec)..."
    if [ -f "binstub/rspec" ]; then
        binstub/rspec
    elif [ -f "bin/rspec" ]; then
        bin/rspec
    else
        echo "Warning: rspec test runner not found"
    fi

    # Check if tests passed (non-zero exit means failure)
    if [ $? -ne 0 ]; then
        echo ""
        echo "ERROR: Unit tests failed. Halting."
        read -p "Press Enter to continue after reviewing failures..."
        return 1
    fi

    # Step 3: Run the demo Jekyll server
    echo ""
    echo "Step 3: Launching demo Jekyll server in demo/ directory..."
    if [ -d "demo" ]; then
        cd demo

        # Start Jekyll server in background
        echo "Starting Jekyll server..."
        bundle exec jekyll serve --host 0.0.0.0 --port 4000 > /tmp/jekyll_server.log 2>&1 &
        JEKYLL_PID=$!
        echo "Jekyll server PID: $JEKYLL_PID"
        echo "Server running at http://localhost:4000"

        # Wait a moment for server to start
        sleep 3

        echo ""
        echo "Please inspect the test website at http://localhost:4000"
        echo "Press Enter when you are done inspecting the website..."
        read -p ""

        # Return to the main project directory
        cd ..

        # Kill the Jekyll server
        echo "Stopping demo Jekyll server..."
        kill $JEKYLL_PID 2>/dev/null || true
        wait $JEKYLL_PID 2>/dev/null || true
    else
        echo "Warning: demo/ directory not found"
    fi

    # Step 4: Launch Visual Studio Code
    echo ""
    echo "Step 4: Launching Visual Studio Code in the project..."
    if command -v code &> /dev/null; then
        echo "Opening /tmp/nugem_test in Visual Studio Code..."
        code /tmp/nugem_test
        echo ""
        echo "Please inspect the generated code in Visual Studio Code."
        echo "Press Enter when you are done inspecting the code..."
        read -p ""
    else
        echo "Warning: Visual Studio Code 'code' command not found"
    fi

    # Step 5: Ask user if they want to make changes
    echo ""
    echo "Do you want to make changes to nugem?"
    echo "If yes, you can now modify the nugem code."
    echo "When you are done making changes and are ready to test again,"
    echo "run cleanup.sh and then rerun this script."
    echo ""
    read -p "Are you done with this option? (yes/no): " done_answer

    if [ "$done_answer" != "yes" ]; then
        echo ""
        echo "Please make your changes now."
        echo "When you are ready to continue, run cleanup.sh and then run driver.sh again."
        read -p "Press Enter when you are ready to continue..."
    fi

    echo ""
    echo "Moving to next Jekyll plugin option..."
    return 0
}

# Main execution
echo "=== Jekyll Plugin Options Driver Script ==="
echo ""
echo "This script will test each Jekyll plugin-related Nugem option:"
echo "  1. --block"
echo "  2. --blockn"
echo "  3. --filter"
echo "  4. --hooks"
echo "  5. --tag"
echo "  6. --tagn"
echo ""
echo "For each option, the script will:"
echo "  - Run the nugem command with the option"
echo "  - Allow user interaction with the command"
echo "  - Verify the generated project (setup, tests, demo, VS Code)"
echo "  - Allow user to make changes to nugem"
echo ""

# Check if nugem command exists, and install if needed
if ! command -v nugem &> /dev/null; then
    echo ""
    echo "Installing nugem gem..."
    echo ""

    # Check if we're in the nugem project directory
    if [ ! -f "Rakefile" ]; then
        echo "Error: Rakefile not found. Please run this script from the nugem project directory."
        exit 1
    fi

    # Run rake install to install the nugem gem
    echo "Running: rake install"
    rake install

    if [ $? -ne 0 ]; then
        echo "Error: Failed to install nugem gem."
        exit 1
    fi

    echo ""
    echo "nugem gem installed successfully!"
    echo ""
fi

echo "nugem command is available."
echo ""
read -p "Press Enter to start testing..."

# Test each Jekyll plugin option
test_jekyll_option "block" "--block test"
test_jekyll_option "blockn" "--blockn test"
test_jekyll_option "filter" "--filter test"
test_jekyll_option "hooks" "--hooks"
test_jekyll_option "tag" "--tag test"
test_jekyll_option "tagn" "--tagn test"

echo ""
echo "All Jekyll plugin options have been tested!"
echo ""
echo "You have completed testing all Jekyll plugin-related Nugem options."
echo "Run cleanup.sh to clean up the test environment if needed."
