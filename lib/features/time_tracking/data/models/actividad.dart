import 'dart:convert';

import 'package:hgtrack/features/time_tracking/data/models/detalle_orden_trabajo.dart';
import 'package:hgtrack/features/time_tracking/data/models/orden_trabajo.dart';

/// Parsea un timestamp que puede llegar como String ISO8601 o como int (epoch ms).
/// El backend puede enviar cualquiera de los dos formatos dependiendo de la versión.
DateTime? _parseDateTime(dynamic value) {
  if (value == null) return null;
  if (value is int) return DateTime.fromMillisecondsSinceEpoch(value);
  if (value is String) return DateTime.parse(value);
  return null;
}

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
      idempleadoext: json["idempleadoext"] ?? json["id"],
      cnombreemp: json["cnombreemp"] ?? json["nombre"],
      ccargoemp: json["ccargoemp"] ?? json["cargo"],
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

/// Modelo de una pausa registrada en backend (v2.0 — API de Pausas con Motivos).
///
/// BREAKING CHANGE v2: el campo [cmotivo] fue reemplazado por [idmotivo] + [cmotivoOtro].
///
/// Campos:
/// - [id]            ID único de la pausa en BD
/// - [idmotivo]      ID del motivo del catálogo (1-8). Ver GET /catalogomotivopausas
/// - [cmotivoOtro]   Descripción libre. Solo presente cuando [idmotivo] == 8 ("Otro")
/// - [dtiempoinicio] Timestamp ISO8601 de inicio de la pausa
/// - [dtiempofin]    Timestamp ISO8601 de fin/reanudación. null = pausa activa
class PausaDto {
  final int id;
  final int idmotivo;
  final String? cmotivoOtro;
  final DateTime dtiempoinicio;
  final DateTime? dtiempofin;

  const PausaDto({
    required this.id,
    required this.idmotivo,
    this.cmotivoOtro,
    required this.dtiempoinicio,
    this.dtiempofin,
  });

  /// Indica si esta pausa sigue activa (sin reanudación)
  bool get estaActiva => dtiempofin == null;

  /// true si el motivo es "Otro" (id=8)
  bool get esMotivOtro => idmotivo == 8;

  factory PausaDto.fromJson(Map<String, dynamic> json) {
    return PausaDto(
      id: json["id"] as int,
      idmotivo: json["idmotivo"] as int? ?? 1,
      cmotivoOtro: json["cmotivoOtro"] as String?,
      dtiempoinicio: _parseDateTime(json["dtiempoinicio"])!,
      dtiempofin: _parseDateTime(json["dtiempofin"]),
    );
  }

  Map<String, dynamic> toJson() => {
        "id": id,
        "idmotivo": idmotivo,
        "cmotivoOtro": cmotivoOtro,
        "dtiempoinicio": dtiempoinicio.toIso8601String(),
        "dtiempofin": dtiempofin?.toIso8601String(),
      };
}

/// Estados de actividad calculados por backend (v2.2+).
/// Mapea directamente el campo [cestadomovil] de la respuesta.
enum EstadoMovil {
  noIniciada,
  enProceso,
  pausada,
  terminada,
}

/// Parsea el string de cestadomovil al enum [EstadoMovil].
/// Devuelve [EstadoMovil.noIniciada] si el valor es desconocido.
EstadoMovil _parsearEstadoMovil(String? valor) {
  switch (valor) {
    case 'EN_PROCESO':
      return EstadoMovil.enProceso;
    case 'PAUSADA':
      return EstadoMovil.pausada;
    case 'TERMINADA':
      return EstadoMovil.terminada;
    case 'NO_INICIADA':
    default:
      return EstadoMovil.noIniciada;
  }
}

