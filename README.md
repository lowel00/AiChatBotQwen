# 🧠 Qwen AI - VLM Tabanlı Kişisel Yapay Zeka Asistanı

Bu proje, açık kaynaklı **Qwen3-VL (Vision-Language Model)** kullanılarak tamamen yerel donanımda (Localhost) çalışan, görüntü işleyebilen ve karmaşık matematik problemlerini "Düşünce Zinciri (Chain of Thought)" mantığıyla çözebilen profesyonel bir mobil yapay zeka asistanıdır. 

Hazır ve maliyetli bulut API'leri yerine **Ollama** üzerinden yerel donanım gücünü kullanır. Böylece veri gizliliği maksimum seviyede tutulur.

## ✨ Öne Çıkan Özellikler

- **📷 Görüntü Analizi (VLM):** Kamera veya galeriden yüklenen fotoğrafları analiz edip metne veya matematiksel işlemlere dökebilme.
- **🤔 Düşünce Süreci (Thinking UI):** Yapay zekanın nihai cevabı vermeden önceki karmaşık hesaplama ve düşünme adımlarını, genişletilebilir (ExpansionTile) bir kutuda gerçek zamanlı gösterme.
- **🧮 LaTeX ve Markdown Desteği:** Yapay zekanın ürettiği karmaşık matematiksel formülleri (integraller, kesirler vb.) ders kitabındaki gibi profesyonelce (render edilmiş şekilde) ekrana basma.
- **💾 Yerel Hafıza ve Çoklu Sohbet (SQLite):** Kullanıcı sohbetlerini kategorize etme, cihazın yerel depolamasında tutma ve yapay zekaya geçmişi (Context) hatırlatma. 
- **🗑️ Modern Arayüz Yönetimi:** "Swipe to delete" (kaydırarak silme), otomatik kaydırma (Auto-scroll) ve güvenli alan (SafeArea) yönetimi.
- **🇹🇷 Dil Zorlaması (System Prompting):** Görsel veya girdi hangi dilde olursa olsun, API tarafında yazılan sistem mesajı sayesinde kesinlikle Türkçe ve anlaşılır cevap verme.

## 📱 Ekran Görüntüleri

| Sohbet Arayüzü | Düşünce Süreci (Thinking) | Menü ve Hafıza Yönetimi |
| :---: | :---: | :---: |
| ![Sohbet](https://via.placeholder.com/250x500.png?text=Sohbet+Ekrani) | ![Thinking](https://via.placeholder.com/250x500.png?text=Dusunceler) | ![Menu](https://via.placeholder.com/250x500.png?text=Gecmis+Sohbetler) |

*(Not: Ekran görüntüleri daha sonra eklenecektir.)*

## 🛠️ Kullanılan Teknolojiler ve Mimari

**Sistem Mimarisi:** `Flutter (Client) -> Ngrok (Tunnel) -> FastAPI (Middleware) -> Ollama (Local LLM) -> GPU/CPU`

* **Frontend (Mobil Uygulama):** Flutter, Dart, Sqflite, Flutter Markdown (LaTeX destekli), HTTP.
* **Backend (API Sunucusu):** Python, FastAPI, Uvicorn, HTTPX (Asenkron Stream için).
* **Yapay Zeka Motoru:** Ollama, Qwen3-VL:4b modeli.
* **Ağ & İletişim:** Ngrok (Tünelleme ve port yönlendirme).

## 🚀 Kurulum ve Çalıştırma

Projeyi kendi bilgisayarınızda çalıştırmak için aşağıdaki adımları izleyin.

### 1. Gereksinimler
* [Ollama](https://ollama.com/) (Qwen3-VL indirilmiş olmalı: `ollama run qwen3-vl:4b`)
* Python 3.10+
* Flutter SDK (3.x.x)
* [Ngrok](https://ngrok.com/) hesabı ve aracı.

### 2. Backend (Python API) Kurulumu
Backend klasörüne gidin ve gerekli kütüphaneleri kurun:

pip install fastapi uvicorn httpx pydantic

Sunucuyu başlatın:
python -m uvicorn main:app --reload

Ayrı bir terminalde Ngrok tünelini açın: ngrok http 8000

(Ngrok'un verdiği https://....ngrok-free.app adresini kopyalayın).

3. Frontend (Flutter) Kurulumu:

Flutter projesinin klasörüne gidin. lib/main.dart dosyasını açıp _apiUrl değişkenine kopyaladığınız Ngrok URL'sini yapıştırın.

final String _apiUrl = "https://<SIZIN-NGROK-ADRESINIZ>.ngrok-free.app/solve-math";

Paketleri indirin ve uygulamayı başlatın:

flutter pub get
flutter run

🎯 Gelecek Planları (Roadmap)

Gelişmiş Tema Motoru (Dark/Light Mode, Baloncuk renkleri özelleştirme).

Kullanıcının kendi arka plan duvar kağıdını seçebilmesi.

Backend sisteminin Cloudflare Tunnels veya kalıcı bir VPS (Bulut Sunucu) sistemine taşınması.

Geliştirici: Ali İhsan AKA
