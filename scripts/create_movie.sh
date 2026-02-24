# Créer un film via Gateway
curl -X POST http://localhost:8080/api/movies \
  -H "Content-Type: application/json" \
  -d '{"title": "PM2 Test Movie", "description": "Test avec PM2"}'
