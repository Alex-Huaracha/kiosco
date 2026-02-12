# Endpoint: POST `/adddetalleasignacion`

## Descripcion
Endpoint para actualizar/tarear una Sub-Tarea (ST) de asignacion.
Se utiliza cuando un empleado asistente registra sus tiempos de trabajo en una actividad.

---

## URL
```
POST http://<servidor>/adddetalleasignacion
Content-Type: application/json
```

---

## Cuando usar este endpoint

Este endpoint se usa para actualizar actividades de tipo **ST (Sub-Tarea)**.

Para identificar si una actividad es ST, verificar en la respuesta de `/empleadosactividades`:
- Si `idAsignacion != null` → Es ST → Usar este endpoint
- Si `idAsignacion == null` → Es TP → Usar endpoint de DetalleOrdentrabajo

---

## Request

### Campos

| Campo | Tipo | Requerido | Descripcion |
|-------|------|-----------|-------------|
| `id` | String | **Si** | ID de la asignacion (`idAsignacion` del endpoint `/empleadosactividades`) |
| `dtiempoinicio` | String | No | Fecha/hora de inicio del trabajo |
| `dtiempofin` | String | No | Fecha/hora de fin del trabajo |
| `bcerrada` | String | No | Estado de cierre: `"1"` = cerrada, `"0"` = abierta |
| `nminutosemp` | String | No | Tiempo real empleado en minutos (calculado por Flutter) |
| `cobservaciones` | String | No | Observaciones o comentarios adicionales |

### Formato de fecha
```
yyyy-MM-dd HH:mm:ss.SSS
```
Ejemplo: `"2026-02-06 08:00:00.000"`

---

## Ejemplos de Request

### Ejemplo 1: Registrar inicio de trabajo
```json
{
  "id": "5",
  "dtiempoinicio": "2026-02-06 08:00:00.000"
}
```

### Ejemplo 2: Registrar fin y cerrar tarea
```json
{
  "id": "5",
  "dtiempofin": "2026-02-06 10:30:00.000",
  "bcerrada": "1",
  "nminutosemp": "150"
}
```

### Ejemplo 3: Tareo completo con observaciones
```json
{
  "id": "5",
  "dtiempoinicio": "2026-02-06 08:00:00.000",
  "dtiempofin": "2026-02-06 10:30:00.000",
  "bcerrada": "1",
  "nminutosemp": "150",
  "cobservaciones": "Trabajo completado sin inconvenientes"
}
```

---

## Response

### Response exitoso (HTTP 200)

```json
{
  "id": 5,
  "idordentrabajo": 71864,
  "iddetalleordentrabajo": 399178,
  "bactivo": true,
  "idempleadoext": "2098",
  "ccargoemp": "TECNICO MECANICO",
  "cnombreemp": "JUAN PEREZ GARCIA",
  "ntiempoestimado": 30,
  "nminutosemp": 150,
  "dtiempoinicio": "2026-02-06T08:00:00.000+00:00",
  "dtiempofin": "2026-02-06T10:30:00.000+00:00",
  "bcerrada": true,
  "cobservaciones": "Trabajo completado sin inconvenientes",
  "cactividad": "Revisar nivel de aceite"
}
```

### Campos del Response

| Campo | Tipo | Descripcion |
|-------|------|-------------|
| `id` | Integer | ID de la asignacion |
| `idordentrabajo` | Integer | ID de la orden de trabajo |
| `iddetalleordentrabajo` | Integer | ID del detalle (tarea principal) |
| `bactivo` | Boolean | Si el registro esta activo |
| `idempleadoext` | String | ID del empleado asistente |
| `ccargoemp` | String | Cargo del empleado |
| `cnombreemp` | String | Nombre del empleado |
| `ntiempoestimado` | Integer | Tiempo estimado en minutos |
| `nminutosemp` | Integer | Tiempo real empleado en minutos |
| `dtiempoinicio` | DateTime | Fecha/hora de inicio |
| `dtiempofin` | DateTime | Fecha/hora de fin |
| `bcerrada` | Boolean | Si la tarea esta cerrada |
| `cobservaciones` | String | Observaciones |
| `cactividad` | String | Descripcion de la sub-actividad |

---

## Errores comunes

### ID invalido
```json
HTTP 400 Bad Request
"id inválido. Solo se permiten números."
```

### Fecha con formato incorrecto
```json
HTTP 400 Bad Request
"dtiempoinicio inválido. la fecha debe de seguir el formato <yyyy-MM-dd HH:mm:ss.SSS>."
```

### bcerrada con valor incorrecto
```json
HTTP 400 Bad Request
"bcerrada inválido. Solo 1 = cerrada o 0 = abierta."
```

---

## Flujo tipico de uso

1. **Usuario inicia trabajo:**
   - Flutter envia `id` + `dtiempoinicio`
   
2. **Usuario finaliza trabajo:**
   - Flutter calcula `nminutosemp` (diferencia entre fin e inicio)
   - Flutter envia `id` + `dtiempofin` + `nminutosemp` + `bcerrada: "1"`

3. **Sincronizacion offline:**
   - Flutter guarda localmente los datos
   - Al recuperar conexion, envia todos los campos juntos

---

## Notas importantes

1. **Todos los valores son Strings**: Aunque representen numeros o booleanos, se envian como String
2. **El campo `id` es obligatorio**: Sin el, no se puede identificar que registro actualizar
3. **Actualizacion parcial**: Solo se actualizan los campos que se envian, los demas permanecen igual
4. **Independencia de tareas**: Cerrar una ST no afecta a la TP ni a otras ST de la misma actividad
5. **Formato de fecha estricto**: Debe incluir milisegundos (`.000`)
