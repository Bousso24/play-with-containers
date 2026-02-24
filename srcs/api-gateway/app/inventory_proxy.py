import requests
import os
from app.config_loader import load_config
config=load_config()
gateway_config = config['services']['api-gateway']

INVENTORY_API_URL = os.getenv(
    "INVENTORY_API_URL",
    gateway_config['routing']['inventory_url']
)
#definir une fonction PROXY http pour transferer les requetes vers inventory
def forward_to_inventory(path, method, data=None, params=None):
    url = f"{INVENTORY_API_URL}{path}"

    response = requests.request(
        method=method,
        url=url,
        json=data,
        params=params
    )

    return response

