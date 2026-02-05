import 'package:hgtrack/core/cache/cache_service.dart';
import 'package:hgtrack/core/network/api_client.dart';
import 'package:hgtrack/features/authentication/data/models/empleado_con_actividades.dart';

/// Servicio de autenticacion y carga de datos de empleados.
/// Usa el endpoint unificado /empleadosactividades para cargar
/// empleados + actividades en una sola llamada.
class AuthService {
  final _api = TrackingApi();
  final _cache = CacheService();

  /// Obtiene todos los empleados con sus actividades.
  /// Estrategia cache-first: retorna cache si existe, sino llama API.
  Future<List<EmpleadoConActividades>?> getAllEmpleadosConActividades() async {
    // Intentar cache primero
    final cached = await _cache.getAllData();
    if (cached != null && cached.isNotEmpty) {
      return cached;
    }

    // Sin cache: llamar a la API (primera vez)
    final result = await _api.getAllEmpleadosConActividades();
    if (result != null && result.isNotEmpty) {
      await _cache.saveAllData(result);
    }
    return result;
  }

  /// Actualiza el cache desde la API.
  /// Retorna los datos frescos o null si la API falla.
  /// En caso de fallo, el cache existente se mantiene intacto.
  Future<List<EmpleadoConActividades>?> refreshAllData() async {
    try {
      final result = await _api.getAllEmpleadosConActividades();
      if (result != null && result.isNotEmpty) {
        await _cache.saveAllData(result);
        return result;
      }
      return null;
    } catch (e) {
      print('Error al refrescar datos desde API: $e');
      return null;
    }
  }
}
