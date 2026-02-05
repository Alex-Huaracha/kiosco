import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import 'package:hgtrack/features/authentication/data/models/empleado.dart';
import 'package:hgtrack/features/time_tracking/data/models/actividad.dart';

/// Servicio de cache local usando SharedPreferences.
/// Implementa estrategia cache-first: mostrar datos locales primero,
/// luego actualizar desde la API en background.
class CacheService {
  static const String _keyEmpleados = 'cache_empleados';
  static const String _keyActividadesPrefix = 'cache_actividades_';
  static const String _keyTimestampPrefix = 'cache_timestamp_';

  // --- EMPLEADOS ---

  /// Guarda la lista de empleados en cache
  Future<bool> saveEmpleados(List<HgEmpleadoMantenimientoDto> empleados) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonList = empleados.map((e) => e.toJson()).toList();
      final jsonString = jsonEncode(jsonList);
      await prefs.setString(_keyEmpleados, jsonString);
      await prefs.setString(
        '${_keyTimestampPrefix}empleados',
        DateTime.now().toIso8601String(),
      );
      print('Cache: ${empleados.length} empleados guardados');
      return true;
    } catch (e) {
      print('Error al guardar cache de empleados: $e');
      return false;
    }
  }

  /// Lee la lista de empleados desde cache
  Future<List<HgEmpleadoMantenimientoDto>?> getEmpleados() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString(_keyEmpleados);

      if (jsonString == null || jsonString.isEmpty) return null;

      final List<dynamic> jsonList = jsonDecode(jsonString);
      final empleados = jsonList
          .map((json) =>
              HgEmpleadoMantenimientoDto.fromJson(json as Map<String, dynamic>))
          .toList();

      print('Cache: ${empleados.length} empleados cargados');
      return empleados;
    } catch (e) {
      print('Error al leer cache de empleados: $e');
      return null;
    }
  }

  /// Verifica si hay empleados en cache
  Future<bool> hasEmpleados() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.containsKey(_keyEmpleados);
    } catch (e) {
      return false;
    }
  }

  // --- ACTIVIDADES POR EMPLEADO ---

  /// Guarda la respuesta cruda de actividades (lista de ActividadEmpleadoDto)
  /// para un empleado especifico
  Future<bool> saveActividades(
    String idEmpleado,
    List<ActividadEmpleadoDto> actividades,
  ) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = '$_keyActividadesPrefix$idEmpleado';
      final jsonList = actividades.map((a) => a.toJson()).toList();
      final jsonString = jsonEncode(jsonList);
      await prefs.setString(key, jsonString);
      await prefs.setString(
        '${_keyTimestampPrefix}actividades_$idEmpleado',
        DateTime.now().toIso8601String(),
      );
      print('Cache: ${actividades.length} actividades guardadas para empleado $idEmpleado');
      return true;
    } catch (e) {
      print('Error al guardar cache de actividades: $e');
      return false;
    }
  }

  /// Lee las actividades cacheadas de un empleado
  Future<List<ActividadEmpleadoDto>?> getActividades(String idEmpleado) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = '$_keyActividadesPrefix$idEmpleado';
      final jsonString = prefs.getString(key);

      if (jsonString == null || jsonString.isEmpty) return null;

      final List<dynamic> jsonList = jsonDecode(jsonString);
      final actividades = jsonList
          .map((json) =>
              ActividadEmpleadoDto.fromJson(json as Map<String, dynamic>))
          .toList();

      print('Cache: ${actividades.length} actividades cargadas para empleado $idEmpleado');
      return actividades;
    } catch (e) {
      print('Error al leer cache de actividades: $e');
      return null;
    }
  }

  /// Verifica si hay actividades en cache para un empleado
  Future<bool> hasActividades(String idEmpleado) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.containsKey('$_keyActividadesPrefix$idEmpleado');
    } catch (e) {
      return false;
    }
  }

  // --- UTILIDADES ---

  /// Obtiene el timestamp de la ultima actualizacion de un cache
  Future<DateTime?> getLastUpdate(String cacheKey) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final timestamp = prefs.getString('$_keyTimestampPrefix$cacheKey');
      if (timestamp == null) return null;
      return DateTime.parse(timestamp);
    } catch (e) {
      return null;
    }
  }

  /// Limpia todo el cache
  Future<void> clearAll() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final keys = prefs.getKeys().where(
            (key) =>
                key.startsWith('cache_'),
          );
      for (var key in keys) {
        await prefs.remove(key);
      }
      print('Cache limpiado completamente');
    } catch (e) {
      print('Error al limpiar cache: $e');
    }
  }
}
