param(
  [Parameter(Mandatory=$true)] [string]$PcmFile,
  [Parameter(Mandatory=$true)] [string]$DruFile,
  [string]$OutDir = "out",
  [string]$PatchCsv
)

$ErrorActionPreference = 'Stop'

function New-DirIfMissing($p) { if (!(Test-Path $p)) { New-Item -ItemType Directory -Path $p | Out-Null } }

New-DirIfMissing $OutDir

$pcmBaseJson = Join-Path $OutDir ("{0}.json" -f [IO.Path]::GetFileNameWithoutExtension($PcmFile))
$detayliJson = Join-Path $OutDir ("{0}_detayli.json" -f [IO.Path]::GetFileNameWithoutExtension($PcmFile))
$fromDetayliJson = Join-Path $OutDir ("{0}_from_detayli.json" -f [IO.Path]::GetFileNameWithoutExtension($PcmFile))
$fromDetayliPcm  = Join-Path $OutDir ("{0}_from_detayli.pcm"  -f [IO.Path]::GetFileNameWithoutExtension($PcmFile))
$patchedPcm      = Join-Path $OutDir ("{0}_kopma_batch.pcm"     -f [IO.Path]::GetFileNameWithoutExtension($PcmFile))

Write-Host "[1/4] PCM → JSON (base)" -ForegroundColor Cyan
powershell -ExecutionPolicy Bypass -File (Join-Path $PSScriptRoot 'pcm_tool.ps1') `
  export -PcmFile $PcmFile -OutFile $pcmBaseJson

Write-Host "[2/4] PCM+DRU → detaylı JSON" -ForegroundColor Cyan
powershell -ExecutionPolicy Bypass -File (Join-Path $PSScriptRoot 'pcm_dru_kombine.ps1') `
  -PcmFile $PcmFile -DruFile $DruFile -OutFile $detayliJson

Write-Host "[3/4] Detaylı JSON → PCM (başlık koruma)" -ForegroundColor Cyan
powershell -ExecutionPolicy Bypass -File (Join-Path $PSScriptRoot 'detayli_to_pcm.ps1') `
  -DetayliJson $detayliJson -FallbackJson $pcmBaseJson -OutJson $fromDetayliJson -OutPcm $fromDetayliPcm

if ($PatchCsv -and (Test-Path $PatchCsv)) {
  Write-Host "[4/4] Toplu yama (kopma_uzamasi) uygulanıyor" -ForegroundColor Cyan
  powershell -ExecutionPolicy Bypass -File (Join-Path $PSScriptRoot 'batch_patch_kopma.ps1') `
    -PcmFile $fromDetayliPcm -ChangesCsv $PatchCsv -OutFile $patchedPcm
}
else {
  Write-Host "[4/4] Toplu yama atlandı (CSV verilmedi)" -ForegroundColor Yellow
}

Write-Host "\nTamamlandı. Çıktılar:" -ForegroundColor Green
Get-ChildItem $OutDir | Where-Object { $_.Name -match ([IO.Path]::GetFileNameWithoutExtension($PcmFile)) } | `
  Select-Object Name, Length | Format-Table -AutoSize

Write-Host "\nİpucu: Otomatik testi çalıştırmak için: tools\\test_kopma_batch_patch.ps1" -ForegroundColor DarkGray
