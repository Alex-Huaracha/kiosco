# 📡 API - Lista de Actividades por Empleado

**Versión:** 2.2.0  
**Fecha:** 16 de Febrero de 2026  
**Base URL:** `http://localhost:8080/api/v1` (desarrollo) | `http://{servidor}:{puerto}/api/v1` (producción)

---

## Información General

**Endpoint:** `/empleadosactividades`  
**Método:** `POST`  
**Content-Type:** `application/json`  
**Autenticación:** No requiere

---

## Descripción

Endpoint optimizado que retorna todos los empleados de mantenimiento con sus actividades pendientes (TP y ST) en una sola llamada. Diseñado para carga offline masiva en aplicaciones móviles.

### ✨ Características Principales

- ✅ **Carga batch optimizada** - Una sola llamada HTTP con todos los datos
- ✅ **Estados calculados automáticamente** - Cada actividad incluye su estado actual
- ✅ **Información de pausas activas** - Detecta actividades pausadas con motivo y tiempo
- ✅ **Unifica dos tipos de tareas:**
  - **TP (Tarea Principal)**: Empleado es el responsable principal
  - **ST (Sub-Tarea)**: Empleado es asistente de otro empleado
- ✅ **Incluye backlog** - Actividades pendientes de órdenes anteriores
- ✅ **Optimización N+1 eliminada** - Queries batch para máximo rendimiento

---

## Solicitud (Request)

### URL Completa
```
POST http://localhost:8080/api/v1/empleadosactividades
```

### Body
El endpoint **NO requiere parámetros** (body vacío):

```json
{}
```

### Ejemplo cURL
```bash
curl -X POST http://localhost:8080/api/v1/empleadosactividades \
  -H "Content-Type: application/json" \
  -d '{}'
```

---

## Respuesta (Response)

### Código de Estado
- `200 OK` - Solicitud exitosa
- `500 Internal Server Error` - Error en el servidor

### Estructura de la Respuesta

