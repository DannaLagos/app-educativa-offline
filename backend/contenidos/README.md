# Contenidos (Firebase Storage)

Los PDF ya no se guardan en el repositorio: la app los descarga desde
**Firebase Storage** (proyecto `aplicacioneducativaoffline`). Esta carpeta solo
conserva `catalogo.json` y los `manifest.json` como copia de referencia.

Estructura en Storage (bucket `aplicacioneducativaoffline.firebasestorage.app`):

```
contenidos/
├── catalogo.json            # lista de módulos (id, nombre, area, grado, descripcion, version, habilitado, contenidos)
└── modulos/<id>/
    ├── manifest.json        # recursos del módulo con tamano y sha256
    └── <archivo>.pdf
```

Reglas de Storage: todos pueden leer `contenidos/`, nadie puede escribir
desde la app (los archivos se suben desde la consola de Firebase).

## Catálogo en Firestore (HU13)

La lista de módulos ahora la gestiona el superadministrador desde la app y se
guarda en la colección `catalogo` de Firestore (ver
[`../CONFIGURAR_SUPERADMIN.md`](../CONFIGURAR_SUPERADMIN.md)). La app usa
`catalogo.json` solo mientras esa colección esté vacía. Desde la app se cambia
la información de un módulo y se habilita o deshabilita; los **archivos**
(PDF, `manifest.json`) se siguen subiendo a Storage como se explica abajo.

## Agregar o cambiar un módulo

1. Pon el archivo en `backend/contenidos/modulos/<id>/` (en tu computador;
   los PDF están en `.gitignore`).
2. Agrega o actualiza el módulo en `catalogo.json` (sube `version` si ya
   estaba publicado).
3. Corre `python backend/actualizar_manifests.py` para recalcular tamaño y
   sha256. Si no coinciden, la app rechaza la descarga.
4. Sube a Firebase Storage el archivo, el `manifest.json` y el `catalogo.json`
   en las mismas rutas.

Para ocultar un módulo, desactívalo en **Gestión de contenidos** dentro de la
app (antes de usar Firestore: `"habilitado": false` en `catalogo.json`).
Quien ya lo descargó lo sigue viendo en "Mis descargas".

## Probar con un servidor local (sin Firebase)

```
cd backend/contenidos
python -m http.server 8000
flutter run --dart-define=FUENTE_CONTENIDOS=http --dart-define=API_BASE_URL=http://10.0.2.2:8000
```
