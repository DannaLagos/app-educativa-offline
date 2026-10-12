"""Recalcula el tamaño y el sha256 de los recursos de cada manifest.json y
copia la versión del módulo desde catalogo.json.

La app verifica el tamaño y el sha256 después de descargar cada recurso, y
compara la versión descargada con la del catálogo para avisar que hay una
actualización. Corre este script cada vez que agregues o cambies un archivo
(y sube "version" en catalogo.json si el módulo ya estaba publicado):

    python backend/actualizar_manifests.py
"""
import hashlib
import json
from pathlib import Path

CARPETA_CONTENIDOS = Path(__file__).parent / "contenidos"
CARPETA_MODULOS = CARPETA_CONTENIDOS / "modulos"


def sha256_de(ruta):
    resumen = hashlib.sha256()
    with ruta.open("rb") as archivo:
        for bloque in iter(lambda: archivo.read(64 * 1024), b""):
            resumen.update(bloque)
    return resumen.hexdigest()


def main():
    catalogo = json.loads(
        (CARPETA_CONTENIDOS / "catalogo.json").read_text(encoding="utf-8")
    )
    versiones = {modulo["id"]: modulo["version"] for modulo in catalogo["modulos"]}

    for ruta_manifest in sorted(CARPETA_MODULOS.glob("*/manifest.json")):
        manifest = json.loads(ruta_manifest.read_text(encoding="utf-8"))
        if manifest["id"] in versiones:
            manifest["version"] = versiones[manifest["id"]]
        else:
            print(f"Aviso: {manifest['id']} no está en catalogo.json")
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
