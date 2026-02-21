import 'package:shared_preferences/shared_preferences.dart';

import 'package:hgtrack/features/time_tracking/data/models/pending_sync_activity.dart';
import 'package:hgtrack/features/time_tracking/data/services/activity_service.dart';

/// Servicio para gestionar cola de actividades finalizadas pendientes de sincronización
/// Almacena en SharedPreferences actividades que fallaron al enviarse al backend.
/// 
/// Soporta tanto Tareas Principales (TP) como Sub-Tareas (ST):
/// - TP: usa /gestionarestadoactividad (endpoint unificado)
/// - ST: usa /gestionarestadosubtarea (endpoint unificado)
class PendingSyncService {
  static const String _keyPrefix = 'pending_sync_';
  static const int maxRetries = 5;

  /// Agrega una actividad a la cola de pendientes.
  /// Usa una key unica combinando tipo + id para evitar colisiones.
  Future<bool> addToPendingQueue(PendingSyncActivity activity) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = _buildKey(activity);
      final jsonString = activity.toJsonString();
      final success = await prefs.setString(key, jsonString);

      if (success) {
        final tipoLabel = activity.esSubTarea ? 'ST' : 'TP';
        print('Actividad $tipoLabel ${activity.idActividad} agregada a cola de pendientes');
      }

