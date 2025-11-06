param(
    [Parameter(Mandatory=$true)]
    [string]$DetayliJson,

    [Parameter(Mandatory=$true)]
    [string]$FallbackJson,

    [Parameter(Mandatory=$true)]
    [string]$OutJson,

    [Parameter(Mandatory=$false)]
    [string]$OutPcm
)

Write-Host "Detaylı JSON okunuyor: $DetayliJson" -ForegroundColor Cyan
$dj = Get-Content -Encoding UTF8 -Raw $DetayliJson | ConvertFrom-Json

if (-not $dj -or -not $dj.pcm_header) {
    throw "Detaylı JSON beklenen yapıda değil (pcm_header yok)."
}

Write-Host "Temel JSON (test verisi) okunuyor: $FallbackJson" -ForegroundColor Cyan
$fj = Get-Content -Encoding UTF8 -Raw $FallbackJson | ConvertFrom-Json

if (-not $fj) {
    throw "Fallback JSON okunamadı."
}

$h = $dj.pcm_header

# Birleşik (pcm_tool.ps1 build ile uyumlu) JSON nesnesi oluştur
$combined = [ordered]@{
    header = $h.header
    version_bytes_hex = $fj.version_bytes_hex
    test_count = $h.test_count
    numune_no = $h.numune_no
    tarih = $h.tarih
    test_standarti = $h.test_standarti
    laboratuvar = $h.laboratuvar
    malzeme_kodu = $h.malzeme_kodu
    musteri_no = $h.musteri_no
    test_data_raw_hex = $fj.test_data_raw_hex
    _source = "detayli:pca_header + fallback:test_data/version"
    _created = (Get-Date -Format "yyyy-MM-dd HH:mm:ss")
}

$outDir = Split-Path -Parent $OutJson
if ($outDir -and -not (Test-Path $outDir)) {
    New-Item -ItemType Directory -Path $outDir -Force | Out-Null
}

$combined | ConvertTo-Json -Depth 5 | Out-File -Encoding UTF8 $OutJson
Write-Host "Birleşik JSON yazıldı: $OutJson" -ForegroundColor Green

if ($OutPcm) {
    $toolsPath = Join-Path (Split-Path -Parent $PSCommandPath) 'pcm_tool.ps1'
    Write-Host "PCM oluşturuluyor: $OutPcm" -ForegroundColor Cyan
    powershell -ExecutionPolicy Bypass -File $toolsPath build -JsonFile $OutJson -OutFile $OutPcm
}
