# API de Pausas con Motivos

Documentación de endpoints para el sistema de registro de pausas con motivos para actividades de mantenimiento.

> **BREAKING CHANGE v2:** El campo `cmotivo` (texto libre) fue reemplazado por `idmotivo` (ID del catálogo) + `cmotivoOtro` (texto libre, solo cuando `idmotivo = 8`). Ver [Guía de Migración para el Frontend](#guia-de-migracion-para-el-frontend).

---

## Índice

1. [Endpoint: Catálogo de Motivos (NUEVO)](#endpoint-0-catalogo-de-motivos)
2. [Endpoint: Gestionar Pausa - Empleado Principal](#endpoint-1-gestionar-pausa---empleado-principal)
3. [Endpoint: Gestionar Pausa - Empleado Asistente](#endpoint-2-gestionar-pausa---empleado-asistente)
4. [Endpoint: Gestionar Estado de Actividad (PAUSAR)](#endpoint-3-gestionar-estado-de-actividad-pausar)
5. [Códigos de Respuesta HTTP](#codigos-de-respuesta-http)
6. [Ejemplos de Errores](#ejemplos-de-errores)
7. [Guía de Migración para el Frontend](#guia-de-migracion-para-el-frontend)
8. [Notas Importantes](#notas-importantes)

---

## Endpoint 0: Catálogo de Motivos

Retorna la lista de motivos de pausa activos. Llamar una vez al iniciar la app y cachear el resultado.

### **URL**
```
GET /api/v1/catalogomotivopausas
```

### **Response (200 OK)**
```json
[
  { "id": 1, "cnombre": "Servicios Higienicos",   "bactivo": true },
  { "id": 2, "cnombre": "Re-asignacion de Tarea", "bactivo": true },
  { "id": 3, "cnombre": "Falta de Repuesto",      "bactivo": true },
  { "id": 4, "cnombre": "Falta de Herramienta",   "bactivo": true },
  { "id": 5, "cnombre": "Alimentacion",            "bactivo": true },
  { "id": 6, "cnombre": "Fin de Turno",            "bactivo": true },
  { "id": 7, "cnombre": "Auxilio Mecanico",        "bactivo": true },
  { "id": 8, "cnombre": "Otro",                    "bactivo": true }
]
```

### **Campos del Response**

| Campo | Tipo | Descripción |
|-------|------|-------------|
| `id` | Integer | ID del motivo (usar como `idmotivo` al registrar pausa) |
| `cnombre` | String | Nombre visible para el usuario |
| `bactivo` | Boolean | Solo se retornan los activos (`true`) |

### **Comportamiento en el frontend**

- Mostrar los motivos como una **lista desplegable** (dropdown / BottomSheet)
- Si el usuario selecciona el motivo con `id = 8` ("Otro"), mostrar un **campo de texto adicional** para que el usuario describa el motivo
- El campo "Otro" no tiene límite mínimo de caracteres pero sí máximo de 500

---

## Endpoint 1: Gestionar Pausa - Empleado Principal

Gestiona pausas para actividades de empleados principales (`DetalleOrdentrabajo`).

### **URL**
```
POST /api/v1/gestionarpausadetalleordentrabajo
```

### **Content-Type**
```
application/json
```

---

### **Operación 1: Registrar Pausa Nueva**

Crea un registro de pausa cuando el empleado presiona el botón "PAUSAR".

#### **Request Body — Motivo predefinido (id 1-7)**
```json
{
  "iddetalleordentrabajo": "123",
  "idmotivo": "3",
  "dtiempoinicio": "2024-02-11 10:30:00.000"
}
```

#### **Request Body — Motivo "Otro" (id 8)**
```json
{
  "iddetalleordentrabajo": "123",
  "idmotivo": "8",
  "cmotivoOtro": "Fui a buscar el permiso del área de logística",
  "dtiempoinicio": "2024-02-11 10:30:00.000"
}
```

#### **Campos del Request**

| Campo | Tipo | Requerido | Descripción |
|-------|------|-----------|-------------|
| `iddetalleordentrabajo` | String | ✅ Sí | ID de la actividad principal (numérico) |
| `idmotivo` | String | ✅ Sí | ID del motivo del catálogo (1-8, numérico) |
| `cmotivoOtro` | String | ⚠️ Solo si `idmotivo = 8` | Descripción libre del motivo. Máximo 500 caracteres. `null` o ausente para motivos 1-7 |
| `dtiempoinicio` | String | ✅ Sí | Timestamp de inicio. Formato: `yyyy-MM-dd HH:mm:ss.SSS` |

#### **Response (200 OK)**
```json
{
  "id": 1,
  "iddetalleordentrabajo": 123,
  "idmotivo": 3,
  "cmotivoOtro": null,
  "dtiempoinicio": "2024-02-11T10:30:00.000+00:00",
  "dtiempofin": null,
  "nminutos": null,
  "bactivo": true
}
```

#### **Campos del Response**

| Campo | Tipo | Descripción |
|-------|------|-------------|
| `id` | Integer | ID único de la pausa creada (**guardar para reanudar**) |
| `iddetalleordentrabajo` | Integer | ID de la actividad |
| `idmotivo` | Integer | ID del motivo seleccionado |
| `cmotivoOtro` | String | Descripción libre (solo si `idmotivo = 8`, de lo contrario `null`) |
| `dtiempoinicio` | DateTime | Timestamp de inicio de pausa |
| `dtiempofin` | DateTime | `null` cuando la pausa está activa |
| `nminutos` | Integer | `null` cuando la pausa está activa |
| `bactivo` | Boolean | Estado del registro (siempre `true`) |

---

### **Operación 2: Reanudar Pausa**

Actualiza el registro de pausa cuando el empleado presiona "REANUDAR". No cambia nada en el motivo.

#### **Request Body**
```json
{
  "id": "1",
  "dtiempofin": "2024-02-11 11:00:00.000"
}
```

#### **Campos del Request**

| Campo | Tipo | Requerido | Descripción |
|-------|------|-----------|-------------|
| `id` | String | ✅ Sí | ID de la pausa a reanudar (retornado al crear la pausa) |
| `dtiempofin` | String | ✅ Sí | Timestamp de fin de pausa. Formato: `yyyy-MM-dd HH:mm:ss.SSS` |

#### **Response (200 OK)**
```json
{
  "id": 1,
  "iddetalleordentrabajo": 123,
  "idmotivo": 3,
  "cmotivoOtro": null,
  "dtiempoinicio": "2024-02-11T10:30:00.000+00:00",
  "dtiempofin": "2024-02-11T11:00:00.000+00:00",
  "nminutos": 30,
  "bactivo": true
}
```

---

## Endpoint 2: Gestionar Pausa - Empleado Asistente

Gestiona pausas para empleados asistentes (`DetalleAsignacion`). Misma lógica que el Endpoint 1.

### **URL**
```
POST /api/v1/gestionarpausadetalleasignacion
```

---

### **Operación 1: Registrar Pausa Nueva**

#### **Request Body — Motivo predefinido (id 1-7)**
```json
{
  "iddetalleasignacion": "456",
  "idmotivo": "5",
  "dtiempoinicio": "2024-02-11 12:00:00.000"
}
```

#### **Request Body — Motivo "Otro" (id 8)**
```json
{
  "iddetalleasignacion": "456",
  "idmotivo": "8",
  "cmotivoOtro": "Coordinación con el proveedor externo",
  "dtiempoinicio": "2024-02-11 12:00:00.000"
}
```

#### **Campos del Request**

| Campo | Tipo | Requerido | Descripción |
|-------|------|-----------|-------------|
| `iddetalleasignacion` | String | ✅ Sí | ID de la asignación (empleado asistente, numérico) |
| `idmotivo` | String | ✅ Sí | ID del motivo del catálogo (1-8, numérico) |
| `cmotivoOtro` | String | ⚠️ Solo si `idmotivo = 8` | Descripción libre. Máximo 500 caracteres |
| `dtiempoinicio` | String | ✅ Sí | Timestamp de inicio. Formato: `yyyy-MM-dd HH:mm:ss.SSS` |

#### **Response (200 OK)**
```json
{
  "id": 2,
  "iddetalleasignacion": 456,
  "idmotivo": 5,
  "cmotivoOtro": null,
  "dtiempoinicio": "2024-02-11T12:00:00.000+00:00",
  "dtiempofin": null,
  "nminutos": null,
  "bactivo": true
}
```

---

### **Operación 2: Reanudar Pausa**

#### **Request Body**
```json
{
  "id": "2",
  "dtiempofin": "2024-02-11 13:30:00.000"
}
```

#### **Response (200 OK)**
```json
{
  "id": 2,
  "iddetalleasignacion": 456,
  "idmotivo": 5,
  "cmotivoOtro": null,
  "dtiempoinicio": "2024-02-11T12:00:00.000+00:00",
  "dtiempofin": "2024-02-11T13:30:00.000+00:00",
  "nminutos": 90,
  "bactivo": true
}
```

---

## Endpoint 3: Gestionar Estado de Actividad (PAUSAR)

El endpoint `/api/v1/gestionarestadoactividad` con acción `PAUSAR` también cambió. Ver documentación de ese endpoint para el detalle completo. El cambio relevante:

### **Antes (campo eliminado)**
```json
{
  "iddetalleordentrabajo": "123",
  "accion": "PAUSAR",
  "timestamp": "2024-02-11 10:30:00.000",
  "cmotivo": "Descanso"
}
```

### **Ahora**
```json
{
  "iddetalleordentrabajo": "123",
  "accion": "PAUSAR",
  "timestamp": "2024-02-11 10:30:00.000",
  "idmotivo": "1",
  "cmotivoOtro": null
}
```

---

## Codigos de Respuesta HTTP

### Respuestas Exitosas

| Código | Descripción |
|--------|-------------|
| `200 OK` | Operación exitosa (pausa registrada o reanudada) |

### Respuestas de Error

| Código | Descripción |
|--------|-------------|
| `400 BAD_REQUEST` | Error en validación de datos (ver mensaje de error) |
| `404 NOT_FOUND` | Pausa no encontrada (al intentar reanudar con ID inexistente) |
| `500 INTERNAL_SERVER_ERROR` | Error interno del servidor |

---

## Ejemplos de Errores

### **Error: idmotivo faltante**

**Request:**
```json
{
  "iddetalleordentrabajo": "123",
  "dtiempoinicio": "2024-02-11 10:30:00.000"
}
```
**Response (400 BAD_REQUEST):**
```
idmotivo es requerido
```

---

### **Error: idmotivo no numérico**

**Request:**
```json
{
  "iddetalleordentrabajo": "123",
  "idmotivo": "abc",
  "dtiempoinicio": "2024-02-11 10:30:00.000"
}
```
**Response (400 BAD_REQUEST):**
```
idmotivo inválido. Solo se permiten números.
```

---

### **Error: cmotivoOtro vacío cuando idmotivo = 8**

**Request:**
```json
{
  "iddetalleordentrabajo": "123",
  "idmotivo": "8",
  "cmotivoOtro": "",
  "dtiempoinicio": "2024-02-11 10:30:00.000"
}
```
**Response (400 BAD_REQUEST):**
```
cmotivoOtro es requerido cuando idmotivo es 8 (Otro)
```

---

### **Error: ID de actividad inválido**

**Response (400 BAD_REQUEST):**
```
iddetalleordentrabajo inválido. Solo se permiten números.
```

---

### **Error: Formato de fecha incorrecto**

**Response (400 BAD_REQUEST):**
```
dtiempoinicio inválido. Formato debe ser: yyyy-MM-dd HH:mm:ss.SSS
```

---

### **Error: Pausa no existe**

**Response (404 NOT_FOUND):**
```
No se encontró pausa con id: 999
```

---

### **Error: Fecha fin anterior a fecha inicio**

**Response (400 BAD_REQUEST):**
```
dtiempofin debe ser posterior a dtiempoinicio
```

---

## Guia de Migracion para el Frontend

### Cambios requeridos

#### 1. Cargar el catálogo al iniciar

Agregar una llamada al iniciar la app (o al abrir la pantalla de pausa):

```
GET /api/v1/catalogomotivopausas
```

Cachear la lista en memoria o en estado local. No es necesario llamarlo en cada pausa.

#### 2. Reemplazar el campo de texto por un selector

La pantalla de "registrar pausa" debe cambiar de:
- `TextField` para `cmotivo` (texto libre)

a:
- `DropdownButton` / `BottomSheet` con los 8 motivos del catálogo
- Un `TextField` adicional para `cmotivoOtro`, que aparece **solo cuando el usuario selecciona "Otro" (id=8)**

#### 3. Actualizar los requests de pausa

| Antes | Ahora |
|-------|-------|
| `"cmotivo": "texto libre"` | `"idmotivo": "3"` |
| — | `"cmotivoOtro": null` (o texto si id=8) |

**Lógica recomendada en el cliente:**
```
si motivoSeleccionado.id == 8:
    enviar idmotivo: "8", cmotivoOtro: campoTexto.value
sino:
    enviar idmotivo: motivoSeleccionado.id.toString(), cmotivoOtro: null
```

#### 4. Actualizar las vistas que muestran pausas

En las pantallas del supervisor y del empleado, donde antes se mostraba `pausa.cmotivo` como texto, ahora deben:

```
si pausa.idmotivo == 8:
    mostrar pausa.cmotivoOtro   // texto libre del usuario
sino:
    mostrar nombre del motivo   // buscar en catálogo: catalogoMotivos[pausa.idmotivo].cnombre
```

**Recomendación:** mantener el catálogo cacheado para hacer este lookup sin llamadas adicionales.

---

## Notas Importantes

### Formato de Fechas

**CRITICO:** Las fechas deben enviarse en el formato exacto:
```
yyyy-MM-dd HH:mm:ss.SSS
```
**Ejemplos válidos:**
- `2024-02-11 10:30:00.000`
- `2024-12-25 14:45:30.123`

**Ejemplos inválidos:**
- `11/02/2024 10:30`
- `2024-02-11 10:30`
- `2024-02-11T10:30:00`

---

### Calculo de Minutos

El campo `nminutos` es **calculado automáticamente por el backend** al reanudar:
```
nminutos = (dtiempofin - dtiempoinicio) / 60000 milisegundos
```
No es necesario enviar este valor desde el cliente.

---

### Flujo de Uso

1. **Al abrir pantalla de pausa:**
   - Cargar motivos de `GET /api/v1/catalogomotivopausas` (si no están cacheados)

2. **Al pausar:**
   - Usuario selecciona motivo del dropdown
   - Si selecciona "Otro" (id=8), usuario escribe descripción
   - Cliente envía request **SIN campo `id`**
   - Backend crea nuevo registro y retorna `id` generado
   - **Cliente guarda este `id` localmente**

3. **Al reanudar:**
   - Cliente envía request **CON el `id` guardado** + `dtiempofin`
   - Backend actualiza el registro y calcula `nminutos`
   - No es necesario reenviar el motivo

---

### Deteccion Automatica de Operacion

El backend detecta automáticamente la operación:

- **Si NO viene `id`** → Registra pausa nueva (CREATE)
- **Si SÍ viene `id`** → Reanuda pausa existente (UPDATE)

---

### Campos de Auditoria

Los siguientes campos se gestionan automáticamente por el backend:

- `dfecreg`: Fecha de creación del registro
- `dfecmod`: Fecha de última modificación
- `idusureg`: Usuario que creó (actualmente hardcoded: 1)
- `idusumod`: Usuario que modificó (actualmente hardcoded: 1)
- `bactivo`: Estado activo (siempre `true`)

**No es necesario enviarlos desde el cliente.**

---

### Validaciones del Backend

El backend valida:

- IDs son numéricos
- `idmotivo` está presente y es numérico
- `cmotivoOtro` no está vacío cuando `idmotivo = 8`
- Formato de fechas correcto
- Fecha fin > fecha inicio
- Pausa existe al intentar reanudar

---

## Ejemplos de Casos de Uso

### **Caso 1: Pausa por falta de repuesto (motivo predefinido)**

```json
// 1. Registrar pausa
POST /api/v1/gestionarpausadetalleordentrabajo
{
  "iddetalleordentrabajo": "100",
  "idmotivo": "3",
  "dtiempoinicio": "2024-02-11 10:00:00.000"
}

// Response: { "id": 5, "idmotivo": 3, "cmotivoOtro": null, ... }

// 2. Reanudar después de 30 minutos
POST /api/v1/gestionarpausadetalleordentrabajo
{
  "id": "5",
  "dtiempofin": "2024-02-11 10:30:00.000"
}

// Response: { "id": 5, "nminutos": 30, ... }
```

---

### **Caso 2: Pausa con motivo "Otro"**

```json
// 1. Registrar pausa
POST /api/v1/gestionarpausadetalleasignacion
{
  "iddetalleasignacion": "200",
  "idmotivo": "8",
  "cmotivoOtro": "Coordinación urgente con el área de compras",
  "dtiempoinicio": "2024-02-11 12:00:00.000"
}

// Response: { "id": 6, "idmotivo": 8, "cmotivoOtro": "Coordinación urgente con el área de compras", ... }

// 2. Reanudar después de 2h 15min
POST /api/v1/gestionarpausadetalleasignacion
{
  "id": "6",
  "dtiempofin": "2024-02-11 14:15:00.000"
}

// Response: { "id": 6, "nminutos": 135, ... }
```

---

## Base URL

```
http://localhost:8080
```

En producción, reemplazar con la URL del servidor.

---

## Version

- **Version API:** 2.0
- **Fecha:** 2026-02-18
- **Backend:** Spring Boot 2.2.2
- **Base de datos:** SQL Server
- **Cambio principal:** `cmotivo` reemplazado por `idmotivo` + `cmotivoOtro` con catálogo `catalogo_motivo_pausa`

---

## Soporte

Para reportar errores o solicitar cambios, contactar al equipo de desarrollo.
