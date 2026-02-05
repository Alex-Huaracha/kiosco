# API Endpoint: `/empleadosactividades`

## Información General

| Atributo | Valor |
|----------|-------|
| **Endpoint** | `/empleadosactividades` |
| **Método HTTP** | `POST` |
| **Content-Type** | `application/json` |
| **Autenticación** | No requerida (CORS habilitado: `*`) |
| **Propósito** | Carga masiva de empleados con todas sus actividades para funcionamiento offline |

---

## Descripción

Este endpoint está **optimizado para aplicaciones móviles offline-first**. Retorna la lista completa de empleados de mantenimiento junto con **todas** sus actividades pendientes en una **única llamada HTTP**.

### Beneficios
- **Reducción drástica de llamadas**: De 46 llamadas (1 + 45) a solo 1
- **Atomicidad**: Garantiza que la carga sea completa o falle por completo (no cachés parciales)
- **Performance**: Utiliza queries batch optimizadas (3 queries vs ~453)
- **Tiempo de respuesta**: <500ms (vs 3-5 segundos anteriormente)

---

## Request

### URL
```
POST http://[servidor]/empleadosactividades
```

### Headers
```http
Content-Type: application/json
```

### Body
```json
{}
```

**Nota**: El body debe ser un objeto JSON vacío `{}`. No requiere parámetros.

### Ejemplo con cURL
```bash
curl -X POST http://localhost:8080/empleadosactividades \
  -H "Content-Type: application/json" \
  -d "{}"
```

### Ejemplo con JavaScript (Fetch API)
```javascript
fetch('http://servidor/empleadosactividades', {
  method: 'POST',
  headers: {
    'Content-Type': 'application/json'
  },
  body: JSON.stringify({})
})
.then(response => response.json())
.then(data => console.log(data))
.catch(error => console.error('Error:', error));
```

### Ejemplo con Dart/Flutter
```dart
import 'dart:convert';
import 'package:http/http.dart' as http;

Future<List<EmpleadoConActividades>> cargarEmpleadosActividades() async {
  final url = Uri.parse('http://servidor/empleadosactividades');
  
  final response = await http.post(
    url,
    headers: {'Content-Type': 'application/json'},
    body: jsonEncode({}),
  );
  
  if (response.statusCode == 200) {
    final List<dynamic> jsonData = jsonDecode(response.body);
    return jsonData
        .map((json) => EmpleadoConActividades.fromJson(json))
        .toList();
  } else {
    throw Exception('Error al cargar empleados: ${response.statusCode}');
  }
}
```

---

## Response

### Status Codes

| Código | Descripción |
|--------|-------------|
| `200 OK` | Operación exitosa, retorna lista de empleados (puede ser vacía) |
| `500 Internal Server Error` | Error en el servidor o en la consulta a BD |

### Estructura de Respuesta Exitosa

```json
[
  {
    "empleado": {
      "id": 2537,
      "nombres": "EFRAIN",
      "apellidopaterno": "ALCCA",
      "apellidomaterno": "QUISPE",
      "nombreCompleto": "ALCCA QUISPE EFRAIN",
      "numerodocumento": "12345678",
      "cargo": "TECNICO ELECTRICISTA M1",
      "area": "MANTENIMIENTO",
      "cantidadActividades": 5,
      "cantidadBacklog": 1,
      "cantidadTotal": 6,
      "fechaActividadReciente": "2024-01-15T10:30:00.000+00:00"
    },
    "actividades": [
      {
        "detalle": {
          "id": 1234,
          "idordentrabajo": 567,
          "idempleadoext": "2537",
          "idactividad": 89,
          "cactividad": "CAMBIO DE ACEITE MOTOR",
          "bcerrada": false,
          "bbacklog": false,
          "bactivo": true,
          "dfecreg": "2024-01-15T10:30:00.000+00:00",
          "cnombreemp": "EFRAIN ALCCA",
          "cobservaciones": "Revisar filtros",
          "dtiempoinicio": null,
          "dtiempofin": null
        },
        "ordentrabajo": {
          "id": 567,
          "dfecha": "2024-01-15T08:00:00.000+00:00",
          "idplacatracto": "ABC-123",
          "idplacaacople": "XYZ-789",
          "nkilometraje": 125000,
          "bcerrada": false,
          "bactivo": true,
          "supervisor": "JUAN PEREZ",
          "taller": "TALLER CENTRAL",
          "cobservaciones": "Mantenimiento preventivo 10K"
        }
      },
      {
        "detalle": { /* Otra actividad */ },
        "ordentrabajo": { /* Otra orden de trabajo */ }
      }
    ]
  },
  {
    "empleado": { /* Otro empleado */ },
    "actividades": [ /* Sus actividades */ ]
  }
]
```

