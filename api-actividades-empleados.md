# API - Lista de Actividades por Empleado

**Versión:** 2.3.0  
**Fecha:** 18 de Febrero de 2026  
**Base URL:** `http://localhost:8080/api/v1`

---

## Endpoint

```
POST /api/v1/empleadosactividades
Content-Type: application/json
Body: {}
```

Retorna todos los empleados de mantenimiento con sus actividades pendientes (TP y ST) en una sola llamada.

---

## Respuesta

Array de empleados ordenados por fecha de actividad más reciente (descendente). Solo se incluyen empleados con al menos una actividad pendiente.

```json
[
  {
    "empleado": {
      "id": 2537,
      "nombres": "EFRAIN",
      "apellidopaterno": "ALCCA",
      "apellidomaterno": "QUISPE",
      "nombreCompleto": "EFRAIN ALCCA QUISPE",
      "numerodocumento": "74991686",
      "cargo": "TECNICO ELECTRICISTA M2",
      "area": "MANTENIMIENTO",
      "cantidadActividades": 3,
      "cantidadAsistencias": 1,
      "cantidadTotal": 4,
      "fechaActividadReciente": "2026-02-14T10:30:00.000+00:00"
    },
    "actividades": [
      {
        "tipo": "TP",
        "codigo": "TP-456",
        "idDetalle": 456,
        "idAsignacion": null,
        "ordentrabajo": { },
        "detalle": { },
        "empleadoPrincipal": null,
        "subActividad": null,
        "tiempoEstimado": null,
        "dtiempoinicio": "2026-02-14T08:30:00.000+00:00",
        "dtiempofin": null,
        "bcerrada": false,
        "cobservaciones": null,
        "cestadomovil": "EN_PROCESO",
        "pausas": []
      },
      {
        "tipo": "TP",
        "codigo": "TP-457",
        "idDetalle": 457,
        "idAsignacion": null,
        "ordentrabajo": { },
        "detalle": { },
        "empleadoPrincipal": null,
        "subActividad": null,
        "tiempoEstimado": null,
        "dtiempoinicio": "2026-02-14T09:00:00.000+00:00",
        "dtiempofin": null,
        "bcerrada": false,
        "cobservaciones": null,
        "cestadomovil": "PAUSADA",
        "pausas": [
          {
            "id": 14,
            "cmotivo": "Almuerzo",
            "dtiempoinicio": "2026-02-14T10:00:00.000+00:00",
            "dtiempofin": "2026-02-14T10:30:00.000+00:00"
          },
          {
            "id": 15,
            "cmotivo": "Esperando repuestos",
            "dtiempoinicio": "2026-02-14T11:00:00.000+00:00",
            "dtiempofin": null
          }
        ]
      },
      {
        "tipo": "ST",
        "codigo": "TP-458 ST-789",
        "idDetalle": 458,
        "idAsignacion": 789,
        "ordentrabajo": { },
        "detalle": { },
        "empleadoPrincipal": {
          "id": "2540",
          "nombre": "PEDRO SILVA",
          "cargo": "TECNICO MECANICO"
        },
        "subActividad": "Lubricacion de componentes",
        "tiempoEstimado": 60,
        "dtiempoinicio": null,
        "dtiempofin": null,
        "bcerrada": false,
        "cobservaciones": null,
        "cestadomovil": "NO_INICIADA",
        "pausas": []
      }
    ]
  }
]
```

---

## Campos: `empleado`

| Campo | Tipo | Descripción |
|-------|------|-------------|
| `id` | Integer | ID del empleado externo |
| `nombres` | String | Nombres |
| `apellidopaterno` | String | Apellido paterno |
| `apellidomaterno` | String | Apellido materno |
| `nombreCompleto` | String | Nombre completo |
| `numerodocumento` | String | DNI u otro documento |
| `cargo` | String | Cargo |
| `area` | String | Área de trabajo |
| `cantidadActividades` | Integer | Total TP asignadas (incluye backlog) |
| `cantidadAsistencias` | Integer | Total ST donde es asistente |
| `cantidadTotal` | Integer | `cantidadActividades` + `cantidadAsistencias` |
| `fechaActividadReciente` | Date | Fecha de la actividad más reciente |

---

## Campos: `actividades[]`

