from gradio_client import Client
try:
    client = Client("Kwai-VGI/IDM-VTON")
    print(client.view_api())
except Exception as e:
    print(f"Error: {e}")
