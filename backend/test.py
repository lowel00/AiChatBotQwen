import requests
import base64

URL = "https://6f5f-85-105-11-193.ngrok-free.app/solve-math"
IMAGE_PATH = "soru.png"

try:
    with open(IMAGE_PATH, "rb") as image_file:
        real_image_base64 = base64.b64encode(image_file.read()).decode('utf-8')
except FileNotFoundError:
    print(f"HATA: {IMAGE_PATH} bulunamadı!")
    exit()

payload = {
    "prompt": "Bu fotoğrafta ne görüyorsun? Kısaca açıkla.",
    "image_base64": real_image_base64
}

headers = {
    "Content-Type": "application/json",
    "ngrok-skip-browser-warning": "true" 
}

print("İstek gönderildi. İşte Ollama'dan gelen GİZLİ SANSÜRSÜZ VERİ:\n")

try:
    response = requests.post(URL, json=payload, headers=headers, stream=True)
    
    # Gelen her şeyi olduğu gibi ekrana basıyoruz!
    for line in response.iter_lines():
        if line:
            print(line.decode('utf-8'))

except Exception as e:
    print(f"Bağlantı hatası: {e}")