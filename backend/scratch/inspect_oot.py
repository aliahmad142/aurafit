from gradio_client import Client
try:
    client = Client("levihsu/OOTDiffusion")
    print(client.view_api())
except Exception as e:
    print(f"Error: {e}")
