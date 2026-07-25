# 🦷 ProDentist Perú — Sistema de Gestión Odontológica

Sistema odontológico en **Flutter** con diseño web moderno, que funciona como **app web** y también de **escritorio (Windows)**: registro de pacientes, agenda de citas, historia clínica y reporte de atenciones por fecha, con base de datos **MySQL**.

Tiene **dos backends equivalentes** (mismos endpoints):
- `api/` — **PHP** (PDO), listo para subir a **cPanel** (producción).
- `server/` — **Dart** (shelf), cómodo para desarrollo local.

## Funcionalidades

- **Login**: autenticación con usuarios en MySQL y token de sesión.
- **Cuentas** (solo admin): crear cuentas de recepción/odontólogo y habilitar/deshabilitar cuentas.
- **Pacientes**: registro, edición, búsqueda por nombre/DNI y eliminación.
- **Citas**: agenda por día, nueva cita con paciente/fecha/hora/motivo, estados (pendiente, atendida, cancelada).
- **Historia clínica**: registros por paciente (fecha, diagnóstico, tratamiento, observaciones) con **exportación a PDF**.
- **Reportes**: atenciones por rango de fechas con conteo total y **exportación a PDF**.
- **Dashboard**: pacientes registrados, citas de hoy y citas pendientes.

Usuarios de ejemplo: `admin`/`admin123`, `recepcion`/`recepcion123`, `doctor`/`doctor123` (⚠️ cambiar antes de publicar).

## Tecnologías

| Tecnología | Uso |
|---|---|
| Flutter 3.x (Web y Windows) | Interfaz de usuario (tema ProDentist: dorado/plata, Poppins) |
| PHP 7.4+ (`api/`) | API REST para producción en cPanel |
| Dart + `shelf` (`server/`) | API REST para desarrollo local |
| MySQL | Base de datos |
| `go_router`, `http`, `pdf`/`printing` | Navegación, API y exportación PDF |

> El navegador no puede conectarse directamente a MySQL, por eso la app (web o escritorio) consume una API REST, y es el servidor quien habla con MySQL.

## Cómo ejecutar

**1. Base de datos** (MySQL 8 corriendo, servicio `MySQL80`):

```bash
mysql -u root -p < docs/database/schema.sql   # crea la base y tablas
mysql -u root -p < docs/database/seed.sql     # (opcional) datos de ejemplo
```

**2. Servidor API** — elige uno de los dos:

```bash
# Opción A: Dart (desarrollo)
cd server
dart pub get
dart run bin/server.dart     # escucha en http://localhost:8090

# Opción B: PHP (el mismo que va a cPanel; credenciales en api/config.php)
cd api
php -S localhost:8090 index.php
```

**3. La app** (en otra terminal):

```bash
flutter pub get
flutter run -d chrome     # versión web
flutter run -d windows    # versión escritorio
```

Si la API corre en otra máquina o puerto, cambia `baseUrl` en `lib/core/api/api_client.dart`.

**4. Iniciar sesión** con el usuario inicial `admin` / `admin123` (⚠️ cámbialo antes de publicar en internet). Todos los endpoints de la API, excepto el login, exigen el token de sesión.

## Publicar en cPanel

1. **Base de datos**: en cPanel crea la base y el usuario MySQL, e importa `docs/database/schema.sql` (y `seed.sql` si quieres datos de prueba) desde phpMyAdmin.
2. **API**: sube la carpeta `api/` a `public_html/api/` y edita `api/config.php` con las credenciales de la base creada (formato `usuariocpanel_dental`).
3. **La app web**: compílala apuntando a tu dominio y sube el resultado:

   ```bash
   flutter build web --dart-define=API_URL=https://tudominio.com/api
   ```

   Sube el contenido de `build/web/` a `public_html/`.
4. Abre `https://tudominio.com`, inicia sesión y listo. ⚠️ Antes de publicar cambia las contraseñas de los usuarios de ejemplo.

## Arquitectura

El proyecto sigue **Clean Architecture** organizada por **features**. La app consume la API REST y el servidor es quien accede a MySQL.

```
DentalClinic/
├── server/                        # API REST en Dart (shelf) — habla con MySQL
│   └── bin/server.dart            # Endpoints: /patients, /appointments,
│                                  # /clinical-records, /reports/…
├── docs/
│   ├── ARQUITECTURA.md            # Diagramas y decisiones
│   └── database/                  # schema.sql y seed.sql
└── lib/
    ├── main.dart                  # Punto de entrada
    ├── app.dart                   # Widget raíz (tema + router + idioma es)
    ├── core/
    │   ├── api/                   # Cliente HTTP hacia la API
    │   ├── constants/             # Constantes globales
    │   ├── router/                # Rutas (go_router)
    │   ├── theme/                 # Tema claro/oscuro
    │   └── widgets/               # Layout principal con menú lateral
    └── features/
        ├── dashboard/             # Indicadores del día
        ├── patients/              # Pacientes + historia clínica
        ├── appointments/          # Agenda de citas
        ├── reports/               # Reporte por rango de fechas
        ├── treatments/            # (pendiente de implementar)
        └── billing/               # (pendiente de implementar)
            │
            │  (features implementados usan estas capas)
            ├── data/repositories/     # Llamadas a la API REST
            ├── domain/entities/       # Entidades de negocio
            ├── domain/repositories/   # Contratos (interfaces)
            └── presentation/          # pages/ y widgets/
```

Más detalle en [`docs/ARQUITECTURA.md`](docs/ARQUITECTURA.md).

## Tests

```bash
flutter test
```
