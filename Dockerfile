FROM --platform=linux/arm64 debian:bullseye-slim
FROM debian:bullseye-slim

# Install required packages
RUN apt-get update && apt-get install -y \
    apache2 \
    curl \
    cron \
    && rm -rf /var/lib/apt/lists/*

# Setup Apache and app
RUN a2enmod cgi headers && \
    mkdir -p /app/logs /app/cgi-bin

# Copy files
COPY disable-internet.sh /app/
COPY cgi-bin/internet-control.cgi /app/cgi-bin/
COPY config/apache.conf /etc/apache2/conf-available/internet-control.conf
COPY config/crontab /etc/cron.d/internet-control
COPY entrypoint.sh /entrypoint.sh

# Set permissions and enable config
RUN chmod +x /app/disable-internet.sh /app/cgi-bin/internet-control.cgi /entrypoint.sh && \
    a2enconf internet-control

# Set environment variables
ENV FRITZBOX_USER="" \
    FRITZBOX_PASSWORD=""

EXPOSE 80
ENTRYPOINT ["/bin/sh", "/entrypoint.sh"]