### Respuesta Vacía (No hay empleados con actividades)
```json
[]
```

### Respuesta de Error
```json
"Error al consultar empleados con actividades: [mensaje de error]"
```

---

## Modelo de Datos

### Objeto Principal: `EmpleadoConTodasActividades`

```typescript
interface EmpleadoConTodasActividades {
  empleado: EmpleadoConActividades;
  actividades: ActividadEmpleado[];
}
```

### Objeto `EmpleadoConActividades`

| Campo | Tipo | Descripción | Ejemplo |
|-------|------|-------------|---------|
| `id` | `Integer` | ID del empleado en sistema externo | `2537` |
| `nombres` | `String` | Nombres del empleado | `"EFRAIN"` |
| `apellidopaterno` | `String` | Apellido paterno | `"ALCCA"` |
| `apellidomaterno` | `String` | Apellido materno | `"QUISPE"` |
| `nombreCompleto` | `String` | Nombre completo concatenado | `"ALCCA QUISPE EFRAIN"` |
| `numerodocumento` | `String` | Número de DNI | `"12345678"` |
| `cargo` | `String` | Cargo del empleado | `"TECNICO ELECTRICISTA M1"` |
| `area` | `String` | Área de trabajo | `"MANTENIMIENTO"` |
| `cantidadActividades` | `Integer` | Actividades normales pendientes | `5` |
| `cantidadBacklog` | `Integer` | Actividades en backlog | `1` |
| `cantidadTotal` | `Integer` | Total de actividades (normal + backlog) | `6` |
| `fechaActividadReciente` | `Date (ISO 8601)` | Fecha de la actividad más reciente | `"2024-01-15T10:30:00.000+00:00"` |

### Objeto `ActividadEmpleado`

```typescript
interface ActividadEmpleado {
  detalle: DetalleOrdentrabajo;
  ordentrabajo: Ordentrabajo;
}
```

### Objeto `DetalleOrdentrabajo`

| Campo | Tipo | Nullable | Descripción |
|-------|------|----------|-------------|
| `id` | `Integer` | No | ID del detalle (PK auto-generado) |
| `idordentrabajo` | `Integer` | No | ID de la orden de trabajo asociada |
| `idempleadoext` | `String` | No | ID del empleado (referencia externa) |
| `idactividad` | `Integer` | Sí | ID de la actividad |
| `cactividad` | `String` | Sí | Nombre/descripción de la actividad |
| `bcerrada` | `Boolean` | Sí | ¿Actividad cerrada/completada? |
| `bbacklog` | `Boolean` | Sí | ¿Es backlog? (actividad pendiente de OT cerrada) |
| `bactivo` | `Boolean` | No | ¿Registro activo? (siempre `true` en respuesta) |
| `dfecreg` | `Date` | No | Fecha de registro |
| `cnombreemp` | `String` | Sí | Nombre del empleado (redundante) |
| `cobservaciones` | `String` | Sí | Observaciones de la actividad |
| `dtiempoinicio` | `Date` | Sí | Fecha/hora de inicio de trabajo |
| `dtiempofin` | `Date` | Sí | Fecha/hora de fin de trabajo |

**Nota**: Solo se devuelven actividades donde `bcerrada` es `false` o `null`, y `bbacklog` puede ser `true`.

### Objeto `Ordentrabajo`

| Campo | Tipo | Nullable | Descripción |
|-------|------|----------|-------------|
| `id` | `Integer` | No | ID de la orden de trabajo (PK) |
| `dfecha` | `Date` | No | Fecha de la orden de trabajo |
| `idplacatracto` | `String` | Sí | Placa del vehículo tracto |
| `idplacaacople` | `String` | Sí | Placa del vehículo acople/remolque |
| `nkilometraje` | `Integer` | Sí | Kilometraje del vehículo |
| `bcerrada` | `Boolean` | Sí | ¿OT cerrada? (puede ser `true` si hay backlog) |
| `bactivo` | `Boolean` | No | ¿Registro activo? (siempre `true` en respuesta) |
| `supervisor` | `String` | Sí | Nombre del supervisor |
| `taller` | `String` | Sí | Taller donde se realiza el mantenimiento |
| `cobservaciones` | `String` | Sí | Observaciones de la OT |

---

## Lógica de Negocio

### Filtros Aplicados

