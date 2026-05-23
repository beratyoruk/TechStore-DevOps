# 🛒 TechStore — Uygulamalı DevOps Projesi

Gerçekçi bir e-ticaret uygulaması üzerinde tam DevOps pipeline'ı.

## Proje Yapısı

```
techstore/
├── app.py                    # Ana Flask uygulaması
├── requirements.txt          # Python bağımlılıkları
├── Dockerfile                # Container tanımı
├── docker-compose.yml        # Tüm servisler (App + Prometheus + Grafana + SonarQube)
├── Jenkinsfile               # CI/CD pipeline
├── sonar-project.properties  # SonarQube yapılandırması
├── templates/
│   ├── index.html            # Ana sayfa (ürün listesi)
│   ├── product.html          # Ürün detay sayfası
│   ├── cart.html             # Sepet sayfası
│   ├── checkout.html         # Ödeme sayfası
│   └── order_success.html    # Sipariş onayı
├── tests/
│   ├── test_app.py           # 30 birim ve entegrasyon testi
│   └── test_ui.py            # 10 Selenium UI testi
└── monitoring/
    └── prometheus.yml        # Prometheus scrape yapılandırması
```

## Ürün Kataloğu

| Ürün | Kategori | Fiyat |
|------|----------|-------|
| Samsung Galaxy S24 Ultra | Telefon | 54,999 TL |
| Apple MacBook Pro 16" M3 Pro | Laptop | 89,999 TL |
| Sony WH-1000XM5 | Kulaklık | 12,499 TL |
| LG OLED C3 55" | Televizyon | 39,999 TL |
| iPad Pro 12.9" M2 | Tablet | 34,999 TL |
| Logitech MX Master 3S | Aksesuar | 2,499 TL |
| DJI Mini 4 Pro | Drone | 28,999 TL |
| Corsair K100 RGB | Aksesuar | 4,299 TL |

---

## 🚀 Hızlı Başlangıç

### Ön Gereksinimler

```bash
python3 --version    # 3.9+
docker --version     # 20+
git --version        # 2+
```

