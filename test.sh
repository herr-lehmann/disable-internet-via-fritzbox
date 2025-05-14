#!/bin/bash

# Colors for output
GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m' # No Color
BLUE='\033[0;34m'

# Function to print section headers
print_header() {
    echo -e "\n${BLUE}=== $1 ===${NC}\n"
}

# Function to check command success
check_result() {
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✓ $1${NC}"
    else
        echo -e "${RED}✗ $1${NC}"
        if [ "$2" = "exit" ]; then
            exit 1
        fi
    fi
}

# Test environment variables
print_header "Checking Environment Variables"

if [ -f .env ]; then
    source .env
    echo -e "${GREEN}✓ Found .env file${NC}"
else
    echo -e "${RED}✗ No .env file found. Creating from template...${NC}"
    cp .env.sample .env
    echo "Please edit .env file with your credentials"
    exit 1
fi

# Check required variables
[ ! -z "$FRITZBOX_USER" ]; check_result "FRITZBOX_USER is set"
[ ! -z "$FRITZBOX_PASSWORD" ]; check_result "FRITZBOX_PASSWORD is set"
[ ! -z "$AUTH_USER" ]; check_result "AUTH_USER is set"
[ ! -z "$AUTH_PASSWORD" ]; check_result "AUTH_PASSWORD is set"

# Build and start containers
print_header "Building and Starting Container"
docker-compose down -v
docker-compose build
check_result "Docker build" "exit"
docker-compose up -d
check_result "Docker compose up" "exit"

# Wait for services to be ready
echo "Waiting for services to start..."
sleep 5

# Test API authentication
print_header "Testing API Authentication"

# Test with wrong credentials
response=$(curl -s -o /dev/null -w "%{http_code}" -u "wrong:wrong" "http://localhost:8080/api/?ip=192.168.178.50&state=on")
if [ "$response" = "401" ]; then
    echo -e "${GREEN}✓ Authentication correctly rejected invalid credentials${NC}"
else
    echo -e "${RED}✗ Authentication failed to reject invalid credentials (got $response)${NC}"
fi

# Test with correct credentials
response=$(curl -s -o /dev/null -w "%{http_code}" -u "$AUTH_USER:$AUTH_PASSWORD" "http://localhost:8080/api/?ip=192.168.178.50&state=on")
if [ "$response" = "200" ]; then
    echo -e "${GREEN}✓ Authentication accepted valid credentials${NC}"
else
    echo -e "${RED}✗ Authentication failed with valid credentials (got $response)${NC}"
fi

# Test API functionality
print_header "Testing API Functionality"

# Test GET request
echo "Testing GET request..."
curl -s -u "$AUTH_USER:$AUTH_PASSWORD" "http://localhost:8080/api/?ip=192.168.178.50&state=on"
echo # New line after curl output
check_result "GET request"

# Test POST request
echo "Testing POST request..."
curl -s -X POST \
     -u "$AUTH_USER:$AUTH_PASSWORD" \
     -H "Content-Type: application/json" \
     -d '{"ip":"192.168.178.50","state":"off"}' \
     http://localhost:8080/api/
echo # New line after curl output
check_result "POST request"

# Test invalid IP
echo "Testing invalid IP validation..."
response=$(curl -s -u "$AUTH_USER:$AUTH_PASSWORD" "http://localhost:8080/api/?ip=invalid&state=on")
if [[ $response == *"Invalid IP address"* ]]; then
    echo -e "${GREEN}✓ IP validation working${NC}"
else
    echo -e "${RED}✗ IP validation failed${NC}"
fi

# Test cron setup
print_header "Testing Cron Setup"
docker-compose exec internet-control ps aux | grep cron
check_result "Cron service running"

# Check logs
print_header "Checking Logs"
if [ -f logs/internet-control.log ]; then
    echo -e "${GREEN}✓ Log file exists${NC}"
    echo "Last 5 log entries:"
    tail -n 5 logs/internet-control.log
else
    echo -e "${RED}✗ Log file not found${NC}"
fi

print_header "Test Summary"
echo "The setup has been tested. Check the output above for any errors."
echo "If all tests passed, your setup is working correctly."
echo "To manually test the API, use:"
echo "curl -u $AUTH_USER:$AUTH_PASSWORD http://localhost:8080/api/?ip=192.168.178.50&state=on"