# PCM Dönüştürücü - PowerShell Versiyonu
# PCM304 V7.2.11 formatı için basit export/import

param(
    [Parameter(Mandatory=$true)]
    [ValidateSet("export", "build")]
    [string]$Command,
    
    [string]$PcmFile,
    [string]$JsonFile,
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

function Write-PcmString {
    param($str, $maxLen)
    $bytes = [System.Text.Encoding]::GetEncoding(1254).GetBytes($str)
    if ($bytes.Length -gt $maxLen) {
        $bytes = $bytes[0..($maxLen-1)]
    }
    $padded = New-Object byte[] $maxLen
    [Array]::Copy($bytes, $padded, $bytes.Length)
    return $padded
}

function Export-Pcm {
    param($inputPath, $outputPath)
    
    $data = [System.IO.File]::ReadAllBytes($inputPath)
    
    if ($data.Length -lt 0x200) {
        throw "Dosya çok küçük: $($data.Length) bayt"
    }
    
    # Parse header
    $header = [System.Text.Encoding]::ASCII.GetString($data[0..15]).TrimEnd([char]0)
    $testCount = [BitConverter]::ToInt32($data, 0x38)
    
    # Parse fields
    $numuneNo = Read-PcmString $data 0x5E 30
    $tarih = Read-PcmString $data 0x7C 20
    $testStandarti = Read-PcmString $data 0x90 40
    $laboratuvar = Read-PcmString $data 0xB8 80
    $malzemeKodu = Read-PcmString $data 0x150 50
    $musteriNo = Read-PcmString $data 0x19E 40
    
    # Test data
    $testDataHex = [BitConverter]::ToString($data[0x200..($data.Length-1)]).Replace('-','')
    
    $obj = @{
        header = $header
        test_count = $testCount
        numune_no = $numuneNo
        tarih = $tarih
        test_standarti = $testStandarti
        laboratuvar = $laboratuvar
        malzeme_kodu = $malzemeKodu
        musteri_no = $musteriNo
        test_data_raw_hex = $testDataHex
        _format_version = "PCM304_V7.2.11"
        _note = "PowerShell ile oluşturuldu"
    }
    
    $obj | ConvertTo-Json -Depth 10 | Out-File -Encoding UTF8 $outputPath
    Write-Host "OK - JSON exported: $outputPath" -ForegroundColor Green
    Write-Host "  - Test count: $testCount"
    Write-Host "  - Sample: $numuneNo"
}

function Build-Pcm {
    param($jsonPath, $outputPath)
    
    $obj = Get-Content $jsonPath -Encoding UTF8 | ConvertFrom-Json
    
    # Create byte array
    $pcmBytes = New-Object byte[] 0x200
    
    # Write header
    $headerBytes = Write-PcmString $obj.header 16
    [Array]::Copy($headerBytes, 0, $pcmBytes, 0, 16)
    
    # Version pattern
    $pcmBytes[0x10] = 0x07
    $pcmBytes[0x11] = 0x01
    $pcmBytes[0x12] = 0x01
    
    # Test count
    $testCountBytes = [BitConverter]::GetBytes([int]$obj.test_count)
    [Array]::Copy($testCountBytes, 0, $pcmBytes, 0x38, 4)
    [Array]::Copy($testCountBytes, 0, $pcmBytes, 0x1E8, 4)
    
    # Write fields with length prefixes
    $pcmBytes[0x5D] = [Math]::Min($obj.numune_no.Length, 255)
    $numuneBytes = Write-PcmString $obj.numune_no 30
    [Array]::Copy($numuneBytes, 0, $pcmBytes, 0x5E, 30)
    
    $pcmBytes[0x7B] = [Math]::Min($obj.tarih.Length, 255)
    $tarihBytes = Write-PcmString $obj.tarih 20
    [Array]::Copy($tarihBytes, 0, $pcmBytes, 0x7C, 20)
    
    $pcmBytes[0x8F] = [Math]::Min($obj.test_standarti.Length, 255)
    $testStandBytes = Write-PcmString $obj.test_standarti 40
    [Array]::Copy($testStandBytes, 0, $pcmBytes, 0x90, 40)
    
    $pcmBytes[0xB7] = [Math]::Min($obj.laboratuvar.Length, 255)
    $labBytes = Write-PcmString $obj.laboratuvar 80
    [Array]::Copy($labBytes, 0, $pcmBytes, 0xB8, 80)
    
    $pcmBytes[0x14F] = [Math]::Min($obj.malzeme_kodu.Length, 255)
    $malzemeBytes = Write-PcmString $obj.malzeme_kodu 50
    [Array]::Copy($malzemeBytes, 0, $pcmBytes, 0x150, 50)
    
    $pcmBytes[0x19D] = [Math]::Min($obj.musteri_no.Length, 255)
    $musteriBytes = Write-PcmString $obj.musteri_no 40
    [Array]::Copy($musteriBytes, 0, $pcmBytes, 0x19E, 40)
    
    # Add test data
    $allBytes = $pcmBytes
    if ($obj.test_data_raw_hex) {
        $hexString = $obj.test_data_raw_hex
        $testDataBytes = New-Object System.Collections.Generic.List[byte]
        for ($i = 0; $i -lt $hexString.Length; $i += 2) {
            $hexByte = $hexString.Substring($i, 2)
            $testDataBytes.Add([Convert]::ToByte($hexByte, 16))
        }
        $allBytes = $pcmBytes + $testDataBytes.ToArray()
    }
    
    [System.IO.File]::WriteAllBytes($outputPath, $allBytes)
    Write-Host "OK - PCM created: $outputPath" -ForegroundColor Green
}

# Main
switch ($Command) {
    "export" {
        if (-not $PcmFile -or -not $OutFile) {
            Write-Error "Kullanım: .\pcm_tool.ps1 export -PcmFile input.pcm -OutFile output.json"
            exit 1
        }
        Export-Pcm $PcmFile $OutFile
    }
    "build" {
        if (-not $JsonFile -or -not $OutFile) {
            Write-Error "Kullanım: .\pcm_tool.ps1 build -JsonFile input.json -OutFile output.pcm"
            exit 1
        }
        Build-Pcm $JsonFile $OutFile
    }
}
