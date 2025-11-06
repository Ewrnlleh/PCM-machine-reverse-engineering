#!/usr/bin/env python3
"""
PCM <-> JSON dönüştürücü (PCM304 V7.2.11 format)

Özellikler:
- .pcm ikili dosyasını JSON'a çevirir (tüm alanlar düzenlenebilir)
- JSON'dan tekrar .pcm oluşturur (PCM304'ün okuyabilmesi için)

Kullanım:
  python tools/pcm_tool.py export "D347-25.pcm" --out out/D347-25.json
  python tools/pcm_tool.py build --json out/D347-25.json --out "D347-25_yeni.pcm"

Format Yapısı (reverse-engineering sonucu):
- 0x00-0x0F: Header "PCM304 V7.2.11_" + versiyon bilgisi
- 0x38-0x3B: Test sayısı (4-byte little-endian)
- Sabit offset'lerde metin alanları (cp1254 kodlama)
- Sonrasında test verileri (yapılandırılmış ikili format)
"""

from __future__ import annotations

import argparse
import json
import struct
from typing import Any, Dict, List


PCM_ENCODING = "cp1254"  # Windows-1254 (Turkish)


def read_string(data: bytes, offset: int, max_len: int) -> str:
    """Read null-terminated string from binary data."""
    end = offset
    while end < offset + max_len and end < len(data) and data[end] != 0:
        end += 1
    return data[offset:end].decode(PCM_ENCODING, errors="replace").strip()


def write_string(s: str, max_len: int) -> bytes:
    """Write string to fixed-length null-padded bytes."""
    b = s.encode(PCM_ENCODING, errors="replace")[:max_len]
    return b + b'\x00' * (max_len - len(b))


def parse_pcm(path: str) -> Dict[str, Any]:
    """Parse PCM binary file to dictionary."""
    with open(path, "rb") as f:
        data = f.read()
    
    if len(data) < 0x200:
        raise ValueError(f"Dosya çok küçük (minimum 512 bayt gerekli): {len(data)} bayt")
    
    # Header
    header = data[0:16].decode("ascii", errors="replace").rstrip('\x00')
    # Capture version bytes block (0x10..0x18)
    version_bytes_hex = data[0x10:0x18].hex()
    
    # Test count at offset 0x38 (4-byte little-endian)
    test_count = struct.unpack("<I", data[0x38:0x3C])[0]
    
    # Fixed fields (based on hex analysis)
    numune_no = read_string(data, 0x5E, 30)         # "D347-25"
    tarih = read_string(data, 0x7C, 20)             # "26.08.25"
    test_standarti = read_string(data, 0x90, 40)    # "TS 708 DEMİR ÇEKME"
    laboratuvar = read_string(data, 0xB8, 80)       # "GÜNEŞ YAPI..."
    malzeme_kodu = read_string(data, 0x150, 50)     # "BEŞKAVAKLAR MAH.BOLU"
    musteri_no = read_string(data, 0x19E, 40)       # "3742702213"
    
    # Test data starts after header (approx 0x200+)
    # For now, store raw test data section
    test_data_offset = 0x200
    test_data_raw = data[test_data_offset:].hex()
    
    return {
        "header": header,
        "version_bytes_hex": version_bytes_hex,
        "test_count": test_count,
        "numune_no": numune_no,
        "tarih": tarih,
        "test_standarti": test_standarti,
        "laboratuvar": laboratuvar,
        "malzeme_kodu": malzeme_kodu,
        "musteri_no": musteri_no,
        "test_data_raw_hex": test_data_raw,
        "_format_version": "PCM304_V7.2.11",
        "_note": "test_data_raw_hex alanı şu an ham hex olarak saklanıyor. İleri versiyonlarda parse edilebilir."
    }


