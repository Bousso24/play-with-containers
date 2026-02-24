# Script test_rabbitmq.py
import pika
import json

connection = pika.BlockingConnection(
    pika.ConnectionParameters('localhost')
)
channel = connection.channel()

channel.queue_declare(queue='billing_queue', durable=True)

message = {
    'user_id': '999',
    'number_of_items': 3,
    'total_amount': 150.50
}

channel.basic_publish(
    exchange='',
    routing_key='billing_queue',
    body=json.dumps(message),
    properties=pika.BasicProperties(delivery_mode=2)  # persistent
)

print("✅ Message envoyé à RabbitMQ")
connection.close()






# Terminal 2 - Envoyer un message via Python
python3 -c "
import pika, json
conn = pika.BlockingConnection(pika.ConnectionParameters('rabbit-queue'))
channel = conn.channel()
channel.basic_publish(
    exchange='',
    routing_key='billing_queue',
    body=json.dumps({'user_id': '1', 'number_of_items': 2, 'total_amount': 99.99})
)
conn.close()
print('Message envoyé')
"

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
