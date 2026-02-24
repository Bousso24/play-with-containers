# Tester l'API movies
curl http://localhost:3000/api/movies

# Créer un film
curl -X POST http://localhost:3000/api/movies \
  -H "Content-Type: application/json" \
  -d '{"title":"Test","description":"Description"}'

# Tester la facturation
curl -X POST http://localhost:3000/api/billing \
  -H "Content-Type: application/json" \
  -d '{"user_id":"123","number_of_items":2,"total_amount":99.99}'