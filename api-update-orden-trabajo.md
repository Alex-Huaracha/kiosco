# API: Actualizar Detalle de Orden de Trabajo

## Información General

**Endpoint:** `/updatedetalleordentrabajo`  
**Método HTTP:** `POST`  
**Content-Type:** `application/json`  
**Descripción:** Actualiza los datos de una actividad (detalle de orden de trabajo) asignada a un empleado.

---

## Casos de Uso

Este endpoint permite a los empleados:
- Registrar tiempos de inicio y fin de trabajo
- Marcar una actividad como cerrada/completada
- Marcar una actividad como backlog (para reprogramación)
- Agregar observaciones
- Registrar minutos trabajados

---

## Request

### URL
```
POST http://tu-servidor/updatedetalleordentrabajo
```

### Headers
```
Content-Type: application/json
```

### Body (JSON)

| Campo | Tipo | Requerido | Descripción | Formato/Valores |
|-------|------|-----------|-------------|-----------------|
| `iddetalleordentrabajo` | String | **Sí** | ID del detalle de orden de trabajo a actualizar | Número como string (ej: `"123"`) |
| `idempleadoext` | String | No | ID externo del empleado | Alfanumérico |
| `ccargoemp` | String | No | Cargo del empleado | Texto libre |
| `cnombreemp` | String | No | Nombre completo del empleado | Texto libre |
| `dtiempoinicio` | String | No | Fecha/hora de inicio del trabajo | `yyyy-MM-dd HH:mm:ss.SSS` |
| `dtiempofin` | String | No | Fecha/hora de fin del trabajo | `yyyy-MM-dd HH:mm:ss.SSS` |
| `nminutosemp` | String | No | Minutos trabajados por el empleado | Número como string (ej: `"120"`) |
| `cobservaciones` | String | No | Observaciones sobre el trabajo realizado | Texto libre |
| `bcerrada` | String | No | Indica si la actividad está cerrada/completada | `"true"`, `"false"`, `"1"`, `"0"` |
| `dfechacierre` | String | No | Fecha/hora de cierre (si se marca como cerrada) | `yyyy-MM-dd HH:mm:ss.SSS` |
| `bbacklog` | String | No | Marca la actividad como backlog para reprogramación | `"true"`, `"false"`, `"1"`, `"0"` |

**Nota:** Solo el campo `iddetalleordentrabajo` es obligatorio. Los demás campos son opcionales y solo se actualizarán si se envían con valores.

---

## Ejemplos de Request

### 1. Marcar como backlog (caso más simple - sin tiempos)

```json
{
  "iddetalleordentrabajo": "124",
  "bbacklog": "true",
  "cobservaciones": "Falta repuesto"
}
```

### 2. Actualizar tiempos de trabajo básico

```json
{
  "iddetalleordentrabajo": "123",
  "idempleadoext": "EMP001",
  "ccargoemp": "Mecánico",
  "cnombreemp": "Juan Pérez",
  "dtiempoinicio": "2026-02-11 08:00:00.000",
  "dtiempofin": "2026-02-11 12:00:00.000"
}
```

### 3. Cerrar una actividad completada

```json
{
  "iddetalleordentrabajo": "123",
  "idempleadoext": "EMP001",
  "ccargoemp": "Mecánico",
  "cnombreemp": "Juan Pérez",
  "dtiempoinicio": "2026-02-11 08:00:00.000",
  "dtiempofin": "2026-02-11 12:00:00.000",
  "bcerrada": "true",
  "nminutosemp": "240",
  "cobservaciones": "Cambio de aceite y filtros completado exitosamente"
}
```

### 4. Marcar actividad como backlog (con tiempos trabajados)

```json
{
  "iddetalleordentrabajo": "125",
  "dtiempoinicio": "2026-02-11 13:00:00.000",
  "dtiempofin": "2026-02-11 14:00:00.000",
  "bbacklog": "true",
  "cobservaciones": "Se trabajó 1 hora pero falta repuesto para completar"
}
```