1. **Solo empleados con actividades**: No se devuelven empleados sin actividades pendientes
2. **Solo actividades pendientes**: 
   - `bcerrada = false` o `bcerrada IS NULL`
   - Se incluyen actividades normales y backlog (`bbacklog = true`)
3. **Solo registros activos**: `bactivo = 1/true`
4. **Solo empleados de mantenimiento**: Filtro aplicado en API externo

### Ordenamiento

Los empleados se ordenan por **fecha de actividad más reciente (descendente)**:
- El empleado con la actividad más reciente aparece primero
- Útil para priorizar trabajo en la UI

### Relación Detalle-Orden de Trabajo

Cada `detalle` pertenece a una `ordentrabajo` a través de `detalle.idordentrabajo == ordentrabajo.id`.

**Importante**: 
- Una orden de trabajo puede estar cerrada (`bcerrada = true`) pero tener actividades pendientes (backlog)
- Las actividades en backlog se identifican con `detalle.bbacklog = true`

---

## Volumen de Datos Esperado

| Métrica | Valor Aproximado |
|---------|------------------|
| **Empleados** | ~45 |
| **Actividades por empleado** | ~10 (promedio) |
| **Total de actividades** | ~450 |
| **Tamaño de respuesta** | 50-100 KB |
| **Tiempo de respuesta** | <500ms |

---

## Casos de Uso

### 1. Carga Inicial Offline (App Móvil)

```dart
// Al abrir la app o al detectar conexión
Future<void> sincronizarDatosOffline() async {
  try {
    // 1. Llamar al endpoint unificado
    final empleados = await cargarEmpleadosActividades();
    
    // 2. Guardar en base de datos local (SQLite, Hive, etc.)
    await database.guardarEmpleadosConActividades(empleados);
    
    // 3. Marcar como sincronizado
    await preferences.setUltimaSincronizacion(DateTime.now());
    
    print('✅ Sincronización completa: ${empleados.length} empleados');
  } catch (e) {
    print('❌ Error en sincronización: $e');
    // Continuar con datos locales
  }
}
```

### 2. Refresco Manual

```dart
// Pull-to-refresh
Future<void> onRefresh() async {
  if (await tieneConexion()) {
    await sincronizarDatosOffline();
    setState(() {
      // Recargar UI desde base local
    });
  } else {
    mostrarMensaje('Sin conexión. Mostrando datos offline.');
  }
}
```

### 3. Mostrar Empleados con Contadores

```dart
// UI: Lista de empleados
ListView.builder(
  itemCount: empleados.length,
  itemBuilder: (context, index) {
    final empleado = empleados[index].empleado;
    return ListTile(
      title: Text(empleado.nombreCompleto),
      subtitle: Text(empleado.cargo),
      trailing: Column(
        children: [
          Text('${empleado.cantidadActividades} normales'),
          Text('${empleado.cantidadBacklog} backlog'),
        ],
      ),
      onTap: () {
        // Navegar a detalle con actividades ya cargadas
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => DetalleEmpleado(
              empleado: empleados[index],
            ),
          ),
        );
      },
    );
  },
);
```

---

## Ejemplo Completo de Modelo en Dart

