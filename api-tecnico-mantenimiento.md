# 📡 API - Modulo de Tecnicos de Mantenimiento

**Version:** 1.1.0  
**Fecha:** 16 de Febrero de 2026  
**Base URL:** `http://localhost:8080/api/v1` (desarrollo) | `http://{servidor}:{puerto}/api/v1` (produccion)

---

## Indice

1. [Gestionar Estado de Actividad](#1-gestionar-estado-de-actividad)

---

## 1. Gestionar Estado de Actividad

Endpoint unificado para manejar todo el ciclo de vida de una actividad: **INICIAR, PAUSAR, REANUDAR, FINALIZAR**.

Este endpoint es utilizado por los tecnicos mecanicos para reportar el progreso de sus actividades asignadas.

### Endpoint
```
POST /api/v1/gestionarestadoactividad
```

### Maquina de Estados

```
NO_INICIADA ──INICIAR──> EN_PROCESO ──PAUSAR──> PAUSADA
                              ^                    │
                              │                    │
                              └────REANUDAR────────┘
                              │
                              └──FINALIZAR──> TERMINADA
```

| Estado | Descripcion |
|--------|-------------|
| `NO_INICIADA` | Actividad asignada pero no iniciada |
| `EN_PROCESO` | Tecnico trabajando activamente |
| `PAUSADA` | Trabajo pausado temporalmente |
| `TERMINADA` | Actividad completada |

### Request

```json
{
  "iddetalleordentrabajo": "399212",
  "accion": "INICIAR",
  "timestamp": "2026-02-16 10:00:00.000",
  "cmotivo": "Esperando repuestos",
  "cobservaciones": "Trabajo completado sin novedad",
  "nminutosemp": "45",
  "idpausa": "10"
}
```

### Parametros

| Campo | Tipo | Requerido | Descripcion |
|-------|------|-----------|-------------|
| `iddetalleordentrabajo` | String | **Si** | ID de la actividad |
| `accion` | String | **Si** | Accion: `INICIAR`, `PAUSAR`, `REANUDAR`, `FINALIZAR` |
| `timestamp` | String | **Si** | Fecha/hora de la accion (formato: `yyyy-MM-dd HH:mm:ss.SSS`) |
| `cmotivo` | String | Solo PAUSAR | Motivo de la pausa |
| `cobservaciones` | String | No | Observaciones (para FINALIZAR) |
| `nminutosemp` | String | No | Minutos empleados (para FINALIZAR) |
| `idpausa` | String | No | ID de pausa especifica (para REANUDAR, opcional) |

### Response Exitoso (200 OK)

```json
{
  "exito": true,
  "mensaje": "Actividad iniciada exitosamente",
  "iddetalleordentrabajo": 399212,
  "accion": "INICIAR",
  "estadoActual": "EN_PROCESO",
  "idpausa": null,
  "timestampAccion": "2026-02-16T10:00:00.000+00:00"
}
```

### Campos de Respuesta

| Campo | Tipo | Descripcion |
|-------|------|-------------|
| `exito` | Boolean | `true` si la operacion fue exitosa |
| `mensaje` | String | Mensaje descriptivo del resultado |
| `iddetalleordentrabajo` | Integer | ID de la actividad |
| `accion` | String | Accion que se ejecuto |
| `estadoActual` | String | Estado despues de la accion |
| `idpausa` | Integer | ID de la pausa (solo para PAUSAR/REANUDAR) |
| `timestampAccion` | DateTime | Timestamp de la accion ejecutada |

---

## Acciones Disponibles

### INICIAR

Marca la actividad como iniciada. Registra `dtiempoinicio` en la base de datos.

**Transicion valida:** `NO_INICIADA` → `EN_PROCESO`

**Request:**
```json
{
  "iddetalleordentrabajo": "399212",
  "accion": "INICIAR",
  "timestamp": "2026-02-16 10:00:00.000"
}
```

**Response:**
```json
{
  "exito": true,
  "mensaje": "Actividad iniciada exitosamente",
  "iddetalleordentrabajo": 399212,
  "accion": "INICIAR",
  "estadoActual": "EN_PROCESO",
  "timestampAccion": "2026-02-16T10:00:00.000+00:00"
}
```

---

### PAUSAR

Crea una nueva pausa para la actividad. Requiere motivo obligatorio.

**Transicion valida:** `EN_PROCESO` → `PAUSADA`

**Request:**
```json
{
  "iddetalleordentrabajo": "399212",
  "accion": "PAUSAR",
  "timestamp": "2026-02-16 11:30:00.000",
  "cmotivo": "Esperando repuestos"
}
```

**Motivos de pausa comunes:**
- Almuerzo / Alimentacion
- Esperando repuestos
- Falta de herramienta
- Servicios higienicos
- Reunion
- Otros

**Response:**
```json
{
  "exito": true,
  "mensaje": "Actividad pausada exitosamente",
  "iddetalleordentrabajo": 399212,
  "accion": "PAUSAR",
  "estadoActual": "PAUSADA",
  "idpausa": 15,
  "timestampAccion": "2026-02-16T11:30:00.000+00:00"
}
```

---

### REANUDAR

Cierra la pausa activa de la actividad. Calcula automaticamente los minutos de pausa.

**Transicion valida:** `PAUSADA` → `EN_PROCESO`

**Request:**
```json
{
  "iddetalleordentrabajo": "399212",
  "accion": "REANUDAR",
  "timestamp": "2026-02-16 12:00:00.000"
}
```

**Request con ID de pausa especifica (opcional):**
```json
{
  "iddetalleordentrabajo": "399212",
  "accion": "REANUDAR",
  "timestamp": "2026-02-16 12:00:00.000",
  "idpausa": "15"
}
```

**Response:**
```json
{
  "exito": true,
  "mensaje": "Actividad reanudada exitosamente. Pausa de 30 minutos registrada.",
  "iddetalleordentrabajo": 399212,
  "accion": "REANUDAR",
  "estadoActual": "EN_PROCESO",
  "idpausa": 15,
  "timestampAccion": "2026-02-16T12:00:00.000+00:00"
}
```

---

### FINALIZAR

Marca la actividad como terminada. Registra `dtiempofin` y `bcerrada=true`.

**IMPORTANTE:** Al finalizar, el sistema **calcula y guarda automaticamente** el tiempo efectivo trabajado (tiempo total - pausas) en el campo `nminutosemp` de la base de datos.

**Transicion valida:** `EN_PROCESO` → `TERMINADA`

**Request:**
```json
{
  "iddetalleordentrabajo": "399212",
  "accion": "FINALIZAR",
  "timestamp": "2026-02-16 14:30:00.000",
  "cobservaciones": "Trabajo completado sin novedad",
  "nminutosemp": "270"
}
```

**Campos opcionales de FINALIZAR:**

| Campo | Descripcion |
|-------|-------------|
| `cobservaciones` | Observaciones finales del trabajo realizado |
| `nminutosemp` | **Opcional**: Minutos empleados. Si se omite, el sistema lo calcula automaticamente como `(dtiempofin - dtiempoinicio) - suma(pausas)` |

**Nota:** Si envias `nminutosemp`, el sistema usara ese valor. Si lo omites o envias vacio, el sistema calculara automaticamente el tiempo efectivo.

**Response:**
```json
{
  "exito": true,
  "mensaje": "Actividad finalizada exitosamente",
  "iddetalleordentrabajo": 399212,
  "accion": "FINALIZAR",
  "estadoActual": "TERMINADA",
  "timestampAccion": "2026-02-16T14:30:00.000+00:00"
}
```

---

## Errores

### Errores de Validacion (400 Bad Request)

| Error | Descripcion |
|-------|-------------|
| `"iddetalleordentrabajo es requerido"` | Falta el ID de la actividad |
| `"accion es requerida (INICIAR, PAUSAR, REANUDAR, FINALIZAR)"` | Falta la accion |
| `"timestamp es requerido"` | Falta el timestamp |
| `"timestamp invalido. Formato: yyyy-MM-dd HH:mm:ss.SSS"` | Formato de fecha incorrecto |
| `"cmotivo es requerido para PAUSAR"` | Falta motivo al pausar |

### Errores de Transicion de Estado (400 Bad Request)

| Error | Descripcion |
|-------|-------------|
| `"No se puede INICIAR una actividad en estado {estado}. Solo se puede iniciar desde NO_INICIADA."` | Transicion invalida |
| `"No se puede PAUSAR una actividad en estado {estado}. Solo se puede pausar desde EN_PROCESO."` | Transicion invalida |
| `"No se puede REANUDAR una actividad en estado {estado}. Solo se puede reanudar desde PAUSADA."` | Transicion invalida |
| `"No se puede FINALIZAR una actividad en estado {estado}. Solo se puede finalizar desde EN_PROCESO."` | Transicion invalida |

### Errores de Recurso No Encontrado (404 Not Found)

| Error | Descripcion |
|-------|-------------|
| `"No se encontro actividad con id: {id}"` | Actividad no existe |
| `"No se encontro pausa activa para esta actividad"` | No hay pausa que reanudar |

---

## Flujo de Uso Completo

### Ejemplo: Tecnico ejecuta una actividad con pausa

```bash
# 1. Tecnico INICIA la actividad (10:00 AM)
curl -X POST http://localhost:8080/api/v1/gestionarestadoactividad \
  -H "Content-Type: application/json" \
  -d '{
    "iddetalleordentrabajo": "399212",
    "accion": "INICIAR",
    "timestamp": "2026-02-16 10:00:00.000"
  }'

# 2. Tecnico PAUSA para almorzar (12:00 PM)
curl -X POST http://localhost:8080/api/v1/gestionarestadoactividad \
  -H "Content-Type: application/json" \
  -d '{
    "iddetalleordentrabajo": "399212",
    "accion": "PAUSAR",
    "timestamp": "2026-02-16 12:00:00.000",
    "cmotivo": "Almuerzo"
  }'

# 3. Tecnico REANUDA despues del almuerzo (1:00 PM)
curl -X POST http://localhost:8080/api/v1/gestionarestadoactividad \
  -H "Content-Type: application/json" \
  -d '{
    "iddetalleordentrabajo": "399212",
    "accion": "REANUDAR",
    "timestamp": "2026-02-16 13:00:00.000"
  }'

# 4. Tecnico FINALIZA la actividad (3:30 PM)
# NOTA: No se envia 'nminutosemp', el sistema lo calculara automaticamente
curl -X POST http://localhost:8080/api/v1/gestionarestadoactividad \
  -H "Content-Type: application/json" \
  -d '{
    "iddetalleordentrabajo": "399212",
    "accion": "FINALIZAR",
    "timestamp": "2026-02-16 15:30:00.000",
    "cobservaciones": "Trabajo completado sin novedad"
  }'

# Resultado guardado en BD:
# - dtiempoinicio: 2026-02-16 10:00:00
# - dtiempofin: 2026-02-16 15:30:00
# - nminutosemp: 270 (calculado automaticamente: 330 minutos totales - 60 minutos de pausa)
```

### Ejemplo: Actividad sin pausas (flujo simple)

```bash
# 1. Tecnico INICIA la actividad
curl -X POST http://localhost:8080/api/v1/gestionarestadoactividad \
  -H "Content-Type: application/json" \
  -d '{
    "iddetalleordentrabajo": "399213",
    "accion": "INICIAR",
    "timestamp": "2026-02-16 08:00:00.000"
  }'

# 2. Tecnico FINALIZA la actividad (sin pausas intermedias)
curl -X POST http://localhost:8080/api/v1/gestionarestadoactividad \
  -H "Content-Type: application/json" \
  -d '{
    "iddetalleordentrabajo": "399213",
    "accion": "FINALIZAR",
    "timestamp": "2026-02-16 09:30:00.000",
    "cobservaciones": "Cambio de aceite completado"
  }'

# Resultado: nminutosemp = 90 (sin pausas, tiempo efectivo = tiempo total)
```

---

## Ejemplo de Calculo Automatico de Tiempo Efectivo

### Escenario Completo

**Timeline de la actividad:**
```
08:00 - INICIAR
10:00 - PAUSAR (Almuerzo)
10:30 - REANUDAR (pausa de 30 minutos)
12:00 - PAUSAR (Esperando repuestos)
13:00 - REANUDAR (pausa de 60 minutos)
15:30 - FINALIZAR
```

**Calculos automaticos al FINALIZAR:**
```
Tiempo total    = 15:30 - 08:00 = 7.5 horas = 450 minutos
Tiempo pausado  = 30 min + 60 min = 90 minutos
Tiempo efectivo = 450 - 90 = 360 minutos (6 horas)
```

**Valor guardado en BD:**
- `nminutosemp = 360`

### Sobrescritura Manual (Opcional)

Si el tecnico necesita ajustar el tiempo manualmente (por ejemplo, por una pausa no registrada):

```json
{
  "iddetalleordentrabajo": "399212",
  "accion": "FINALIZAR",
  "timestamp": "2026-02-16 15:30:00.000",
  "nminutosemp": "300",
  "cobservaciones": "Tiempo ajustado manualmente"
}
```

En este caso, el sistema guardara `nminutosemp = 300` (5 horas) en lugar del calculo automatico.

---

## Notas Importantes

### Sincronizacion
- El frontend debe enviar las acciones al backend **inmediatamente** cuando ocurren
- Esto permite al supervisor ver el estado en tiempo real

### Validaciones de Tiempo
- El `timestamp` de REANUDAR debe ser posterior al inicio de la pausa
- El `timestamp` de FINALIZAR debe ser posterior al inicio de la actividad

### Multiples Pausas
- Una actividad puede tener multiples pausas durante su ejecucion
- Solo puede haber **una pausa activa** a la vez
- Al REANUDAR sin especificar `idpausa`, se cierra la pausa activa mas reciente

### Calculo Automatico de Tiempo Efectivo
- Al ejecutar **FINALIZAR**, el sistema calcula automaticamente el tiempo efectivo trabajado
- Formula: `tiempo_efectivo = (tiempo_fin - tiempo_inicio) - suma_de_pausas`
- Este valor se guarda en el campo `nminutosemp` de la base de datos
- El tecnico puede sobrescribir este valor enviando `nminutosemp` en el request de FINALIZAR

---

## Historial de Cambios

### v1.1.0 (16 de Febrero de 2026)
- **Accion FINALIZAR:** Ahora calcula y guarda automaticamente el tiempo efectivo
  - Si no se envia `nminutosemp`, el sistema lo calcula como: `(dtiempofin - dtiempoinicio) - suma(pausas)`
  - El valor calculado se guarda en el campo `nminutosemp` de la base de datos
  - El tecnico puede seguir enviando `nminutosemp` manualmente si lo desea

### v1.0.0 (16 de Febrero de 2026)
- Version inicial
- Endpoint unificado `/gestionarestadoactividad` con acciones: INICIAR, PAUSAR, REANUDAR, FINALIZAR
- Maquina de estados con validacion de transiciones

---

**Documentacion generada:** 16 de Febrero de 2026  
**Controlador:** `ActividadEstadoServiceController.java`
