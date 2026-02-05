import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import 'package:hgtrack/features/authentication/data/models/empleado_con_actividades.dart';

/// Servicio de cache local usando SharedPreferences.
/// Implementa estrategia cache-first: mostrar datos locales primero,
/// luego actualizar desde la API en background.
/// 
/// Usa una sola clave para almacenar empleados + actividades juntos.
class CacheService {
  static const String _keyAllData = 'cache_empleados_actividades';
  static const String _keyTimestamp = 'cache_timestamp';

  /// Guarda la lista completa de empleados con sus actividades
  Future<bool> saveAllData(List<EmpleadoConActividades> data) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonList = data.map((e) => e.toJson()).toList();
      final jsonString = jsonEncode(jsonList);
      await prefs.setString(_keyAllData, jsonString);
      await prefs.setString(_keyTimestamp, DateTime.now().toIso8601String());
      
      final totalActividades = data.fold<int>(
        0,
        (sum, e) => sum + e.actividades.length,
      );
      print('Cache: ${data.length} empleados y $totalActividades actividades guardados');
      return true;
    } catch (e) {
      print('Error al guardar cache: $e');
      return false;
    }
  }

  /// Lee todos los datos desde cache
  Future<List<EmpleadoConActividades>?> getAllData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString(_keyAllData);

      if (jsonString == null || jsonString.isEmpty) return null;

      final List<dynamic> jsonList = jsonDecode(jsonString);
      final data = jsonList
          .map((json) =>
              EmpleadoConActividades.fromJson(json as Map<String, dynamic>))
          .toList();

      final totalActividades = data.fold<int>(
        0,
        (sum, e) => sum + e.actividades.length,
      );
      print('Cache: ${data.length} empleados y $totalActividades actividades cargados');
      return data;
    } catch (e) {
      print('Error al leer cache: $e');
      return null;
    }
  }

  /// Verifica si hay datos en cache
  Future<bool> hasData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.containsKey(_keyAllData);
    } catch (e) {
      return false;
    }
  }

  /// Obtiene el timestamp de la ultima actualizacion
  Future<DateTime?> getLastUpdate() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final timestamp = prefs.getString(_keyTimestamp);
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
      await prefs.remove(_keyAllData);
      await prefs.remove(_keyTimestamp);
      print('Cache limpiado completamente');
    } catch (e) {
      print('Error al limpiar cache: $e');
    }
  }
}
