import 'package:shared_preferences/shared_preferences.dart';

import 'package:hgtrack/features/authentication/data/models/empleado.dart';
import 'package:hgtrack/features/time_tracking/data/models/detalle_orden_trabajo.dart';
import 'package:hgtrack/features/time_tracking/data/models/pending_sync_activity.dart';
import 'package:hgtrack/features/time_tracking/data/services/activity_service.dart';

/// Servicio para gestionar cola de actividades finalizadas pendientes de sincronización
/// Almacena en SharedPreferences actividades que fallaron al enviarse al backend
class PendingSyncService {
  static const String _keyPrefix = 'pending_sync_';
  static const int maxRetries = 5;

  /// Agrega una actividad a la cola de pendientes
  Future<bool> addToPendingQueue(PendingSyncActivity activity) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = _buildKey(activity.idActividad);
      final jsonString = activity.toJsonString();
      final success = await prefs.setString(key, jsonString);

      if (success) {
        print('✓ Actividad ${activity.idActividad} agregada a cola de pendientes');
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

  /// Verifica si existe una actividad específica en la cola de pendientes
  Future<bool> hasPendingActivity(int? idActividad) async {
    if (idActividad == null) return false;

    try {
      final prefs = await SharedPreferences.getInstance();
      final key = _buildKey(idActividad);
      return prefs.containsKey(key);
    } catch (e) {
      print('Error al verificar actividad pendiente: $e');
      return false;
    }
  }

  /// Intenta sincronizar una actividad específica con el backend.
  /// Respeta el limite de reintentos (maxRetries).
  Future<bool> syncActivity(PendingSyncActivity activity) async {
    // Verificar limite de reintentos
    if (activity.retryCount >= maxRetries) {
      print('Actividad ${activity.idActividad} excede el limite de reintentos ($maxRetries). Requiere atencion manual.');
      return false;
    }

    try {
      print('Intentando sincronizar actividad ${activity.idActividad} (intento ${activity.retryCount + 1}/$maxRetries)...');

      final service = ActivityService();

      // Crear DTOs necesarios para el servicio
      final actividadDto = HgDetalleOrdenTrabajoDto(
        id: activity.idActividad,
        cactividad: activity.nombreActividad,
      );

      final empleadoDto = HgEmpleadoMantenimientoDto(
        id: activity.idEmpleado,
        nombres: activity.nombreEmpleado,
        cargo: activity.cargoEmpleado,
      );

      // Intentar enviar al backend
      final resultado = await service.finalizarActividad(
        actividad: actividadDto,
        empleado: empleadoDto,
        tiempoInicio: activity.fechaInicio,
        tiempoFin: activity.fechaFin,
        minutosEmpleado: activity.minutosTotal,
        observaciones: activity.observaciones ?? '',
      );

      if (resultado != null) {
        // ✅ Sincronización exitosa
        print('✓ Actividad ${activity.idActividad} sincronizada correctamente');
        await removeFromQueue(activity.idActividad);
        return true;
      } else {
        // ❌ Falló la sincronización
        print('✗ Falló sincronización de actividad ${activity.idActividad}');
        await incrementRetryCount(activity.idActividad);
        return false;
      }
    } catch (e) {
      print('Error al sincronizar actividad ${activity.idActividad}: $e');
      await incrementRetryCount(activity.idActividad);
      return false;
    }
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
  Future<bool> removeFromQueue(int idActividad) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = _buildKey(idActividad);
      return await prefs.remove(key);
    } catch (e) {
      print('Error al remover actividad de cola: $e');
      return false;
    }
  }

  /// Incrementa el contador de reintentos de una actividad
  Future<void> incrementRetryCount(int idActividad) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = _buildKey(idActividad);
      final jsonString = prefs.getString(key);

      if (jsonString != null) {
        final activity = PendingSyncActivity.fromJsonString(jsonString);
        final updatedActivity = activity.incrementRetry();
        await prefs.setString(key, updatedActivity.toJsonString());

        print(
            'Intento ${updatedActivity.retryCount} para actividad $idActividad');
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

  /// Construye la clave de almacenamiento
  String _buildKey(int idActividad) {
    return '$_keyPrefix$idActividad';
  }
}
