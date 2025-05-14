FROM debian:bullseye-slim

# Install and configure
RUN apt-get update && apt-get install -y apache2 curl cron && \
    rm -rf /var/lib/apt/lists/* && \
    a2enmod cgi headers && \
    mkdir -p /app/logs /app/cgi-bin

# Copy files and set permissions
COPY disable-internet.sh /app/
COPY cgi-bin/internet-control.cgi /app/cgi-bin/
COPY config/apache.conf /etc/apache2/conf-available/internet-control.conf
COPY config/crontab /etc/cron.d/internet-control
RUN chmod +x /app/disable-internet.sh /app/cgi-bin/internet-control.cgi && \
    a2enconf internet-control && \
    service cron start

# Set Fritz!Box credentials
ENV FRITZBOX_USER="" FRITZBOX_PASSWORD=""

EXPOSE 80
CMD service cron start && apache2ctl -D FOREGROUND