from flask import Blueprint, request, Response, jsonify
import logging
from app.inventory_proxy import forward_to_inventory
from app.billing_producer import send_billing_message

api_bp = Blueprint("api", __name__)
logger = logging.getLogger(__name__)

# ---------- INVENTORY ----------
@api_bp.route("/api/movies", methods=["GET", "POST", "DELETE"])
@api_bp.route("/api/movies/<int:movie_id>", methods=["GET", "PUT", "DELETE"])
def proxy_inventory(movie_id=None):
    """Proxy transparent vers l'API Inventory"""
    try:
        response = forward_to_inventory(
            path=request.path,
            method=request.method,
            data=request.get_json(silent=True),
            params=request.args
        )
        
        logger.info(f"Proxy {request.method} {request.path} → {response.status_code}")
        
        return Response(
            response.content,
            status=response.status_code,
            content_type=response.headers.get("Content-Type", "application/json")
        )
        
    except Exception as e:
        logger.error(f"❌ Erreur proxy vers Inventory: {e}")
        return jsonify({
            "error": "Gateway Error",
            "message": "Unable to reach Inventory API"
        }), 502 

# ---------- BILLING ----------
@api_bp.route("/api/billing", methods=["POST"])
def billing():
    """Reçoit une commande et la publie dans RabbitMQ"""
    try:
        # Vérifier Content-Type
        if not request.is_json:
            return jsonify({
                "error": "Bad Request",
                "message": "Content-Type must be application/json"
            }), 400
        
        data = request.get_json()
        
        # Validation minimale
        if not data or not isinstance(data, dict):
            return jsonify({
                "error": "Bad Request", 
                "message": "Invalid JSON data"
            }), 400
        
        required_fields = ['user_id', 'number_of_items', 'total_amount']
        for field in required_fields:
            if field not in data:
                return jsonify({
                    "error": "Bad Request",
                    "message": f"Missing required field: {field}"
                }), 400
        
        # Envoyer à RabbitMQ
        success = send_billing_message(data)
        
        if success:
            logger.info(f"✅ Commande publiée: {data}")
            return jsonify({
                "message": "Order received and queued for processing",
                "status": "pending"
            }), 202
        else:
            logger.error(f"❌ Échec publication RabbitMQ: {data}")
            return jsonify({
                "error": "Service Unavailable",
                "message": "Unable to process order. Please try again."
            }), 503
            
    except Exception as e:
        logger.error(f"💥 Erreur inattendue /billing: {e}")
        return jsonify({
            "error": "Internal Server Error",
            "message": "An unexpected error occurred"
        }), 500


