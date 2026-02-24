#!/bin/bash


#################################
# API GATEWAY
#################################
pm2 start /home/bousso/Bureau/crud-master/srcs/api-gateway/server.py \
  --name api-gateway \
  --interpreter /home/bousso/Bureau/crud-master/srcs/api-gateway/venv/bin/python3 \
  --cwd /home/bousso/Bureau/crud-master/srcs/api-gateway


#################################
# INVENTORY API
#################################
pm2 start /home/bousso/Bureau/crud-master/srcs/inventory-app/server.py \
  --name inventory-app \
  --interpreter /home/bousso/Bureau/crud-master/srcs/inventory-app/venv/bin/python3 \
  --cwd /home/bousso/Bureau/crud-master/srcs/inventory-app


#################################
# BILLING API (RabbitMQ Consumer)
#################################
pm2 start "/home/bousso/Bureau/crud-master/srcs/billing-app/venv/bin/python3 -m app.consumer" \
  --name billing-app \
  --cwd /home/bousso/Bureau/crud-master/srcs/billing-app
#################################

echo "✅ All services have been started"
pm2 list
