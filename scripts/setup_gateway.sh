#!/bin/bash
# scripts/setup_gateway.sh
# Sur la VM api-gateway
sudo apt-get update
set -e

echo "🌐 Configuration API Gateway..."

APP_DIR="/home/crudmaster/api-gateway"

echo "📁 Création du répertoire..."
mkdir -p $APP_DIR

echo "📁 Copie du code source..."
cp -r /vagrant/srcs/api-gateway/* $APP_DIR/
chown -R crudmaster:crudmaster $APP_DIR

# Copier le fichier .env S'IL EXISTE
if [ -f "/vagrant/.env" ]; then
    echo "📄 Copie du fichier .env..."
    cp /vagrant/.env $APP_DIR/
else
    # Créer un .env spécifique pour gateway
    echo "📄 Création du fichier .env pour gateway..."
    cat > $APP_DIR/.env << EOF
# Configuration Gateway
# === INVENTORY API ===
INVENTORY_API_URL=http://localhost:5001
RABBITMQ_HOST=192.168.121.80
RABBITMQ_PORT=5672
RABBITMQ_USER=api_user
RABBITMQ_PASS=MonMotDePasseSecure123
RABBITMQ_QUEUE=billing_queue

EOF
fi
echo "🔧 Configuration environnement..."
cd $APP_DIR

# Nettoyage ancien venv
rm -rf venv

# Création environnement virtuel
sudo -u crudmaster python3 -m venv venv

# Installation dépendances Python
sudo -u crudmaster bash -c "
source venv/bin/activate
pip3 install --upgrade pip
pip3 install -r requirements.txt
"

echo "📄 Copie des fichiers de configuration..."
cp /vagrant/config.yaml $APP_DIR/
cp /vagrant/.env $APP_DIR/ 2>/dev/null || echo '.env non trouvé'

echo "⚙️ Configuration PM2..."
npm install -g pm2

echo "🚀 Configuration service systemd..."
cat > /etc/systemd/system/crudmaster-gateway.service << EOF
[Unit]
Description=CRUD Master API Gateway
After=network.target

[Service]
User=crudmaster
WorkingDirectory=$APP_DIR
ExecStart=$APP_DIR/venv/bin/python3 server.py
Restart=always
Environment=PATH=$APP_DIR/venv/bin:/usr/bin:/bin
Environment="INVENTORY_API_URL=http://192.168.121.83:5001"


[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable crudmaster-gateway
systemctl restart crudmaster-gateway

echo "✅ API Gateway prêt sur http://$(hostname -I | awk '{print $1}'):8080"
