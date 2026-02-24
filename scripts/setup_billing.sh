#!/bin/bash
# scripts/setup_billing.sh

echo "💰 Configuration Billing API..."
apt-get update

# Installation PostgreSQL et dépendances
echo "🗄️ Installation dependances..."
apt-get install -y postgresql postgresql-contrib rabbitmq-server python3 python3-pip python3-venv

# Démarrer les services
systemctl start postgresql
systemctl enable postgresql
systemctl start rabbitmq-server
systemctl enable rabbitmq-server

# Configuration PostgreSQL pour billing
echo "🔧 Configuration base billing..."
sudo -u postgres psql -c "CREATE DATABASE billing_db;" 2>/dev/null || echo "Database billing_db existe déjà"
sudo -u postgres psql -c "ALTER USER postgres WITH PASSWORD 'postgres123';"
sudo -u postgres psql -c "GRANT ALL PRIVILEGES ON DATABASE billing_db TO postgres;"

# Configuration RabbitMQ
echo "🔧 Configuration RabbitMQ..."
rabbitmq-plugins enable rabbitmq_management
systemctl restart rabbitmq-server
sleep 2

# Créer le répertoire de l'application
APP_DIR="/home/crudmaster/billing-app"
mkdir -p $APP_DIR

# Copier le code source
echo "📁 Copie du code source..."
cp -r /vagrant/srcs/billing-app/* $APP_DIR/
chown -R crudmaster:crudmaster $APP_DIR

# Créer un .env
echo "📄 Création du fichier .env..."
cat > $APP_DIR/.env << EOF
# PostgreSQL Configuration
POSTGRES_USER=postgres
POSTGRES_PASSWORD=postgres123
POSTGRES_HOST=localhost

#BILLING
BILLING_DB_NAME=billing_db
BILLING_PORT=5432
BILLING_DATABASE_URL=postgresql://${POSTGRES_USER}:${POSTGRES_PASSWORD}@${POSTGRES_HOST}:${BILLING_PORT}/${BILLING_DB_NAME}
SECRET_KEY=billing-secret-key-123
DEBUG=True

# RabbitMQ Configuration
RABBITMQ_HOST=localhost
RABBITMQ_PORT=5672
RABBITMQ_USER=api_user
RABBITMQ_PASS=MonMotDePasseSecure123
RABBITMQ_QUEUE=billing_queue

# Services externes
INVENTORY_API_URL=http://localhost:5001
EOF

# Configuration de l'environnement Python
echo "🔧 Configuration environnement Python..."
cd $APP_DIR

# Installation des dépendances Python globalement
echo "📦 Installation des dépendances Python globalement..."



# Vérifier que Flask est installé globalement
echo "🔍 Vérification de l'installation..."
python3 -c "
try:
    import flask, psycopg2, pika
    print(f'✅ Flask installé')
    print(f'✅ psycopg2 installé')
    print(f'✅ pika installé')
except ImportError as e:
    print(f'❌ Erreur: {e}')
    exit(1)
"

# Service systemd avec python3 GLOBAL
echo "🚀 Configuration service systemd..."
cat > /etc/systemd/system/crudmaster-billing.service << EOF
[Unit]
Description=CRUD Master Billing API
After=network.target postgresql.service rabbitmq-server.service
Requires=postgresql.service rabbitmq-server.service
[Service]
Type=simple
User=crudmaster
WorkingDirectory=$APP_DIR
Environment="PATH=/usr/bin"
Environment="BILLING_DATABASE_URL=postgresql://postgres:postgres123@localhost:5432/billing_db"
Environment="DATABASE_URL=postgresql://postgres:postgres123@localhost:5432/billing_db"
Environment="SQLALCHEMY_DATABASE_URI=postgresql://postgres:postgres123@localhost:5432/billing_db"
Environment="RABBITMQ_HOST=localhost"
Environment="SECRET_KEY=billing-secret-key-123"

ExecStart=/usr/bin/python3 -m app.consumer
Restart=on-failure
RestartSec=5

# Services externes
Environment="INVENTORY_API_URL=http://localhost:5001"

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable crudmaster-billing

# Test avec python3 GLOBAL
echo "🧪 Test de l'application..."
cd $APP_DIR
if python3 -c "
import sys
print(f'🔍 Python utilisé: {sys.executable}')

try:
    # Test des imports
    print('🔍 Test des imports...')
    import flask
    print(f'  ✅ flask installé')
    import psycopg2
    print(f'  ✅ psycopg2 installé')
    import pika
    print(f'  ✅ pika installé')
    
    # Test PostgreSQL
    print('🔍 Test connexion PostgreSQL...')
    conn = psycopg2.connect(
        host='localhost',
        database='billing_db',
        user='postgres',
        password='postgres123'
    )
    conn.close()
    print('✅ PostgreSQL: connexion réussie')
    
    # Test RabbitMQ
    print('🔍 Test connexion RabbitMQ...')
    connection = pika.BlockingConnection(
        pika.ConnectionParameters(host='localhost')
    )
    connection.close()
    print('✅ RabbitMQ: connexion réussie')
    
    print('🎉 Tous les tests passés!')
    
except Exception as e:
    print(f'❌ Erreur de test: {e}')
    import traceback
    traceback.print_exc()
    sys.exit(1)
"; then
    echo "✅ Test réussi, démarrage du service..."
    systemctl start crudmaster-billing
    sleep 5
    
    # Vérifier le statut
    if systemctl is-active --quiet crudmaster-billing; then
        echo "✅ Service crudmaster-billing démarré"
        echo "📊 Statut:"
        systemctl status crudmaster-billing --no-pager
        
        # Tester l'API - VERSION SIMPLIFIÉE SANS ERREUR DE SYNTAXE
        echo "🌐 Test de l'API..."
        sleep 3
        if curl -f -s http://localhost:5002/health > /dev/null; then
            echo "✅ API accessible: http://localhost:5002/health"
            # Version simple sans variable qui cause l'erreur
            curl -s http://localhost:5002/health
        else
            echo "⚠️ API non accessible, vérification logs..."
            journalctl -u crudmaster-billing -n 15 --no-pager
        fi
    else
        echo "❌ Échec démarrage service"
        journalctl -u crudmaster-billing -n 20 --no-pager
        exit 1
    fi
else
    echo "❌ Échec des tests"
    exit 1
fi

echo ""
echo "================================================"
echo "✅ BILLING API CONFIGURÉ !"
echo "================================================"
echo "📡 API:          http://$(hostname -I | awk '{print $1}'):5002"
echo "🗄️ PostgreSQL:   postgres:postgres123@localhost:5432/billing_db"
echo "================================================"