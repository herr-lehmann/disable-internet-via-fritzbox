#!/bin/bash

# Function to log messages
log_message() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" >> /app/logs/internet-control.log
}

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

# Function to handle the Fritz!Box command
handle_internet_access() {
    local target_ip=$1
    local requested_state=$2

    log_message "Attempting to set internet access for IP $target_ip to: $requested_state"

    # Validate IP address
    if ! validate_ip "$target_ip"; then
        log_message "Error: Invalid IP address: $target_ip"
        echo "Error: Invalid IP address format"
        return 1
    fi

    # Validate and set state
    local state
    if [ "$requested_state" == "on" ]; then
        state="0"
    elif [ "$requested_state" == "off" ]; then
        state="1"
    else
        log_message "Error: Invalid state requested: $requested_state"
        echo "Invalid state. Use 'on' or 'off'"
        return 1
    fi

    # Configuration variables
    FRITZBOX_IP="192.168.178.1"
    FRITZBOX_PORT="49000"

    # Check if credentials are set
    if [ -z "$FRITZBOX_USER" ] || [ -z "$FRITZBOX_PASSWORD" ]; then
        log_message "Error: Missing credentials"
        echo "Error: FRITZBOX_USER and FRITZBOX_PASSWORD environment variables must be set"
        return 1
    fi

    # XML payload template
    XML_PAYLOAD="<?xml version='1.0' encoding='utf-8'?>
<s:Envelope s:encodingStyle='http://schemas.xmlsoap.org/soap/encoding/' xmlns:s='http://schemas.xmlsoap.org/soap/envelope/'>
  <s:Body>
    <u:DisallowWANAccessByIP xmlns:u='urn:dslforum-org:service:X_AVM-DE_HostFilter:1'>
      <u:NewIPv4Address>$target_ip</u:NewIPv4Address>
      <u:NewDisallow>$state</u:NewDisallow>
    </u:DisallowWANAccessByIP>
  </s:Body>
</s:Envelope>"

    # Execute curl command
    local RESULT
    RESULT=$(curl -s -k -m 5 \
        --anyauth \
        -u "$FRITZBOX_USER:$FRITZBOX_PASSWORD" \
        "http://$FRITZBOX_IP:$FRITZBOX_PORT/upnp/control/x_hostfilter" \
        -H 'Content-Type: text/xml; charset="utf-8"' \
        -H "SoapAction:urn:dslforum-org:service:X_AVM-DE_HostFilter:1#DisallowWANAccessByIP" \
        -d "$XML_PAYLOAD" 2>&1)

    if [ $? -eq 0 ]; then
        log_message "Success: Internet access for IP $target_ip set to $requested_state"
        echo "Success: Internet access for IP $target_ip set to $requested_state"
        return 0
    else
        log_message "Error: Failed to set internet access. Details: $RESULT"
        echo "Error: Failed to set internet access. Details: $RESULT"
        return 1
    fi
}

# Show usage if not enough arguments
if [ $# -ne 2 ]; then
    echo "Usage: $0 <ip_address> [on|off]"
    echo "Example: $0 192.168.178.50 off"
    exit 1
fi

handle_internet_access "$1" "$2"
exit $?