# disable-internet-via-fritzbox

Control internet access of clients connected to your Fritz!Box.

## Features

- REST API to enable/disable internet access for specific IPs
- Query current internet access state per IP
- Automatic disable at 5:00 AM via cron (configurable target IP)
- Docker-based deployment

## Prerequisites

- Fritz!Box router with a user that has home network access permissions
- Docker and Docker Compose

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
TARGET_IP=192.168.178.50
```

3. Start the service:
```bash
docker-compose up -d
```

## API Reference

### GET /api/status
Query the current internet access state of a device.

```bash
curl "http://your-host:8080/api/status?ip=192.168.178.50"
```

Response:
```json
{"ip": "192.168.178.50", "state": "on"}
```

`state` is either `"on"` (internet allowed) or `"off"` (internet blocked).

---

### POST /api/
Enable or disable internet access for a device.

```bash
curl -X POST \
     -H "Content-Type: application/json" \
     -d '{"ip":"192.168.178.50","state":"off"}' \
     http://your-host:8080/api/
```

Response:
```json
{"status": "success", "message": "Internet access for 192.168.178.50 set to off"}
```

## Apple Shortcuts

iOS/macOS shortcuts for quick access are available in `shortcuts/`:
- `enable.shortcut` — enables internet access for a device
- `disable.shortcut` — disables internet access for a device

To import and configure a shortcut:
1. Download the `.shortcut` file to your device and tap it to add it
2. Edit the shortcut and update:
   - The IP address of the device to control
   - The host address of your container (e.g. `http://192.168.178.19:8080`)
   - Request method: `POST`
   - Header: `Content-Type: application/json`
   - Body: `{"ip":"192.168.178.50","state":"on"}` (or `"off"`)

## License

MIT
