#!/bin/bash

# Set CGI headers
echo "Content-Type: application/json"
echo "Access-Control-Allow-Origin: *"
echo "Access-Control-Allow-Methods: GET, POST, OPTIONS"
echo "Access-Control-Allow-Headers: Content-Type"
echo

# Handle OPTIONS request for CORS
if [ "$REQUEST_METHOD" = "OPTIONS" ]; then
    exit 0
fi

# Function to validate IP address
validate_ip() {
    local ip=$1
    if [[ $ip =~ ^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$ ]]; then
        for octet in $(echo "$ip" | tr '.' ' '); do
            if [[ $octet -lt 0 || $octet -gt 255 ]]; then
                return 1
            fi
        done
        return 0
    else
        return 1
    fi
}

# Function to return JSON error
send_error() {
    echo "{\"status\":\"error\",\"message\":\"$1\"}"
    exit 1
}

# Parse query string for GET requests
if [ "$REQUEST_METHOD" = "GET" ]; then
    # Extract parameters from QUERY_STRING
    eval $(echo "$QUERY_STRING" | tr '&' '\n' | sed 's/\([^=]*\)=\([^=]*\)/\1="\2"/')
    
    # Validate parameters
    if [ -z "$ip" ]; then
        send_error "IP parameter is required"
    fi
    
    if [ -z "$state" ]; then
        send_error "State parameter is required"
    fi
    
    if ! validate_ip "$ip"; then
        send_error "Invalid IP address format"
    fi
    
    if [ "$state" != "on" ] && [ "$state" != "off" ]; then
        send_error "State must be 'on' or 'off'"
    fi

# Parse JSON for POST requests
elif [ "$REQUEST_METHOD" = "POST" ]; then
    # Read POST data
    read -n "$CONTENT_LENGTH" POST_DATA

    # Extract parameters from JSON
    ip=$(echo "$POST_DATA" | grep -o '"ip":"[^"]*' | cut -d'"' -f4)
    state=$(echo "$POST_DATA" | grep -o '"state":"[^"]*' | cut -d'"' -f4)

    # Validate parameters
    if [ -z "$ip" ]; then
        send_error "IP parameter is required"
    fi
    
    if [ -z "$state" ]; then
        send_error "State parameter is required"
    fi
    
    if ! validate_ip "$ip"; then
        send_error "Invalid IP address format"
    fi
    
    if [ "$state" != "on" ] && [ "$state" != "off" ]; then
        send_error "State must be 'on' or 'off'"
    fi
else
    send_error "Unsupported HTTP method"
fi

# Execute the control script
result=$(/app/disable-internet.sh "$ip" "$state" 2>&1)
exit_code=$?

if [ $exit_code -eq 0 ]; then
    echo "{\"status\":\"success\",\"message\":\"Internet access for $ip set to $state\"}"
else
    echo "{\"status\":\"error\",\"message\":\"Failed to set internet access: $result\"}"
fi