```dart
class EmpleadoConTodasActividades {
  final EmpleadoConActividades empleado;
  final List<ActividadEmpleado> actividades;

  EmpleadoConTodasActividades({
    required this.empleado,
    required this.actividades,
  });

  factory EmpleadoConTodasActividades.fromJson(Map<String, dynamic> json) {
    return EmpleadoConTodasActividades(
      empleado: EmpleadoConActividades.fromJson(json['empleado']),
      actividades: (json['actividades'] as List)
          .map((a) => ActividadEmpleado.fromJson(a))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() => {
    'empleado': empleado.toJson(),
    'actividades': actividades.map((a) => a.toJson()).toList(),
  };
}

class EmpleadoConActividades {
  final int id;
  final String nombres;
  final String apellidopaterno;
  final String apellidomaterno;
  final String nombreCompleto;
  final String numerodocumento;
  final String cargo;
  final String area;
  final int cantidadActividades;
  final int cantidadBacklog;
  final int cantidadTotal;
  final DateTime fechaActividadReciente;

  EmpleadoConActividades({
    required this.id,
    required this.nombres,
    required this.apellidopaterno,
    required this.apellidomaterno,
    required this.nombreCompleto,
    required this.numerodocumento,
    required this.cargo,
    required this.area,
    required this.cantidadActividades,
    required this.cantidadBacklog,
    required this.cantidadTotal,
    required this.fechaActividadReciente,
  });

  factory EmpleadoConActividades.fromJson(Map<String, dynamic> json) {
    return EmpleadoConActividades(
      id: json['id'],
      nombres: json['nombres'] ?? '',
      apellidopaterno: json['apellidopaterno'] ?? '',
      apellidomaterno: json['apellidomaterno'] ?? '',
      nombreCompleto: json['nombreCompleto'] ?? '',
      numerodocumento: json['numerodocumento'] ?? '',
      cargo: json['cargo'] ?? '',
      area: json['area'] ?? '',
      cantidadActividades: json['cantidadActividades'] ?? 0,
      cantidadBacklog: json['cantidadBacklog'] ?? 0,
      cantidadTotal: json['cantidadTotal'] ?? 0,
      fechaActividadReciente: DateTime.parse(json['fechaActividadReciente']),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'nombres': nombres,
    'apellidopaterno': apellidopaterno,
    'apellidomaterno': apellidomaterno,
    'nombreCompleto': nombreCompleto,
    'numerodocumento': numerodocumento,
    'cargo': cargo,
    'area': area,
    'cantidadActividades': cantidadActividades,
    'cantidadBacklog': cantidadBacklog,
    'cantidadTotal': cantidadTotal,
    'fechaActividadReciente': fechaActividadReciente.toIso8601String(),
  };
}

class ActividadEmpleado {
  final DetalleOrdentrabajo detalle;
  final Ordentrabajo ordentrabajo;

  ActividadEmpleado({
    required this.detalle,
    required this.ordentrabajo,
  });

  factory ActividadEmpleado.fromJson(Map<String, dynamic> json) {
    return ActividadEmpleado(
      detalle: DetalleOrdentrabajo.fromJson(json['detalle']),
      ordentrabajo: Ordentrabajo.fromJson(json['ordentrabajo']),
    );
  }

  Map<String, dynamic> toJson() => {
    'detalle': detalle.toJson(),
    'ordentrabajo': ordentrabajo.toJson(),
  };
}

class DetalleOrdentrabajo {
  final int id;
  final int idordentrabajo;
  final String idempleadoext;
  final int? idactividad;
  final String? cactividad;
  final bool? bcerrada;
  final bool? bbacklog;
  final bool bactivo;
  final DateTime dfecreg;
  final String? cnombreemp;
  final String? cobservaciones;
  final DateTime? dtiempoinicio;
  final DateTime? dtiempofin;

  DetalleOrdentrabajo({
    required this.id,
    required this.idordentrabajo,
    required this.idempleadoext,
    this.idactividad,
    this.cactividad,
    this.bcerrada,
    this.bbacklog,
    required this.bactivo,
    required this.dfecreg,
    this.cnombreemp,
    this.cobservaciones,
    this.dtiempoinicio,
    this.dtiempofin,
  });

  factory DetalleOrdentrabajo.fromJson(Map<String, dynamic> json) {
    return DetalleOrdentrabajo(
      id: json['id'],
      idordentrabajo: json['idordentrabajo'],
      idempleadoext: json['idempleadoext'],
      idactividad: json['idactividad'],
      cactividad: json['cactividad'],
      bcerrada: json['bcerrada'],
      bbacklog: json['bbacklog'],
      bactivo: json['bactivo'] ?? true,
      dfecreg: DateTime.parse(json['dfecreg']),
      cnombreemp: json['cnombreemp'],
      cobservaciones: json['cobservaciones'],
      dtiempoinicio: json['dtiempoinicio'] != null 
          ? DateTime.parse(json['dtiempoinicio']) 
          : null,
      dtiempofin: json['dtiempofin'] != null 
          ? DateTime.parse(json['dtiempofin']) 
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'idordentrabajo': idordentrabajo,
    'idempleadoext': idempleadoext,
    'idactividad': idactividad,
    'cactividad': cactividad,
    'bcerrada': bcerrada,
    'bbacklog': bbacklog,
    'bactivo': bactivo,
    'dfecreg': dfecreg.toIso8601String(),
    'cnombreemp': cnombreemp,
    'cobservaciones': cobservaciones,
    'dtiempoinicio': dtiempoinicio?.toIso8601String(),
    'dtiempofin': dtiempofin?.toIso8601String(),
  };
}

class Ordentrabajo {
  final int id;
  final DateTime dfecha;
  final String? idplacatracto;
  final String? idplacaacople;
  final int? nkilometraje;
  final bool? bcerrada;
  final bool bactivo;
  final String? supervisor;
  final String? taller;
  final String? cobservaciones;

  Ordentrabajo({
    required this.id,
    required this.dfecha,
    this.idplacatracto,
    this.idplacaacople,
    this.nkilometraje,
    this.bcerrada,
    required this.bactivo,
    this.supervisor,
    this.taller,
    this.cobservaciones,
  });

  factory Ordentrabajo.fromJson(Map<String, dynamic> json) {
    return Ordentrabajo(
      id: json['id'],
      dfecha: DateTime.parse(json['dfecha']),
      idplacatracto: json['idplacatracto'],
      idplacaacople: json['idplacaacople'],
      nkilometraje: json['nkilometraje'],
      bcerrada: json['bcerrada'],
      bactivo: json['bactivo'] ?? true,
      supervisor: json['supervisor'],
      taller: json['taller'],
      cobservaciones: json['cobservaciones'],
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'dfecha': dfecha.toIso8601String(),
    'idplacatracto': idplacatracto,
    'idplacaacople': idplacaacople,
    'nkilometraje': nkilometraje,
    'bcerrada': bcerrada,
    'bactivo': bactivo,
    'supervisor': supervisor,
    'taller': taller,
    'cobservaciones': cobservaciones,
  };
}
```

