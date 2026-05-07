from gradio_client import Client
try:
    client = Client("Nymbo/Virtual-Try-On")
    print(client.view_api())
except Exception as e:
    print(f"Error: {e}")
