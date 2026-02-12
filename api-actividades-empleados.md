# API - Lista de Actividades por Empleado

## Información General

**Endpoint:** `/empleadosactividades`  
**Método:** `POST`  
**Content-Type:** `application/json`  
**Autenticación:** No especificada (CORS abierto: `*`)

---

## Descripción

Este endpoint devuelve una lista completa de todos los empleados que tienen actividades pendientes asignadas, junto con el detalle de cada una de sus actividades. Está diseñado para carga offline masiva en una sola llamada.

### Características Principales

- ✅ **Carga en batch optimizada** - Una sola llamada trae todos los empleados con sus actividades
- ✅ **Unifica dos tipos de tareas:**
  - **TP (Tarea Principal)**: Actividades donde el empleado es el responsable principal
  - **ST (Sub-Tarea)**: Actividades donde el empleado es asistente de otro empleado
- ✅ **Incluye backlog** - Las actividades marcadas como backlog se incluyen en el conteo normal
- ✅ **Indicador de backlog individual** - Cada actividad indica si es backlog mediante `detalle.bbacklog`

---

## Solicitud (Request)

### URL Completa
```
POST http://{host}:{port}/empleadosactividades
```

### Headers
```http
Content-Type: application/json
```

### Body
El endpoint **NO requiere body** (cuerpo vacío o `{}`):

```json
{}
```

### Ejemplo cURL
```bash
curl -X POST \
  http://localhost:8080/empleadosactividades \
  -H 'Content-Type: application/json' \
  -d '{}'
```

---

## Respuesta (Response)

### Código de Estado
- `200 OK` - Solicitud exitosa
- `500 Internal Server Error` - Error en el servidor

### Estructura de la Respuesta

La respuesta es un **array de objetos** `DtoEmpleadoConActividadesUnificadas`, ordenados por fecha de actividad más reciente (más recientes primero).

```json
[
  {
    "empleado": {
      "id": 123,
      "nombres": "Juan",
      "apellidopaterno": "Pérez",
      "apellidomaterno": "García",
      "nombreCompleto": "Juan Pérez García",
      "numerodocumento": "12345678",
      "cargo": "Mecánico",
      "area": "Mantenimiento",
      "cantidadActividades": 8,
      "cantidadTotal": 10,
      "cantidadAsistencias": 2,
      "fechaActividadReciente": "2026-02-11T14:30:00.000+00:00"
    },
    "actividades": [
      {
        "tipo": "TP",
        "codigo": "TP-1234",
        "idDetalle": 1234,
        "idAsignacion": null,
        "ordentrabajo": { /* Objeto Ordentrabajo completo */ },
        "detalle": {
          "id": 1234,
          "cactividad": "Cambio de aceite",
          "bbacklog": false,
          "bcerrada": false,
          "idempleadoext": "123",
          "cnombreemp": "Juan Pérez García",
          "ccargoemp": "Mecánico",
          "dtiempoinicio": null,
          "dtiempofin": null,
          "cobservaciones": null
          /* ... más campos de DetalleOrdentrabajo */
        },
        "empleadoPrincipal": null,
        "subActividad": null,
        "tiempoEstimado": null,
        "dtiempoinicio": null,
        "dtiempofin": null,
        "bcerrada": false,
        "cobservaciones": null
      },
      {
        "tipo": "ST",
        "codigo": "TP-1234 ST-5678",
        "idDetalle": 1234,
        "idAsignacion": 5678,
        "ordentrabajo": { /* Objeto Ordentrabajo completo */ },
        "detalle": { /* DetalleOrdentrabajo del responsable principal */ },
        "empleadoPrincipal": {
          "id": "456",
          "nombre": "María López",
          "cargo": "Jefe de Mecánicos"
        },
        "subActividad": "Asistir en cambio de transmisión",
        "tiempoEstimado": 120,
        "dtiempoinicio": null,
        "dtiempofin": null,
        "bcerrada": false,
        "cobservaciones": null
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
| `detalle` | Object | Objeto completo `DetalleOrdentrabajo` (contiene **`bbacklog`**) |
| `empleadoPrincipal` | Object | Info del empleado principal (solo para ST, `null` para TP) |
| `subActividad` | String | Descripción de la sub-actividad (solo para ST) |
| `tiempoEstimado` | Integer | Tiempo estimado en minutos (solo para ST) |
| `dtiempoinicio` | Date | Fecha/hora de inicio de la actividad |
| `dtiempofin` | Date | Fecha/hora de fin de la actividad |
| `bcerrada` | Boolean | Indica si la actividad está cerrada |
| `cobservaciones` | String | Observaciones de la actividad |

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

## Casos de Uso Frontend

### 1. Mostrar Lista de Empleados con Contadores

```javascript
// Parsear respuesta
const empleados = JSON.parse(response);