---

## Manejo de Errores

### Escenarios de Error

| Escenario | Response Status | Response Body |
|-----------|----------------|---------------|
| Error en BD | 500 | `"Error al consultar empleados con actividades: [detalle]"` |
| API externo caído | 500 | `"Error al consultar empleados con actividades: [detalle]"` |
| Sin empleados con actividades | 200 | `[]` |

### Recomendaciones Frontend

```dart
try {
  final response = await http.post(url, ...);
  
  if (response.statusCode == 200) {
    final data = jsonDecode(response.body);
    
    // Validar si es un array o un string de error
    if (data is List) {
      // Procesar normalmente
      if (data.isEmpty) {
        print('ℹ️ No hay empleados con actividades pendientes');
      }
    } else if (data is String) {
      // Error devuelto como string
      throw Exception('Error del servidor: $data');
    }
  } else {
    throw Exception('Error HTTP ${response.statusCode}');
  }
} catch (e) {
  // Manejar error y trabajar con datos locales
  print('❌ Error: $e');
  return await cargarDatosLocales();
}
```

---

## Performance y Optimización

### Queries Ejecutadas (Backend)

1. **Query conteos**: Agregación de actividades por empleado
2. **Query detalles**: TODOS los detalles pendientes (batch)
3. **Query órdenes**: Todas las OTs relacionadas (batch con `IN`)
4. **API externo**: Datos de empleados de mantenimiento

**Total: 3 queries a BD + 1 API externo**

### Tiempo de Ejecución Estimado

- Base de datos: ~200ms
- API externo: ~150ms
- Procesamiento Java: ~50ms
- **Total: <500ms**

### Recomendaciones de Cache (Frontend)

```dart
// Estrategia de cache recomendada
class CacheStrategy {
  static const DURACION_CACHE = Duration(hours: 2);
  
  Future<List<EmpleadoConTodasActividades>> obtenerEmpleados() async {
    final ultimaSync = await getUltimaSincronizacion();
    final tiempoTranscurrido = DateTime.now().difference(ultimaSync);
    
    if (tiempoTranscurrido > DURACION_CACHE && await tieneConexion()) {
      // Cache expirado y hay conexión: recargar
      return await sincronizarDatosOffline();
    } else {
      // Cache válido o sin conexión: usar datos locales
      return await cargarDatosLocales();
    }
  }
}
```

---

## Notas Importantes

1. **CORS habilitado**: El endpoint acepta peticiones desde cualquier origen (`*`)
2. **Sin autenticación**: Actualmente no requiere token/credenciales
3. **Body requerido**: Aunque vacío, debe enviarse `{}` como body
4. **Formato de fechas**: ISO 8601 con timezone (`2024-01-15T10:30:00.000+00:00`)
5. **Nullables**: Muchos campos pueden ser `null`, validar en frontend
6. **Ordenamiento garantizado**: Los empleados vienen ordenados por fecha reciente
7. **Actividades ordenadas**: Backlog primero (ASC), luego por fecha (DESC)

---

## Soporte y Contacto

Para dudas o reportar problemas con este endpoint:
- Revisar logs del servidor en caso de error 500
- Validar conectividad con el API externo de empleados
- Verificar estado de la base de datos SQL Server

---

**Versión del documento**: 1.0  
**Fecha**: 2026-02-05  
**Endpoint implementado en**: `OrdentrabajoServiceController.java:304-450`