      return success;
    } catch (e) {
      print('Error al agregar a cola de pendientes: $e');
      return false;
    }
  }

  /// Obtiene todas las actividades pendientes de sincronización
  Future<List<PendingSyncActivity>> getPendingActivities() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final keys = prefs.getKeys().where((key) => key.startsWith(_keyPrefix));

      List<PendingSyncActivity> activities = [];

      for (var key in keys) {
        final jsonString = prefs.getString(key);
        if (jsonString != null) {
          try {
            final activity = PendingSyncActivity.fromJsonString(jsonString);
            activities.add(activity);
          } catch (e) {
            print('Error al parsear actividad pendiente $key: $e');
          }
        }
      }

      // Ordenar por fecha de creación (más antiguas primero)
      activities.sort((a, b) => a.createdAt.compareTo(b.createdAt));

      return activities;
    } catch (e) {
      print('Error al obtener actividades pendientes: $e');
      return [];
    }
  }

  /// Obtiene la cantidad de actividades pendientes
  Future<int> getPendingCount() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final keys = prefs.getKeys().where((key) => key.startsWith(_keyPrefix));
      return keys.length;
    } catch (e) {
      print('Error al contar actividades pendientes: $e');
      return 0;
    }
  }

  /// Obtiene los IDs de actividades (TP) pendientes de sincronización.
  /// Usado para filtrar actividades ya finalizadas de la lista.
  Future<Set<int>> getPendingActivityIds() async {
    try {
      final activities = await getPendingActivities();
      return activities.map((a) => a.idActividad).toSet();
    } catch (e) {
      print('Error al obtener IDs de actividades pendientes: $e');
      return {};
    }
  }

  /// Obtiene los IDs de asignaciones (ST) pendientes de sincronización.
  /// Usado para filtrar sub-tareas ya finalizadas de la lista.
  Future<Set<int>> getPendingAsignacionIds() async {
    try {
      final activities = await getPendingActivities();
      return activities
          .where((a) => a.idAsignacion != null)
          .map((a) => a.idAsignacion!)
          .toSet();
    } catch (e) {
      print('Error al obtener IDs de asignaciones pendientes: $e');
      return {};
    }
  }

  /// Verifica si existe una actividad específica en la cola de pendientes.
  /// Busca por idActividad (TP) o idAsignacion (ST).
  Future<bool> hasPendingActivity({
    int? idActividad,
    int? idAsignacion,
    String tipo = "TP",
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      if (tipo == "ST" && idAsignacion != null) {
        // Buscar ST por idAsignacion
        final key = '${_keyPrefix}ST_$idAsignacion';
        return prefs.containsKey(key);
      } else if (idActividad != null) {
        // Buscar TP por idActividad
        final key = '${_keyPrefix}TP_$idActividad';
        if (prefs.containsKey(key)) return true;
        
        // Compatibilidad con datos antiguos (sin prefijo de tipo)
        final keyLegacy = '${_keyPrefix}$idActividad';
        return prefs.containsKey(keyLegacy);
      }
      
      return false;
    } catch (e) {
      print('Error al verificar actividad pendiente: $e');
      return false;
    }
  }

  /// Intenta sincronizar una actividad específica con el backend.
  /// Respeta el limite de reintentos (maxRetries).
  /// Detecta automaticamente si es TP o ST y usa el endpoint correcto.
  Future<bool> syncActivity(PendingSyncActivity activity) async {
    // Verificar limite de reintentos
    if (activity.retryCount >= maxRetries) {
      final tipoLabel = activity.esSubTarea ? 'ST' : 'TP';
      print('Actividad $tipoLabel ${activity.idActividad} excede el limite de reintentos ($maxRetries). Requiere atencion manual.');
      return false;
    }

    try {
      final tipoLabel = activity.esSubTarea ? 'ST' : 'TP';
      print('Intentando sincronizar actividad $tipoLabel ${activity.idActividad} (intento ${activity.retryCount + 1}/$maxRetries)...');

      bool success = false;

      if (activity.esSubTarea) {
        // Sub-Tarea (ST) - usar endpoint de asignacion
        success = await _syncSubTarea(activity);
      } else {
        // Tarea Principal (TP) - usar endpoint de detalle
        success = await _syncTareaPrincipal(activity);
      }

      if (success) {
        // Sincronizacion exitosa
        print('Actividad $tipoLabel ${activity.idActividad} sincronizada correctamente');
        await removeFromQueue(activity);
        return true;
      } else {
        // Fallo la sincronizacion
        print('Fallo sincronizacion de actividad $tipoLabel ${activity.idActividad}');
        await incrementRetryCount(activity);
        return false;
      }
    } catch (e) {
      print('Error al sincronizar actividad ${activity.idActividad}: $e');
      await incrementRetryCount(activity);
      return false;
    }
  }

  /// Sincroniza una Tarea Principal (TP) usando endpoint unificado
  /// /gestionarestadoactividad con acción FINALIZAR
  Future<bool> _syncTareaPrincipal(PendingSyncActivity activity) async {
    final service = ActivityService();

    // Usar NUEVO endpoint unificado con acción FINALIZAR
    // NOTA: No enviamos minutosEmpleado, el backend lo calcula automáticamente
    final response = await service.finalizarActividadTPNuevo(
      idDetalleOrdenTrabajo: activity.idActividad,
      timestamp: activity.fechaFin,
      observaciones: activity.observaciones,
    );

    return response != null && response.exito;
  }

  /// Sincroniza una Sub-Tarea (ST) usando endpoint unificado
  /// /gestionarestadosubtarea con acción FINALIZAR
  Future<bool> _syncSubTarea(PendingSyncActivity activity) async {
    if (activity.idAsignacion == null) {
      print('Error: idAsignacion es null para Sub-Tarea ${activity.idActividad}');
      return false;
    }

    final service = ActivityService();

    // Usar NUEVO endpoint unificado con acción FINALIZAR
    // NOTA: No enviamos minutosEmpleado, el backend lo calcula automáticamente
    final response = await service.finalizarActividadSTNuevo(
      idDetalleAsignacion: activity.idAsignacion!,
      timestamp: activity.fechaFin,
      observaciones: activity.observaciones,
    );

    return response != null && response.exito;
  }

  /// Intenta sincronizar todas las actividades pendientes
  Future<SyncResult> syncAllPending() async {
    final activities = await getPendingActivities();
    final total = activities.length;

    if (total == 0) {
      return SyncResult(
        total: 0,
        exitosos: 0,
        fallidos: 0,
        errores: [],
      );
    }

    int exitosos = 0;
    int fallidos = 0;
    List<String> errores = [];

    print('Iniciando sincronizacion de $total actividades pendientes...');

    for (var activity in activities) {
      if (activity.retryCount >= maxRetries) {
        fallidos++;
        errores.add(
            'Actividad ${activity.idActividad}: ${activity.nombreActividad} (excede reintentos)');
        continue;
      }

      final success = await syncActivity(activity);

      if (success) {
        exitosos++;
      } else {
        fallidos++;
        errores.add(
            'Actividad ${activity.idActividad}: ${activity.nombreActividad}');
      }
    }

    print('Sincronización completada: $exitosos exitosos, $fallidos fallidos');

    return SyncResult(
      total: total,
      exitosos: exitosos,
      fallidos: fallidos,
      errores: errores,
    );
  }

  /// Remueve una actividad de la cola (después de sincronización exitosa)
  Future<bool> removeFromQueue(PendingSyncActivity activity) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = _buildKey(activity);
      return await prefs.remove(key);
    } catch (e) {
      print('Error al remover actividad de cola: $e');
      return false;
    }
  }

  /// Incrementa el contador de reintentos de una actividad
  Future<void> incrementRetryCount(PendingSyncActivity activity) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = _buildKey(activity);
      final jsonString = prefs.getString(key);

      if (jsonString != null) {
        final loadedActivity = PendingSyncActivity.fromJsonString(jsonString);
        final updatedActivity = loadedActivity.incrementRetry();
        await prefs.setString(key, updatedActivity.toJsonString());

        final tipoLabel = activity.esSubTarea ? 'ST' : 'TP';
        print(
            'Intento ${updatedActivity.retryCount} para actividad $tipoLabel ${activity.idActividad}');
      }
    } catch (e) {
      print('Error al incrementar contador de reintentos: $e');
    }
  }

  /// Limpia todas las actividades pendientes (usar con precaución)
  Future<bool> clearAllPending() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final keys = prefs.getKeys().where((key) => key.startsWith(_keyPrefix));

      for (var key in keys) {
        await prefs.remove(key);
      }

      print('Cola de pendientes limpiada');
      return true;
    } catch (e) {
      print('Error al limpiar cola de pendientes: $e');
      return false;
    }
  }

  /// Construye la clave de almacenamiento.
  /// Formato: pending_sync_{tipo}_{id} para evitar colisiones entre TP y ST
  String _buildKey(PendingSyncActivity activity) {
    final tipo = activity.tipo;
    // Para ST usamos idAsignacion, para TP usamos idActividad
    final id = activity.esSubTarea 
        ? activity.idAsignacion ?? activity.idActividad
        : activity.idActividad;
    return '$_keyPrefix${tipo}_$id';
  }
}