empleados.forEach(emp => {
  console.log(`${emp.empleado.nombreCompleto}:`);
  console.log(`  - Tareas Principales: ${emp.empleado.cantidadActividades}`);
  console.log(`  - Asistencias: ${emp.empleado.cantidadAsistencias}`);
  console.log(`  - Total: ${emp.empleado.cantidadTotal}`);
});
```

### 2. Identificar y Destacar Actividades de Backlog

```javascript
// Recorrer actividades de un empleado
emp.actividades.forEach(actividad => {
  const esBacklog = actividad.detalle.bbacklog === true;
  
  if (esBacklog) {
    // Mostrar badge "BACKLOG" o ícono especial
    console.log(`⚠️ BACKLOG: ${actividad.detalle.cactividad}`);
  } else {
    console.log(`✓ ${actividad.detalle.cactividad}`);
  }
});
```

### 3. Filtrar Solo Actividades de Backlog

```javascript
// Obtener solo actividades de backlog
const actividadesBacklog = emp.actividades.filter(
  act => act.detalle.bbacklog === true
);

console.log(`Actividades de backlog: ${actividadesBacklog.length}`);
```

### 4. Diferenciar entre TP y ST

```javascript
emp.actividades.forEach(actividad => {
  if (actividad.tipo === "TP") {
    // Es tarea principal - el empleado es el responsable
    console.log(`📋 Tarea Principal: ${actividad.detalle.cactividad}`);
  } else if (actividad.tipo === "ST") {
    // Es sub-tarea - el empleado es asistente
    console.log(`🤝 Asistir a: ${actividad.empleadoPrincipal.nombre}`);
    console.log(`   Actividad: ${actividad.subActividad}`);
  }
});
```

### 5. Calcular Totales Personalizados

```javascript
// Contar actividades de backlog vs normales
const totalBacklog = emp.actividades.filter(
  act => act.tipo === "TP" && act.detalle.bbacklog === true
).length;

const totalNormales = emp.actividades.filter(
  act => act.tipo === "TP" && act.detalle.bbacklog !== true
).length;

