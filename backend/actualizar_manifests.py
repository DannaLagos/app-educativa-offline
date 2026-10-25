# Recalcula tamaño, sha256 y versión de cada manifest.json; uso: python backend/actualizar_manifests.py
import hashlib
import json
from pathlib import Path

CARPETA_CONTENIDOS = Path(__file__).parent / "contenidos"
CARPETA_MODULOS = CARPETA_CONTENIDOS / "modulos"
RUTA_CATALOGO = CARPETA_CONTENIDOS / "catalogo.json"
TAMANO_BLOQUE_LECTURA = 64 * 1024
CODIFICACION = "utf-8"


def main():
    versiones_por_modulo = leer_versiones_del_catalogo()

    for ruta_manifest in sorted(CARPETA_MODULOS.glob("*/manifest.json")):
        actualizar_manifest(ruta_manifest, versiones_por_modulo)
        print(f"Actualizado {ruta_manifest.parent.name}")


def leer_versiones_del_catalogo():
    catalogo = leer_json(RUTA_CATALOGO)

    return {modulo["id"]: modulo["version"] for modulo in catalogo["modulos"]}


def actualizar_manifest(ruta_manifest, versiones_por_modulo):
    manifest = leer_json(ruta_manifest)
    copiar_version(manifest, versiones_por_modulo)

    for recurso in manifest["recursos"]:
        actualizar_huella(recurso, ruta_manifest.parent / recurso["archivo"])

    escribir_json(ruta_manifest, manifest)


def copiar_version(manifest, versiones_por_modulo):
    modulo_id = manifest["id"]

    if modulo_id not in versiones_por_modulo:
        print(f"Aviso: {modulo_id} no está en {RUTA_CATALOGO.name}")
        return

    manifest["version"] = versiones_por_modulo[modulo_id]


def actualizar_huella(recurso, ruta_recurso):
    recurso["tamano"] = ruta_recurso.stat().st_size
    recurso["sha256"] = calcular_sha256(ruta_recurso)


def calcular_sha256(ruta):
    resumen = hashlib.sha256()

    with ruta.open("rb") as archivo:
        for bloque in iter(lambda: archivo.read(TAMANO_BLOQUE_LECTURA), b""):
            resumen.update(bloque)

    return resumen.hexdigest()


def leer_json(ruta):
    return json.loads(ruta.read_text(encoding=CODIFICACION))


def escribir_json(ruta, contenido):
    ruta.write_text(
        json.dumps(contenido, ensure_ascii=False, indent=2) + "\n",
        encoding=CODIFICACION,
    )


if __name__ == "__main__":
    main()
