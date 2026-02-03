import 'package:shared_preferences/shared_preferences.dart';
import 'package:hgtrack/appseguimiento/model/actividad_tracking_state.dart';

/// Servicio para persistir estados de tracking de actividades en SharedPreferences
/// Permite guardar, cargar y limpiar estados localmente
class ActividadLocalStorageService {
  static const String _keyPrefix = 'actividad_tracking_';

  /// Guarda el estado de una actividad
  Future<bool> saveState(ActividadTrackingState state) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = _buildKey(state.idActividad);
      final jsonString = state.toJsonString();
      return await prefs.setString(key, jsonString);
    } catch (e) {
      print('Error al guardar estado de actividad ${state.idActividad}: $e');
      return false;
    }
  }

  /// Carga el estado de una actividad (null si no existe)
  Future<ActividadTrackingState?> loadState(int idActividad) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = _buildKey(idActividad);
      final jsonString = prefs.getString(key);

      if (jsonString == null) {
        return null;
      }

      return ActividadTrackingState.fromJsonString(jsonString);
    } catch (e) {
      print('Error al cargar estado de actividad $idActividad: $e');
      return null;
    }
  }

  /// Elimina el estado de una actividad (después de finalizar y enviar al backend)
  Future<bool> clearState(int idActividad) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = _buildKey(idActividad);
      return await prefs.remove(key);
    } catch (e) {
      print('Error al limpiar estado de actividad $idActividad: $e');
      return false;
    }
  }

  /// Obtiene todas las actividades con estado guardado
  Future<List<int>> getAllTrackedActividades() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final keys = prefs.getKeys();

      final ids = keys
          .where((key) => key.startsWith(_keyPrefix))
          .map((key) {
            final idStr = key.substring(_keyPrefix.length);
            return int.tryParse(idStr);
          })
          .whereType<int>()
          .toList();

      return ids;
    } catch (e) {
      print('Error al listar actividades trackeadas: $e');
      return [];
    }
  }

  /// Verifica si existe un estado guardado para una actividad
  Future<bool> hasState(int idActividad) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = _buildKey(idActividad);
      return prefs.containsKey(key);
    } catch (e) {
      print('Error al verificar estado de actividad $idActividad: $e');
      return false;
    }
  }

  /// Limpia todos los estados guardados (usar con precaución)
  Future<bool> clearAllStates() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final keys = prefs.getKeys().where((key) => key.startsWith(_keyPrefix));

      for (var key in keys) {
        await prefs.remove(key);
      }

      return true;
    } catch (e) {
      print('Error al limpiar todos los estados: $e');
      return false;
    }
  }

  /// Construye la clave de almacenamiento para una actividad
  String _buildKey(int idActividad) {
    return '$_keyPrefix$idActividad';
  }

  /// Obtiene el tamaño aproximado de datos guardados (debug)
  Future<int> getStorageSize() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final keys = prefs.getKeys().where((key) => key.startsWith(_keyPrefix));

      int totalSize = 0;
      for (var key in keys) {
        final value = prefs.getString(key);
        if (value != null) {
          totalSize += value.length;
        }
      }

      return totalSize;
    } catch (e) {
      print('Error al calcular tamaño de almacenamiento: $e');
      return 0;
    }
  }
}
