# PCM & DRU Dönüştürücü ve Yama Araçları

PCM304 için .pcm/.dru dosyalarını okunabilir JSON'a çevirir, düzenler ve tekrar .pcm üretir; ayrıca DRU tarzı detaylı JSON ve toplu değer yama (kopma_uzaması vb.) desteği sağlar.

## 🎯 Hızlı Başlangıç

### ⭐ YENİ: PCM + DRU Birleşik Detaylı JSON (ÖNERİLEN)

DRU dosyasındaki **tüm test bilgilerini** (akma, çekme, grafik verisi vb.) içeren detaylı JSON:

```powershell
# PCM ve DRU'yu birleştir - detaylı JSON oluştur
powershell -ExecutionPolicy Bypass -File "tools\pcm_dru_kombine.ps1" `
  -PcmFile "D347-25.pcm" `
  -DruFile "D347-25.dru" `
  -OutFile "out\D347-25_detayli.json"
```

Bu JSON içerir:
- ✅ PCM header bilgileri (numune no, tarih, test standardı)
- ✅ **9 testin özet bilgileri** (çap, akma, çekme, kopma uzaması vb.)
- ✅ **13,000+ veri noktası** (zaman-kuvvet-uzama grafik verisi)

📖 Detaylı kullanım: [DRU_FORMAT_JSON.md](DRU_FORMAT_JSON.md)

---

### PCM Dosyası (.pcm → JSON → .pcm)

**PowerShell ile** (Python gerektirmez):

```powershell
# PCM'i JSON'a çevir
.\tools\pcm_tool.ps1 export -PcmFile "D347-25.pcm" -OutFile "out\D347-25.json"

# JSON'u düzenle (VS Code, Notepad++ vs.)

# Yeni PCM oluştur
.\tools\pcm_tool.ps1 build -JsonFile "out\D347-25.json" -OutFile "D347-25_yeni.pcm"
```

Not: Python alternatifi de mevcuttur (`tools/pcm_tool.py`).

### DRU Tarzı Görünüm (Detaylı JSON)

DRU dosyasındaki tablo ve grafik görüntüsünü JSON'da almak için üstteki birleşik komutu kullanın. Ayrıntı: [DRU_FORMAT_JSON.md](DRU_FORMAT_JSON.md)

Python alternatifi: `tools/pcm_to_dru_format.py` aynı çıktı yapısını üretir.

---

## 📋 PCM Dosyası Detayları

### Ne Düzenlenebilir?

PCM dosyasını JSON'a çevirdiğinizde şu alanları düzenleyebilirsiniz:

- **numune_no**: Numune numarası (örn. "D347-25")
- **tarih**: Test tarihi (örn. "26.08.25")
- **test_standarti**: Test standardı (örn. "TS 708 DEMİR ÇEKME")
- **laboratuvar**: Laboratuvar adı
- **malzeme_kodu**: Malzeme/proje kodu
- **musteri_no**: Müşteri numarası
- **test_count**: Test sayısı
- **test_data_raw_hex**: Ham test verileri (hex formatında)

### JSON Örneği

```json
{
  "header": "PCM304 V7.2.11_",
  "version_bytes_hex": "0701010000000000",
  "test_count": 301,
  "numune_no": "D347-25",
  "tarih": "26.08.25",
  "test_standarti": "TS 708 DEMİR ÇEKME",
  "laboratuvar": "GÜNEŞ YAPI MALZEMELERİ LABORATUVARI",
  "malzeme_kodu": "BEŞKAVAKLAR MAH.BOLU",
  "musteri_no": "3742702213",
  "test_data_raw_hex": "0001020304..."
}
```

### Önemli Notlar

- **Kodlama**: PCM dosyaları Windows-1254 (cp1254) Türkçe kodlama kullanır
- **Alan Uzunlukları**: Her alanın maksimum uzunluğu vardır (fazlası kesilir):
  - numune_no: 30 karakter
  - tarih: 20 karakter
  - test_standarti: 40 karakter
  - laboratuvar: 80 karakter
  - malzeme_kodu: 50 karakter
  - musteri_no: 40 karakter
- **Version baytları**: Artık otomatik korunuyor (`version_bytes_hex`); yeniden inşada başlık birebir eşleşir.
- **Test verisi**: Şu an ham hex olarak saklanıyor. Gerçek test verilerini (kuvvet, cetvel değerleri vs.) parse etmek ileri geliştirme kapsamındadır.

---

## 🔧 Detaylı JSON → PCM (başlık koruyarak)

Detaylı JSON'daki `pcm_header` alanlarını, temel JSON'daki sürüm/test verisiyle birleştirip yeni PCM üretmek için:

```powershell
powershell -ExecutionPolicy Bypass -File .\tools\detayli_to_pcm.ps1 `
  -DetayliJson .\out\D347-25_detayli.json `
  -FallbackJson .\out\D347-25.json `
  -OutJson .\out\D347-25_from_detayli.json `
  -OutPcm .\out\D347-25_from_detayli.pcm
