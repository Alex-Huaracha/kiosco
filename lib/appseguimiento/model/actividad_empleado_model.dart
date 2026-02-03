import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:hgtrack/appseguimiento/model/hgdetalleordentrabajodto_model.dart';
import 'package:hgtrack/appseguimiento/model/hgordentrabajodto_model.dart';
import 'package:hgtrack/utils/app_colors.dart';

/// Parsea lista de actividades desde JSON
List<ActividadEmpleadoDto> actividadEmpleadoDtoListFromJson(String str) {
  final List<dynamic> jsonList = json.decode(str);
  return jsonList.map((json) => ActividadEmpleadoDto.fromJson(json)).toList();
}

/// Modelo principal que representa una actividad del endpoint
/// Estructura: { "detalle": {...}, "ordentrabajo": {...} }
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

/// Helper class para agrupar actividades por Orden de Trabajo
class OrdenTrabajoConActividades {
  final HgOrdenTrabajoDto ordentrabajo;
  final List<HgDetalleOrdenTrabajoDto> actividades;

  OrdenTrabajoConActividades({
    required this.ordentrabajo,
    required this.actividades,
  });

  /// Cuenta total de actividades
  int get countActividades => actividades.length;

  /// Cuenta actividades pendientes (no cerradas, no backlog)
  int get countPendientes => actividades
      .where((a) => a.bcerrada == false && a.bbacklog != true)
      .length;

  /// Cuenta actividades cerradas
  int get countCerradas => actividades.where((a) => a.bcerrada == true).length;

  /// Cuenta actividades en backlog
  int get countBacklog => actividades.where((a) => a.bbacklog == true).length;

  /// Cuenta actividades en proceso (tienen tiempo inicio pero no cerradas)
  int get countEnProceso => actividades
      .where((a) =>
          a.bcerrada == false && a.bbacklog != true && a.dtiempoinicio != null)
      .length;

  /// Determina el estado predominante de la OT
  /// Prioridad: En Proceso > Pendiente > Backlog > Cerrada
  String get estadoBadge {
    // Si la OT está cerrada
    if (ordentrabajo.bcerrada == true) {
      return 'Cerrada';
    }

    // Si alguna actividad es backlog
    if (countBacklog > 0) {
      return 'Backlog';
    }

    // Si alguna actividad está en proceso (tiene tiempo inicio)
    if (countEnProceso > 0) {
      return 'En Proceso';
    }

    // Por defecto, pendiente
    return 'Pendiente';
  }

  /// Retorna el color del badge según el estado
  Color get colorBadge {
    switch (estadoBadge) {
      case 'Cerrada':
        return AppColors.success; // Verde
      case 'En Proceso':
        return AppColors.primary; // Azul
      case 'Backlog':
        return AppColors.warning; // Naranja
      case 'Pendiente':
      default:
        return AppColors.warning; // Naranja
    }
  }

  /// Determina si esta OT debe aparecer en el tab "Activas"
  /// Activas = Pendientes + En Proceso
  bool get esActiva {
    return estadoBadge == 'Pendiente' || estadoBadge == 'En Proceso';
  }

  /// Determina si esta OT debe aparecer en el tab "Terminadas"
  /// Terminadas = Cerradas + Backlog
  bool get esTerminada {
    return estadoBadge == 'Cerrada' || estadoBadge == 'Backlog';
  }

  /// Porcentaje de actividades completadas (0-100)
  int get porcentajeCompletado {
    if (countActividades == 0) return 0;
    return ((countCerradas / countActividades) * 100).round();
  }

  /// Texto descriptivo: "4 de 8 actividades terminadas"
  String get textoProgreso {
    final plural = countActividades != 1 ? 'es' : '';
    final pluralTerminadas = countCerradas != 1 ? 's' : '';
    return '$countCerradas de $countActividades actividad$plural terminada$pluralTerminadas';
  }
}
