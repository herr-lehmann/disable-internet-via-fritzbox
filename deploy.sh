#!/bin/bash

# Configuration
RASPI_USER=${1:-"pi"}
RASPI_HOST=${2:-"raspberry"}
REMOTE_PATH="/home/$RASPI_USER/disable-internet"

# Colors for output
GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${GREEN}Deploying to Raspberry Pi...${NC}"

# Ensure we have a .env file
if [ ! -f .env ]; then
    echo -e "${RED}No .env file found. Creating from template...${NC}"
    cp .env.sample .env
    echo "Please edit .env file with your credentials"
    exit 1
fi

# Create deployment directory
ssh $RASPI_USER@$RASPI_HOST "mkdir -p $REMOTE_PATH"

# Copy files
rsync -avz --progress \
    --exclude 'logs/*' \
    --exclude '.git' \
    --exclude '.env' \
    ./ $RASPI_USER@$RASPI_HOST:$REMOTE_PATH/

# Copy .env file separately (if it doesn't exist on remote)
scp .env $RASPI_USER@$RASPI_HOST:$REMOTE_PATH/.env

# Connect to Raspberry Pi and start services
ssh $RASPI_USER@$RASPI_HOST "cd $REMOTE_PATH && docker-compose down && docker-compose up -d"

echo -e "${GREEN}Deployment complete!${NC}"
echo "You can now access the API at http://$RASPI_HOST:8080/api/"