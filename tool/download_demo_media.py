"""Descarga los recursos de demostración como archivos locales, sin claves API.
Las fuentes y licencias se conservan junto a cada recurso. No modifica fotos ni
obtiene nombres, cédulas o información personal de las personas retratadas.
"""
import concurrent.futures
import hashlib
import json
import pathlib
import time
import urllib.request

ROOT = pathlib.Path(__file__).resolve().parents[1]
SOURCES = json.loads((ROOT / "tool/demo_media_sources.json").read_text(encoding="utf-8"))

def download(item):
    target = ROOT / item["asset"]
    target.parent.mkdir(parents=True, exist_ok=True)
    if target.exists():
        data = target.read_bytes()
    else:
        for attempt in range(3):
            try:
                request = urllib.request.Request(item["url"], headers={"User-Agent": "FarmaciaJAEDemo/1.0"})
                with urllib.request.urlopen(request, timeout=30) as response:
                    data = response.read()
                if not data.startswith(b"\xff\xd8\xff") or len(data) < 1000:
                    raise ValueError("La respuesta no contiene una foto JPEG válida")
                target.write_bytes(data)
                break
            except Exception:
                if attempt == 2:
                    raise
                time.sleep(1)
    if not data.startswith(b"\xff\xd8\xff"):
        raise ValueError(f"JPEG no válido: {target}")
    return {**item, "bytes": len(data), "sha256": hashlib.sha256(data).hexdigest()}

if __name__ == "__main__":
    with concurrent.futures.ThreadPoolExecutor(max_workers=6) as pool:
        records = list(pool.map(download, SOURCES))
    (ROOT / "images/DEMO_MEDIA_SOURCES.json").write_text(
        json.dumps(records, indent=2, ensure_ascii=False) + "\n", encoding="utf-8")
    print(f"{len(records)} fotos verificadas; {sum(r['bytes'] for r in records):,} bytes.")
