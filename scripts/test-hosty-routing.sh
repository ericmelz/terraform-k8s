#!/bin/bash
set -e

echo "=== Testing Hosty Host-Based Routing ==="
echo ""

# Set kubeconfig
export KUBECONFIG=/Users/ericmelz/.kube/k3s-tailscale.yaml

# Colors for output
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Test counter
TESTS_PASSED=0
TESTS_FAILED=0

# Function to test a service
test_service() {
    local namespace=$1
    local service=$2
    local expected_host=$3
    local description=$4

    echo "Testing: $description"
    echo "  Namespace: $namespace"
    echo "  Service: $service"
    echo "  Expected host: $expected_host"

    # Port forward in background
    kubectl port-forward -n "$namespace" "svc/$service" 8080:8000 > /dev/null 2>&1 &
    local PID=$!

    # Wait for port forward to be ready
    sleep 2

    # Make request with custom Host header
    local response=$(curl -s -H "Host: $expected_host" http://localhost:8080/ 2>&1)

    # Kill port forward
    kill $PID 2>/dev/null || true
    wait $PID 2>/dev/null || true

    # Parse response
    local actual_host=$(echo "$response" | grep -o '"host":"[^"]*"' | cut -d'"' -f4)

    # Check result
    if [ "$actual_host" == "$expected_host" ]; then
        echo -e "  ${GREEN}✓ PASS${NC} - Response: $response"
        echo ""
        ((TESTS_PASSED++))
        return 0
    else
        echo -e "  ${RED}✗ FAIL${NC} - Expected host '$expected_host', got '$actual_host'"
        echo "  Full response: $response"
        echo ""
        ((TESTS_FAILED++))
        return 1
    fi
}

# Run tests
echo "Starting tests..."
echo ""

test_service "dev-weighter-net" "hosty-dev" "dev.weighter.net" "Dev environment"
test_service "weighter-org" "hosty-prod" "weighter.org" "Production environment (weighter.org)"
test_service "weighter-org" "hosty-prod" "www.weighter.org" "Production environment (www.weighter.org)"

# Test with localhost to verify it responds with whatever host is sent
test_service "dev-weighter-net" "hosty-dev" "localhost:8080" "Dev with localhost header"

# Summary
echo "================================"
echo "Test Summary:"
echo -e "  ${GREEN}Passed: $TESTS_PASSED${NC}"
if [ $TESTS_FAILED -gt 0 ]; then
    echo -e "  ${RED}Failed: $TESTS_FAILED${NC}"
    echo ""
    echo "Some tests failed. This is expected if:"
    echo "  1. The pods are not fully ready yet"
    echo "  2. The services are not configured correctly"
    echo ""
    exit 1
else
    echo -e "  ${GREEN}All tests passed!${NC}"
    echo ""
    echo "Hosty is correctly responding with the Host header from each request."
    exit 0
fi