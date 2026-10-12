"""Recalcula el tamaño y el sha256 de los recursos de cada manifest.json.

La app verifica ambos valores después de descargar cada recurso, así que este
script se debe correr cada vez que se agregue o cambie un archivo de un módulo:

    python backend/actualizar_manifests.py
"""
import hashlib
import json
from pathlib import Path

CARPETA_MODULOS = Path(__file__).parent / "contenidos" / "modulos"


def sha256_de(ruta):
    resumen = hashlib.sha256()
    with ruta.open("rb") as archivo:
        for bloque in iter(lambda: archivo.read(64 * 1024), b""):
            resumen.update(bloque)
    return resumen.hexdigest()


def main():
    for ruta_manifest in sorted(CARPETA_MODULOS.glob("*/manifest.json")):
        manifest = json.loads(ruta_manifest.read_text(encoding="utf-8"))
        for recurso in manifest["recursos"]:
            ruta_recurso = ruta_manifest.parent / recurso["archivo"]
            recurso["tamano"] = ruta_recurso.stat().st_size
            recurso["sha256"] = sha256_de(ruta_recurso)
        ruta_manifest.write_text(
            json.dumps(manifest, ensure_ascii=False, indent=2) + "\n",
            encoding="utf-8",
        )
        print(f"Actualizado {ruta_manifest.parent.name}")


if __name__ == "__main__":
    main()
