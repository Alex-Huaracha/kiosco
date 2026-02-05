import 'dart:convert';

import 'package:hgtrack/features/authentication/data/models/empleado.dart';
import 'package:hgtrack/features/time_tracking/data/models/actividad.dart';

/// Parser para la respuesta del endpoint /empleadosactividades
List<EmpleadoConActividades> empleadoConActividadesListFromJson(String str) {
  final List<dynamic> jsonList = json.decode(str);
  return jsonList
      .map((json) => EmpleadoConActividades.fromJson(json))
      .toList();
}

/// Modelo que agrupa un empleado con todas sus actividades.
/// Respuesta del endpoint unificado /empleadosactividades
class EmpleadoConActividades {
  final HgEmpleadoMantenimientoDto empleado;
  final List<ActividadEmpleadoDto> actividades;

  EmpleadoConActividades({
    required this.empleado,
    required this.actividades,
  });

  factory EmpleadoConActividades.fromJson(Map<String, dynamic> json) {
    return EmpleadoConActividades(
      empleado: HgEmpleadoMantenimientoDto.fromJson(json['empleado']),
      actividades: json['actividades'] != null
          ? (json['actividades'] as List)
              .map((a) => ActividadEmpleadoDto.fromJson(a))
              .toList()
          : [],
    );
  }

  Map<String, dynamic> toJson() => {
        'empleado': empleado.toJson(),
        'actividades': actividades.map((a) => a.toJson()).toList(),
      };

  String toJsonString() => jsonEncode(toJson());

  factory EmpleadoConActividades.fromJsonString(String jsonString) {
    return EmpleadoConActividades.fromJson(jsonDecode(jsonString));
  }
}
