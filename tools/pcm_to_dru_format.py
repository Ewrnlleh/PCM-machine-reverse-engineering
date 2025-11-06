#!/usr/bin/env python3
"""
PCM dosyasını DRU formatındaki gibi detaylı JSON'a çevir

Kullanım:
  python tools/pcm_to_dru_format.py D347-25.pcm D347-25.dru --out out/D347-25_detayli.json
"""

import argparse
import json
import struct
from pathlib import Path


def parse_dru(dru_path: str) -> dict:
    """DRU dosyasını parse et ve test bilgilerini çıkar."""
    with open(dru_path, "r", encoding="cp1254") as f:
        lines = f.readlines()
    
    tests = []
    grafik_data = {}
    mode = "header"
    
    for line in lines:
        line = line.strip()
        if not line:
            continue
            
        if line.startswith("Grafik"):
            mode = "grafik"
            continue
            
        if mode == "header":
            # İlk iki satır başlıklar
            if line.startswith("Test no") or line.startswith("( )"):
                continue
            
            # Test satırı
            parts = line.split("\t")
            if len(parts) >= 11:
                test_info = {
                    "test_no": parts[0].strip(),
                    "test_tipi": parts[1].strip(),
                    "anma_capi": parts[2].strip(),
                    "sinifi": parts[3].strip(),
                    "ilk_boy": parts[4].strip(),
                    "kutle": parts[5].strip(),
                    "birim_kutle": parts[6].strip(),
                    "akma": parts[7].strip(),
                    "cekme": parts[8].strip(),
                    "cekme_akma": parts[9].strip(),
                    "kopma_uzamasi": parts[10].strip()
                }
                tests.append(test_info)
        
        elif mode == "grafik":
            # Grafik başlığı
            if line.startswith("Test no"):
                continue
                
            # Grafik verisi
            parts = line.split("\t")
            if len(parts) >= 6:
                test_no = parts[0].strip()
                if test_no not in grafik_data:
                    grafik_data[test_no] = []
                
                grafik_data[test_no].append({
                    "zaman": parts[1].strip(),
                    "kuvvet_n": parts[2].strip(),
                    "cetvel_mm": parts[3].strip(),
                    "kanal3": parts[4].strip(),
                    "kanal4": parts[5].strip()
                })
    
    return {
        "tests": tests,
        "grafik": grafik_data
    }


def parse_pcm_header(pcm_path: str) -> dict:
    """PCM dosyasından başlık bilgilerini çıkar."""
    with open(pcm_path, "rb") as f:
        data = f.read()
    
    def read_string(offset, max_len):
        end = offset
        while end < (offset + max_len) and end < len(data) and data[end] != 0:
            end += 1
        return data[offset:end].decode("cp1254", errors="ignore").strip()
    
    header = data[0:16].decode("ascii", errors="ignore").strip("\x00")
    test_count = struct.unpack("<I", data[0x38:0x3C])[0]
    
    numune_no = read_string(0x5E, 30)
    tarih = read_string(0x7C, 20)
    test_standarti = read_string(0x90, 40)
    laboratuvar = read_string(0xB8, 80)
    malzeme_kodu = read_string(0x150, 50)
    musteri_no = read_string(0x19E, 40)
    
    return {
        "header": header,
        "test_count": test_count,
        "numune_no": numune_no,
        "tarih": tarih,
        "test_standarti": test_standarti,
        "laboratuvar": laboratuvar,
        "malzeme_kodu": malzeme_kodu,
        "musteri_no": musteri_no
    }


def main():
    parser = argparse.ArgumentParser(description="PCM + DRU -> Detaylı JSON")
    parser.add_argument("pcm", help="PCM dosyası")
    parser.add_argument("dru", help="DRU dosyası")
    parser.add_argument("--out", required=True, help="Çıktı JSON dosyası")
    
    args = parser.parse_args()
    
    print(f"PCM dosyası okunuyor: {args.pcm}")
    pcm_info = parse_pcm_header(args.pcm)
    
    print(f"DRU dosyası okunuyor: {args.dru}")
    dru_info = parse_dru(args.dru)
    
    # Birleştir
    combined = {
        "pcm_header": pcm_info,
        "test_summary": dru_info["tests"],
        "test_grafik": dru_info["grafik"],
        "_note": "Bu dosya PCM ve DRU dosyalarından birleştirilerek oluşturuldu"
    }
    
    print(f"\nJSON oluşturuluyor: {args.out}")
    Path(args.out).parent.mkdir(parents=True, exist_ok=True)
    with open(args.out, "w", encoding="utf-8") as f:
        json.dump(combined, f, ensure_ascii=False, indent=2)
    
    print(f"\n✅ Tamamlandı!")
    print(f"  - PCM header bilgileri: {len(pcm_info)} alan")
    print(f"  - Test özeti: {len(dru_info['tests'])} test")
    print(f"  - Grafik verisi: {sum(len(v) for v in dru_info['grafik'].values())} veri noktası")


if __name__ == "__main__":
    main()
