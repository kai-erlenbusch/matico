#!/bin/bash

# Generate .env file for Rust Server
echo DB.HOST=${DB_HOST} >> .env
echo DB.PORT=${DB_PORT} >> .env
echo DB.USERNAME=${DB_USERNAME} >> .env
echo DB.NAME=${DB_NAME} >> .env
echo DB.PASSWORD=${DB_PASSWORD} >> .env
echo DATADB.HOST=${DB_HOST} >> .env
echo DATADB.PORT=${DB_PORT} >> .env
echo DATADB.USERNAME=${DB_USERNAME} >> .env
echo DATADB.NAME=${DB_NAME} >> .env
echo DATADB.PASSWORD=${DB_PASSWORD} >> .env
echo SERVER_ADDR=0.0.0.0:8000 >> .env

# Start Nginx
service nginx start

# Start Admin UI
# We use 'next start' directly via PM2 to ensure it runs on port 3000
echo "Starting Admin UI on port 3000..."
cd matico_admin
PORT=3000 pm2 start npm --name admin -- start -- -H 0.0.0.0
cd ..

# Start API Server
echo "Starting Matico Server..."
./matico_server