### 5. Cerrar con fecha de cierre específica

```json
{
  "iddetalleordentrabajo": "126",
  "idempleadoext": "EMP001",
  "ccargoemp": "Mecánico",
  "cnombreemp": "Juan Pérez",
  "dtiempoinicio": "2026-02-11 08:00:00.000",
  "dtiempofin": "2026-02-11 10:30:00.000",
  "bcerrada": "true",
  "dfechacierre": "2026-02-11 10:35:00.000",
  "nminutosemp": "150"
}
```

### 6. Actualizar solo observaciones

```json
{
  "iddetalleordentrabajo": "127",
  "cobservaciones": "Actualización: Se encontró desgaste adicional en frenos"
}
```

---

## Response

### Respuesta Exitosa (HTTP 200)

Devuelve el objeto `DetalleOrdentrabajo` actualizado en formato JSON.

**Ejemplo:**
```json
{
  "iddetalleordentrabajo": 123,
  "idordentrabajo": 45,
  "cactividad": "Cambio de aceite y filtros",
  "idempleadoext": "EMP001",
  "ccargoemp": "Mecánico",
  "cnombreemp": "Juan Pérez",
  "dtiempoinicio": "2026-02-11T08:00:00.000+00:00",
  "dtiempofin": "2026-02-11T12:00:00.000+00:00",
  "dfechacierre": "2026-02-11T12:05:00.000+00:00",
  "nminutosemp": 240,
  "cobservaciones": "Cambio de aceite y filtros completado exitosamente",
  "bcerrada": true,
  "bbacklog": false,
  "breprogramado": false,
  "bactivo": true,
  "dfecreg": "2026-02-10T09:00:00.000+00:00",
  "dfecmod": "2026-02-11T12:05:00.000+00:00"
}
```

### Respuestas de Error

#### Error 400 - Formato de fecha inválido
```json
"2026-02-11 25:00:00.000 o 2026-02-11 12:00:00.000 No son fecha validas con formato (yyyy-MM-dd HH:mm:ss.SSS)."
```

#### Error 400 - ID de detalle inválido
```json
"abc ID inválido. Solo se permiten números."
```

#### Error 400 - Detalle no existe
```json
"No existe el ID o la OT esta inactiva: 999"
```

#### Error 400 - Minutos inválidos
```json
"nminutosemp inválido. Solo se permiten números."
```

#### Error 400 - Fecha de cierre inválida
```json
"dfechacierre inválido. la fecha debe de seguir el formato <yyyy-MM-dd HH:mm:ss.SSS>."
```

---

## Notas Importantes

### 1. Formato de Fechas
- **Estricto:** Debe seguir el formato `yyyy-MM-dd HH:mm:ss.SSS`
- **Ejemplo válido:** `2026-02-11 08:30:45.123`
- **Ejemplo inválido:** `2026-02-11 08:30:45` (falta milisegundos)

### 2. Campo `bcerrada`
- Si se marca como `true` o `1` y NO se envía `dfechacierre`, el sistema usará la fecha/hora actual automáticamente
- Si se marca como `false` o `0`, la actividad vuelve a estado pendiente

### 3. Campo `bbacklog`
- Marca la actividad para ser reprogramada en una futura orden de trabajo
- Una actividad puede estar marcada como backlog **sin estar cerrada** y **sin tiempos**
- El sistema de OT gestionará la copia de la actividad a la nueva orden de trabajo
- **Caso de uso típico:** El empleado detecta que no puede completar una tarea (falta repuesto, herramienta, etc.) y la marca como backlog sin haber iniciado el trabajo
- **Comportamiento automático:** Al marcar `bbacklog=true`, el sistema automáticamente marca `bbacklogemp=true` internamente
- **Efecto en lista de actividades:** La actividad **desaparece inmediatamente** de la lista del empleado después de marcarla como backlog

