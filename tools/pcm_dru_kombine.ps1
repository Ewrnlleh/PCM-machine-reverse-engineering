# PCM + DRU -> Detaylı JSON Dönüştürücü
# DRU dosyasındaki gibi test bilgilerini JSON'da gösterir

param(
    [Parameter(Mandatory=$true)]
    [string]$PcmFile,
    
    [Parameter(Mandatory=$true)]
    [string]$DruFile,
    
    [Parameter(Mandatory=$true)]
    [string]$OutFile
)

function Read-PcmString {
    param($bytes, $offset, $maxLen)
    $end = $offset
    while ($end -lt ($offset + $maxLen) -and $end -lt $bytes.Length -and $bytes[$end] -ne 0) {
        $end++
    }
    $str = [System.Text.Encoding]::GetEncoding(1254).GetString($bytes[$offset..($end-1)])
    return $str.Trim()
}

function Parse-PcmHeader {
    param($path)
    
    $data = [System.IO.File]::ReadAllBytes($path)
    
    $header = [System.Text.Encoding]::ASCII.GetString($data[0..15]).TrimEnd([char]0)
    $testCount = [BitConverter]::ToInt32($data, 0x38)
    
    $numuneNo = Read-PcmString $data 0x5E 30
    $tarih = Read-PcmString $data 0x7C 20
    $testStandarti = Read-PcmString $data 0x90 40
    $laboratuvar = Read-PcmString $data 0xB8 80
    $malzemeKodu = Read-PcmString $data 0x150 50
    $musteriNo = Read-PcmString $data 0x19E 40
    
    return @{
        header = $header
        test_count = $testCount
        numune_no = $numuneNo
        tarih = $tarih
        test_standarti = $testStandarti
        laboratuvar = $laboratuvar
        malzeme_kodu = $malzemeKodu
        musteri_no = $musteriNo
    }
}

function Parse-DruFile {
    param($path)
    
    $lines = Get-Content $path -Encoding Default
    $tests = @()
    $grafik = @{}
    $mode = "header"
    
    foreach ($line in $lines) {
        $line = $line.Trim()
        if (-not $line) { continue }
        
        if ($line -match "^Grafik") {
            $mode = "grafik"
            continue
        }
        
        if ($mode -eq "header") {
            # Başlık satırlarını atla
            if ($line -match "^Test no" -or $line -match "^\( \)") {
                continue
            }
            
            # Test satırını parse et
            $parts = $line -split "`t"
            if ($parts.Length -ge 11) {
                $test = @{
                    test_no = $parts[0].Trim()
                    test_tipi = $parts[1].Trim()
                    anma_capi = $parts[2].Trim()
                    sinifi = $parts[3].Trim()
                    ilk_boy = $parts[4].Trim()
                    kutle = $parts[5].Trim()
                    birim_kutle = $parts[6].Trim()
                    akma = $parts[7].Trim()
                    cekme = $parts[8].Trim()
                    cekme_akma = $parts[9].Trim()
                    kopma_uzamasi = $parts[10].Trim()
                }
                $tests += $test
            }
        }
        elseif ($mode -eq "grafik") {
            # Grafik başlığını atla
            if ($line -match "^Test no") {
                continue
            }
            
            # Grafik verisini parse et
            $parts = $line -split "`t"
            if ($parts.Length -ge 6) {
                $testNo = $parts[0].Trim()
                if (-not $grafik.ContainsKey($testNo)) {
                    $grafik[$testNo] = @()
                }
                
                $dataPoint = @{
                    zaman = $parts[1].Trim()
                    kuvvet_n = $parts[2].Trim()
                    cetvel_mm = $parts[3].Trim()
                    kanal3 = $parts[4].Trim()
                    kanal4 = $parts[5].Trim()
                }
                $grafik[$testNo] += $dataPoint
            }
        }
    }
    
    return @{
        tests = $tests
        grafik = $grafik
    }
}

# Ana işlem
Write-Host "PCM dosyası okunuyor: $PcmFile" -ForegroundColor Cyan
$pcmInfo = Parse-PcmHeader $PcmFile

Write-Host "DRU dosyası okunuyor: $DruFile" -ForegroundColor Cyan
$druInfo = Parse-DruFile $DruFile

# Birleştir
$combined = @{
    pcm_header = $pcmInfo
    test_summary = $druInfo.tests
    test_grafik = $druInfo.grafik
    _note = "Bu dosya PCM ve DRU dosyalarından birleştirilerek oluşturuldu"
    _format_version = "PCM304_V7.2.11"
    _created = (Get-Date -Format "yyyy-MM-dd HH:mm:ss")
}

Write-Host "`nJSON oluşturuluyor: $OutFile" -ForegroundColor Cyan

# Klasör yoksa oluştur
$outDir = Split-Path -Parent $OutFile
if ($outDir -and -not (Test-Path $outDir)) {
    New-Item -ItemType Directory -Path $outDir -Force | Out-Null
}

# JSON'a çevir ve kaydet
$combined | ConvertTo-Json -Depth 10 | Out-File -Encoding UTF8 $OutFile

Write-Host "`n✅ Tamamlandı!" -ForegroundColor Green
Write-Host "  - PCM header bilgileri: OK"
Write-Host "  - Test özeti: $($druInfo.tests.Count) test"
$totalPoints = ($druInfo.grafik.Values | ForEach-Object { $_.Count } | Measure-Object -Sum).Sum
Write-Host "  - Grafik verisi: $totalPoints veri noktası"
Write-Host "`nDosya: $OutFile"
