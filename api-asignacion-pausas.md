# API de Gestion de Estado de Subtareas

## Endpoint

```
POST /api/v1/gestionarestadosubtarea
Content-Type: application/json
```

## Descripcion

Endpoint unificado para gestionar el ciclo de vida completo de una subtarea (asignacion).
Maneja las acciones: INICIAR, PAUSAR, REANUDAR, FINALIZAR.

## Maquina de Estados

```
NO_INICIADA ──INICIAR──> EN_PROCESO
EN_PROCESO  ──PAUSAR───> PAUSADA
PAUSADA     ──REANUDAR─> EN_PROCESO
EN_PROCESO  ──FINALIZAR> TERMINADA
```

| Estado Actual | Acciones Permitidas |
|---------------|---------------------|
| NO_INICIADA   | INICIAR             |
| EN_PROCESO    | PAUSAR, FINALIZAR   |
| PAUSADA       | REANUDAR            |
| TERMINADA     | (ninguna)           |

---

## Request

### Campos comunes (requeridos)

| Campo | Tipo | Descripcion |
|-------|------|-------------|
| `iddetalleasignacion` | String | ID de la subtarea (requerido) |
| `accion` | String | INICIAR, PAUSAR, REANUDAR, FINALIZAR (requerido) |
| `timestamp` | String | Fecha/hora de la accion en formato `yyyy-MM-dd HH:mm:ss.SSS` (requerido) |

### Campos adicionales por accion

#### INICIAR
No requiere campos adicionales.

#### PAUSAR
| Campo | Tipo | Descripcion |
|-------|------|-------------|
| `idmotivo` | String | ID del motivo de pausa (requerido). Ver catalogo abajo. |
| `cmotivoOtro` | String | Descripcion libre (requerido solo si idmotivo = 8) |

#### REANUDAR
| Campo | Tipo | Descripcion |
|-------|------|-------------|
| `idpausa` | String | ID de la pausa a cerrar (opcional, si no se envia se cierra la pausa activa mas reciente) |

#### FINALIZAR
| Campo | Tipo | Descripcion |
|-------|------|-------------|
| `cobservaciones` | String | Observaciones finales (opcional) |
| `nminutosemp` | String | Minutos efectivos trabajados (opcional, si no se envia se calcula automaticamente) |

---

## Response

### Exitoso (HTTP 200)

```json
{
  "exito": true,
  "mensaje": "Subtarea iniciada exitosamente",
  "iddetalleasignacion": 14,
  "accion": "INICIAR",
  "estadoActual": "EN_PROCESO",
  "idpausa": null,
  "timestampAccion": "2026-02-21T10:30:00.000+0000"
}
```

### Error (HTTP 400/404)

```json
{
  "exito": false,
  "mensaje": "No se puede PAUSAR una subtarea en estado NO_INICIADA. Solo se puede pausar desde EN_PROCESO.",
  "iddetalleasignacion": null,
  "accion": null,
  "estadoActual": null,
  "idpausa": null,
  "timestampAccion": null
}
```

---

## Ejemplos de uso

### 1. INICIAR subtarea

```json
{
  "iddetalleasignacion": "14",
  "accion": "INICIAR",
  "timestamp": "2026-02-21 10:30:00.000"
}
```

**Response:**
```json
{
  "exito": true,
  "mensaje": "Subtarea iniciada exitosamente",
  "iddetalleasignacion": 14,
  "accion": "INICIAR",
  "estadoActual": "EN_PROCESO",
  "timestampAccion": "2026-02-21T10:30:00.000+0000"
}
```

### 2. PAUSAR subtarea

```json
{
  "iddetalleasignacion": "14",
  "accion": "PAUSAR",
  "timestamp": "2026-02-21 11:00:00.000",
  "idmotivo": "1"
}
```

**Response:**
```json
{
  "exito": true,
  "mensaje": "Subtarea pausada exitosamente",
  "iddetalleasignacion": 14,
  "accion": "PAUSAR",
  "estadoActual": "PAUSADA",
  "idpausa": 25,
  "timestampAccion": "2026-02-21T11:00:00.000+0000"
}
```