### 4. Campos Opcionales y Actualizaciones Parciales
- **Solo el campo `iddetalleordentrabajo` es obligatorio**
- Si un campo NO se envía o viene vacío (`""`), NO se modificará en la base de datos
- **Puedes actualizar solo el campo que necesites** (ej: solo observaciones, solo backlog, solo tiempos, etc.)
- Los campos `dtiempoinicio` y `dtiempofin` **deben enviarse juntos** si se quieren actualizar (no se puede enviar solo uno)

### 5. Modificación Automática
- El campo `dfecmod` (fecha de modificación) se actualiza automáticamente con la fecha/hora actual del servidor

### 6. Tiempos de Trabajo
- Los tiempos son **opcionales** - puedes marcar backlog sin enviar tiempos
- Si envías tiempos, **ambos** (`dtiempoinicio` y `dtiempofin`) deben estar presentes
- Para cerrar una actividad (`bcerrada: true`) **se recomienda** enviar tiempos, aunque no es estrictamente obligatorio

---

## Flujos de Trabajo Comunes

### Flujo 1: Empleado completa una actividad
1. Empleado inicia trabajo → registra `dtiempoinicio`
2. Empleado termina trabajo → registra `dtiempofin`
3. Marca como completada → `bcerrada: "true"`
4. Agrega observaciones → `cobservaciones: "..."`

**Request:**
```json
{
  "iddetalleordentrabajo": "123",
  "idempleadoext": "EMP001",
  "ccargoemp": "Mecánico",
  "cnombreemp": "Juan Pérez",
  "dtiempoinicio": "2026-02-11 08:00:00.000",
  "dtiempofin": "2026-02-11 12:00:00.000",
  "bcerrada": "true",
  "cobservaciones": "Trabajo completado sin novedades"
}
```

### Flujo 2: Empleado marca actividad como backlog (sin iniciar trabajo)
1. Empleado revisa la actividad asignada
2. Detecta que no puede completarla (falta repuesto, herramienta, etc.)
3. Marca como backlog → `bbacklog: "true"`
4. Explica razón → `cobservaciones: "Falta repuesto X"`

**Request simplificado (sin tiempos):**
```json
{
  "iddetalleordentrabajo": "124",
  "bbacklog": "true",
  "cobservaciones": "Falta repuesto: filtro de aire especial"
}
```

**Alternativa con tiempos (si ya trabajó en la actividad):**
```json
{
  "iddetalleordentrabajo": "124",
  "dtiempoinicio": "2026-02-11 13:00:00.000",
  "dtiempofin": "2026-02-11 13:30:00.000",
  "bbacklog": "true",
  "cobservaciones": "Se trabajó 30 min pero falta repuesto especial"
}
```

### Flujo 3: Escenario del usuario (5 actividades)
**Contexto:** Empleado tiene 5 actividades, completa 4 y marca 1 como backlog.

**Actividades 1-4 (completadas):**
```json
{
  "iddetalleordentrabajo": "101",
  "idempleadoext": "EMP001",
  "ccargoemp": "Mecánico",
  "cnombreemp": "Juan Pérez",
  "dtiempoinicio": "2026-02-11 08:00:00.000",
  "dtiempofin": "2026-02-11 09:00:00.000",
  "bcerrada": "true"
}
```
(Repetir para actividades 102, 103, 104)

**Actividad 5 (backlog - sin iniciar):**
```json
{
  "iddetalleordentrabajo": "105",
  "bbacklog": "true",
  "cobservaciones": "Requiere herramienta especializada no disponible"
}
```

---

## Integración con Flutter

### Ejemplo básico con Dart/Flutter (usando http package)

