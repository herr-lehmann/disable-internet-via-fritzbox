# disable-internet-via-fritzbox

Control internet access of clients connected to your Fritz!Box.

## Features

- REST API to enable/disable internet access for specific IPs
- Automatic enable at 5:00 AM via cron
- Docker-based deployment
- Detailed logging
- Simple API without authentication

## Prerequisites

- Fritz!Box router
- Docker and Docker Compose
- Fritz!Box user with appropriate permissions

## Installation

1. Clone the repository:
```bash
git clone https://github.com/yourusername/disable-internet-via-fritzbox.git
cd disable-internet-via-fritzbox
```

2. Create and edit environment file:
```bash
cp .env.sample .env
nano .env
```

Required environment variables:
```
FRITZBOX_USER=your_fritzbox_username
FRITZBOX_PASSWORD=your_fritzbox_password
```

3. Start the service:
```bash
docker-compose up -d
```

## Usage

Enable internet access:
```bash
curl "http://your-host:8080/api/?ip=192.168.178.50&state=on"
```

Disable internet access:
```bash
curl "http://your-host:8080/api/?ip=192.168.178.50&state=off"
```

Using POST:
```bash
curl -X POST \
     -H "Content-Type: application/json" \
     -d '{"ip":"192.168.178.50","state":"off"}' \
     http://your-host:8080/api/
```

## Deployment

Deploy to Raspberry Pi:
```bash
./deploy.sh pi raspberry.local
```

## API Reference

### GET /api/
Enable/disable internet access

Parameters:
- `ip`: Target IP address
- `state`: Either "on" or "off"

### POST /api/
Same functionality as GET but accepts JSON body:
```json
{
  "ip": "192.168.178.50",
  "state": "off"
}
```

## Logs

Logs are stored in `logs/internet-control.log`

## Apple Shortcuts

To control internet access via your iOS device:

1. Available shortcuts in `shortcuts/`:
   - `enable.shortcut`: Enables internet access for a device
   - `disable.shortcut`: Disables internet access for a device

3. To import and configure a shortcut:
   - Download the .shortcut file to your iOS device
   - Tap the file
   - Choose "Add Shortcut"
   - Configure:
     - IP address of the device to control
     - Host address of your container (e.g. http://192.168.178.19:8080)

4. Apply your settings to the shortcuts
  - Adjust the called url with the IP adresses of your devices


## License

MIT
