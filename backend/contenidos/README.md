# Contenidos (servidor estático)

La app descarga estos archivos desde la URL raw de GitHub
(`https://raw.githubusercontent.com/DannaLagos/app-educativa-offline/main/backend/contenidos`).
Se puede cambiar con `--dart-define=API_BASE_URL=...`.

```
contenidos/
├── catalogo.json            # lista de módulos (id, nombre, area, grado, descripcion, version, habilitado, contenidos)
└── modulos/<id>/
    ├── manifest.json        # recursos del módulo con tamano y sha256
    └── <archivo>.pdf
```

- Para ocultar un módulo del catálogo, pon `"habilitado": false`. Quien ya lo
  descargó lo sigue viendo en "Mis descargas".
- Después de agregar o cambiar un PDF, corre `python backend/actualizar_manifests.py`.
  Si el tamaño o el sha256 no coinciden, la app rechaza la descarga.
- Los PDF actuales son de ejemplo y se reemplazarán por el material real.

## Probar con un servidor local (emulador)

```
cd backend/contenidos
python -m http.server 8000
flutter run --dart-define=API_BASE_URL=http://10.0.2.2:8000
```