Array de empleados con sus actividades, ordenados por fecha de actividad más reciente (descendente).

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
      "cantidadAsistencias": 2,
      "cantidadTotal": 5,
      "fechaActividadReciente": "2026-02-14T10:30:00.000+00:00"
    },
    "actividades": [
      {
        "tipo": "TP",
        "codigo": "TP-456",
        "idDetalle": 456,
        "idAsignacion": null,
        "ordentrabajo": { /* Objeto Ordentrabajo */ },
        "detalle": { /* Objeto DetalleOrdentrabajo */ },
        "empleadoPrincipal": null,
        "subActividad": null,
        "tiempoEstimado": null,
        "dtiempoinicio": "2026-02-14T08:30:00.000+00:00",
        "dtiempofin": null,
        "bcerrada": false,
        "cobservaciones": null,
        "cestadomovil": "EN_PROCESO",
        "pausaActiva": null
      },
      {
        "tipo": "TP",
        "codigo": "TP-457",
        "idDetalle": 457,
        "idAsignacion": null,
        "dtiempoinicio": "2026-02-14T09:00:00.000+00:00",
        "dtiempofin": null,
        "bcerrada": false,
        "cestadomovil": "PAUSADA",
        "pausaActiva": {
          "id": 25,
          "cmotivo": "Esperando repuestos",
          "dtiempoinicio": "2026-02-14T10:15:00.000+00:00"
        }
      },
      {
        "tipo": "ST",
        "codigo": "TP-458 ST-789",
        "idDetalle": 458,
        "idAsignacion": 789,
        "empleadoPrincipal": {
          "id": "2540",
          "nombre": "PEDRO SILVA",
          "cargo": "TECNICO MECANICO"
        },
        "subActividad": "Lubricación de componentes",
        "tiempoEstimado": 60,
        "dtiempoinicio": null,
        "dtiempofin": null,
        "bcerrada": false,
        "cestadomovil": "NO_INICIADA",
        "pausaActiva": null
      },
      {
        "tipo": "TP",
        "codigo": "TP-459",
        "idDetalle": 459,
        "dtiempoinicio": "2026-02-14T07:00:00.000+00:00",
        "dtiempofin": "2026-02-14T08:00:00.000+00:00",
        "bcerrada": true,
        "cestadomovil": "TERMINADA",
        "pausaActiva": null
      }
    ]
  }
]
```

---

## Descripción de Campos

### Objeto: `empleado` (DtoEmpleadoConActividades)

| Campo | Tipo | Descripción |
|-------|------|-------------|
| `id` | Integer | ID del empleado externo |
| `nombres` | String | Nombres del empleado |
| `apellidopaterno` | String | Apellido paterno |
| `apellidomaterno` | String | Apellido materno |
| `nombreCompleto` | String | Nombre completo concatenado |
| `numerodocumento` | String | Número de documento (DNI, etc.) |
| `cargo` | String | Cargo del empleado |
| `area` | String | Área de trabajo |
| `cantidadActividades` | Integer | **Total de tareas principales (TP) asignadas** (incluye backlog) |
| `cantidadTotal` | Integer | **Total general** = `cantidadActividades` + `cantidadAsistencias` |
| `cantidadAsistencias` | Integer | Cantidad de sub-tareas (ST) donde es asistente |
| `fechaActividadReciente` | Date | Fecha de la actividad más reciente (TP o ST) |

### Objeto: `actividades[]` (DtoActividadUnificada)

| Campo | Tipo | Descripción |
|-------|------|-------------|
| `tipo` | String | **"TP"** (Tarea Principal) o **"ST"** (Sub-Tarea) |
| `codigo` | String | Código visual: `"TP-1234"` o `"TP-1234 ST-5678"` |
| `idDetalle` | Integer | ID del `DetalleOrdentrabajo` (siempre presente) |
| `idAsignacion` | Integer | ID del `DetalleAsignacion` (solo para ST, `null` para TP) |
| `ordentrabajo` | Object | Objeto completo de la orden de trabajo |
| `detalle` | Object | Objeto completo `DetalleOrdentrabajo` (contiene `bbacklog`) |
| `empleadoPrincipal` | Object | Info del empleado principal (solo para ST, `null` para TP) |
| `subActividad` | String | Descripción de la sub-actividad (solo para ST) |
| `tiempoEstimado` | Integer | Tiempo estimado en minutos (solo para ST) |
| `dtiempoinicio` | Date | Fecha/hora de inicio de la actividad |
| `dtiempofin` | Date | Fecha/hora de fin de la actividad |
| `bcerrada` | Boolean | Indica si la actividad está cerrada |
| `cobservaciones` | String | Observaciones de la actividad |
| **`cestadomovil`** | **String** | **NUEVO:** Estado calculado (ver tabla de estados) |
| **`pausaActiva`** | **Object/null** | **NUEVO:** Info de pausa activa (solo si `cestadomovil = "PAUSADA"`) |

### Estados de Actividad (cestadomovil)

| Estado | Descripción | Condición |
|--------|-------------|-----------|
| `NO_INICIADA` | Actividad pendiente de iniciar | `dtiempoinicio = null` |
| `EN_PROCESO` | Actividad en ejecución | Tiene tiempo inicio, no está cerrada ni pausada |
| `PAUSADA` | Actividad pausada temporalmente | Existe pausa activa sin tiempo fin |
| `TERMINADA` | Actividad completada | `bcerrada = true` |

### Objeto: `pausaActiva` (DtoPausaActiva) - Solo cuando cestadomovil = "PAUSADA"

| Campo | Tipo | Descripción |
|-------|------|-------------|
| `id` | Integer | ID de la pausa |
| `cmotivo` | String | Motivo de la pausa |
| `dtiempoinicio` | DateTime | Fecha/hora cuando se inició la pausa |

### Objeto: `detalle` (DetalleOrdentrabajo) - Campos Relevantes

| Campo | Tipo | Descripción | Importante |
|-------|------|-------------|-----------|
| `id` | Integer | ID del detalle | ✓ |
| `cactividad` | String | Descripción de la actividad | ✓ |
| **`bbacklog`** | **Boolean** | **`true` = Es actividad de backlog (arrastrada)** | **⭐ CLAVE** |
| `bcerrada` | Boolean | `true` = Actividad cerrada/completada | ✓ |
| `idempleadoext` | String | ID del empleado asignado | ✓ |
| `cnombreemp` | String | Nombre del empleado | ✓ |
| `ccargoemp` | String | Cargo del empleado | ✓ |
| `dtiempoinicio` | Date | Fecha/hora de inicio | ✓ |
| `dtiempofin` | Date | Fecha/hora de fin | ✓ |
| `nminutosemp` | Integer | Minutos trabajados | |
| `cobservaciones` | String | Observaciones | |
| `idordentrabajo` | Integer | ID de la orden de trabajo padre | ✓ |

### Objeto: `empleadoPrincipal` (DtoEmpleadoPrincipal) - Solo para ST

| Campo | Tipo | Descripción |
|-------|------|-------------|
| `id` | String | ID del empleado principal |
| `nombre` | String | Nombre del empleado principal |
| `cargo` | String | Cargo del empleado principal |

---

## Cambios Importantes vs. Versión Anterior

### ❌ Campo ELIMINADO: `cantidadBacklog`

**Antes (versión anterior):**
```json
{
  "empleado": {
    "cantidadActividades": 5,
    "cantidadBacklog": 3,     // ❌ YA NO EXISTE
    "cantidadTotal": 10
  }
}
```

**Ahora (versión actual):**
```json
{
  "empleado": {
    "cantidadActividades": 8,   // ✅ Incluye backlog + normales
    "cantidadTotal": 10
  }
}
```

### ✅ Indicador Individual de Backlog Preservado

Para saber si una actividad específica es backlog, acceder a:

```javascript
actividad.detalle.bbacklog === true  // Es backlog
actividad.detalle.bbacklog === false // Es actividad normal
```

---

## Lógica de Negocio

### ¿Qué es un Backlog?

Una actividad se marca como **backlog** (`bbacklog = true`) cuando:
1. Es una actividad pendiente de una orden de trabajo anterior
2. El vehículo volvió para una nueva orden de trabajo
3. El sistema trajo automáticamente las actividades pendientes
4. El planner las asignó a un empleado (puede ser el mismo u otro)

**Importante:** 
- El campo `bbacklog = true` se **mantiene** incluso después de reasignar
- Cuando el empleado completa la actividad: `bcerrada = true` y `bbacklog = true` (ambos)

### Flujo Completo de Backlog y Reprogramación

```
OT-001 (cerrada) → Detalle ID=100
                   - bbacklog = true
                   - breprogramado = false  ◄── NO aparece en lista (OT cerrada)
                   - bcerrada = 0/NULL
                     ↓
                   (Vehículo regresa → se crea OT-002)
                     ↓
