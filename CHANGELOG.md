# Değişiklik Geçmişi

## [2.0.0] - 2025-11-06

### ✨ Yeni Özellikler

- **Detaylı JSON desteği**: PCM + DRU birleşik format (`pcm_dru_kombine.ps1`, `pcm_to_dru_format.py`)
- **Toplu yama aracı**: kopma_uzamasi değerlerini CSV ile değiştirme (`batch_patch_kopma.ps1`)
- **Otomatik test**: Yama işlemlerini doğrulayan test script'i (`test_kopma_batch_patch.ps1`)
- **Uçtan-uca orkestrasyon**: Tek komutla tüm akışı çalıştırma (`run_all.ps1`)
- **Detaylı JSON → PCM**: Birleşik JSON'dan PCM üretme (`detayli_to_pcm.ps1`)

### 🔧 İyileştirmeler

- **Header koruma**: `version_bytes_hex` alanı ile sürüm byte'ları tam korunuyor
- **Round-trip doğrulama**: PCM → JSON → PCM boyut eşleşmesi %100
- **Dokümantasyon**: README ve DRU_FORMAT_JSON kapsamlı güncelleme
- **Proje yapısı**: Eski dosyalar `legacy/` klasörüne taşındı

### 📝 Dokümantasyon

- README: Toplu yama, detaylı JSON, uçtan-uca akış ve SSS eklendi
- DRU_FORMAT_JSON: Yama mekanizması ve heuristik notları eklendi
- CHANGELOG: Bu dosya eklendi

### 🗂️ Proje Yapısı

- `tools/`: Tüm araçlar (7 PowerShell + 2 Python script)
- `out/`: Çıktı klasörü
- `legacy/`: Eski EXE, config ve güncelliği geçmiş dokümanlar
- Ana klasör: Örnek PCM/DRU dosyaları ve dokümanlar

---

## [1.0.0] - 2025-11-05

### İlk Sürüm

- PCM ↔ JSON dönüştürücü (`pcm_tool.ps1`, `pcm_tool.py`)
- Temel format keşfi ve reverse-engineering
- Windows-1254 (cp1254) kodlama desteği
- Türkçe karakter uyumluluğu
