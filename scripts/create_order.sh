# Créer une commande via Gateway
curl -X POST http://192.168.121.29:8080/api/billing \
  -H "Content-Type: application/json" \
  -d '{"user_id": "gateway_user", "number_of_items": "50", "total_amount": "50"}'

