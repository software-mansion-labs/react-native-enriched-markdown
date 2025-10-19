#!/bin/bash

# MD4C Test Script
# This script compiles and runs the MD4C integration test for both iOS and Android

set -e  # Exit on any error

echo "🧪 Running MD4C Integration Tests"
echo "================================="

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Test results
TESTS_PASSED=0
TESTS_FAILED=0

# Function to run a test and track results
run_test() {
    local test_name="$1"
    local test_command="$2"
    
    echo -e "${BLUE}Running: ${test_name}${NC}"
    echo "Command: ${test_command}"
    echo ""
    
    if eval "$test_command"; then
        echo -e "${GREEN}✅ ${test_name} PASSED${NC}"
        ((TESTS_PASSED++))
    else
        echo -e "${RED}❌ ${test_name} FAILED${NC}"
        ((TESTS_FAILED++))
    fi
    echo ""
}

# Test Shared MD4C
echo "🔗 Testing Shared MD4C Integration"
echo "==================================="
cd "$(dirname "$0")/../shared"

# Check if MD4C submodule is initialized
if [ ! -d "MD4C/src" ]; then
    echo "❌ Shared MD4C submodule not found. Please run:"
    echo "   git submodule update --init --recursive"
    exit 1
fi

# Test Shared MD4C
run_test "Shared MD4C Compilation" "make clean && make test_md4c"
run_test "Shared MD4C Execution" "./test_md4c && make clean"

# Test Platform Integration
echo ""
echo "🔗 Testing Platform Integration"
echo "==============================="

# Test iOS integration (podspec references)
if [ -f "../RichText.podspec" ] && grep -q "shared/MD4C/src" "../RichText.podspec"; then
    echo "✅ iOS podspec correctly references shared/MD4C"
    ((TESTS_PASSED++))
else
    echo "❌ iOS podspec not configured for shared/MD4C"
    echo "   Expected: podspec to reference shared/MD4C/src"
    ((TESTS_FAILED++))
fi


# Summary
echo ""
echo "====================================="
echo "📊 Test Summary"
echo "====================================="
echo -e "${GREEN}✅ Tests Passed: ${TESTS_PASSED}${NC}"
echo -e "${RED}❌ Tests Failed: ${TESTS_FAILED}${NC}"

if [ $TESTS_FAILED -eq 0 ]; then
    echo -e "${GREEN}🎉 All MD4C tests passed!${NC}"
    exit 0
else
    echo -e "${RED}💥 Some MD4C tests failed!${NC}"
    exit 1
fi
