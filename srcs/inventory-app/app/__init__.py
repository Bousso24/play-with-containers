from flask import Flask
from dotenv import load_dotenv
from .extensions import db
from .routes import movies_bp
import os

def create_app():
    load_dotenv()
    app=Flask(__name__)
    app.config['SQLALCHEMY_DATABASE_URI']=os.getenv('INVENTORY_DATABASE_URL')
    #Désactiver le suivi des modifications (économise de la mémoire)
    app.config['SQLALCHEMY_TRACK_MODIFICATIONS'] = False
    #Configuration optionnelle: afficher les requêtes SQL (pour déboguer)
    app.config['SQLALCHEMY_ECHO']=True
    db.init_app(app)


    with app.app_context():
        db.create_all()

    app.register_blueprint(movies_bp)

    return app