console.log(`Backlog: ${totalBacklog}, Normales: ${totalNormales}`);
```

---

## Ejemplo Completo de Respuesta

```json
[
  {
    "empleado": {
      "id": 101,
      "nombres": "Carlos",
      "apellidopaterno": "Ruiz",
      "apellidomaterno": "Torres",
      "nombreCompleto": "Carlos Ruiz Torres",
      "numerodocumento": "87654321",
      "cargo": "Técnico Eléctrico",
      "area": "Electricidad",
      "cantidadActividades": 3,
      "cantidadTotal": 5,
      "cantidadAsistencias": 2,
      "fechaActividadReciente": "2026-02-11T10:15:00.000+00:00"
    },
    "actividades": [
      {
        "tipo": "TP",
        "codigo": "TP-8901",
        "idDetalle": 8901,
        "idAsignacion": null,
        "ordentrabajo": {
          "id": 450,
          "idplacatracto": "ABC-123",
          "bcerrada": false
        },
        "detalle": {
          "id": 8901,
          "idordentrabajo": 450,
          "cactividad": "Revisar sistema eléctrico",
          "bbacklog": true,
          "bcerrada": false,
          "idempleadoext": "101",
          "cnombreemp": "Carlos Ruiz Torres",
          "ccargoemp": "Técnico Eléctrico",
          "dtiempoinicio": null,
          "dtiempofin": null,
          "nminutosemp": null,
          "cobservaciones": null
        },
        "empleadoPrincipal": null,
        "subActividad": null,
        "tiempoEstimado": null,
        "dtiempoinicio": null,
        "dtiempofin": null,
        "bcerrada": false,
        "cobservaciones": null
      },
      {
        "tipo": "TP",
        "codigo": "TP-8902",
        "idDetalle": 8902,
        "idAsignacion": null,
        "ordentrabajo": {
          "id": 451,
          "idplacatracto": "XYZ-789",
          "bcerrada": false
        },
        "detalle": {
          "id": 8902,
          "idordentrabajo": 451,
          "cactividad": "Cambio de alternador",
          "bbacklog": false,
          "bcerrada": false,
          "idempleadoext": "101",
          "cnombreemp": "Carlos Ruiz Torres",
          "ccargoemp": "Técnico Eléctrico",
          "dtiempoinicio": "2026-02-11T08:00:00.000+00:00",
          "dtiempofin": null,
          "nminutosemp": null,
          "cobservaciones": "Alternador solicitado a almacén"
        },
        "empleadoPrincipal": null,
        "subActividad": null,
        "tiempoEstimado": null,
        "dtiempoinicio": "2026-02-11T08:00:00.000+00:00",
        "dtiempofin": null,
        "bcerrada": false,
        "cobservaciones": "Alternador solicitado a almacén"
      },
      {
        "tipo": "ST",
        "codigo": "TP-8900 ST-1234",
        "idDetalle": 8900,
        "idAsignacion": 1234,
        "ordentrabajo": {
          "id": 449,
          "idplacatracto": "DEF-456",
          "bcerrada": false
        },
        "detalle": {
          "id": 8900,
          "idordentrabajo": 449,
          "cactividad": "Mantenimiento preventivo completo",
          "bbacklog": false,
          "bcerrada": false,
          "idempleadoext": "205",
          "cnombreemp": "Luis Gómez",
          "ccargoemp": "Jefe de Taller"
        },
        "empleadoPrincipal": {
          "id": "205",
          "nombre": "Luis Gómez",
          "cargo": "Jefe de Taller"
        },
        "subActividad": "Revisar conexiones eléctricas",
        "tiempoEstimado": 60,
        "dtiempoinicio": null,
        "dtiempofin": null,
        "bcerrada": false,
        "cobservaciones": null
      }
    ]
  },
  {
    "empleado": {
      "id": 102,
      "nombres": "Ana",
      "apellidopaterno": "Martínez",
      "apellidomaterno": "Silva",
      "nombreCompleto": "Ana Martínez Silva",
      "numerodocumento": "11223344",
      "cargo": "Mecánica",
      "area": "Mantenimiento",
      "cantidadActividades": 2,
      "cantidadTotal": 2,
      "cantidadAsistencias": 0,
      "fechaActividadReciente": "2026-02-10T16:45:00.000+00:00"
    },
    "actividades": [
      {
        "tipo": "TP",
        "codigo": "TP-8903",
        "idDetalle": 8903,
        "idAsignacion": null,
        "ordentrabajo": {
          "id": 452,
          "idplacatracto": "GHI-321",
          "bcerrada": false
        },
        "detalle": {
          "id": 8903,
          "idordentrabajo": 452,
          "cactividad": "Revisión de frenos",
          "bbacklog": true,
          "bcerrada": false,
          "idempleadoext": "102",
          "cnombreemp": "Ana Martínez Silva",
          "ccargoemp": "Mecánica",
          "dtiempoinicio": null,
          "dtiempofin": null,
          "nminutosemp": null,
          "cobservaciones": "Pendiente desde OT anterior"
        },
        "empleadoPrincipal": null,
        "subActividad": null,
        "tiempoEstimado": null,
        "dtiempoinicio": null,
        "dtiempofin": null,
        "bcerrada": false,
        "cobservaciones": "Pendiente desde OT anterior"
      },
      {
        "tipo": "TP",
        "codigo": "TP-8904",
        "idDetalle": 8904,
        "idAsignacion": null,
        "ordentrabajo": {
          "id": 453,
          "idplacatracto": "JKL-654",
          "bcerrada": false
        },
        "detalle": {
          "id": 8904,
          "idordentrabajo": 453,
          "cactividad": "Cambio de aceite motor",
          "bbacklog": false,
          "bcerrada": false,
          "idempleadoext": "102",
          "cnombreemp": "Ana Martínez Silva",
          "ccargoemp": "Mecánica",
          "dtiempoinicio": "2026-02-10T14:00:00.000+00:00",
          "dtiempofin": "2026-02-10T15:30:00.000+00:00",
          "nminutosemp": 90,
          "cobservaciones": "Completado satisfactoriamente"
        },
        "empleadoPrincipal": null,
        "subActividad": null,
        "tiempoEstimado": null,
        "dtiempoinicio": "2026-02-10T14:00:00.000+00:00",
        "dtiempofin": "2026-02-10T15:30:00.000+00:00",
        "bcerrada": false,
        "cobservaciones": "Completado satisfactoriamente"
      }
    ]
  }
]
```

---

## Notas Importantes

### 🔴 Cambios de la Versión Anterior

1. **Campo `cantidadBacklog` eliminado** - Ya no existe en la respuesta del empleado
2. **`cantidadActividades` ahora incluye backlog** - Es el total de TP (backlog + normales)
3. **Ordenamiento cambiado** - Ya no se prioriza backlog al final, todo se ordena por fecha
4. **Filtro de backlog implementado** - Excluye backlogs reprogramados y backlogs con OT cerrada

### ⚠️ Validaciones Frontend

- Siempre validar que `actividad.detalle` no sea `null` antes de acceder a `bbacklog`
- El campo `bbacklog` puede ser `null`, `true` o `false`
- Considerar `null` como `false` para efectos prácticos
- **IMPORTANTE**: Los backlogs mostrados en la lista son SOLO los que tienen la OT abierta y no fueron reprogramados
- Los backlogs con `breprogramado = true` o con OT cerrada NO aparecen en la lista

### 💡 Recomendaciones UI/UX

1. **Badge de Backlog**: Mostrar un badge visual cuando `detalle.bbacklog === true`
   - Ejemplo: `🔴 BACKLOG` o `⚠️ Pendiente anterior`

2. **Filtros**: Permitir filtrar actividades por:
   - Tipo (TP / ST)
   - Backlog (Sí / No)
   - Estado (Cerrada / Abierta)

3. **Colores diferenciados**:
   - Backlog: Rojo o naranja
   - Normal: Azul o verde
   - Cerrada: Gris

4. **Priorización**: El empleado puede decidir priorizar backlogs viendo el indicador

### 🔍 Casos Especiales de Backlog

| Caso | `bbacklog` | `breprogramado` | OT cerrada | ¿Aparece en lista? | Explicación |
|------|------------|-----------------|------------|-------------------|-------------|
| Actividad normal | false/null | - | No | ✅ SÍ | Actividad estándar de la OT actual |
| Backlog nuevo (no asignado) | true | false/null | **Sí** | ❌ NO | OT cerrada, esperando que vehículo regrese |
| Backlog asignado (OT abierta) | true | false/null | **No** | ✅ SÍ | Backlog en OT nueva, asignado a empleado |
| Backlog reprogramado | true | **true** | Sí | ❌ NO | Ya fue copiado a nueva OT, registro obsoleto |
| Backlog heredado | true | false/null | No | ✅ SÍ | Nuevo registro creado desde backlog original |

**Ejemplo práctico:**

```javascript
// Caso 1: Actividad normal - APARECE ✅
{
  "detalle": {
    "bbacklog": false,
    "breprogramado": false
  },
  "ordentrabajo": {
    "bcerrada": false  // OT abierta
  }
}

