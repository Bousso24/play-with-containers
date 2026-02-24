from flask import Flask
from dotenv import load_dotenv
import os
from app.config_loader import load_config



config=load_config()
gateway_config = config['services']['api-gateway']
def create_app():
    load_dotenv()
    app = Flask(__name__)
    app.config['INVENTORY_API_URL'] = os.getenv('INVENTORY_API_URL', gateway_config['routing']['inventory_url'])
    app.config['RABBITMQ_HOST'] = os.getenv('RABBITMQ_HOST', 'rabbit-queue')
    app.config['RABBITMQ_QUEUE'] = os.getenv('RABBITMQ_QUEUE', 'billing_queue')

     # Enregistrer les routes
    from app.routes import api_bp
    app.register_blueprint(api_bp)

    return app