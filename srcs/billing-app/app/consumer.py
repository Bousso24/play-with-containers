import pika
import json
from app.billing_service import create_invoice
from app import create_app
import os

app = create_app()

def on_movie_created(ch, method, properties, body):
    #Traite un message de commande reçu de RabbitMQ
    order_data = json.loads(body)
    print("📥 Film reçu :", order_data)

    try:
         with app.app_context():
            create_invoice(order_data)
            ch.basic_ack(delivery_tag=method.delivery_tag)
    except Exception as e:
        print("❌ Erreur billing:", e)


def start_consumer():
    # Démarre le consommateur RabbitMQ
    # Connexion à RabbitMQ
    try:
        rabbitmq_host = os.getenv('RABBITMQ_HOST', 'rabbit-queue')
    
        connection = pika.BlockingConnection(
            pika.ConnectionParameters(
                host=rabbitmq_host,
                credentials=pika.PlainCredentials(
                    os.getenv('RABBITMQ_USER', 'guest'),
                    os.getenv('RABBITMQ_PASSWORD', 'guest')
                )
            )
        )

        channel = connection.channel()
        # Déclarer la queue
        channel.queue_declare(queue="billing_queue", durable=True)
        # Configurer la qualité de service
        channel.basic_qos(prefetch_count=1)
        # Configurer le consommateur
        channel.basic_consume(
            queue="billing_queue",
            on_message_callback=on_movie_created
            #auto_ack=False
        )

        print("🎧 Billing API en attente de messages...")
        channel.start_consuming()
    except KeyboardInterrupt:
        if 'connection' in locals() and connection.is_open:
            connection.close()

if __name__ == "__main__":
    start_consumer()
