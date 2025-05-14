#!/bin/bash
set -e

# Check required environment variables
if [ -z "$FRITZBOX_USER" ] || [ -z "$FRITZBOX_PASSWORD" ]; then
    echo "Error: FRITZBOX_USER and FRITZBOX_PASSWORD must be set"
    exit 1
fi

# Start cron daemon
service cron start

# Start Apache in foreground
apachectl -D FOREGROUND