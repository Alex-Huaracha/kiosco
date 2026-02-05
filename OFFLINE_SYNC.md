# Sistema Offline y Sincronizacion Automatica - HG Track

## Resumen

Se implemento un sistema completo de resiliencia ante perdida de conectividad que permite a los tecnicos seguir usando la aplicacion sin interrupciones cuando no hay internet. El sistema se compone de tres pilares:

1. **Cache-First**: Los datos se cargan del cache local primero (una sola llamada carga todo)
2. **Cola de sincronizacion**: Las actividades finalizadas sin internet se guardan localmente
3. **Auto-sync inteligente**: Al recuperar internet, se sincronizan automaticamente los pendientes

---

## Arquitectura (Endpoint Unificado)

Con el endpoint unificado `/empleadosactividades`, toda la informacion se carga en una sola llamada:

```
                    ┌─────────────────────┐
                    │   ConnectivityService│ (Singleton)
                    │   - Stream online    │
                    │   - Auto-sync       │
                    └────────┬────────────┘
                             │ notifica
              ┌──────────────┼──────────────┐
              v              v              v
    ┌─────────────┐  ┌──────────────┐  ┌──────────────┐
    │ Empleados   │  │ Actividades  │  │ Detalle      │
    │ ListPage    │  │ ListPage     │  │ Page         │
    │             │  │              │  │              │
    │ - Carga TODO│  │ - Recibe     │  │ - Banner     │
    │   en inicio │  │   datos ya   │  │   offline    │
    │ - Banner    │  │   cargados   │  │              │
    │   offline   │  │ - Banner     │  │              │
    │ - Cache-    │  │   offline    │  │              │
    │   first     │  │ - Banner     │  │              │
    └──────┬──────┘  │   pendientes │  └──────────────┘
           │         └──────────────┘
           v
    ┌─────────────┐
    │ AuthService │
    │ cache-first │
    └──────┬──────┘
           │
           v
    ┌───────────────────────────┐
    │      CacheService         │
    │  (SharedPreferences)      │
    │                           │
    │  cache_empleados_         │
    │  actividades (una clave)  │
    └───────────────────────────┘
```

### Flujo de Datos

```
1. EmpleadosListPage
   └── AuthService.getAllEmpleadosConActividades()
       ├── CacheService.getEmpleadosConActividades() [PRIMERO]
       └── TrackingApi.getAllEmpleadosConActividades() [SI NO HAY CACHE]
           └── POST /empleadosactividades
               └── Retorna: [{empleado, actividades[]}, ...]

2. Usuario selecciona empleado
   └── Navega a ActivitiesListPage(empleadoConActividades)
       └── Las actividades ya vienen cargadas, no hay llamada HTTP

3. Usuario toca actividad
   └── Navega a ActivityDetailPage(actividad, ordentrabajo, empleado)
       └── Trabaja con datos ya cargados

4. Usuario finaliza actividad
   └── ActivityService.finalizarActividad()
       └── POST /updatedetalleordentrabajo
           ├── Exito: vuelve a EmpleadosListPage (recarga todo)
           └── Fallo: guarda en PendingSyncService (cola offline)
```

---

## Componentes

### 1. ConnectivityService (`lib/core/network/connectivity_service.dart`)

**Tipo:** Singleton

**Responsabilidades:**
- Monitorea el estado de red via `connectivity_plus`
- Expone `Stream<bool> onlineStream` para que las pantallas reaccionen
- Expone `Stream<SyncResult> syncResultStream` para notificar resultados de auto-sync
- Al detectar transicion offline -> online: ejecuta `PendingSyncService.syncAllPending()` automaticamente
- Metodo `forceSync()` para sincronizacion bajo demanda

**Inicializacion:** Se inicializa en `EmpleadosListPage.initState()` (primera pantalla de la app)

### 2. CacheService (`lib/core/cache/cache_service.dart`)

**Responsabilidades:**
- Guardar/leer la respuesta completa del endpoint unificado
- Una sola clave para todos los empleados y actividades

**Clave SharedPreferences:**

| Clave | Contenido | Tamano aprox. |
|-------|-----------|---------------|
| `cache_empleados_actividades` | JSON array de EmpleadoConActividades | 20-50 KB |

### 3. AuthService (`lib/features/authentication/data/services/auth_service.dart`)

**Metodos:**
- `getAllEmpleadosConActividades()`: Cache-first. Lee del cache primero, llama API si no hay cache.

### 4. ActivityService (`lib/features/time_tracking/data/services/activity_service.dart`)

**Simplificado:** Solo contiene `finalizarActividad()` para enviar actividades completadas al backend.

Las actividades ya no se cargan desde este servicio - vienen precargadas desde EmpleadosListPage.

### 5. PendingSyncService (`lib/features/time_tracking/data/services/pending_sync_service.dart`)

**Responsabilidades:**
- Guardar actividades finalizadas que fallaron al enviar
- Reintentar automaticamente al recuperar conexion
- Limite de 5 reintentos por actividad

---

## Modelo de Datos

### EmpleadoConActividades (`lib/features/authentication/data/models/empleado_con_actividades.dart`)

```dart
class EmpleadoConActividades {
  final HgEmpleadoMantenimientoDto empleado;
  final List<ActividadEmpleadoDto> actividades;
}
```

Este modelo agrupa un empleado con todas sus actividades asignadas. Es la respuesta del endpoint unificado.

---

## Pantallas

### EmpleadosListPage

