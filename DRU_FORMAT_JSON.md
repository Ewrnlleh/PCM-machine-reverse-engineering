# 🎯 PCM Dosyalarını DRU Formatında Görüntüleme

## Hızlı Kullanım

DRU dosyasındaki gibi detaylı test bilgilerini JSON formatında görmek için:

```powershell
powershell -ExecutionPolicy Bypass -File "tools\pcm_dru_kombine.ps1" `
  -PcmFile "D347-25.pcm" `
  -DruFile "D347-25.dru" `
  -OutFile "out\D347-25_detayli.json"
```

## JSON İçeriği

Oluşturulan JSON dosyası 3 ana bölüm içerir:

### 1. PCM Header Bilgileri
```json
{
  "pcm_header": {
    "header": "PCM304 V7.2.11_",
    "test_count": 11521,
    "numune_no": "DN347-25",
    "tarih": "26.08.25",
    "test_standarti": "EMİR ÇEKME",
    "musteri_no": "3742702213"
  }
}
```

### 2. Test Özeti (DRU formatından)
Her test için detaylı bilgiler:

```json
{
  "test_summary": [
    {
      "test_no": "1 / 1",
      "test_tipi": "Demir çekme",
      "anma_capi": "8.00",
      "sinifi": "B 420C",
      "ilk_boy": "80.00",
      "kutle": "30.88",
      "birim_kutle": "0.39",
      "akma": "492.00",
      "cekme": "587.40",
      "cekme_akma": "1.19",
      "kopma_uzamasi": "22.27"
    },
    ...9 test daha...
  ]
}
```

**Test Özeti Alanları:**
- `test_no`: Test numarası
- `test_tipi`: Test tipi (örn: "Demir çekme")
- `anma_capi`: Anma çapı (mm)
- `sinifi`: Malzeme sınıfı (örn: "B 420C")
- `ilk_boy`: İlk boy (mm)
- `kutle`: Kütle (kg)
- `birim_kutle`: Birim kütle (kg/M)
- `akma`: Akma mukavemeti (N/mm²)
- `cekme`: Çekme mukavemeti (N/mm²)
- `cekme_akma`: Çekme/Akma oranı
- `kopma_uzamasi`: Kopma uzaması (%)

### 3. Grafik Verisi (Zaman Serisi)
Her test için zamana bağlı ölçüm verileri:

```json
{
  "test_grafik": {
    "1 / 1": [
      {
        "zaman": "0.1",
        "kuvvet_n": "5024",
        "cetvel_mm": "0",
        "kanal3": "0",
        "kanal4": "0"
      },
      ...binlerce veri noktası...
    ],
    "1 / 2": [...],
    ...diğer testler...
  }
}
```

**Grafik Verisi Alanları:**
- `zaman`: Zaman (saniye)
- `kuvvet_n`: Uygulanan kuvvet (Newton)
- `cetvel_mm`: Cetvel okuması (mm) - uzama
- `kanal3`, `kanal4`: Ek ölçüm kanalları

## İstatistikler

Örnek dosya için:
- ✅ **9 test** (farklı çaplarda demir çekme testleri)
- ✅ **13,278 veri noktası** (tüm testlerin grafik verisi)
- ✅ **PCM header bilgileri** (numune no, tarih, test standardı vb.)

## Veri Analizi Örnekleri

### PowerShell ile

```powershell
# JSON'ı oku
$data = Get-Content "out\D347-25_detayli.json" -Raw | ConvertFrom-Json

# Tüm testlerin akma değerlerini listele
$data.test_summary | Select-Object test_no, akma, cekme

# Test 1/1'in maksimum kuvvetini bul
$maxKuvvet = ($data.test_grafik.'1 / 1'.kuvvet_n | Measure-Object -Maximum).Maximum
Write-Host "Test 1/1 maksimum kuvvet: $maxKuvvet N"

# Ortalama kopma uzamasını hesapla
$ortalamaUzama = ($data.test_summary.kopma_uzamasi | Measure-Object -Average).Average
Write-Host "Ortalama kopma uzaması: $ortalamaUzama %"
```

### Python ile

```python
import json

# JSON'ı oku
with open("out/D347-25_detayli.json", "r", encoding="utf-8") as f:
    data = json.load(f)

# Tüm testlerin çekme mukavemetini yazdır
for test in data["test_summary"]:
    print(f"{test['test_no']}: {test['cekme']} N/mm²")

# Test 1/1'in grafik verisini analiz et
test_1_1 = data["test_grafik"]["1 / 1"]
kuvvetler = [float(p["kuvvet_n"]) for p in test_1_1]
print(f"Maksimum kuvvet: {max(kuvvetler)} N")
```

## Excel'de Kullanım

1. JSON dosyasını Excel'de aç (Veri → JSON'dan)
2. `test_summary` tablosunu seç → detaylı test bilgilerini göreceksiniz
3. `test_grafik` verilerini seç → grafik çizmek için kullanabilirsiniz

## Yama: kopma_uzamasi ve diğer özet değerleri

Detaylı JSON'daki `test_summary` alanlarını (örn. `kopma_uzamasi: 23.49`) değiştirdiğinizde, bu değerlerin PCM dosyasında da değişmesini istiyorsanız:

```powershell
# CSV oluştur (old,new)
@"
old,new
23.49,30.00
24.65,29.00
"@ | Out-File -Encoding UTF8 .\out\kopma_changes.csv

# Toplu yama uygula
powershell -ExecutionPolicy Bypass -File .\tools\batch_patch_kopma.ps1 `
  -PcmFile .\out\D347-25_from_detayli.pcm `
  -ChangesCsv .\out\kopma_changes.csv `
  -OutFile .\out\D347-25_kopma_batch.pcm
```

⚠️ **Not**: Yama aracı, değerleri 32-bit little-endian tamsayı (değer×100) olarak arayıp değiştirir. Bu, PCM formatının tam reverse-engineering'i değil, heuristik bir yöntemdir. Diğer alanlar (akma, çekme) için benzer varsayımlar geçerli olabilir; gelişmiş destek sonraki fazdır.

## Notlar

- ✅ **Türkçe karakter desteği**: JSON UTF-8 formatında, Türkçe karakterler doğru görünür
- ✅ **DRU ile tam uyumlu**: DRU dosyasındaki tüm bilgiler JSON'da mevcut
- ✅ **PCM header eklendi**: DRU'da olmayan PCM bilgileri de eklendi
- ⚠️ **Büyük dosyalar**: Grafik verisi çok büyük olabilir (10,000+ satır)
- ⚠️ **Yama heuristik**: kopma_uzamasi için patch varsayım temelli; formatın tam dökümanı mevcut değil

## Sorun Giderme

### "Get-Content" hatası
PowerShell 5.1 kullanıyorsanız, büyük JSON dosyaları için:
```powershell
[System.IO.File]::ReadAllText("out\D347-25_detayli.json") | ConvertFrom-Json
```

### Türkçe karakterler bozuk
JSON dosyası UTF-8 BOM ile kaydedildi. Not Defteri yerine VS Code veya modern editör kullanın.

### Veri noktaları eksik
DRU dosyası tam okunamamış olabilir. Dosyanın cp1254 (Windows-1254) kodlamasında olduğundan emin olun.

---

**İhtiyacınız olan her bilgi artık tek bir JSON dosyasında!** 🎉