> 📦 Hazır imaj: [`synexis/techstore-app`](https://hub.docker.com/r/synexis/techstore-app) — `docker pull synexis/techstore-app:latest`
>
> 📂 GitHub: [beratyoruk/TechStore-DevOps](https://github.com/beratyoruk/TechStore-DevOps)

### 1. Yerel Çalıştırma

```bash
# Klonla
git clone https://github.com/beratyoruk/TechStore-DevOps.git
cd TechStore-DevOps

# Sanal ortam kur
python3 -m venv venv
source venv/bin/activate          # Windows: venv\Scripts\activate

# Bağımlılıkları yükle
pip install -r requirements.txt

# Uygulamayı başlat
python app.py
# → http://localhost:5000
```

### 2. Docker ile Çalıştırma

```bash
# Sadece uygulama
docker build -t techstore-app .
docker run -p 5000:5000 techstore-app

# Tüm stack (Uygulama + Prometheus + Grafana + SonarQube)
docker-compose up -d
```

Servisler:
| Servis | URL | Kimlik |
|--------|-----|--------|
| TechStore | http://localhost:5000 | — |
| Prometheus | http://localhost:9090 | — |
| Grafana | http://localhost:3000 | admin / techstore123 |
| SonarQube | http://localhost:9000 | admin / admin |

---

## 🧪 Testler

### Birim ve Entegrasyon Testleri

```bash
source venv/bin/activate

# Tüm testleri çalıştır
pytest tests/test_app.py -v

# Kapsam raporu ile
pytest tests/test_app.py -v --cov=app --cov-report=term-missing

# Belirli bir test
pytest tests/test_app.py::test_add_to_cart_success -v
```

### UI Testleri (Selenium)

```bash
# Önce uygulamayı başlatın (python app.py)
# ChromeDriver otomatik indirmek için:
pip install webdriver-manager

pytest tests/test_ui.py -v
```

---

## 🔄 CI/CD Pipeline (Jenkins)

### Jenkins Kurulum

```bash
# Docker ile Jenkins
docker run -d \
  -p 8080:8080 -p 50000:50000 \
  -v jenkins_home:/var/jenkins_home \
  --name jenkins \
  jenkins/jenkins:lts

# İlk şifreyi al
docker logs jenkins | grep -A 3 "Please use"
```

### Jenkins Yapılandırması

1. `http://localhost:8080` → Kurulum sihirbazını tamamlayın
2. Plugins: **Pipeline**, **GitHub**, **SonarQube Scanner**, **Slack Notification**, **Docker Pipeline**, **Cobertura**
3. Credentials ekle (her biri `Secret text` veya `Username with password`):
   - `sonar-token` → SonarQube token (Secret text)
   - `docker-hub-creds` → Docker Hub kullanıcı adı/şifre (Username with password)
   - `slack-webhook` → Slack Incoming Webhook URL'si (Secret text)
4. **New Item** → **Pipeline** → SCM: Git (GitHub repo URL)
5. GitHub Webhook: `http://JENKINS_IP:8080/github-webhook/`
6. SonarQube server config: Manage Jenkins → System → SonarQube servers → Name: `SonarQube`, URL: `http://sonarqube:9000` (compose ağı DNS)
7. SonarQube Scanner CLI (Jenkins container içine kurulmalı):
   ```bash
   docker exec -u root jenkins bash -c "curl -sL -o /tmp/s.zip https://binaries.sonarsource.com/Distribution/sonar-scanner-cli/sonar-scanner-cli-5.0.1.3006-linux.zip && unzip -q /tmp/s.zip -d /opt && ln -sf /opt/sonar-scanner-5.0.1.3006-linux/bin/sonar-scanner /usr/local/bin/sonar-scanner"
   ```
8. Jenkins'i compose network'üne bağla (sonarqube/app DNS çözümü için):
   ```bash
   docker network connect techstore-devops_techstore-net jenkins
   ```

### Pipeline Aşamaları

```
Checkout → Setup → Unit Tests → SonarQube → Quality Gate
    → Docker Build → Docker Push → Deploy → Smoke Test → UI Tests
```

---

## 📊 İzleme (Prometheus + Grafana)

### Mevcut Metrikler

| Metrik | Açıklama |
|--------|----------|
| `http_requests_total` | HTTP istek sayacı (method, endpoint, status) |
| `http_request_duration_seconds` | İstek süresi histogramı |
| `cart_add_total` | Sepete ekleme sayacı (product_id) |
| `orders_total` | Tamamlanan sipariş sayacı |

### Grafana Dashboard Sorguları

```promql
# Dakikada istek sayısı
rate(http_requests_total[1m])

# 95. yüzdelik istek süresi
histogram_quantile(0.95, rate(http_request_duration_seconds_bucket[5m]))

# En çok eklenen ürünler
topk(5, cart_add_total)

# Hata oranı
rate(http_requests_total{status=~"5.."}[5m]) / rate(http_requests_total[5m])
```

---

## 📱 API Referansı

| Method | Endpoint | Açıklama |
|--------|----------|----------|
| GET | `/` | Ana sayfa |
| GET | `/product/<id>` | Ürün detayı |
| GET | `/cart` | Sepet sayfası |
| POST | `/api/cart/add` | Sepete ekle `{"product_id": 1, "quantity": 1}` |
| POST | `/api/cart/remove` | Sepetten sil `{"product_id": 1}` |
| POST | `/api/cart/update` | Miktar güncelle `{"product_id": 1, "quantity": 3}` |
| GET | `/api/search?q=samsung&category=Telefon` | Ürün ara |
| GET | `/checkout` | Ödeme sayfası |
| POST | `/checkout` | Sipariş oluştur |
| GET | `/health` | Sağlık kontrolü |
| GET | `/metrics` | Prometheus metrikleri |

---

## 🎯 Kalite Metrikleri

| Metrik | Hedef | Gerçekleşen |
|--------|-------|-------------|
| Test kapsamı | > %80 | **%94.6** ✅ |
| Test sayısı | 25+ birim, 10+ UI | **30 birim + 10 UI** ✅ |
| Hata oranı | < %1 | 0 hata (smoke test) ✅ |
| Yanıt süresi (p95) | < 500ms | < 50ms (lokal stack) ✅ |
| Deploy süresi | < 5 dakika | ~3 dakika (Jenkins build) ✅ |
| Pipeline başarı oranı | %100 | Build #10 PASSED ✅ |
| Quality Gate | PASSED | **PASSED** (`techstore-gate`) ✅ |

---

## 📈 Gerçekleşen Sonuçlar

| Bileşen | Durum | Detay |
|---|---|---|
| Flask uygulaması | ✅ | 11 endpoint, 8 ürün, sepet+ödeme akışı |
| Birim testleri | ✅ | 30/30 PASSED, çalışma süresi ~0.3 sn |
| UI testleri | ✅ | 10 Selenium senaryosu (Jenkins'te koşar) |
| Kod kapsamı | ✅ | %94.6 (129 satırdan 7'si test edilmedi) |
| Docker imajı | ✅ | `synexis/techstore-app:latest` (Docker Hub) |
| Compose stack | ✅ | 4 servis: App + Prometheus + Grafana + SonarQube |
| Jenkins pipeline | ✅ | 10 stage, ~3 dk total süre |
| SonarQube analizi | ✅ | Quality Gate PASSED, 16 issue tespit |
| Grafana dashboard | ✅ | 4 panel (rate, p95, top products, error %) |
| Slack notification | ✅ | Incoming webhook `#devops` kanalı |
| GitHub repo | ✅ | 12+ commit, main branch korumalı |

---

## 🛠 Yaygın Sorunlar ve Çözümler

| Sorun | Sebep | Çözüm |
|---|---|---|
| `ModuleNotFoundError: app` (pytest) | pytest cwd'yi sys.path'e eklemiyor | Proje köküne `pytest.ini` ekle: `pythonpath = .` |
| `sonar-scanner: not found` (Jenkins) | CLI Jenkins container'ında yok | Yukarıdaki adım 7'deki kurulum komutunu çalıştır |
| `Permission denied (docker.sock)` | jenkins user docker grubunda değil | `docker exec -u root jenkins chgrp docker /var/run/docker.sock && chmod 660 /var/run/docker.sock` |
| Jenkins → SonarQube `Connection refused` | Compose network'ünde değil | `docker network connect techstore-devops_techstore-net jenkins` |
| Smoke test `HTTP 000` | localhost'tan container'a erişim yok | Smoke test URL'ini `http://techstore-app:5000` yap |
| Slack webhook null credential | `slack-webhook` ID'li credential yok | Jenkins → Credentials → Add Secret Text, ID=`slack-webhook` |

---

## 📚 Pipeline Düzeltme Tarihçesi

İlk uçtan uca yeşil pipeline'a ulaşana kadar yapılan düzeltmeler:

1. `pytest-cov` requirements.txt'e eklendi (Unit Tests --cov flag tanınmıyordu)
2. `pytest.ini` oluşturuldu (pythonpath ile app modülü bulunsun)
3. Jenkinsfile'da `coberturaAdapter` → `archiveArtifacts` (plugin yok)
4. `SONAR_HOST`: `localhost:9000` → `sonarqube:9000` (compose DNS)
5. Smoke test: `localhost:5000` → `techstore-app:5000` (compose DNS)
6. Deploy stage: container compose network'üne dahil edildi
7. Slack: plugin yerine curl + webhook (`slackSend` → `withCredentials + sh curl`)
