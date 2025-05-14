#!/bin/bash

# Set CGI headers
echo "Content-Type: application/json"
echo "Access-Control-Allow-Origin: *"
echo "Access-Control-Allow-Methods: GET, POST, OPTIONS"
echo "Access-Control-Allow-Headers: Content-Type, X-Api-Key"
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
    local status_code=$1
    local message=$2
    echo "Status: $status_code"
    echo "{\"status\":\"error\",\"message\":\"$message\"}"
    exit 1
}

# Validate API key
API_KEY_HEADER="HTTP_X_API_KEY"
VALID_API_KEY=${API_KEY:-"default_key_replace_me"}

if [ -z "${!API_KEY_HEADER}" ]; then
    send_error 401 "API key is missing"
fi

if [ "${!API_KEY_HEADER}" != "$VALID_API_KEY" ]; then
    send_error 403 "Invalid API key"
fi

# Parse query string for GET requests
if [ "$REQUEST_METHOD" = "GET" ]; then
    # Extract parameters from QUERY_STRING
    eval $(echo "$QUERY_STRING" | tr '&' '\n' | sed 's/\([^=]*\)=\([^=]*\)/\1="\2"/')
    
    # Validate parameters
    if [ -z "$ip" ]; then
        send_error 400 "IP parameter is required"
    fi
    
    if [ -z "$state" ]; then
        send_error 400 "State parameter is required"
    fi
    
    if ! validate_ip "$ip"; then
        send_error 400 "Invalid IP address format"
    fi
    
    if [ "$state" != "on" ] && [ "$state" != "off" ]; then
        send_error 400 "State must be 'on' or 'off'"
    fi

# Parse JSON for POST requests
elif [ "$REQUEST_METHOD" = "POST" ]; then
    # Read POST data
    read -n "$CONTENT_LENGTH" POST_DATA

    # Extract parameters from JSON (basic parsing)
    ip=$(echo "$POST_DATA" | grep -o '"ip":"[^"]*' | cut -d'"' -f4)
    state=$(echo "$POST_DATA" | grep -o '"state":"[^"]*' | cut -d'"' -f4)

    # Validate parameters
    if [ -z "$ip" ]; then
        send_error 400 "IP parameter is required"
    fi
    
    if [ -z "$state" ]; then
        send_error 400 "State parameter is required"
    fi
    
    if ! validate_ip "$ip"; then
        send_error 400 "Invalid IP address format"
    fi
    
    if [ "$state" != "on" ] && [ "$state" != "off" ]; then
        send_error 400 "State must be 'on' or 'off'"
    fi
else
    send_error 405 "Unsupported HTTP method"
fi

# Log the request
echo "[$(date '+%Y-%m-%d %H:%M:%S')] API request: IP=$ip, State=$state" >> /app/logs/api.log

# Execute the control script
result=$(/app/disable-internet.sh "$ip" "$state" 2>&1)
exit_code=$?

if [ $exit_code -eq 0 ]; then
    echo "{\"status\":\"success\",\"message\":\"Internet access for $ip set to $state\"}"
else
    send_error 500 "Failed to set internet access: $result"
fi