```dart
import 'dart:convert';
import 'package:http/http.dart' as http;

Future<Map<String, dynamic>> actualizarDetalleOT({
  required String idDetalleOT,
  String? idEmpleado,
  String? cargo,
  String? nombre,
  DateTime? tiempoInicio,
  DateTime? tiempoFin,
  bool? cerrada,
  bool? backlog,
  String? observaciones,
  int? minutos,
}) async {
  final url = Uri.parse('http://tu-servidor/updatedetalleordentrabajo');
  
  // Formato de fecha requerido por la API
  String formatoFecha(DateTime fecha) {
    return '${fecha.year}-${fecha.month.toString().padLeft(2, '0')}-${fecha.day.toString().padLeft(2, '0')} '
           '${fecha.hour.toString().padLeft(2, '0')}:${fecha.minute.toString().padLeft(2, '0')}:${fecha.second.toString().padLeft(2, '0')}.'
           '${fecha.millisecond.toString().padLeft(3, '0')}';
  }
  
  final body = {
    'iddetalleordentrabajo': idDetalleOT,
  };
  
  // Agregar campos opcionales solo si vienen
  if (idEmpleado != null && idEmpleado.isNotEmpty) body['idempleadoext'] = idEmpleado;
  if (cargo != null && cargo.isNotEmpty) body['ccargoemp'] = cargo;
  if (nombre != null && nombre.isNotEmpty) body['cnombreemp'] = nombre;
  
  // Los tiempos se envían juntos o no se envían
  if (tiempoInicio != null && tiempoFin != null) {
    body['dtiempoinicio'] = formatoFecha(tiempoInicio);
    body['dtiempofin'] = formatoFecha(tiempoFin);
  }
  
  if (cerrada != null) body['bcerrada'] = cerrada.toString();
  if (backlog != null) body['bbacklog'] = backlog.toString();
  if (observaciones != null && observaciones.isNotEmpty) body['cobservaciones'] = observaciones;
  if (minutos != null) body['nminutosemp'] = minutos.toString();
  
  final response = await http.post(
    url,
    headers: {'Content-Type': 'application/json'},
    body: jsonEncode(body),
  );
  
  if (response.statusCode == 200) {
    return jsonDecode(response.body);
  } else {
    throw Exception('Error: ${response.body}');
  }
}

// Ejemplo de uso 1: Cerrar actividad
void cerrarActividad() async {
  try {
    final resultado = await actualizarDetalleOT(
      idDetalleOT: '123',
      idEmpleado: 'EMP001',
      cargo: 'Mecánico',
      nombre: 'Juan Pérez',
      tiempoInicio: DateTime(2026, 2, 11, 8, 0, 0),
      tiempoFin: DateTime(2026, 2, 11, 12, 0, 0),
      cerrada: true,
      observaciones: 'Trabajo completado',
    );
    print('Actividad cerrada: $resultado');
  } catch (e) {
    print('Error: $e');
  }
}

// Ejemplo de uso 2: Marcar como backlog (sin tiempos)
void marcarBacklog() async {
  try {
    final resultado = await actualizarDetalleOT(
      idDetalleOT: '124',
      backlog: true,
      observaciones: 'Falta repuesto especial',
    );
    print('Marcado como backlog: $resultado');
  } catch (e) {
    print('Error: $e');
  }
}

// Ejemplo de uso 3: Actualizar solo observaciones
void actualizarObservaciones() async {
  try {
    final resultado = await actualizarDetalleOT(
      idDetalleOT: '125',
      observaciones: 'Se encontró desgaste adicional en componentes',
    );
    print('Observaciones actualizadas: $resultado');
  } catch (e) {
    print('Error: $e');
  }
}
```

---

## Validaciones del Servidor

El servidor valida:
1. Que el `iddetalleordentrabajo` sea un número válido (campo obligatorio)
2. Que el detalle de orden de trabajo exista y esté activo
3. Formato de fechas (`yyyy-MM-dd HH:mm:ss.SSS`) - **solo si se envían**
4. Que `nminutosemp` sea un número válido - **solo si se envía**
5. Que `dfechacierre` tenga formato válido - **solo si se envía**
6. Si se envían tiempos, **ambos** (`dtiempoinicio` y `dtiempofin`) deben estar presentes y ser válidos

---

## Changelog

