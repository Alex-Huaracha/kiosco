import 'dart:convert';

import 'package:hgtrack/features/time_tracking/data/models/detalle_orden_trabajo.dart';
import 'package:hgtrack/features/time_tracking/data/models/orden_trabajo.dart';

/// Parsea lista de actividades desde JSON
List<ActividadEmpleadoDto> actividadEmpleadoDtoListFromJson(String str) {
  final List<dynamic> jsonList = json.decode(str);
  return jsonList.map((json) => ActividadEmpleadoDto.fromJson(json)).toList();
}

/// Modelo principal que representa una actividad del empleado.
/// 
/// Estructura JSON: { "detalle": {...}, "ordentrabajo": {...} }
/// 
/// Usado en la respuesta del endpoint unificado /empleadosactividades
class ActividadEmpleadoDto {
  HgDetalleOrdenTrabajoDto? detalle;
  HgOrdenTrabajoDto? ordentrabajo;

  ActividadEmpleadoDto({
    this.detalle,
    this.ordentrabajo,
  });

  factory ActividadEmpleadoDto.fromJson(Map<String, dynamic> json) {
    return ActividadEmpleadoDto(
      detalle: json["detalle"] != null
          ? HgDetalleOrdenTrabajoDto.fromJson(json["detalle"])
          : null,
      ordentrabajo: json["ordentrabajo"] != null
          ? HgOrdenTrabajoDto.fromJson(json["ordentrabajo"])
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
        "detalle": detalle?.toJson(),
        "ordentrabajo": ordentrabajo?.toJson(),
      };
}
