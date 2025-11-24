import urllib.request
import os

url = "https://huggingface.co/TheBloke/TinyLlama-1.1B-Chat-v1.0-GGUF/resolve/main/tinyllama-1.1b-chat-v1.0.Q4_0.gguf"
dest = "data/models/TinyLlama-1.1B-Chat-v1.0.Q4_0.gguf"

print(f"Downloading {url} to {dest}...")
try:
    urllib.request.urlretrieve(url, dest)
    print("Download complete!")
except Exception as e:
    print(f"Error: {e}")
