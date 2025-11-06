param(
  [Parameter(Mandatory=$true)] [string]$PcmFile,
  [Parameter(Mandatory=$true)] [double]$OldValue,
  [Parameter(Mandatory=$true)] [double]$NewValue,
  [Parameter(Mandatory=$true)] [string]$OutFile,
  [int]$SearchStart = 0x2EE00,
  [int]$SearchLength = 0x1000
)

Write-Host "PCM okunuyor: $PcmFile" -ForegroundColor Cyan
$bytes = [System.IO.File]::ReadAllBytes($PcmFile)

if ($SearchStart -lt 0 -or $SearchStart -ge $bytes.Length) { throw "SearchStart aralık dışında." }
$end = [Math]::Min($bytes.Length, $SearchStart + $SearchLength)

# 32-bit little-endian tam sayı: value * 100
function ToLE32([double]$v){
    $i = [int][math]::Round($v * 100)
    return [BitConverter]::GetBytes([UInt32]$i)
}

$oldSeq = ToLE32 $OldValue
$newSeq = ToLE32 $NewValue

function Find-Seq($arr, $seq, $s, $e){
  for($i=$s; $i -le $e - $seq.Length; $i++){
    $ok = $true
    for($j=0; $j -lt $seq.Length; $j++){
      if($arr[$i+$j] -ne $seq[$j]){ $ok = $false; break }
    }
    if($ok){ return $i }
  }
  return -1
}

$idx = Find-Seq $bytes $oldSeq $SearchStart $end
if ($idx -lt 0){
  Write-Host "Uyarı: Belirtilen aralıkta ($('{0:X}' -f $SearchStart) - $('{0:X}' -f ($end-1))) eski değer bulunamadı." -ForegroundColor Yellow
  exit 2
}

Write-Host ("Eski değer bulundu: offset=0x{0:X}" -f $idx) -ForegroundColor Green

# Yama uygula
for($k=0; $k -lt 4; $k++){ $bytes[$idx+$k] = $newSeq[$k] }

# Çıkışa yaz
[System.IO.File]::WriteAllBytes($OutFile, $bytes)
Write-Host "OK - Yama uygulandı ve yazıldı: $OutFile" -ForegroundColor Green

# Küçük rapor
Write-Host ("Old ({0}) -> New ({1})" -f $OldValue, $NewValue)
Write-Host ("Bölge: 0x{0:X}..0x{1:X}" -f $SearchStart, ($end-1))
