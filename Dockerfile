FROM python:3.12-slim

RUN apt-get update && apt-get install -y curl cron gettext-base && \
    rm -rf /var/lib/apt/lists/*

WORKDIR /app

RUN pip install --no-cache-dir fastapi uvicorn httpx

COPY main.py .
COPY config/crontab /app/crontab.template

EXPOSE 8000

CMD envsubst < /app/crontab.template > /etc/cron.d/internet-control && \
    chmod 0644 /etc/cron.d/internet-control && \
    crontab /etc/cron.d/internet-control && \
    service cron start && \
    uvicorn main:app --host 0.0.0.0 --port 8000
