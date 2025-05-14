# Internet Access Control for Fritz!Box

Simple utility to control internet access for specific IP addresses on your Fritz!Box router. Features both a REST API (via Apache CGI) and scheduled control (via cron).

## Features

- REST API to enable/disable internet access
- Automatic enable at 5:00 AM via cron
- IP address validation
- Secure credential handling
- Detailed logging

## Prerequisites

- Docker and Docker Compose
- Fritz!Box router with remote access enabled
- Fritz!Box user credentials with appropriate permissions

## Quick Start

1. Create your environment file:
```bash
cp .env.sample .env
nano .env  # Edit with your credentials
```

2. Build and start the service:
```bash
docker-compose up -d
```

## Usage

### REST API

The API is available at `http://your-host:8080/api/`

**Enable internet access:**
```bash
curl "http://your-host:8080/api/?ip=192.168.178.50&state=on"
```

**Disable internet access:**
```bash
curl "http://your-host:8080/api/?ip=192.168.178.50&state=off"
```

**Using POST:**
```bash
curl -X POST http://your-host:8080/api/ \
  -H "Content-Type: application/json" \
  -d '{"ip":"192.168.178.50","state":"off"}'
```

### Automatic Schedule

By default, internet access is enabled every morning at 5:00 AM for the configured TARGET_IP.
To modify the schedule, edit `config/crontab` and restart the container:

```bash
docker-compose restart
```

## Configuration

Environment variables in `.env`:

- `FRITZBOX_USER`: Your Fritz!Box username (required)
- `FRITZBOX_PASSWORD`: Your Fritz!Box password (required)
- `TARGET_IP`: Default IP for cron jobs (default: 192.168.178.50)
- `FRITZBOX_IP`: Fritz!Box IP address (default: 192.168.178.1)
- `FRITZBOX_PORT`: Fritz!Box port (default: 49000)
- `TZ`: Timezone for cron jobs (default: Europe/Berlin)

## API Response Format

Successful response:
```json
{
  "status": "success",
  "message": "Internet access for 192.168.178.50 set to on"
}
```

Error response:
```json
{
  "status": "error",
  "message": "Invalid IP address format"
}
```

## Logs

- Apache access logs: `logs/apache/access.log`
- Apache error logs: `logs/apache/error.log`
- Script execution logs: `logs/internet-control.log`

## Security Notes

- Use HTTPS if exposing the API to the internet
- Consider implementing authentication for the API
- Never commit the `.env` file
- Credentials are stored as environment variables

## Troubleshooting

1. **API returns 500 error**
   - Check Apache error logs
   - Verify Fritz!Box credentials
   - Ensure Fritz!Box is accessible

2. **Cron job not running**
   - Check container logs: `docker-compose logs`
   - Verify timezone settings
   - Check cron service status inside container

## License

MIT License