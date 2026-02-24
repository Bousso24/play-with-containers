from app import create_app
from app.config_loader import load_config
import logging

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)
# Charger la configuration
config=load_config()
gateway_config = config['services']['api-gateway']


app = create_app()

if __name__ == '__main__':
    logger.info("🚀 Gateway démarré sur http://localhost:%s", gateway_config['port'])
    app.run(
        host=gateway_config['host'], 
        port=gateway_config['port'], 
        debug=True)