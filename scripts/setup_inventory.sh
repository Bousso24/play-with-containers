#!/bin/bash
# scripts/setup_inventory.sh

echo "🎬 Configuration Inventory API..."

# Installation PostgreSQL
echo "🗄️ Installation PostgreSQL..."
apt-get update
apt-get install -y postgresql postgresql-contrib python3-pip python3-venv

# Démarrer PostgreSQL
systemctl start postgresql
systemctl enable postgresql

# Attendre que PostgreSQL soit prêt
sleep 5

# Configuration PostgreSQL
echo "🔧 Configuration base de données..."
sudo -u postgres psql -c "CREATE DATABASE movies_db;" 2>/dev/null || echo "Database movies_db existe déjà"
sudo -u postgres psql -c "ALTER USER postgres WITH PASSWORD 'postgres123';"
sudo -u postgres psql -c "GRANT ALL PRIVILEGES ON DATABASE movies_db TO postgres;"

# Créer le répertoire de l'application
APP_DIR="/home/crudmaster/inventory-app"
mkdir -p $APP_DIR

# Copier le code source
echo "📁 Copie du code source..."
cp -r /vagrant/srcs/inventory-app/* $APP_DIR/

# Copier le fichier .env S'IL EXISTE
if [ -f "/vagrant/.env" ]; then
    echo "📄 Copie du fichier .env..."
    cp /vagrant/.env $APP_DIR/
else
    # Créer un .env spécifique pour inventory
    echo "📄 Création du fichier .env pour inventory..."
    cat > $APP_DIR/.env << EOF
# Configuration Inventory
POSTGRES_USER=postgres
POSTGRES_PASSWORD=postgres123
POSTGRES_HOST=localhost
INVENTORY_DB_NAME=movies_db
INVENTORY_PORT=5432
INVENTORY_DATABASE_URL=postgresql://postgres:postgres123@localhost:5432/movies_db
EOF
fi

# Définir les permissions
chown -R crudmaster:crudmaster $APP_DIR

# Configuration de l'environnement
echo "🔧 Configuration environnement..."
cd $APP_DIR

# Créer environnement virtuel
sudo -u crudmaster python3 -m venv venv

# Installer les dépendances
sudo -u crudmaster bash -c "
source $APP_DIR/venv/bin/activate
pip3 install --upgrade pip
pip3 install -r requirements.txt
"

# Service systemd CORRIGÉ
echo "🚀 Configuration service systemd..."
cat > /etc/systemd/system/crudmaster-inventory.service << EOF
[Unit]
Description=CRUD Master Inventory API
After=network.target postgresql.service

[Service]
Type=simple
User=crudmaster
Group=crudmaster
WorkingDirectory=$APP_DIR
Environment="PATH=$APP_DIR/venv/bin"
Environment="INVENTORY_DATABASE_URL=postgresql://postgres:postgres123@localhost:5432/movies_db"
ExecStart=$APP_DIR/venv/bin/python3 server.py
Restart=on-failure
RestartSec=10
StandardOutput=journal
StandardError=journal

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable crudmaster-inventory

# Tester d'abord manuellement avant de démarrer
echo "🧪 Test de l'application..."
cd $APP_DIR
if sudo -u crudmaster bash -c "source venv/bin/activate && python3 -c 'from app import create_app; print(\"✅ Import OK\")'"; then
    echo "✅ Test réussi, démarrage du service..."
    systemctl start crudmaster-inventory
    sleep 3
    systemctl status crudmaster-inventory --no-pager
else
    echo "❌ Échec du test, vérifiez les erreurs ci-dessus"
    exit 1
fi

echo "✅ Inventory API configuré sur http://$(hostname -I | awk '{print $1}'):5001"