| Versión | Fecha | Cambios |
|---------|-------|---------|
| 1.3 | 2026-02-11 | **FIX: Actividades marcadas como backlog ahora desaparecen de la lista del empleado**. Implementado campo interno `bbacklogemp` que se setea automáticamente. Las queries de `/empleadosactividades` excluyen actividades con `bbacklogemp=true`. |
| 1.2 | 2026-02-11 | **Todos los campos opcionales excepto `iddetalleordentrabajo`**. Permite actualizaciones parciales (ej: solo backlog, solo observaciones). Tiempos ahora opcionales. |
| 1.1 | 2026-02-11 | Agregado soporte para campo `bbacklog` |
| 1.0 | - | Versión inicial |

---

---

## Comportamiento de Backlog (Importante)

### Problema Resuelto: Actividades backlog que no desaparecían

**Contexto del problema original:**
Cuando un empleado marcaba una actividad como backlog desde la app móvil, la actividad seguía apareciendo en su lista de tareas pendientes. Esto causaba confusión porque el empleado ya había "despachado" esa tarea.

**Causa raíz:**
Existían dos tipos de actividades con `bbacklog=true` que eran indistinguibles:

| Tipo | Origen | ¿Debe mostrarse? |
|------|--------|------------------|
| Backlog asignado | Actividad copiada de una OT anterior por el planner | **SÍ** - El planner la asignó para que el empleado la trabaje |
| Backlog marcado por empleado | Empleado acaba de marcar como backlog en esta sesión | **NO** - El empleado ya la despachó |

**Solución implementada (v1.3):**

1. **Campo interno `bbacklogemp`**: Se agrega automáticamente al marcar backlog
   - Cuando el empleado llama al endpoint con `bbacklog: "true"`, el sistema automáticamente setea `bbacklogemp: true`
   - El empleado **NO necesita** enviar `bbacklogemp` en el request (se maneja automáticamente)

2. **Queries modificadas**: Excluyen `bbacklogemp=true`
   - El endpoint `/empleadosactividades` ya no devuelve actividades con `bbacklogemp=true`
   - La actividad desaparece inmediatamente de la lista del empleado

3. **Distinción clara**:
   ```
   bbacklog=true + bbacklogemp=false/null  → Backlog asignado → SE MUESTRA
   bbacklog=true + bbacklogemp=true        → Backlog despachado → NO SE MUESTRA
   ```

### Flujo completo de Backlog

**Escenario 1: Empleado marca backlog**
1. Empleado ve actividad X en su lista
2. Empleado toca "Marcar como Backlog" → `POST /updatedetalleordentrabajo` con `bbacklog: "true"`
3. Sistema setea automáticamente: `bbacklog=true` Y `bbacklogemp=true`
4. Empleado actualiza su lista → Actividad X **ya no aparece** ✅
5. Planner cierra la OT y copia actividad X a nueva OT
6. En nueva OT: `bbacklog=true`, `bbacklogemp=false`, `iddetalleorigen=ID_anterior`

**Escenario 2: Planner asigna backlog de OT anterior**
1. Planner crea nueva OT para el vehículo
2. Sistema copia actividad Y de OT anterior → `bbacklog=true`, `bbacklogemp=false`
3. Empleado abre su lista → Actividad Y **aparece** ✅
4. Empleado debe trabajar en ella (o marcarla como backlog nuevamente si no puede)

**Escenario 3: Empleado marca backlog heredado**
1. Empleado recibe actividad Z que ya era backlog de OT anterior
2. Estado inicial: `bbacklog=true`, `bbacklogemp=false`, `iddetalleorigen=123`
3. Empleado tampoco puede completarla → Marca backlog nuevamente
4. Estado final: `bbacklog=true`, `bbacklogemp=true` ✅
5. Actividad Z **desaparece** de su lista
6. Planner deberá copiarla a siguiente OT (y resetear `bbacklogemp=false`)

---

## Soporte

Para dudas o problemas con este endpoint, contactar al equipo de desarrollo de HGAPI.
