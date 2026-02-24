import pika
import json
import logging
import os

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

def send_billing_message(data):
    """Publie un message de facturation dans RabbitMQ"""
    # Configuration de la connexion
    try:
        
        parameters = pika.ConnectionParameters(
            host=os.getenv("RABBITMQ_HOST", "rabbit-queue"),  
           )
        
        # Connexion à RabbitMQ
        connection = pika.BlockingConnection(parameters)
        channel = connection.channel()
        
        # S'assurer que la queue existe
        channel.queue_declare(
            queue='billing_queue',
            durable=True  # Survit au redémarrage
        )
        
        # Publier le message
        channel.basic_publish(
            exchange='',
            routing_key='billing_queue',
            body=json.dumps(data),
            properties=pika.BasicProperties(
                delivery_mode=2,  # Message persistant
                content_type='application/json'
            )
        )

        print(f"✅ Message de facturation envoyé : {data}")
        connection.close()

        logger.info(f"✅ Message publié: {data}")
        return True
    
    except Exception as e:
        logger.error(f"❌ Erreur RabbitMQ: {e}")
        return False