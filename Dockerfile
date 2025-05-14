FROM debian:bullseye-slim

# Install required packages
RUN apt-get update && apt-get install -y \
    apache2 \
    bash \
    curl \
    cron \
    tzdata \
    dos2unix \
    && rm -rf /var/lib/apt/lists/*

# Enable Apache modules
RUN a2enmod cgi headers

# Create app directory and logs directory
WORKDIR /app
RUN mkdir -p /app/logs /app/cgi-bin

# Copy script and configuration
COPY disable-internet.sh /app/
COPY cgi-bin/internet-control.cgi /app/cgi-bin/
COPY config/apache.conf /etc/apache2/conf-available/internet-control.conf
COPY config/crontab /etc/cron.d/internet-control
RUN chmod +x /app/disable-internet.sh /app/cgi-bin/internet-control.cgi

# Enable our Apache configuration
RUN a2enconf internet-control

# Set environment variables for Fritz!Box credentials
ENV FRITZBOX_USER=""
ENV FRITZBOX_PASSWORD=""

# Copy and set up entrypoint script
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh && \
    dos2unix /entrypoint.sh

# Expose web port
EXPOSE 80

# Add healthcheck
HEALTHCHECK --interval=5m --timeout=3s \
    CMD curl -f http://localhost/api/ || exit 1

ENTRYPOINT ["/entrypoint.sh"]