OT-002 (nueva)   → Detalle ID=250 (NUEVO REGISTRO)
                   - iddetalleorigen = 100
                   - bbacklog = true       ◄── Hereda el backlog
                   - breprogramado = false
                   - bcerrada = 0/NULL
                   - idempleadoext = "2537" ◄── ✅ SÍ aparece en lista
                     ↓
                   (Se marca el registro original como reprogramado)
                     ↓
OT-001           → Detalle ID=100 (se actualiza)
                   - bbacklog = true
                   - breprogramado = true  ◄── Ya NO aparece en lista
```

**Campos clave:**
- **`bbacklog`**: Indica que la actividad viene de una OT anterior (se hereda al copiar)
- **`breprogramado`**: Indica que el backlog original ya fue copiado a una nueva OT
- **`iddetalleorigen`**: Referencia al detalle original que generó este backlog
- **`o.bcerrada`**: Estado de la orden de trabajo (abierta/cerrada)

### Criterios de Actividad Pendiente

Una actividad se considera **pendiente** cuando cumple **TODOS** estos criterios:

```sql
d.bactivo = 1                              -- Está activa
AND (d.bcerrada IS NULL OR d.bcerrada = 0) -- NO está cerrada
AND d.idempleadoext IS NOT NULL            -- Tiene empleado asignado