### 3. PAUSAR con motivo "Otro"

```json
{
  "iddetalleasignacion": "14",
  "accion": "PAUSAR",
  "timestamp": "2026-02-21 11:00:00.000",
  "idmotivo": "8",
  "cmotivoOtro": "Esperando repuesto especial"
}
```

### 4. REANUDAR subtarea

```json
{
  "iddetalleasignacion": "14",
  "accion": "REANUDAR",
  "timestamp": "2026-02-21 11:30:00.000"
}
```

**Response:**
```json
{
  "exito": true,
  "mensaje": "Subtarea reanudada exitosamente. Pausa de 30 minutos registrada.",
  "iddetalleasignacion": 14,
  "accion": "REANUDAR",
  "estadoActual": "EN_PROCESO",
  "idpausa": 25,
  "timestampAccion": "2026-02-21T11:30:00.000+0000"
}
```

### 5. FINALIZAR subtarea

```json
{
  "iddetalleasignacion": "14",
  "accion": "FINALIZAR",
  "timestamp": "2026-02-21 12:00:00.000",
  "cobservaciones": "Trabajo completado sin inconvenientes"
}
```

**Response:**
```json
{
  "exito": true,
  "mensaje": "Subtarea finalizada exitosamente",
  "iddetalleasignacion": 14,
  "accion": "FINALIZAR",
  "estadoActual": "TERMINADA",
  "timestampAccion": "2026-02-21T12:00:00.000+0000"
}
```

---

## Catalogo de Motivos de Pausa

| ID | Nombre |
|----|--------|
| 1  | Almuerzo |
| 2  | Descanso |
| 3  | Esperando repuestos |
| 4  | Esperando autorizacion |
| 5  | Reunion |
| 6  | Capacitacion |
| 7  | Emergencia |
| 8  | Otro (requiere cmotivoOtro) |

---

## Codigos de Error HTTP

| Codigo | Descripcion |
|--------|-------------|
| 200 | Operacion exitosa |
| 400 | Error de validacion (campos faltantes, formato invalido, transicion de estado invalida) |
| 404 | Subtarea no encontrada |
| 500 | Error interno del servidor |

---

## Notas importantes

1. **Formato de timestamp**: Siempre usar `yyyy-MM-dd HH:mm:ss.SSS` (ejemplo: `2026-02-21 10:30:00.000`)

2. **Transiciones de estado**: El endpoint valida que la accion sea valida para el estado actual. Por ejemplo, no se puede PAUSAR una subtarea que no ha sido INICIADA.

3. **Calculo automatico de tiempo**: Al FINALIZAR, si no se envia `nminutosemp`, el sistema calcula automaticamente:
   - Tiempo total = timestamp_fin - timestamp_inicio
   - Tiempo pausado = suma de todas las pausas
   - Tiempo efectivo = tiempo total - tiempo pausado

4. **Pausa activa**: Una subtarea solo puede tener una pausa activa a la vez. Al REANUDAR, se cierra la pausa activa.

5. **Consistencia con actividades principales**: Este endpoint funciona igual que `/gestionarestadoactividad` pero para subtareas.

---

## Comparacion con endpoint de actividades principales

| Aspecto | Actividades (TP) | Subtareas (ST) |
|---------|------------------|----------------|
| Endpoint | `/gestionarestadoactividad` | `/gestionarestadosubtarea` |
| ID campo | `iddetalleordentrabajo` | `iddetalleasignacion` |
| Tabla principal | `detalle_ordentrabajo` | `detalle_asignacion` |
| Tabla pausas | `pausa_detalle_ordentrabajo` | `pausa_detalle_asignacion` |
| Acciones | INICIAR, PAUSAR, REANUDAR, FINALIZAR | INICIAR, PAUSAR, REANUDAR, FINALIZAR |
| Estados | NO_INICIADA, EN_PROCESO, PAUSADA, TERMINADA | NO_INICIADA, EN_PROCESO, PAUSADA, TERMINADA |
