import 'dart:convert';

import 'package:hgtrack/features/time_tracking/data/models/detalle_orden_trabajo.dart';
import 'package:hgtrack/features/time_tracking/data/models/orden_trabajo.dart';

/// Parsea lista de actividades desde JSON
List<ActividadEmpleadoDto> actividadEmpleadoDtoListFromJson(String str) {
  final List<dynamic> jsonList = json.decode(str);
  return jsonList.map((json) => ActividadEmpleadoDto.fromJson(json)).toList();
}

/// Modelo del empleado principal (responsable de la tarea).
/// Solo presente cuando tipo == "ST" (Sub-Tarea).
class EmpleadoPrincipalDto {
  String? idempleadoext;
  String? cnombreemp;
  String? ccargoemp;

  EmpleadoPrincipalDto({
    this.idempleadoext,
    this.cnombreemp,
    this.ccargoemp,
  });

  factory EmpleadoPrincipalDto.fromJson(Map<String, dynamic> json) {
    return EmpleadoPrincipalDto(
      idempleadoext: json["idempleadoext"],
      cnombreemp: json["cnombreemp"],
      ccargoemp: json["ccargoemp"],
    );
  }

  Map<String, dynamic> toJson() => {
        "idempleadoext": idempleadoext,
        "cnombreemp": cnombreemp,
        "ccargoemp": ccargoemp,
      };

  /// Verifica si el empleado principal está sin asignar
  bool get sinAsignar => cnombreemp == null || cnombreemp == "Sin asignar";
}

/// Modelo principal que representa una actividad del empleado.
/// 
/// Estructura JSON actualizada con soporte para TP (Tarea Principal) y ST (Sub-Tarea):
/// {
///   "tipo": "TP" | "ST",
///   "codigo": "TP-1234" | "TP-1234 ST-5",
///   "idDetalle": 1234,
///   "idAsignacion": null | 5,
///   "detalle": {...},
///   "ordentrabajo": {...},
///   "empleadoPrincipal": null | {...},
///   "subActividad": null | "Descripcion de sub-actividad",
///   "tiempoEstimado": null | 30
/// }
/// 
/// Usado en la respuesta del endpoint unificado /empleadosactividades
class ActividadEmpleadoDto {
  /// Tipo de actividad: "TP" (Tarea Principal) o "ST" (Sub-Tarea)
  /// Default: "TP" para compatibilidad con datos antiguos
  String? tipo;

  /// Codigo visual para mostrar en headline: "TP-1234" o "TP-1234 ST-5"
  String? codigo;

  /// ID del detalle de orden de trabajo (igual que detalle.id)
  int? idDetalle;

  /// ID de la asignacion (solo para ST, null para TP)
  /// Se usa para el endpoint /adddetalleasignacion al finalizar
  int? idAsignacion;

  /// Datos del detalle de la actividad
  HgDetalleOrdenTrabajoDto? detalle;

  /// Datos de la orden de trabajo
  HgOrdenTrabajoDto? ordentrabajo;

  /// Empleado principal/responsable (solo para ST)
  /// Contiene info del tecnico responsable de la tarea principal
  EmpleadoPrincipalDto? empleadoPrincipal;

  /// Descripcion de la sub-actividad especifica (solo para ST)
  String? subActividad;

  /// Tiempo estimado en minutos (solo para ST)
  int? tiempoEstimado;

  /// Tiempo de inicio del tareo (timestamp en milisegundos)
  int? dtiempoinicio;

  /// Tiempo de fin del tareo (timestamp en milisegundos)
  int? dtiempofin;

  /// Si la actividad esta cerrada
  bool? bcerrada;

  /// Observaciones del tecnico
  String? cobservaciones;

  ActividadEmpleadoDto({
    this.tipo,
    this.codigo,
    this.idDetalle,
    this.idAsignacion,
    this.detalle,
    this.ordentrabajo,
    this.empleadoPrincipal,
    this.subActividad,
    this.tiempoEstimado,
    this.dtiempoinicio,
    this.dtiempofin,
    this.bcerrada,
    this.cobservaciones,
  });

  factory ActividadEmpleadoDto.fromJson(Map<String, dynamic> json) {
    return ActividadEmpleadoDto(
      tipo: json["tipo"] ?? "TP", // Default a TP para compatibilidad
      codigo: json["codigo"],
      idDetalle: json["idDetalle"],
      idAsignacion: json["idAsignacion"],
      detalle: json["detalle"] != null
          ? HgDetalleOrdenTrabajoDto.fromJson(json["detalle"])
          : null,
      ordentrabajo: json["ordentrabajo"] != null
          ? HgOrdenTrabajoDto.fromJson(json["ordentrabajo"])
          : null,
      empleadoPrincipal: json["empleadoPrincipal"] != null
          ? EmpleadoPrincipalDto.fromJson(json["empleadoPrincipal"])
          : null,
      subActividad: json["subActividad"],
      tiempoEstimado: json["tiempoEstimado"],
      dtiempoinicio: json["dtiempoinicio"],
      dtiempofin: json["dtiempofin"],
      bcerrada: json["bcerrada"],
      cobservaciones: json["cobservaciones"],
    );
  }

  Map<String, dynamic> toJson() => {
        "tipo": tipo,
        "codigo": codigo,
        "idDetalle": idDetalle,
        "idAsignacion": idAsignacion,
        "detalle": detalle?.toJson(),
        "ordentrabajo": ordentrabajo?.toJson(),
        "empleadoPrincipal": empleadoPrincipal?.toJson(),
        "subActividad": subActividad,
        "tiempoEstimado": tiempoEstimado,
        "dtiempoinicio": dtiempoinicio,
        "dtiempofin": dtiempofin,
        "bcerrada": bcerrada,
        "cobservaciones": cobservaciones,
      };

  /// Verifica si es una Sub-Tarea (asistencia)
  bool get esSubTarea => tipo == "ST";

  /// Verifica si es una Tarea Principal
  bool get esTareaPrincipal => tipo == "TP" || tipo == null;

  /// Obtiene el codigo formateado para mostrar
  /// Si no hay codigo, construye uno basado en el detalle
  String get codigoDisplay {
    if (codigo != null && codigo!.isNotEmpty) {
      return codigo!;
    }
    // Fallback para datos antiguos
    return "TP-${detalle?.id ?? 'N/A'}";
  }

  /// Obtiene el ID correcto para finalizar la actividad
  /// Para ST usa idAsignacion, para TP usa idDetalle
  int? get idParaFinalizar => esSubTarea ? idAsignacion : idDetalle;
}
