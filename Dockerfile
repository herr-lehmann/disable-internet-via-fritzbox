FROM debian:bullseye-slim

# Install required packages
RUN apt-get update && apt-get install -y \
    apache2 \
    bash \
    curl \
    cron \
    tzdata \
    apache2-utils \
    && rm -rf /var/lib/apt/lists/*

# Enable Apache modules
RUN a2enmod cgi headers auth_basic authn_file authz_user

# Create app directory and logs directory
WORKDIR /app
RUN mkdir -p /app/logs /app/cgi-bin

# Copy script and configuration
COPY disable-internet.sh /app/
COPY cgi-bin/internet-control.cgi /app/cgi-bin/
COPY config/apache.conf /etc/apache2/conf-available/internet-control.conf
COPY config/crontab /etc/cron.d/internet-control

# Set up Basic Auth
RUN htpasswd -bc /app/config/.htpasswd ${AUTH_USER:-admin} ${AUTH_PASSWORD:-admin}
RUN chmod 644 /app/config/.htpasswd

# Set permissions
RUN chmod +x /app/disable-internet.sh /app/cgi-bin/internet-control.cgi

# Enable our Apache configuration
RUN a2enconf internet-control

# Set environment variables for Fritz!Box credentials
ENV FRITZBOX_USER=""
ENV FRITZBOX_PASSWORD=""

# Create entrypoint script
RUN echo -e '#!/bin/bash\n\
if [ -z "$FRITZBOX_USER" ] || [ -z "$FRITZBOX_PASSWORD" ]; then\n\
    echo "Error: FRITZBOX_USER and FRITZBOX_PASSWORD must be set"\n\
    exit 1\n\
fi\n\
\n\
# Start cron daemon\n\
service cron start\n\
\n\
# Start Apache in foreground\n\
apachectl -D FOREGROUND' > /entrypoint.sh && \
    chmod +x /entrypoint.sh

# Expose web port
EXPOSE 80

# Add healthcheck
HEALTHCHECK --interval=5m --timeout=3s \
    CMD curl -f http://localhost/api/ || exit 1

ENTRYPOINT ["/entrypoint.sh"]