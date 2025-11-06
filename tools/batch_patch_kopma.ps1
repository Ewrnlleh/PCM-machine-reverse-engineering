param(
  [Parameter(Mandatory=$true)] [string]$PcmFile,
  [Parameter(Mandatory=$true)] [string]$ChangesCsv,  # columns: old,new (numbers)
  [Parameter(Mandatory=$true)] [string]$OutFile,
  [int]$SearchStart = 0x000000,
  [int]$SearchLength = 0          # 0 => scan to end
)

Write-Host "PCM okunuyor: $PcmFile" -ForegroundColor Cyan
$bytes = [System.IO.File]::ReadAllBytes($PcmFile)
if ($SearchLength -le 0) { $SearchLength = $bytes.Length - $SearchStart }
$end = [Math]::Min($bytes.Length, $SearchStart + $SearchLength)

function ToLE32([double]$v){
  $i = [int][math]::Round($v * 100)
  return [BitConverter]::GetBytes([UInt32]$i)
}

function Find-Seq([byte[]]$arr, [byte[]]$seq, [int]$s, [int]$e, [int]$from){
  $start = [Math]::Max($s, $from)
  for($i=$start; $i -le $e - $seq.Length; $i++){
    $ok = $true
    for($j=0; $j -lt $seq.Length; $j++){
      if($arr[$i+$j] -ne $seq[$j]){ $ok = $false; break }
    }
    if($ok){ return $i }
  }
  return -1
}

if (-not (Test-Path $ChangesCsv)) { throw "CSV bulunamadı: $ChangesCsv" }
$rows = Import-Csv -Path $ChangesCsv -Delimiter ','
if (-not $rows -or $rows.Count -eq 0) { throw "CSV boş: $ChangesCsv" }

$cursor = $SearchStart
$patched = @()

foreach($row in $rows){
  if (-not $row.old -or -not $row.new) { continue }
  $oldVal = [double]$row.old
  $newVal = [double]$row.new
  $oldSeq = ToLE32 $oldVal
  $newSeq = ToLE32 $newVal

  $idx = Find-Seq $bytes $oldSeq $SearchStart $end $cursor
  if ($idx -lt 0) {
    Write-Host ("Bulunamadı: old={0} (x100={1}) aralık 0x{2:X}-0x{3:X} başlangıç 0x{4:X}" -f $oldVal, ([int]::Round($oldVal*100)), $SearchStart, ($end-1), $cursor) -ForegroundColor Yellow
    continue
  }

  for($k=0; $k -lt 4; $k++){ $bytes[$idx+$k] = $newSeq[$k] }
  $cursor = $idx + 4
  $patched += [pscustomobject]@{ old=$oldVal; new=$newVal; offset=('0x{0:X}' -f $idx) }
}

[IO.File]::WriteAllBytes($OutFile, $bytes)
Write-Host "OK - Toplu yama uygulandı: $OutFile" -ForegroundColor Green
if ($patched.Count -gt 0) {
  Write-Host "Değiştirilenler:" -ForegroundColor Cyan
  $patched | Format-Table -AutoSize
} else {
  Write-Host "Not: Hiç eşleşme bulunamadı." -ForegroundColor Yellow
}
