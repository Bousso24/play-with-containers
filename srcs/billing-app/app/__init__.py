from flask import Flask
from app.extensions import db
from dotenv import load_dotenv
import os

def create_app():
    app = Flask(__name__)

    # Charger les variables d'environnement depuis le fichier .env
    load_dotenv()

    # Configurer la base de données
    app.config['SQLALCHEMY_DATABASE_URI'] = os.getenv('BILLING_DATABASE_URL')
    app.config['SQLALCHEMY_TRACK_MODIFICATIONS'] = False
    app.config['SQLALCHEMY_ECHO'] = False

    # Initialiser les extensions
    db.init_app(app)

    with app.app_context():
        # Importer les modèles pour créer les tables
        db.create_all()

    return app