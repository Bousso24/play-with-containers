from .extensions import db
from .models import Order
# fonction pour créer une facture
def create_invoice(data):
    # Créer l'ordre dans la base de données
    try:
        order = Order(
            user_id=str(data["user_id"]), 
            number_of_items=int(data["number_of_items"]),
            total_amount=float(data["total_amount"])
        )
        
        db.session.add(order)
        db.session.commit()
        print(f"🧾 Facture {order.id} enregistrée")
        
    except ValueError as e:
        print(f"❌ Erreur conversion: {e}")
        raise