# 🦷 Dental Clinic — Sistema de Gestión

Aplicación de **escritorio (Windows)** desarrollada en **Flutter** para la gestión integral de una clínica dental: pacientes, citas, tratamientos, facturación y reportes.

## Tecnologías

| Tecnología | Uso |
|---|---|
| Flutter 3.x (Windows Desktop) | UI multiplataforma de escritorio |
| SQLite (`sqflite_common_ffi`) | Base de datos local |
| `go_router` | Navegación declarativa |
| `provider` | Gestión de estado |
| `equatable` | Comparación de entidades |

## Arquitectura

El proyecto sigue **Clean Architecture** organizada por **features** (módulos funcionales). Cada feature tiene 3 capas: `data`, `domain` y `presentation`.

```
lib/
├── main.dart                  # Punto de entrada (inicializa DB y arranca la app)
├── app.dart                   # Widget raíz (tema + router)
├── core/                      # Código compartido entre features
│   ├── constants/             # Constantes globales
│   ├── database/              # Helper de SQLite (esquema y conexión)
│   ├── di/                    # Inyección de dependencias
│   ├── errors/                # Excepciones y fallos
│   ├── router/                # Configuración de rutas (go_router)
│   ├── theme/                 # Tema claro/oscuro
│   ├── utils/                 # Utilidades (formateo de fechas, validadores…)
│   └── widgets/               # Widgets reutilizables (layout principal, etc.)
└── features/
    ├── auth/                  # Autenticación de usuarios
    ├── dashboard/             # Resumen general de la clínica
    ├── patients/              # Gestión de pacientes e historial clínico
    ├── appointments/          # Agenda de citas
    ├── treatments/            # Tratamientos y odontograma
    ├── billing/               # Facturación y pagos
    └── reports/               # Reportes y estadísticas
        │
        │   (cada feature tiene la misma estructura interna)
        ├── data/
        │   ├── datasources/   # Acceso a SQLite
        │   ├── models/        # Modelos (mapeo a/desde la DB)
        │   └── repositories/  # Implementación de los contratos del dominio
        ├── domain/
        │   ├── entities/      # Entidades de negocio puras
        │   ├── repositories/  # Contratos (interfaces)
        │   └── usecases/      # Casos de uso (lógica de negocio)
        └── presentation/
            ├── pages/         # Pantallas
            ├── widgets/       # Widgets propios del feature
            └── providers/     # Estado (Provider/ChangeNotifier)
```

Más detalle en [`docs/ARQUITECTURA.md`](docs/ARQUITECTURA.md).

## Cómo ejecutar

```bash
flutter pub get
flutter run -d windows
```

## Tests

```bash
flutter test
```
