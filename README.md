# PLAY-WITH-CONTAINERS
Docker est une plateforme de conteneurisation open source qui permet aux équipes de développement d'empaqueter leurs applications et toutes leurs dépendances dans des conteneurs légers et portables

Pour ce projet, on va mettre en place une architecture de microservices avec docker et docker-compose.
Pour chaque service, on va cree un conteneur Dockerfile ainsi que les services stantard(les base de donnees, rabbitmq).
Tout d abord nous devrons disposer d un reseau Docker qui etablit la connexion entre tous les services a l interieur de notre hote docker.

## 🏗️ Architecture
- API Gateway (port 3000)
- Inventory Service (port 8080 interne)
- Billing Service (port 8080 interne)
- RabbitMQ (message queue)
- PostgreSQL (2 bases de données)

## 📋 Prérequis
- Docker 20.10.
- Docker Compose 1.29.
```bash
sudo apt install -y docker.io
sudo systemctl enable docker
sudo systemctl start docker
sudo usermod -aG docker $USER
newgrp docker
docker --version
docker compose version
```

1. Creons notre reseaux prive appele my-network
```bash 
docker network create my-network 
```
2. Creons les volumes Docker pour la persistance des donnees generees permettant ainsi de garder les donnees meme si on supprime le conteneur.
```bash
# Créer le volume nommé du inventory-db-volume
docker volume create inventory-db-volume

# Créer le volume nommé du billing-db-volume
docker volume create billing-db-volume

#Créer le volume nommé du api-gateway-logs-volume
docker volume create api-gateway-logs-volume

# Créer le volume nommé du rabbitmq-data
docker volume create rabbitmq-data
# Vérifier les volumes
docker volume ls

# Voir les détails d'un volume
docker volume inspect inventory-db-volume
```
3. Passons a la creation de container inventory-db avec l image officielle
```bash
docker run -d \
  --name inventory-db \
  --network my-network \
  -e POSTGRES_DB=movies_db \
  -e POSTGRES_PASSWORD=postgres123 \
  -e POSTGRES_USER=postgres \
  -v inventory-db-volume:/var/lib/postgresql/data \
  postgres:15-alpine
```

4. Creation du container billing_db avec l image officielle
```bash
docker run -d \
  --name billing-db \
  --network my-network \
  -e POSTGRES_DB=billing_db \
  -e POSTGRES_USER=postgres \
  -e POSTGRES_PASSWORD=postgres123 \
  -v billing-db-volume:/var/lib/postgresql/data \
  -p 5432:5432 \
  postgres:15-alpine
```
5. Creation du container rabbitMQ avec l image officielle
```bash
docker run -d \
  --name rabbit-queue \
  --network my-network \
  -e RABBITMQ_USER=guest \
  -e RABBITMQ_PASSWORD=guest \
  -v rabbitmq-data:/var/lib/rabbitmq \
  -p 5672:5672 \
  rabbitmq:3.12-management-alpine
  ```
## - creation des fichiers dockerfile pour chaque api
Apres avoir creer le fichier Dockerfile pour l image, on va lancer creer des coneneurs pour chaque image.
- lancer le container pour inventory-app:
```bash
docker run -d \
  --name inventory-app \
  --network my-network \
  --env-file /home/bousso/play-with-containers/.env \
  -p 8080:5001 \
  inventory-app
```
- lancer le container pour billing-app:
```bash
docker run -d \
  --name billing-app-api \
  --network my-network \
  --env-file /home/bousso/play-with-containers/.env \
  billing-app
  ```
- lancer le container pour api-gateway:
```bash
docker run -d \
  --name api-gateway \
  --network my-network \
  -p 3000:3000 \
  -e INVENTORY_API_URL=http://inventory-app:5001 \
  -e RABBITMQ_HOST=rabbit-queue \
  -e CONFIG_PATH=/app/config.yaml \
  -v /home/bousso/play-with-containers/config.yaml:/app/config.yaml \
  api-gateway
```