/// Modelo principal que representa una actividad del empleado.
///
/// Versión 2.3: agrega [cestadomovil] y [pausas].
/// [dtiempoinicio] y [dtiempofin] ahora son [DateTime?] (antes eran int?).
///
/// Usado en la respuesta del endpoint unificado /empleadosactividades
class ActividadEmpleadoDto {
  /// Tipo de actividad: "TP" (Tarea Principal) o "ST" (Sub-Tarea)
  String? tipo;

  /// Codigo visual para mostrar en headline: "TP-1234" o "TP-1234 ST-5"
  String? codigo;

  /// ID del detalle de orden de trabajo (igual que detalle.id)
  int? idDetalle;

  /// ID de la asignacion (solo para ST, null para TP)
  int? idAsignacion;

  /// Datos del detalle de la actividad
  HgDetalleOrdenTrabajoDto? detalle;

  /// Datos de la orden de trabajo
  HgOrdenTrabajoDto? ordentrabajo;

  /// Empleado principal/responsable (solo para ST)
  EmpleadoPrincipalDto? empleadoPrincipal;

  /// Descripcion de la sub-actividad especifica (solo para ST)
  String? subActividad;

  /// Tiempo estimado en minutos (solo para ST)
  int? tiempoEstimado;

  /// Timestamp de inicio (ISO8601, v2.3+)
  DateTime? dtiempoinicio;

  /// Timestamp de fin (ISO8601, v2.3+)
  DateTime? dtiempofin;

  /// Si la actividad esta cerrada
  bool? bcerrada;

  /// Observaciones del tecnico
  String? cobservaciones;

  /// Estado calculado por backend (v2.2+):
  /// NO_INICIADA | EN_PROCESO | PAUSADA | TERMINADA
  EstadoMovil cestadomovil;

  /// Lista de pausas registradas, ordenadas ASC por dtiempoinicio (v2.3+).
  /// Array vacío si no hay pausas. Nunca null.
  List<PausaDto> pausas;

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
    this.cestadomovil = EstadoMovil.noIniciada,
    this.pausas = const [],
  });

  factory ActividadEmpleadoDto.fromJson(Map<String, dynamic> json) {
    return ActividadEmpleadoDto(
      tipo: json["tipo"] ?? "TP",
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
      dtiempoinicio: _parseDateTime(json["dtiempoinicio"]),
      dtiempofin: _parseDateTime(json["dtiempofin"]),
      bcerrada: json["bcerrada"],
      cobservaciones: json["cobservaciones"],
      cestadomovil: _parsearEstadoMovil(json["cestadomovil"] as String?),
      pausas: (json["pausas"] as List<dynamic>?)
              ?.map((p) => PausaDto.fromJson(p as Map<String, dynamic>))
              .toList() ??
          [],
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
        "dtiempoinicio": dtiempoinicio?.toIso8601String(),
        "dtiempofin": dtiempofin?.toIso8601String(),
        "bcerrada": bcerrada,
        "cobservaciones": cobservaciones,
        "cestadomovil": cestadomovil.name,
        "pausas": pausas.map((p) => p.toJson()).toList(),
      };

  /// Verifica si es una Sub-Tarea (asistencia)
  bool get esSubTarea => tipo == "ST";

  /// Verifica si es una Tarea Principal
  bool get esTareaPrincipal => tipo == "TP" || tipo == null;

  /// Obtiene el codigo formateado para mostrar
  String get codigoDisplay {
    if (codigo != null && codigo!.isNotEmpty) {
      if (esSubTarea && codigo!.contains(' ')) {
        return codigo!.replaceFirst(' ', ' • ');
      }
      return codigo!;
    }
    return "TP-${detalle?.id ?? 'N/A'}";
  }

  /// Obtiene el ID correcto para finalizar la actividad
  int? get idParaFinalizar => esSubTarea ? idAsignacion : idDetalle;

  /// Pausa activa (dtiempofin == null), si existe
  PausaDto? get pausaActiva {
    try {
      return pausas.firstWhere((p) => p.estaActiva);
    } catch (_) {
      return null;
    }
  }
}
