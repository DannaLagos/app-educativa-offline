# 📚 App Educativa Offline

Aplicación móvil educativa con funcionamiento **offline-first** para el aprendizaje de **Lenguaje** y **Ciencias Sociales** en educación primaria. Permite descargar módulos con conexión a Internet y usarlos después sin conexión, guardando el progreso del estudiante en el dispositivo y sincronizándolo cuando vuelva la conectividad.

> **Estado:** 🚧 En desarrollo · **Tipo:** Prueba de concepto (PoC) · **Versión del documento de planificación:** 1.0

---

## 📖 Contexto

Este proyecto se desarrolla en articulación con la **Secretaría de Educación Departamental de Nariño**. Busca complementar el acceso a recursos educativos digitales en situaciones donde no existe una conexión a Internet permanente.

Como base pedagógica se usan materiales del modelo **Escuela Nueva** del Ministerio de Educación Nacional:

- Ciencias Sociales, grado primero (1 módulo)
- Lenguaje, grado tercero (3 cartillas)

La propuesta **no digitaliza por completo las cartillas originales**. Adapta una selección de sus contenidos a actividades interactivas (preguntas, asociaciones, clasificaciones, secuencias y ejercicios de comprensión), conservando su propósito educativo.

## 🎯 Objetivos

**Objetivo general:** desarrollar una aplicación móvil educativa con funcionamiento offline que permita acceder a contenidos y actividades interactivas de módulos seleccionados, con descarga y uso sin conexión, almacenamiento del progreso y gestión básica de contenidos.

**Objetivos específicos:**

1. Diseñar la estructura funcional, visual y tecnológica de los contenidos, adaptándolos a actividades digitales interactivas con y sin conexión.
2. Implementar una aplicación móvil que permita descargar módulos, desarrollar actividades sin conexión y almacenar localmente el progreso.
3. Validar la solución mediante pruebas de acceso a contenidos, descarga, funcionamiento offline, conservación del progreso y sincronización.

## ✨ Funcionalidades

### Estudiante
- Crear un perfil con su nombre (se genera internamente un identificador único).
- Consultar los módulos disponibles, organizados por área y grado.
- Descargar módulos cuando hay conexión y eliminarlos cuando ya no se necesiten.
- Acceder a los contenidos y actividades **sin conexión a Internet**.
- Realizar actividades y juegos interactivos con retroalimentación básica.
- Guardar el progreso localmente y retomarlo donde quedó.
- Consultar su avance (actividades completadas y pendientes).
- Ver el estado de conexión y sincronización de la app.
- Sincronizar el progreso automáticamente al recuperar la conexión.

### Superadministrador
- Iniciar y cerrar sesión de forma segura.
- Registrar, actualizar, habilitar o deshabilitar contenidos.
- Consultar información general de uso (módulos descargados, actividades realizadas y progreso registrado).

## 🔄 Flujo general

```
Crear perfil → Consultar módulos → Descargar módulo (con conexión)
      → Usar contenidos y actividades (sin conexión)
      → Guardar progreso localmente
      → Sincronizar con el servidor al recuperar la conexión
      → Continuar desde el progreso registrado
```

## 🏗️ Arquitectura y principios de diseño

El enfoque es **offline-first**: los módulos se descargan al dispositivo y permanecen disponibles sin conexión; las respuestas y el progreso se guardan localmente y se envían al servidor cuando es posible.

Calidad esperada (requerimientos no funcionales principales):

| Categoría | Descripción |
|---|---|
| Funcionamiento offline | Un módulo descargado funciona sin comunicación con el servidor |
| Persistencia | El progreso se conserva al cerrar la app, reiniciar el dispositivo o perder conexión |
| Integridad de datos | Un fallo de red o de sincronización no provoca pérdida de progreso |
| Sincronización | Admite reintentos y evita registros duplicados |
| Usabilidad y accesibilidad | Interfaz sencilla para niños: textos legibles, controles táctiles amplios, buen contraste |
| Seguridad y privacidad | Autenticación del superadministrador, comunicación segura y mínimo de datos del estudiante |
| Mantenibilidad | Separación entre interfaz, lógica de negocio, almacenamiento local, acceso remoto y sincronización |
| Extensibilidad | Permite agregar nuevos grados, áreas y módulos sin cambios mayores |
| Compatibilidad | Dispositivos Android definidos para la prueba de concepto |

## 🛠️ Tecnologías

<!-- COMPLETAR con el stack real del proyecto -->

| Capa | Tecnología |
|---|---|
| App móvil | _[completar]_ |
| Almacenamiento local | _[completar]_ |
| Backend / API | _[completar]_ |
| Base de datos | _[completar]_ |

## 🚀 Clonar repositorio



```bash
# 1. Clonar el repositorio
git clone https://github.com/DannaLagos/app-educativa-offline.git
cd app-educativa-offline


## 🧪 Pruebas previstas

- Acceso a contenidos y descarga de módulos
- Funcionamiento sin conexión
- Conservación del progreso
- Sincronización de la información

## 🗂️ Metodología

El proyecto se organiza con **Scrum**. La planificación incluye 14 historias de usuario (11 de estudiante y 3 de superadministrador, con criterios de aceptación), además de 18 requerimientos funcionales y 12 no funcionales.

## 👥 Equipo

<!-- COMPLETAR -->

| Nombre | 
|---|
| Valentina Álvarez Solarte |
| Danna Lagos|
| Karen Erazo|

## 📄 Contenidos y licencia

Los contenidos pedagógicos se basan en materiales del modelo Escuela Nueva del Ministerio de Educación Nacional de Colombia. Los derechos de los materiales originales pertenecen a sus titulares.
