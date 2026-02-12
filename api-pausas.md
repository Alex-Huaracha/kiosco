# API de Pausas con Motivos

Documentación de endpoints para el sistema de registro de pausas con motivos para actividades de mantenimiento.

---

## 📋 Índice

1. [Endpoint: Gestionar Pausa - Empleado Principal](#endpoint-1-gestionar-pausa---empleado-principal)
2. [Endpoint: Gestionar Pausa - Empleado Asistente](#endpoint-2-gestionar-pausa---empleado-asistente)
3. [Códigos de Respuesta HTTP](#códigos-de-respuesta-http)
4. [Ejemplos de Errores](#ejemplos-de-errores)
5. [Notas Importantes](#notas-importantes)

---

## Endpoint 1: Gestionar Pausa - Empleado Principal

Gestiona pausas para actividades de empleados principales (`DetalleOrdentrabajo`).

### **URL**
```
POST /gestionarpausadetalleordentrabajo
```

### **Content-Type**
```
application/json
```

---

### **Operación 1: Registrar Pausa Nueva**

Crea un registro de pausa cuando el empleado presiona el botón "PAUSAR".

#### **Request Body**
```json
{
  "iddetalleordentrabajo": "123",
  "cmotivo": "Reunión de equipo",
  "dtiempoinicio": "2024-02-11 10:30:00.000"
}
```

#### **Campos del Request**

| Campo | Tipo | Requerido | Descripción |
|-------|------|-----------|-------------|
| `iddetalleordentrabajo` | String | ✅ Sí | ID de la actividad principal (numérico) |
| `cmotivo` | String | ✅ Sí | Motivo de la pausa (máximo 500 caracteres) |
| `dtiempoinicio` | String | ✅ Sí | Timestamp de inicio de pausa. Formato: `yyyy-MM-dd HH:mm:ss.SSS` |

#### **Response (200 OK)**
```json
{
  "id": 1,
  "iddetalleordentrabajo": 123,
  "cmotivo": "Reunión de equipo",
  "dtiempoinicio": "2024-02-11T10:30:00.000+00:00",
  "dtiempofin": null,
  "nminutos": null,
  "bactivo": true
}
```

#### **Campos del Response**

| Campo | Tipo | Descripción |
|-------|------|-------------|
| `id` | Integer | ID único de la pausa creada (guardar para reanudar) |
| `iddetalleordentrabajo` | Integer | ID de la actividad |
| `cmotivo` | String | Motivo de la pausa |
| `dtiempoinicio` | DateTime | Timestamp de inicio de pausa |
| `dtiempofin` | DateTime | `null` cuando la pausa está activa |
| `nminutos` | Integer | `null` cuando la pausa está activa |
| `bactivo` | Boolean | Estado del registro (siempre `true`) |

---

### **Operación 2: Reanudar Pausa**

Actualiza el registro de pausa cuando el empleado presiona el botón "REANUDAR".

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
  "cmotivo": "Reunión de equipo",
  "dtiempoinicio": "2024-02-11T10:30:00.000+00:00",
  "dtiempofin": "2024-02-11T11:00:00.000+00:00",
  "nminutos": 30,
  "bactivo": true
}
```

#### **Campos del Response**

| Campo | Tipo | Descripción |
|-------|------|-------------|
| `id` | Integer | ID de la pausa |
| `iddetalleordentrabajo` | Integer | ID de la actividad |
| `cmotivo` | String | Motivo de la pausa |
| `dtiempoinicio` | DateTime | Timestamp de inicio de pausa |
| `dtiempofin` | DateTime | Timestamp de fin de pausa |
| `nminutos` | Integer | **Duración en minutos (calculado automáticamente por backend)** |
| `bactivo` | Boolean | Estado del registro |

---

## Endpoint 2: Gestionar Pausa - Empleado Asistente

Gestiona pausas para empleados asistentes (`DetalleAsignacion`).

### **URL**
```
POST /gestionarpausadetalleasignacion
```

### **Content-Type**
```
application/json
```

---

### **Operación 1: Registrar Pausa Nueva**

#### **Request Body**
```json
{
  "iddetalleasignacion": "456",
  "cmotivo": "Almuerzo",
  "dtiempoinicio": "2024-02-11 12:00:00.000"
}
```

#### **Campos del Request**

| Campo | Tipo | Requerido | Descripción |
|-------|------|-----------|-------------|
| `iddetalleasignacion` | String | ✅ Sí | ID de la asignación (empleado asistente, numérico) |
| `cmotivo` | String | ✅ Sí | Motivo de la pausa (máximo 500 caracteres) |
| `dtiempoinicio` | String | ✅ Sí | Timestamp de inicio de pausa. Formato: `yyyy-MM-dd HH:mm:ss.SSS` |

#### **Response (200 OK)**
```json
{
  "id": 2,
  "iddetalleasignacion": 456,
  "cmotivo": "Almuerzo",
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

#### **Campos del Request**

| Campo | Tipo | Requerido | Descripción |
|-------|------|-----------|-------------|
| `id` | String | ✅ Sí | ID de la pausa a reanudar |
| `dtiempofin` | String | ✅ Sí | Timestamp de fin de pausa. Formato: `yyyy-MM-dd HH:mm:ss.SSS` |

#### **Response (200 OK)**
```json
{
  "id": 2,
  "iddetalleasignacion": 456,
  "cmotivo": "Almuerzo",
  "dtiempoinicio": "2024-02-11T12:00:00.000+00:00",
  "dtiempofin": "2024-02-11T13:30:00.000+00:00",
  "nminutos": 90,
  "bactivo": true
}
```

---

## Códigos de Respuesta HTTP

### ✅ **Respuestas Exitosas**

| Código | Descripción |
|--------|-------------|
| `200 OK` | Operación exitosa (pausa registrada o reanudada) |

### ❌ **Respuestas de Error**

| Código | Descripción |
|--------|-------------|
| `400 BAD_REQUEST` | Error en validación de datos (ver mensaje de error) |
| `404 NOT_FOUND` | Pausa no encontrada (al intentar reanudar con ID inexistente) |
| `500 INTERNAL_SERVER_ERROR` | Error interno del servidor |

---

## Ejemplos de Errores

### **Error: ID inválido (no numérico)**

**Request:**
```json
{
  "iddetalleordentrabajo": "abc",
  "cmotivo": "Reunión",
  "dtiempoinicio": "2024-02-11 10:30:00.000"
}
```

**Response (400 BAD_REQUEST):**
```
iddetalleordentrabajo inválido. Solo se permiten números.
```

---

### **Error: Motivo vacío**

**Request:**
```json
{
  "iddetalleordentrabajo": "123",
  "cmotivo": "",
  "dtiempoinicio": "2024-02-11 10:30:00.000"
}
```

**Response (400 BAD_REQUEST):**
```
cmotivo es requerido y no puede estar vacío
```

---

### **Error: Formato de fecha incorrecto**

**Request:**
```json
{
  "iddetalleordentrabajo": "123",
  "cmotivo": "Reunión",
  "dtiempoinicio": "11/02/2024 10:30"
}
```

**Response (400 BAD_REQUEST):**
```
dtiempoinicio inválido. Formato debe ser: yyyy-MM-dd HH:mm:ss.SSS
```

---

### **Error: Pausa no existe**

**Request:**
```json
{
  "id": "999",
  "dtiempofin": "2024-02-11 11:00:00.000"
}
```

**Response (404 NOT_FOUND):**
```
No se encontró pausa con id: 999
```

---

### **Error: Fecha fin anterior a fecha inicio**

**Request:**
```json
{
  "id": "1",
  "dtiempofin": "2024-02-11 09:00:00.000"
}
```

**Response (400 BAD_REQUEST):**
```
dtiempofin debe ser posterior a dtiempoinicio
```

---

## Notas Importantes

### 📅 **Formato de Fechas**

**CRÍTICO:** Las fechas deben enviarse en el formato exacto:

```
yyyy-MM-dd HH:mm:ss.SSS
```

**Ejemplos válidos:**
- `2024-02-11 10:30:00.000`
- `2024-12-25 14:45:30.123`

**Ejemplos inválidos:**
- ❌ `11/02/2024 10:30`
- ❌ `2024-02-11 10:30`
- ❌ `2024-02-11T10:30:00`

---

### 🔢 **Cálculo de Minutos**

El campo `nminutos` es **calculado automáticamente por el backend** al reanudar:

```
nminutos = (dtiempofin - dtiempoinicio) / 60000 milisegundos
```

**No es necesario enviar este valor desde el cliente.**

---

### 🔑 **Flujo de Uso**

1. **Al pausar:**
   - Cliente envía request **SIN campo `id`**
   - Backend crea nuevo registro y retorna `id` generado
   - **Cliente debe guardar este `id` localmente**

2. **Al reanudar:**
   - Cliente envía request **CON el `id` guardado**
   - Backend actualiza el registro y calcula `nminutos`
   - Cliente puede usar `nminutos` para actualizar tiempo efectivo

---

### 🎯 **Detección Automática de Operación**

El backend detecta automáticamente la operación:

- **Si NO viene `id`** → Registra pausa nueva (CREATE)
- **Si SÍ viene `id`** → Reanuda pausa existente (UPDATE)

---

### 🔒 **Campos de Auditoría**

Los siguientes campos se gestionan automáticamente:

- `dfecreg`: Fecha de creación del registro
- `dfecmod`: Fecha de última modificación
- `idusureg`: Usuario que creó (actualmente hardcoded: 1)
- `idusumod`: Usuario que modificó (actualmente hardcoded: 1)
- `bactivo`: Estado activo (siempre `true`)

**No es necesario enviarlos desde el cliente.**

---

### ⚠️ **Validaciones del Backend**

El backend valida:

- ✅ IDs son numéricos
- ✅ Motivo no está vacío
- ✅ Formato de fechas correcto
- ✅ Fecha fin > fecha inicio
- ✅ Pausa existe al intentar reanudar

---

## 📊 Ejemplos de Casos de Uso

### **Caso 1: Pausa de 30 minutos**

```json
// 1. Registrar pausa
POST /gestionarpausadetalleordentrabajo
{
  "iddetalleordentrabajo": "100",
  "cmotivo": "Descanso",
  "dtiempoinicio": "2024-02-11 10:00:00.000"
}

// Response: { "id": 5, ... }

// 2. Reanudar después de 30 minutos
POST /gestionarpausadetalleordentrabajo
{
  "id": "5",
  "dtiempofin": "2024-02-11 10:30:00.000"
}

// Response: { "id": 5, "nminutos": 30, ... }
```

---

### **Caso 2: Pausa de 2 horas y 15 minutos**

```json
// 1. Registrar pausa
POST /gestionarpausadetalleasignacion
{
  "iddetalleasignacion": "200",
  "cmotivo": "Almuerzo extendido",
  "dtiempoinicio": "2024-02-11 12:00:00.000"
}

// Response: { "id": 6, ... }

// 2. Reanudar después de 2h 15min
POST /gestionarpausadetalleasignacion
{
  "id": "6",
  "dtiempofin": "2024-02-11 14:15:00.000"
}

// Response: { "id": 6, "nminutos": 135, ... }
```

---

## 🔗 Base URL

```
http://localhost:8080
```

**En producción, reemplazar con la URL del servidor.**

---

## 📝 Versión

- **Versión API:** 1.0
- **Fecha:** 2024-02-11
- **Backend:** Spring Boot 2.2.2
- **Base de datos:** SQL Server

---

## 🆘 Soporte

Para reportar errores o solicitar cambios, contactar al equipo de desarrollo.