```

---

## 🩹 Toplu Yama: kopma_uzamasi (örn. 23.49 → 30.00)

DRU özetindeki kopma_uzamasi değerlerini PCM içinde güncellemek için toplu yama aracı:

1) CSV oluşturun (old,new):

```powershell
@"
old,new
23.49,30.00
24.65,29.00
"@ | Out-File -Encoding UTF8 .\out\kopma_changes.csv
```

2) Toplu yama:

```powershell
powershell -ExecutionPolicy Bypass -File .\tools\batch_patch_kopma.ps1 `
  -PcmFile .\out\D347-25_from_detayli.pcm `
  -ChangesCsv .\out\kopma_changes.csv `
  -OutFile .\out\D347-25_kopma_batch.pcm
```

3) Otomatik test:

```powershell
powershell -ExecutionPolicy Bypass -File .\tools\test_kopma_batch_patch.ps1
```

Notlar:
- Yama, değerleri 32‑bit little-endian tamsayı (değer×100) olarak arayıp değiştirir.
- Gerekirse `-SearchStart`/`-SearchLength` ile arama aralığını sınırlayabilirsiniz.

---

## 📊 DRU Dosyası Detayları (Detaylı JSON üzerinden)

DRU dosyası düz metin (text) formatındadır ancak Windows-1254 kodlama ve TAB ayracı kullanır.

### Yapı

1. **Özet Tablosu** (summary.csv):
   - İlk iki satır: Başlıklar ve birimler
   - Sonraki satırlar: Test özeti (Test no, Test tipi, Çap, Sınıf, Boy, Kütle, Akma, Çekme, vb.)

2. **Grafik Verisi** (grafik.csv):
   - "Grafik" satırından sonra başlar
   - Zaman-serisi verisi: Zaman, Kuvvet(N), Cetvel(mm), Kanal3, Kanal4

### Kullanım

Detaylı JSON kullanarak DRU verilerine denk düşen özet ve grafik bilgilerini analiz edebilirsiniz (bkz. DRU_FORMAT_JSON.md).

### Format Notları

- DRU yazarken **cp1254** kodlama kullanılır (PCM304 programı için)
- CSV'ler **UTF-8 BOM** ile yazılır (Excel uyumluluğu için)
- Ayraç: TAB (\t)
- Sayısal değerlerde nokta (.) ondalık ayırıcı olarak kalmalıdır

---

## 🔍 İsteğe Bağlı

Python alternatifi ve analiz yardımcıları: `tools/pcm_tool.py`, `tools/pcm_to_dru_format.py`.

---

## 🛠️ Gereksinimler

- **PowerShell**: Windows 10/11 varsayılan (pcm_tool.ps1 için)
- **Python 3.8+**: Opsiyonel (Python araçları için)
  - Harici kütüphane gerektirmez (sadece standart kütüphane)

---

## 📂 Dosya Yapısı

```
.
├── tools/
│   ├── pcm_tool.ps1              # PCM <-> JSON (PowerShell)
│   ├── pcm_tool.py               # PCM <-> JSON (Python alternatifi)
│   ├── pcm_dru_kombine.ps1       # PCM+DRU -> detaylı JSON
│   ├── pcm_to_dru_format.py      # (Python) eşdeğer detaylı JSON
│   ├── detayli_to_pcm.ps1        # Detaylı JSON + fallback JSON -> PCM
│   ├── patch_kopma_value.ps1     # Tekil kopma_uzamasi yaması
│   └── batch_patch_kopma.ps1     # Toplu kopma_uzamasi yaması (CSV)
├── D347-25.pcm
├── D347-25.dru
└── README.md
```

---

## ❓ SSS

**S: PCM dosyasındaki test verilerini (kuvvet, uzama vs.) düzenleyebilir miyim?**  
A: Ham veriyi henüz yapılandırmıyoruz; ancak DRU özetindeki kopma_uzamasi için toplu/tekil yama araçları vardır. Gelişmiş tam-pars etme sonraki fazdır.

**S: Python kurulu değil, ne yapmalıyım?**  
A: PCM dosyaları için `pcm_tool.ps1` PowerShell betiğini kullanın (Python gerektirmez). DRU için Python gerekli.

**S: Değiştirdiğim PCM dosyasını PCM304 programı okuyamıyor?**  
A: JSON'daki alan uzunluklarını kontrol edin. Çok uzun metinler kesilir ama JSON formatı bozuksa hata verir.

**S: GitHub reposu boş, neden?**  
A: Klonlanan repo boştu, formatı tersine mühendislik yaparak çözdüm. İsterseniz bulgularımızı oraya commit edebiliriz.

---

## 🚀 İleri Geliştirmeler

- [ ] Test verilerini (kuvvet-cetvel grafiği) parse edip CSV'ye çıkartma
- [ ] PCM → DRU otomatik dönüşümü
- [ ] Grafik çizim (matplotlib ile)
- [ ] GUI arayüz (tkinter/PyQt)
- [ ] Toplu (batch) işlem desteği

---

## 📝 Lisans

MIT (kişisel kullanım için)

## 🤝 Katkı

Sorularınız veya önerileriniz için GitHub Issues kullanabilirsiniz.

---

**Son Güncelleme**: 6 Kasım 2025  
**Format**: PCM304 V7.2.11  
**Durum**: Çalışıyor ✅