// Caso 2: Backlog con OT cerrada - NO APARECE ❌
{
  "detalle": {
    "bbacklog": true,
    "breprogramado": false
  },
  "ordentrabajo": {
    "bcerrada": true  // OT cerrada (pre-cierre aplicado)
  }
}

// Caso 3: Backlog reprogramado - NO APARECE ❌
{
  "detalle": {
    "bbacklog": true,
    "breprogramado": true  // Ya fue copiado
  },
  "ordentrabajo": {
    "bcerrada": true
  }
}

// Caso 4: Backlog reasignado en OT nueva - APARECE ✅
{
  "detalle": {
    "id": 250,
    "bbacklog": true,      // Hereda backlog
    "breprogramado": false,
    "iddetalleorigen": 100 // Referencia al original
  },
  "ordentrabajo": {
    "id": 2,
    "bcerrada": false  // Nueva OT abierta
  }
}
```

---

## Soporte Técnico

**Archivo Controller:** `OrdentrabajoServiceController.java:197`  
**Método:** `listarEmpleadosActividades()`  
**Repositorios:**
- `DetalleOrdentrabajoRepository.java`
- `DetalleAsignacionRepository.java`
- `OrdentrabajoRepository.java`

**Fecha de Última Actualización:** 2026-02-11  
**Versión del Proyecto:** hgapi 0.0.1-SNAPSHOT

---

## Changelog

### Versión 2.1 (2026-02-11) - FIX Filtrado de Backlog
- 🔧 **FIX**: Agregado filtro para excluir backlogs con `breprogramado = true`
- 🔧 **FIX**: Agregado filtro para excluir backlogs cuya OT está cerrada (`o.bcerrada = 1`)
- ✅ Ahora SOLO se muestran:
  - Actividades normales (todas)
  - Backlogs NO reprogramados con OT abierta (esperando nueva asignación)
- ✅ Implementado en 3 queries:
  - `buscarDetallesXempleado`
  - `obtenerConteosActividadesPorEmpleado`
  - `buscarTodosDetallesPendientes`

### Versión 2.0 (2026-02-11) - Eliminación de Conteo Separado
- ❌ Eliminado campo `cantidadBacklog` de la respuesta del empleado
- ✅ `cantidadActividades` ahora incluye actividades de backlog y normales unificadas
- ✅ Simplificado ordenamiento: solo por fecha (sin priorizar backlog al final)
- ✅ Preservado indicador individual `detalle.bbacklog` para cada actividad

### Versión 1.0 (Anterior)
- Conteo separado de backlog (`cantidadBacklog`)
- Ordenamiento priorizando actividades normales antes que backlog
- ⚠️ PROBLEMA: Mostraba backlogs reprogramados y backlogs con OT cerrada