-- FILTRO DE BACKLOG (nuevo)
AND (
    d.bbacklog IS NULL OR d.bbacklog = 0   -- NO es backlog (actividad normal)
    OR                                      -- O BIEN...
    (
        d.bbacklog = 1                      -- ES backlog
        AND (d.breprogramado IS NULL OR d.breprogramado = 0)  -- NO reprogramado aún
        AND (o.bcerrada IS NULL OR o.bcerrada = 0)            -- OT está ABIERTA
    )
)
```

**Explicación del filtro:**
- **Actividades normales** (`bbacklog = 0/NULL`): Siempre se muestran
- **Backlog NO reprogramado** con **OT abierta**: Se muestran (esperando asignación)
- **Backlog reprogramado** (`breprogramado = 1`): NO se muestran (ya fueron copiados)
- **Backlog con OT cerrada**: NO se muestran (esperando nueva OT del vehículo)

### Ordenamiento

Las actividades se ordenan por:
1. **Por empleado** (agrupadas por empleado)
2. **Por fecha de registro** (más recientes primero) - **Sin priorizar backlog**

---

## 💡 Casos de Uso

### 1. Identificar Estado de Actividad

Cada actividad incluye su estado calculado automáticamente en `cestadomovil`:

- **`NO_INICIADA`**: Actividad pendiente (sin `dtiempoinicio`)
- **`EN_PROCESO`**: Actividad en curso (con inicio, sin cerrar, sin pausa)
- **`PAUSADA`**: Actividad temporalmente detenida (con pausa activa)
- **`TERMINADA`**: Actividad completada (`bcerrada = true`)

### 2. Detectar Actividades Pausadas

Cuando `cestadomovil = "PAUSADA"`, el campo `pausaActiva` contiene:
- ID de la pausa
- Motivo de la pausa
- Fecha/hora de inicio de la pausa

### 3. Diferenciar TP vs ST

- **`tipo = "TP"`**: Empleado es responsable principal
- **`tipo = "ST"`**: Empleado es asistente (ver `empleadoPrincipal` para saber quién es el responsable)

### 4. Identificar Backlog

Acceder a `actividad.detalle.bbacklog`:
- `true`: Actividad pendiente de orden anterior
- `false/null`: Actividad normal de la orden actual

### 5. Contadores de Actividades

- `cantidadActividades`: Total de tareas principales (TP)
- `cantidadAsistencias`: Total de sub-tareas (ST)
- `cantidadTotal`: Suma de ambos

---

## 📄 Ejemplo de Respuesta Completa

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
        "ordentrabajo": {
          "id": 123,
          "idplacatracto": "ABC-123",
          "bcerrada": false
        },
        "detalle": {
          "id": 456,
          "cactividad": "Cambio de aceite motor",
          "bbacklog": false,
          "bcerrada": false,
          "dtiempoinicio": "2026-02-14T08:30:00.000+00:00",
          "dtiempofin": null
        },
        "empleadoPrincipal": null,
        "subActividad": null,
        "tiempoEstimado": null,
        "dtiempoinicio": "2026-02-14T08:30:00.000+00:00",
        "dtiempofin": null,
        "bcerrada": false,
        "cobservaciones": null,
        "cestadomovil": "EN_PROCESO",
        "pausaActiva": null
      },
      {
        "tipo": "TP",
        "codigo": "TP-457",
        "idDetalle": 457,
        "idAsignacion": null,
        "detalle": {
          "id": 457,
          "cactividad": "Revision de frenos",
          "bbacklog": false,
          "dtiempoinicio": "2026-02-14T09:00:00.000+00:00"
        },
        "dtiempoinicio": "2026-02-14T09:00:00.000+00:00",
        "bcerrada": false,
        "cestadomovil": "PAUSADA",
        "pausaActiva": {
          "id": 15,
          "cmotivo": "Esperando repuestos",
          "dtiempoinicio": "2026-02-14T10:30:00.000+00:00"
        }
      },
      {
        "tipo": "TP",
        "codigo": "TP-458",
        "idDetalle": 458,
        "detalle": {
          "id": 458,
          "cactividad": "Cambio de filtros",
          "bbacklog": true,
          "dtiempoinicio": null
        },
        "dtiempoinicio": null,
        "bcerrada": false,
        "cestadomovil": "NO_INICIADA",
        "pausaActiva": null
      },
      {
        "tipo": "ST",
        "codigo": "TP-459 ST-790",
        "idDetalle": 459,
        "idAsignacion": 790,
        "empleadoPrincipal": {
          "id": "2540",
          "nombre": "PEDRO SILVA",
          "cargo": "TECNICO MECANICO"
        },
        "subActividad": "Revision de componentes electricos",
        "tiempoEstimado": 45,
        "dtiempoinicio": "2026-02-14T07:00:00.000+00:00",
        "dtiempofin": "2026-02-14T08:00:00.000+00:00",
        "bcerrada": true,
        "cestadomovil": "TERMINADA",
        "pausaActiva": null
      }
    ]
  }
]
```

---

## ⚠️ Notas Importantes

### Estados Calculados Automáticamente

- El backend calcula el estado de cada actividad en tiempo real
- No es necesario implementar lógica de cálculo de estados en el frontend
- El campo `pausaActiva` solo tiene valor cuando `cestadomovil = "PAUSADA"`