- **Carga inicial:** Llama `AuthService.getAllEmpleadosConActividades()`
- **Cache-first:** Muestra datos del cache inmediatamente, actualiza en background
- **Banner offline:** Rojo cuando no hay internet
- **Navegacion:** Pasa `EmpleadoConActividades` completo a la siguiente pantalla

### ActivitiesListPage

- **Recibe:** `EmpleadoConActividades` ya cargado
- **No hace llamadas HTTP** para cargar actividades
- **Banner offline:** Rojo cuando no hay internet
- **Banner pendientes:** Naranja cuando hay actividades en cola de sync
- **Auto-sync:** Al entrar, si hay pendientes y hay internet, sincroniza
- **Refresh:** Vuelve a EmpleadosListPage para recargar todo

### ActivityDetailPage

- **Recibe:** `HgDetalleOrdenTrabajoDto`, `HgOrdenTrabajoDto`, `HgEmpleadoMantenimientoDto`
- **Banner offline:** Visible mientras el tecnico trabaja
- **Finalizacion:** Intenta enviar al backend; si falla, guarda en cola

---

## Flujos de Usuario

### Flujo normal (con internet)

```
Tecnico abre app
  -> Carga empleados+actividades (cache + API en una llamada)
  -> Selecciona su nombre
  -> Ve sus actividades (ya cargadas, sin espera)
  -> Trabaja en actividad (iniciar/pausar/reanudar)
  -> Finaliza -> Envia al backend -> Exito
  -> Vuelve a EmpleadosListPage (recarga todo)
```

### Flujo sin internet (con cache previo)

```
Tecnico abre app (sin internet, con cache previo)
  -> Banner rojo "Sin conexion a internet"
  -> Carga empleados+actividades del CACHE -> Inmediato
  -> Selecciona su nombre
  -> Ve actividades (ya cargadas)
  -> Trabaja normalmente (tracking es 100% local)
  -> Finaliza -> API falla -> Guarda en cola
  -> Vuelve a lista
  -> Banner naranja "1 actividad pendiente de envio"
```

### Flujo de reconexion

```
Internet vuelve
  -> ConnectivityService detecta cambio
  -> Banner rojo desaparece
  -> Auto-sync se ejecuta automaticamente
  -> SnackBar: "1 actividad sincronizada"
  -> Banner naranja desaparece
  -> Tecnico no tuvo que hacer nada
```

### Flujo primera vez (sin cache, sin internet)

```
Tecnico abre app por PRIMERA VEZ (sin internet)
  -> No hay cache
  -> API falla
  -> Pantalla de error "Error al cargar empleados"
  -> Boton "Reintentar"
  -> (Necesita internet al menos una vez para la carga inicial)
```

---

## Claves de SharedPreferences (Resumen)

| Patron de clave | Servicio | Proposito |
|-----------------|----------|-----------|
| `actividad_tracking_{id}` | ActividadLocalStorageService | Estado de cronometro (periodos, pausas) |
| `pending_sync_{id}` | PendingSyncService | Actividades finalizadas pendientes de envio |
| `cache_empleados_actividades` | CacheService | Respuesta completa del endpoint unificado |

---

## Dependencias

| Paquete | Version | Proposito |
|---------|---------|-----------|
| `connectivity_plus` | ^6.0.3 | Deteccion de estado de red (WiFi, ethernet, none) |

---

## Archivos Clave

| Archivo | Proposito |
|---------|-----------|
| `lib/core/network/connectivity_service.dart` | Singleton de monitoreo de red + auto-sync |
| `lib/core/cache/cache_service.dart` | Cache local simplificado (una clave) |
| `lib/core/network/api_client.dart` | Cliente HTTP con endpoint unificado |
| `lib/features/authentication/data/models/empleado_con_actividades.dart` | Modelo para respuesta unificada |
| `lib/features/authentication/data/services/auth_service.dart` | Carga cache-first de empleados+actividades |
| `lib/features/time_tracking/data/services/activity_service.dart` | Solo finalizacion de actividades |
| `lib/features/time_tracking/data/services/pending_sync_service.dart` | Cola de sincronizacion offline |

---

## Limitaciones conocidas

1. **Primera carga requiere internet**: Si la tablet nunca se conecto, no hay cache y no puede mostrar datos.
2. **Datos del cache pueden estar desactualizados**: Si un supervisor asigna una nueva OT mientras el tecnico esta offline, no la vera hasta que vuelva la conexion.
3. **No hay sync en background (app cerrada)**: La sincronizacion solo ocurre mientras la app esta abierta.
4. **Limite de 5 reintentos**: Actividades que fallan 5 veces dejan de intentarse automaticamente.
5. **connectivity_plus en web**: En entorno web, `connectivity_plus` puede no detectar correctamente el estado offline. Funciona correctamente en Android/tablets.

---

## Endpoint Unificado

**URL:** `POST /hgapi/empleadosactividades`

**Request:**
```json
{
  "cidempresa": "1"
}
```

**Response:**
```json
[
  {
    "empleado": {
      "id": 123,
      "nombres": "Juan",
      "apellidopaterno": "Perez",
      ...
    },
    "actividades": [
      {
        "ordentrabajo": { ... },
        "detalle": { ... }
      },
      ...
    ]
  },
  ...
]
```

Este endpoint reemplaza las llamadas separadas a `/listarempleadosconactividades` y `/consultaractividadesempleado`, reduciendo la latencia y simplificando el cache.