def build_pcm(data: Dict[str, Any], out_path: str) -> None:
    """Build PCM binary file from dictionary."""
    # Start with zeros
    pcm_bytes = bytearray(0x200)  # Minimum header size
    
    # Write header (offset 0x00, 16 bytes)
    header = data.get("header", "PCM304 V7.2.11_")
    pcm_bytes[0:16] = write_string(header, 16)
    
    # Write version bytes (offset 0x10-0x17, observed pattern)
    ver_hex = data.get("version_bytes_hex")
    if isinstance(ver_hex, str) and len(ver_hex) >= 2:
        try:
            ver_bytes = bytes.fromhex(ver_hex)[:8]
            pcm_bytes[0x10:0x10+len(ver_bytes)] = ver_bytes
        except ValueError:
            # Fallback to default if parsing fails
            pcm_bytes[0x10] = 0x07
            pcm_bytes[0x11] = 0x01
            pcm_bytes[0x12] = 0x01
    else:
        pcm_bytes[0x10] = 0x07
        pcm_bytes[0x11] = 0x01
        pcm_bytes[0x12] = 0x01
    
    # Write test count (offset 0x38, 4-byte little-endian)
    test_count = data.get("test_count", 1)
    pcm_bytes[0x38:0x3C] = struct.pack("<I", test_count)
    
    # Copy test count to 0x1E8 as well (observed in original)
    pcm_bytes[0x1E8:0x1EC] = struct.pack("<I", test_count)
    
    # Write text fields
    numune_no = data.get("numune_no", "")
    tarih = data.get("tarih", "")
    test_standarti = data.get("test_standarti", "")
    laboratuvar = data.get("laboratuvar", "")
    malzeme_kodu = data.get("malzeme_kodu", "")
    musteri_no = data.get("musteri_no", "")
    
    # Length prefixes (observed pattern: 1-byte length before string)
    pcm_bytes[0x5D] = min(len(numune_no), 255)
    pcm_bytes[0x5E:0x5E+30] = write_string(numune_no, 30)
    
    pcm_bytes[0x7B] = min(len(tarih), 255)
    pcm_bytes[0x7C:0x7C+20] = write_string(tarih, 20)
    
    pcm_bytes[0x8F] = min(len(test_standarti), 255)
    pcm_bytes[0x90:0x90+40] = write_string(test_standarti, 40)
    
    pcm_bytes[0xB7] = min(len(laboratuvar), 255)
    pcm_bytes[0xB8:0xB8+80] = write_string(laboratuvar, 80)
    
    pcm_bytes[0x14F] = min(len(malzeme_kodu), 255)
    pcm_bytes[0x150:0x150+50] = write_string(malzeme_kodu, 50)
    
    pcm_bytes[0x19D] = min(len(musteri_no), 255)
    pcm_bytes[0x19E:0x19E+40] = write_string(musteri_no, 40)
    
    # Append test data (from hex)
    test_data_hex = data.get("test_data_raw_hex", "")
    if test_data_hex:
        test_data = bytes.fromhex(test_data_hex)
        pcm_bytes.extend(test_data)
    
    # Write to file
    with open(out_path, "wb") as f:
        f.write(pcm_bytes)


def main():
    ap = argparse.ArgumentParser(description=".pcm <-> JSON dönüştürücü")
    sub = ap.add_subparsers(dest="cmd", required=True)

    ap_export = sub.add_parser("export", help=".pcm dosyasını JSON'a çevir")
    ap_export.add_argument("pcm", help="Girdi .pcm dosyası")
    ap_export.add_argument("--out", required=True, help="Çıktı JSON dosyası")

    ap_build = sub.add_parser("build", help="JSON'dan .pcm üret")
    ap_build.add_argument("--json", required=True, help="Girdi JSON dosyası")
    ap_build.add_argument("--out", required=True, help="Üretilecek .pcm dosya yolu")

    args = ap.parse_args()

    if args.cmd == "export":
        data = parse_pcm(args.pcm)
        with open(args.out, "w", encoding="utf-8") as f:
            json.dump(data, f, ensure_ascii=False, indent=2)
        print(f"✓ JSON'a aktarıldı: {args.out}")
        print(f"  - Test sayısı: {data['test_count']}")
        print(f"  - Numune: {data['numune_no']}")
        
    elif args.cmd == "build":
        with open(args.json, "r", encoding="utf-8") as f:
            data = json.load(f)
        build_pcm(data, args.out)
        print(f"✓ PCM oluşturuldu: {args.out}")


if __name__ == "__main__":
    main()