* Pour tester RabbitMQ depuis un container Alpine avec l api billing-app:
```bash
docker run --rm -it \
  --network my-network \
  python:3.12-alpine \
  sh
```
- puis dans le shell 
```bash
pip install pika
python3

import pika, json

conn = pika.BlockingConnection(
    pika.ConnectionParameters('rabbit-queue')
)

channel = conn.channel()
channel.basic_publish(
    exchange='',
    routing_key='billing_queue',
    body=json.dumps({
        "user_id": "2",
        "number_of_items": 4,
        "total_amount": 100
    })
)

conn.close()
print("✅ Message envoyé")

#voir les messages en attente
docker exec -it rabbit-queue rabbitmqctl list_queues

```
- Vérifier que la facture est bien en base:
```bash
docker exec -it billing-db psql -U postgres -d billing_db
SELECT * FROM orders;

docker exec -it inventory-db psql -U postgres -d movies_db
SELECT * FROM movies;
```
- les commandes:
```bash
docker build -t inventory-app .
docker images
docker ps
#voir les logs
docker logs inventory-app-test
docker stop inventory-app-test
docker rm inventory-app-test
# Arrêter tous les conteneurs
docker stop $(docker ps -q)
# Démarrer tous les conteneurs arrêtés
docker start $(docker ps -aq)
# suppression par ID de l'image
docker rmi ID_de_l_image
#suppression d un conteneur
docker rm nom_container
```
* Tester avec l API inventory-app:
```bash 
# Créer un film
curl -X POST http://localhost:8080/api/movies/ \
  -H "Content-Type: application/json" \
  -d '{"title":"description","description":"it s me"}'

# Lister les films
curl http://localhost:8080/api/movies/

docker logs api-gateway --tail 10

Ajouter votre utilisateur au groupe docker (pour éviter sudo)
sudo usermod -aG docker $USER
```
## - configuration du fichier docker-compose.yaml
Le docker-compose est un outil qui permet de definir et d executer des application Docker multi-conteneur, avec compose on va cree un fichier .taml pour configurer les services de notre application.
il permet:
- Définir TOUS les services dans un seul fichier
- Gérer le réseau automatiquement
- Gérer les volumes automatiquement
- Ordonner le démarrage (ex: DB avant app)
- Rendre l'infrastructure REPRODUCTIBLE

```bash
# 2. Lancer toute l'infrastructure avec compose
cd ~/play-with-containers
docker-compose up -d

# 3. Voir l'état
docker-compose ps

# 4. Voir les logs de tous les services
docker-compose logs -f

# 5. Voir les logs d'un service spécifique
docker-compose logs -f api-gateway

# 6. Arrêter tout
docker-compose down

curl http://localhost:3000/api/movies

# Tester la création d'un film via gateway
curl -X POST http://localhost:3000/api/movies \
  -H "Content-Type: application/json" \
  -d '{"title":"Test","description":"test"}'

# Tester billing via gateway
curl -X POST http://localhost:3000/api/billing \
  -H "Content-Type: application/json" \
  -d '{"user_id":"3","number_of_items":4,"total_amount":4000}'

# Voir les films dans inventory-db
sudo docker exec -it inventory-db psql -U postgres -d movies_db -c "SELECT * FROM movies;"

#Voir les factures dans billing-db
sudo docker exec -it billing-db psql -U postgres -d billing_db -c "SELECT * FROM orders;"
  ```
Nous utilisons .gitignore pour protéger le dépôt et .dockerignore pour optimiser les images Docker et améliorer les performances de build.
* * * queleques notions:
* Conteneur: est une instance en cour d execution d une image docker.
aventages:
legerete -> il partage le noyau de l os d hote, ce qui facilite le demarrage
portabilite -> marche partout
isolation -> les appication ne marche pas dessus
reproductibilite -> meme environnemt en dev, test, prod
scalabilite -> facile de duplique pour gerer plus de charge

