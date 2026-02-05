import 'package:hgtrack/core/cache/cache_service.dart';
import 'package:hgtrack/core/network/api_client.dart';
import 'package:hgtrack/features/authentication/data/models/empleado.dart';

class AuthService {
  final _api = TrackingApi();
  final _cache = CacheService();

  /// Obtiene empleados con estrategia cache-first:
  /// 1. Si hay cache, retorna datos del cache inmediatamente
  /// 2. Si no hay cache (primera vez), llama a la API directamente
  /// 
  /// Para actualizar el cache en background, usar [refreshEmpleados]
  Future<List<HgEmpleadoMantenimientoDto>?> getAllEmpleadosMantenimiento() async {
    // Intentar cache primero
    final cached = await _cache.getEmpleados();
    if (cached != null && cached.isNotEmpty) {
      return cached;
    }

    // Sin cache: llamar a la API (primera vez)
    final result = await _api.getAllEmpleadosMantenimiento();
    if (result != null && result.isNotEmpty) {
      await _cache.saveEmpleados(result);
    }
    return result;
  }

  /// Actualiza el cache de empleados desde la API.
  /// Retorna los datos frescos o null si la API falla.
  /// En caso de fallo, el cache existente se mantiene intacto.
  Future<List<HgEmpleadoMantenimientoDto>?> refreshEmpleados() async {
    try {
      final result = await _api.getAllEmpleadosMantenimiento();
      if (result != null && result.isNotEmpty) {
        await _cache.saveEmpleados(result);
        return result;
      }
      return null;
    } catch (e) {
      print('Error al refrescar empleados desde API: $e');
      return null;
    }
  }
}
