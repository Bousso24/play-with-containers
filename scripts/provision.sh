#!/bin/bash
# scripts/provision.sh - Provisionnement des VMs

set -e  # Arrêter en cas d'erreur

VM_TYPE=$1  # gateway, inventory, ou billing

echo "🔧 Provisionnement pour: $VM_TYPE"
echo "================================"

# Mise à jour du système
echo "🔄 Mise à jour du système..."
apt-get update
# Installation des dépendances de base
echo "📦 Installation des dépendances..."
apt-get install -y \
    python3 \
    python3-pip \
    python3-venv \
    git \
    curl \
    wget \
    net-tools
# Node.js + npm (pour PM2)
curl -fsSL https://deb.nodesource.com/setup_18.x | bash -
apt-get install -y nodejs

# Création de l'utilisateur de service
echo "👤 Configuration de l'utilisateur..."
if ! id -u crudmaster >/dev/null 2>&1; then
    useradd -m -s /bin/bash crudmaster
    echo "crudmaster:crudmaster123" | chpasswd
    usermod -aG sudo crudmaster
fi

# Dépendances spécifiques par type de VM
case $VM_TYPE in
    "gateway")
        /vagrant/scripts/setup_gateway.sh
        ;;
    "inventory")
        /vagrant/scripts/setup_inventory.sh
        ;;
    "billing")
        /vagrant/scripts/setup_billing.sh
        ;;
    *)
        echo "❌ Type de VM inconnu: $VM_TYPE"
        exit 1
        ;;
esac

echo "✅ Provisionnement $VM_TYPE terminé avec succès!"