| Campo | Tipo | Descripción |
|-------|------|-------------|
| `tipo` | String | `"TP"` (responsable principal) o `"ST"` (asistente) |
| `codigo` | String | `"TP-1234"` o `"TP-1234 ST-5678"` |
| `idDetalle` | Integer | ID del `DetalleOrdentrabajo` |
| `idAsignacion` | Integer | ID del `DetalleAsignacion` (solo ST, `null` para TP) |
| `ordentrabajo` | Object | Objeto completo `Ordentrabajo` |
| `detalle` | Object | Objeto completo `DetalleOrdentrabajo` |
| `empleadoPrincipal` | Object | Solo para ST (ver tabla abajo) |
| `subActividad` | String | Descripción de la sub-actividad (solo ST) |
| `tiempoEstimado` | Integer | Minutos estimados (solo ST) |
| `dtiempoinicio` | Date | Timestamp de inicio |
| `dtiempofin` | Date | Timestamp de fin |
| `bcerrada` | Boolean | `true` si la actividad está cerrada |
| `cobservaciones` | String | Observaciones |
| `cestadomovil` | String | Estado calculado (ver tabla abajo) |
| `pausas` | Array | Lista de pausas. Array vacío `[]` si no hay. |

### Estados (`cestadomovil`)

| Valor | Condición |
|-------|-----------|
| `NO_INICIADA` | `dtiempoinicio = null` |
| `EN_PROCESO` | Tiene inicio, no cerrada, sin pausa activa |
| `PAUSADA` | Existe al menos una pausa con `dtiempofin = null` |
| `TERMINADA` | `bcerrada = true` |

### `empleadoPrincipal` (solo ST)

| Campo | Tipo | Descripción |
|-------|------|-------------|
| `id` | String | ID del empleado principal |
| `nombre` | String | Nombre del empleado principal |
| `cargo` | String | Cargo del empleado principal |

---

## Campos: `pausas[]`

Lista ordenada de más antigua a más reciente.

| Campo | Tipo | Descripción |
|-------|------|-------------|
| `id` | Integer | ID de la pausa |
| `cmotivo` | String | Motivo |
| `dtiempoinicio` | DateTime | Inicio de la pausa |
| `dtiempofin` | DateTime | Fin de la pausa. `null` si la pausa sigue activa |

---

## Campos relevantes: `detalle` (DetalleOrdentrabajo)

| Campo | Tipo | Descripción |
|-------|------|-------------|
| `id` | Integer | ID del detalle |
| `cactividad` | String | Descripción de la actividad |
| `bbacklog` | Boolean | `true` = actividad arrastrada de OT anterior |
| `bcerrada` | Boolean | `true` = actividad completada |
| `idempleadoext` | String | ID del empleado asignado |
| `cnombreemp` | String | Nombre del empleado |
| `ccargoemp` | String | Cargo del empleado |
| `dtiempoinicio` | Date | Inicio |
| `dtiempofin` | Date | Fin |
| `nminutosemp` | Integer | Minutos trabajados |
| `cobservaciones` | String | Observaciones |
| `idordentrabajo` | Integer | ID de la OT padre |

---

## Notas

- **Tipos de actividad**: TP = empleado es el responsable. ST = empleado es asistente de otro.
- **Pausas**: `dtiempofin = null` indica pausa activa. Las pausas de TP se guardan en `pausa_detalle_ordentrabajo`; las de ST en `pausa_detalle_asignacion`.
- **Backlog**: `detalle.bbacklog = true` indica actividad pendiente de una OT anterior. Solo se muestran backlogs cuya OT sigue abierta y no han sido reprogramados.
- **Ordenamiento**: empleados por `fechaActividadReciente` DESC; pausas por `dtiempoinicio` ASC.

---

## Historial de Cambios

### v2.3.0 (18 de Febrero de 2026)
- Campo `pausaActiva` (objeto, solo cuando pausada) reemplazado por `pausas` (array siempre presente)
- `pausas` incluye todas las pausas activas y cerradas, ordenadas ASC
- Cada pausa agrega campo `dtiempofin` (`null` = activa)
- Nuevo método `buscarTodasPausasXidsAsignacion()` en `PausaDetalleAsignacionRepository`

### v2.2.0 (16 de Febrero de 2026)
- Campo `cestadomovil` con estado calculado automáticamente
- Campo `pausaActiva` con info de la pausa activa
- Queries batch para pausas (elimina N+1)

### v2.1.0 (11 de Febrero de 2026)
- Filtro de backlog: excluye reprogramados y OTs cerradas

### v2.0.0 (11 de Febrero de 2026)
- Eliminado `cantidadBacklog`; `cantidadActividades` ahora incluye backlog