### Pausas Activas

- **Tareas Principales (TP)**: Las pausas se registran en `pausa_detalle_ordentrabajo`
- **Sub-Tareas (ST)**: Las pausas se registran en `pausa_detalle_asignacion`
- Una pausa activa es aquella con `dtiempofin = null` y `bactivo = true`

### Backlog

- `detalle.bbacklog = true`: Actividad pendiente de una orden anterior
- `detalle.bbacklog = false/null`: Actividad normal de la orden actual
- Solo se muestran backlogs con OT abierta y no reprogramados

### Ordenamiento

- Empleados ordenados por `fechaActividadReciente` (descendente)
- Actividades sin ordenamiento específico dentro de cada empleado

### 💡 Recomendaciones UI/UX

1. **Indicadores de Estado**:
   - `NO_INICIADA`: Badge gris "Pendiente"
   - `EN_PROCESO`: Badge azul "En Curso"
   - `PAUSADA`: Badge amarillo/naranja "Pausada" + mostrar motivo
   - `TERMINADA`: Badge verde "Completada"

2. **Badge de Backlog**: 
   - Mostrar `⚠️ BACKLOG` cuando `detalle.bbacklog = true`

3. **Información de Pausa**:
   - Cuando `cestadomovil = "PAUSADA"`, mostrar:
     - Motivo: `pausaActiva.cmotivo`
     - Desde: `pausaActiva.dtiempoinicio`

4. **Diferenciación TP vs ST**:
   - TP: "Responsable principal"
   - ST: "Asistiendo a [empleadoPrincipal.nombre]"

---

## 🔧 Información Técnica

**Controller:** `OrdentrabajoServiceController.java`  
**Método:** `listarEmpleadosActividades()`  
**Línea:** ~199

**Repositorios utilizados:**
- `DetalleOrdentrabajoRepository`
- `DetalleAsignacionRepository`
- `OrdentrabajoRepository`
- `PausaDetalleOrdentrabajoRepository` ⭐ NUEVO
- `PausaDetalleAsignacionRepository` ⭐ NUEVO

**DTOs principales:**
- `DtoEmpleadoConActividadesUnificadas`
- `DtoActividadUnificada` (modificado)
- `DtoActividadUnificada.DtoPausaActiva` ⭐ NUEVO

---

## 📝 Historial de Cambios

### Versión 2.2.0 (16 de Febrero de 2026) ⭐ ACTUAL
**Estados Calculados y Pausas Activas**

- ✅ **NUEVO**: Campo `cestadomovil` - Estado calculado automáticamente
  - Estados: `NO_INICIADA`, `EN_PROCESO`, `PAUSADA`, `TERMINADA`
- ✅ **NUEVO**: Campo `pausaActiva` - Información de pausas activas
  - Incluye: `id`, `cmotivo`, `dtiempoinicio`
- ✅ **NUEVO**: Clase interna `DtoPausaActiva` en `DtoActividadUnificada`
- 🚀 **OPTIMIZACIÓN**: Queries batch para obtener pausas (elimina problema N+1)
  - 2 queries batch adicionales (TP y ST) en lugar de N queries individuales
- 🔧 Agregados métodos `calcularEstadoActividad()` y `calcularEstadoAsignacion()`
- 🔧 Inyectados repositorios de pausas (TP y ST)

**Archivos modificados:**
- `DtoActividadUnificada.java`: +2 campos, +1 clase interna
- `PausaDetalleOrdentrabajoRepository.java`: +1 método batch
- `PausaDetalleAsignacionRepository.java`: +2 métodos
- `OrdentrabajoServiceController.java`: +150 líneas aprox

### Versión 2.1.0 (11 de Febrero de 2026)
**Filtrado de Backlog**

- 🔧 Filtro para excluir backlogs reprogramados (`breprogramado = true`)
- 🔧 Filtro para excluir backlogs con OT cerrada
- ✅ Solo muestra backlogs activos con OT abierta

### Versión 2.0.0 (11 de Febrero de 2026)
**Simplificación de Contadores**

- ❌ Eliminado campo `cantidadBacklog`
- ✅ `cantidadActividades` incluye backlog + normales
- ✅ Preservado `detalle.bbacklog` individual

---

**Última actualización:** 16 de Febrero de 2026  
**Proyecto:** hgapi 0.0.1-SNAPSHOT
