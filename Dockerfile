FROM debian:bullseye-slim

# Install and configure
RUN apt-get update && apt-get install -y apache2 curl cron && \
    rm -rf /var/lib/apt/lists/* && \
    a2enmod cgi headers && \
    mkdir -p /app/logs /app/cgi-bin && \
    chown -R www-data:www-data /app

# Copy files and set permissions
COPY disable-internet.sh /app/
COPY cgi-bin/internet-control.cgi /app/cgi-bin/
COPY config/apache.conf /etc/apache2/conf-available/internet-control.conf
COPY config/crontab /etc/cron.d/internet-control

# Configure permissions and services
RUN chmod 755 /app/disable-internet.sh /app/cgi-bin/internet-control.cgi && \
    chown -R www-data:www-data /app && \
    chmod 755 /app/cgi-bin && \
    chmod 0644 /etc/cron.d/internet-control && \
    crontab /etc/cron.d/internet-control && \
    a2enconf internet-control && \
    echo "ServerName localhost" >> /etc/apache2/apache2.conf

# Expose web port
EXPOSE 80

# Start services
CMD service cron start && apache2ctl -D FOREGROUND
