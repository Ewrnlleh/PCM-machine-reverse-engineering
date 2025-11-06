# Automated test for tools/batch_patch_kopma.ps1
param(
  [string]$OrigPcm = "c:\\Users\\Can\\Desktop\\PCM to text\\PCM-machine-reverse-engineering\\D347-25.pcm"
)

$ErrorActionPreference = 'Stop'

function ToLE32([double]$v){
  $i = [int][math]::Round($v * 100)
  return [BitConverter]::GetBytes([UInt32]$i)
}

function FindAll([byte[]]$arr, [byte[]]$seq){
  $hits=@();
  for($i=0;$i -le $arr.Length-$seq.Length;$i++){
    $ok=$true
    for($j=0;$j -lt $seq.Length;$j++){ if($arr[$i+$j] -ne $seq[$j]){ $ok=$false; break } }
    if($ok){ $hits+=$i }
  }
  return $hits
}

# Arrange
$work = "c:\\Users\\Can\\Desktop\\PCM to text\\PCM-machine-reverse-engineering\\out"
$inPcm = Join-Path $work 'D347-25_from_detayli.pcm'
if (-not (Test-Path $inPcm)) { $inPcm = Join-Path (Split-Path $OrigPcm -Parent) 'D347-25.pcm' }
$csv = Join-Path $work 'kopma_changes_test.csv'
$outPcm = Join-Path $work 'D347-25_kopma_batch_test.pcm'

@" 
old,new
23.49,30.00
24.65,29.00
"@.Trim() | Out-File -Encoding UTF8 $csv

# Baseline read
$orig = [IO.File]::ReadAllBytes($inPcm)
$oldA = ToLE32 23.49
$oldB = ToLE32 24.65
$hitsOldA = FindAll $orig $oldA
$hitsOldB = FindAll $orig $oldB

Write-Host "Baseline: oldA(23.49) hits=$($hitsOldA.Count) oldB(24.65) hits=$($hitsOldB.Count)" -ForegroundColor Cyan

# Act: run batch patch
echo "Running batch patch..."
powershell -ExecutionPolicy Bypass -File "c:\\Users\\Can\\Desktop\\PCM to text\\PCM-machine-reverse-engineering\\tools\\batch_patch_kopma.ps1" `
  -PcmFile $inPcm -ChangesCsv $csv -OutFile $outPcm | Out-Host

# Assert
$new = [IO.File]::ReadAllBytes($outPcm)
$newA = ToLE32 30.00
$newB = ToLE32 29.00

$hitsNewA = FindAll $new $newA
$hitsNewB = FindAll $new $newB

$pass = ($hitsNewA.Count -ge 1) -and ($hitsNewB.Count -ge 1)

if ($pass) {
  Write-Host "PASS: New values detected (30.00, 29.00) in output PCM." -ForegroundColor Green
  exit 0
} else {
  Write-Host "FAIL: Expected new values not detected." -ForegroundColor Red
  Write-Host "Debug: hitsNewA=$($hitsNewA.Count) hitsNewB=$($hitsNewB.Count)" -ForegroundColor Yellow
  exit 1
}