* la difference entre un coteneur et une machine virtuelle:
-> un conteneur partage le meme systeme d exploitation de l hote alors qu une VM a son propre OS complet
-> pour la performance et la taille: les conteneurs sont legers (quelque Mo/Go) et utilise moin de memoire alors que les VM sont lourdes (plusieurs Go) car elles embarquent un systeme d exploitation complet.
->demarrage: un conteneur demarre quelque secondes alors qu une VM demarre quelque minutes. 

* Docker: docker est une plateforme open source de conteneurisation qui permet d empaqueter une application et toutes ses dependances dans un conteneur leger et portable.
Il sert a garantir qu une application fonctionne de maniere identique quel que soit l environnement (dev, test, prod) facilitant ainsi le deploiement rapide et la gestion des microservices.

* Une architecture microservice: est une architecture ou une application est decoupee en petits services independants qui communiquent entre eux via des API.

* Pourquoi utilisons-nous une architecture de microservices?
Scalabilité indépendante ->	On scale seulement ce qui est nécessaire.
Isolation des pannes ->	Un service qui plante ne tue pas toute l appication.
Développement parallèle ->	Plusieurs équipes peuvent travailler sur plusieurs services differents.
Technologies hétérogènes -> Chaque service peut utiliser sa stack, les services peuvent avoir des dependances differentes.
Déploiement indépendant	-> On peut déployer sans tout re-déployer. c a t on peut update un service sans tout update.

* Qu'est-ce qu'une file d'attente et à quoi sert-elle ?
Structure de données FIFO (First In, First Out) où les messages sont stockés temporairement en attendant d'être traités.
Elle sert à organiser les flux, gérer la demande, optimiser les ressources et garantir l'équité.

* RABBITMQ: est un message broker (un courtier de messages) : Garantir la livraison des messages de paiement
-> reçoit des messages
-> les stocke
-> les transmet aux consommateurs
-> Gère les ACK

* Dockerfile: est un fichier test qui contient des commandes (instructions) qu un utilisateur peut appele sur la ligne de commande pour creer une image.
INSTRUCTIONS DOCKERFILE
Instruction	                    Rôle	                                Exemple
FROM	                     Image de base	                            FROM python:3.11-alpine
WORKDIR	                Répertoire de travail	                        WORKDIR /app
COPY	                   Copie fichiers	                              COPY . .
RUN	                      Exécute commande	                          RUN pip install -r requirements.txt
ENV	                       Variable d'env	                            ENV DEBUG=False
EXPOSE	                   Port à ouvrir	                            EXPOSE 8080
CMD	                     Commande par défaut	                        CMD ["python", "app.py"]
ENTRYPOINT	               Commande fixe	                            ENTRYPOINT ["python"]

ORDRE OPTIMAL:
FROM          # 1. Base
WORKDIR       # 2. Répertoire
COPY req.txt  # 3. Dépendances d'abord
RUN install   # 4. Installation (cache optimisé)
COPY .        # 5. Code ensuite
CMD           # 6. Commande finale

* Qu'est-ce qu'un volume Docker ?
les volumes constituent le mecanisme privilegie pour la persistance des donnees generees et utilisees par les conteneurs docker, permettant de conserver les informations même si un conteneur est supprimé ou redémarré. Ils permettent de séparer le stockage des données de la durée de vie du conteneur, facilitant le partage de fichiers entre conteneurs et la sauvegarde. 

* un reseau Docker: il permet a un utilisateur de connecter un conteneur docker a autant de reseaux qu il le souhaite, il permet de cree un reseau prive pour la communication entre les differents API.
il permet de connecter des conteneurs entre eux, permettant la communication d'applications distribuées

* image Docker: est un modele en lecture seul qui contient ensemble d instructions pour creer un conteneur pouvant s executer sur la plateforme docker.
Les images Docker sont utilisées pour empaqueter des applications avec toutes leurs dépendances (bibliothèques, configurations, code) dans un format unique, léger et immuable. Elles garantissent la portabilité et la reproductibilité ("ça marche sur ma machine" partout), simplifient le déploiement, et permettent d'isoler les services pour éviter les conflits.

## 🚀 Installation

1. Cloner le projet
3. Lancer l'infrastructure :
```bash
docker-compose up -d
```