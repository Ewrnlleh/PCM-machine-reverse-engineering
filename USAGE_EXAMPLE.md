# PCM Dosyası Düzenleme Örneği

## Hızlı Başlangıç

PCM dosyalarını JSON formatına dönüştürüp düzenleyebilir ve tekrar PCM formatına çevirebilirsiniz.

### 1. PCM → JSON (Dışa Aktarma)

```powershell
# PowerShell ile
powershell -ExecutionPolicy Bypass -File "tools\pcm_tool.ps1" export -PcmFile "D347-25.pcm" -OutFile "out\D347-25.json"
```

### 2. JSON'ı Düzenleyin

`out\D347-25.json` dosyasını bir metin editörü ile açın. Düzenleyebileceğiniz alanlar:

```json
{
    "test_count": 11521,
    "numune_no": "DN347-25",
    "tarih": "26.08.25",
    "test_standarti": "TS 708 DEMİR ÇEKME",
    "laboratuvar": "",
    "malzeme_kodu": "",
    "musteri_no": "3742702213"
}
```

**Önemli Notlar:**
- `numune_no`: Maksimum 30 karakter
- `tarih`: Maksimum 20 karakter  
- `test_standarti`: Maksimum 40 karakter
- `laboratuvar`: Maksimum 80 karakter
- `malzeme_kodu`: Maksimum 50 karakter
- `musteri_no`: Maksimum 40 karakter
- `test_data_raw_hex`: Test verilerinin ham hexadecimal formatı - **düzenlemeyin!**

### 3. JSON → PCM (İçe Aktarma)

```powershell
# PowerShell ile
powershell -ExecutionPolicy Bypass -File "tools\pcm_tool.ps1" build -JsonFile "out\D347-25.json" -OutFile "out\D347-25_yeni.pcm"
```

## Örnek: Numune Numarasını Değiştirme

1. **Dışa aktar:**
   ```powershell
   powershell -ExecutionPolicy Bypass -File "tools\pcm_tool.ps1" export -PcmFile "D347-25.pcm" -OutFile "out\test.json"
   ```

2. **JSON'da düzenle:**
   ```json
   {
       "numune_no": "D347-25-KOPYA",
       ...
   }
   ```

3. **Yeni PCM oluştur:**
   ```powershell
   powershell -ExecutionPolicy Bypass -File "tools\pcm_tool.ps1" build -JsonFile "out\test.json" -OutFile "out\D347-25-KOPYA.pcm"
   ```

## Bilinen Sınırlamalar

### Küçük Format Farklılıkları
Şu anda araçlar neredeyse mükemmel bir dönüşüm sağlıyor. Sadece birkaç bayt fark olabilir:

- **Header version byte'ları**: Dosya yine de PCM304 V7.2.11 tarafından açılabilir
- **Bazı alan prefix'leri**: İç format farkları var ama işlevselliği etkilemiyor

### Round-Trip Test Sonuçları

Orijinal dosya ile dönüştürülmüş dosya karşılaştırması:
- ✅ **Dosya boyutu**: %100 aynı (753,120 bayt)
- ✅ **Test sayısı**: Doğru okunuyor (11,521 veri noktası)
- ✅ **Tüm metin alanları**: Doğru okunuyor ve yazılıyor
- ✅ **Test verileri**: Tam olarak korunuyor
- ⚠️ **Header detayları**: ~3 bayt fark (version pattern) - işlevselliği etkilemiyor

## Sorun Giderme

### "Could not find file" Hatası
Tam yol kullanın veya doğru klasördeyseniz emin olun:
```powershell
cd "C:\Users\Can\Desktop\PCM to text\PCM-machine-reverse-engineering"
```

### Türkçe Karakter Sorunları
PowerShell araçları Windows-1254 (Türkçe) kodlamasını destekler. JSON dosyası UTF-8 olarak kaydedilir.

### Test Verilerini Düzenlemek
Şu anda `test_data_raw_hex` alanı ham hexadecimal formatındadır. Gelecek sürümlerde yapılandırılmış format eklenebilir.

## Ek Bilgiler

- **PCM Format Versiyonu**: PCM304 V7.2.11
- **Kodlama**: Windows-1254 (cp1254) - Türkçe karakter desteği
- **Test Count**: Dosyadaki toplam force/displacement ölçüm sayısı (11,521 gibi değerler normaldir)

## Güvenlik

⚠️ **Önemli**: Orijinal PCM dosyalarınızın yedeğini alın! Düzenlenmiş dosyalar test edilmeden üretim ortamında kullanılmamalıdır.
