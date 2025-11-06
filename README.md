# PCM & DRU Dosya Dönüştürücü

PCM304 yazılımı için .pcm ve .dru dosyalarını metin formatına çevirip düzenledikten sonra geri binary/text formatına dönüştürmek için araçlar.

## 🎯 Hızlı Başlangıç

### PCM Dosyası (.pcm → JSON → .pcm)

**PowerShell ile** (Python gerektirmez):

```powershell
# PCM'i JSON'a çevir
.\tools\pcm_tool.ps1 export -PcmFile "PCM-machine-reverse-engineering\D347-25.pcm" -OutFile "out\D347-25.json"

# JSON'u düzenle (VS Code, Notepad++ vs.)

# Yeni PCM oluştur
.\tools\pcm_tool.ps1 build -JsonFile "out\D347-25.json" -OutFile "D347-25_yeni.pcm"
```

**Python ile** (Python 3.8+):

```powershell
python tools/pcm_tool.py export "PCM-machine-reverse-engineering\D347-25.pcm" --out "out\D347-25.json"
python tools/pcm_tool.py build --json "out\D347-25.json" --out "D347-25_yeni.pcm"
```

### DRU Dosyası (.dru → CSV → .dru)

```powershell
# DRU'yu CSV'lere ayır
python tools/dru_tool.py export D347-25.dru --outdir out

# CSV'leri düzenle (Excel, LibreOffice vs.)
# out/summary.csv ve out/grafik.csv

# Yeni DRU oluştur
python tools/dru_tool.py build --summary out/summary.csv --grafik out/grafik.csv --out D347-25_yeni.dru
```

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
- **Test Verisi**: Şu an ham hex olarak saklanıyor. Gerçek test verilerini (kuvvet, cetvel değerleri vs.) parse etmek için ileri geliştirme yapılabilir.

---

## 📊 DRU Dosyası Detayları

DRU dosyası düz metin (text) formatındadır ancak Windows-1254 kodlama ve TAB ayracı kullanır.

### Yapı

1. **Özet Tablosu** (summary.csv):
   - İlk iki satır: Başlıklar ve birimler
   - Sonraki satırlar: Test özeti (Test no, Test tipi, Çap, Sınıf, Boy, Kütle, Akma, Çekme, vb.)

2. **Grafik Verisi** (grafik.csv):
   - "Grafik" satırından sonra başlar
   - Zaman-serisi verisi: Zaman, Kuvvet(N), Cetvel(mm), Kanal3, Kanal4

### Kullanım

```powershell
# Export
python tools/dru_tool.py export D347-25.dru --outdir out

# CSV'leri Excel ile düzenle (UTF-8 BOM ile kaydedilir, Türkçe karakterler sorunsuz)

# Build
python tools/dru_tool.py build --summary out/summary.csv --grafik out/grafik.csv --out D347-25_yeni.dru
```

### Format Notları

- DRU yazarken **cp1254** kodlama kullanılır (PCM304 programı için)
- CSV'ler **UTF-8 BOM** ile yazılır (Excel uyumluluğu için)
- Ayraç: TAB (\t)
- Sayısal değerlerde nokta (.) ondalık ayırıcı olarak kalmalıdır

---

## 🔍 Keşif Aracı (pcm_dump.py)

Bilinmeyen PCM formatlarını incelemek için hex döküm aracı:

```powershell
python tools/pcm_dump.py .\ornek.pcm --outdir out_pcm
```

Çıktı:
- Hex dökümü (ilk/son 256 bayt)
- ASCII ve cp1254 string'ler
- Rapor dosyası: `out_pcm\ornek.pcm.report.txt`

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
│   ├── pcm_tool.ps1      # PowerShell PCM dönüştürücü (Python gerektirmez)
│   ├── pcm_tool.py       # Python PCM dönüştürücü
│   ├── dru_tool.py       # DRU dönüştürücü
│   └── pcm_dump.py       # Hex döküm/analiz aracı
├── PCM-machine-reverse-engineering/
│   └── D347-25.pcm       # Örnek PCM dosyası
└── README.md             # Bu dosya
```

---

## ❓ SSS

**S: PCM dosyasındaki test verilerini (kuvvet, uzama vs.) düzenleyebilir miyim?**  
A: Şu an test_data_raw_hex alanı ham hex formatında. İleri versiyonlarda bu alanı parse edip yapılandırılmış JSON'a çevirebiliriz. Şimdilik sadece başlık alanları düzenlenebilir.

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
