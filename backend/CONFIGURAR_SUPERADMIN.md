# Configurar el superadministrador (HU12, HU13 y HU14)

El superadministrador hace todo desde la app: inicia sesión, gestiona los
módulos y consulta el uso. Solo hay que preparar Firebase **una vez**, desde la
consola del proyecto `aplicacioneducativaoffline`. Toma unos 5 minutos.

## 1. Activar el inicio de sesión con correo

Firebase Console → **Authentication** → **Sign-in method** → **Correo
electrónico/contraseña** → Habilitar → Guardar.

(El acceso **Anónimo** debe seguir habilitado: lo usan los estudiantes.)

## 2. Crear la cuenta del superadministrador

**Authentication** → **Users** → **Agregar usuario**: escribe el correo y la
contraseña del superadministrador.

Copia el **UID** del usuario que aparece en la lista (por ejemplo
`aB3dE...`).

## 3. Darle permisos de administrador

**Firestore Database** → **Datos** → **Iniciar colección**:

- ID de la colección: `administradores`
- ID del documento: **el UID copiado** (no uses el ID automático)
- Campo: `nombre` (string) = el nombre para el saludo, por ejemplo `Valentina`

Una cuenta de Authentication sin este documento **no** puede entrar al panel.
Para quitarle el acceso a alguien, borra su documento.

## 4. Publicar las reglas

**Firestore Database** → **Reglas**: reemplaza todo por el contenido de
[`firestore.rules`](firestore.rules) → **Publicar**.

Las reglas de Storage no cambian.

## 5. Primer ingreso

En la app: **Acceso administrador** → correo y contraseña → **Gestión de
contenidos**. La primera vez, la app copia los módulos de `catalogo.json` a la
colección `catalogo` de Firestore. Desde ese momento los estudiantes reciben el
catálogo desde Firestore.

## Qué guarda cada colección

| Colección | Quién escribe | Quién lee |
|---|---|---|
| `administradores/{uid}` | Solo la consola | Cada admin, el suyo |
| `catalogo/{modulo}` | Superadministrador (HU13) | Todos con sesión |
| `estudiantes/{perfil}/...` | Cada dispositivo, el suyo (HU11) | Superadministrador (HU14) |

## Si algo no funciona

- **"Los datos de acceso no son válidos"** con la contraseña correcta: falta
  el documento del paso 3, su ID no es el UID exacto o no se publicaron las
  reglas.
- **"No fue posible leer los módulos"** o **"No fue posible consultar la
  información de uso"**: las reglas del paso 4 no están publicadas.
