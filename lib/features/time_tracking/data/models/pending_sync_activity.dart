import 'dart:convert';

/// Modelo para actividades finalizadas pendientes de sincronización con el backend
/// Se guarda en SharedPreferences cuando falla el envío al servidor
/// 
/// Soporta tanto Tareas Principales (TP) como Sub-Tareas (ST):
/// - TP: usa idActividad (idDetalle) con endpoint /updatedetalleordentrabajo
/// - ST: usa idAsignacion con endpoint /adddetalleasignacion
class PendingSyncActivity {
  /// Tipo de actividad: "TP" (Tarea Principal) o "ST" (Sub-Tarea)
  /// Default: "TP" para compatibilidad con datos antiguos
  final String tipo;
  
  /// ID del detalle de orden de trabajo (usado para TP)
  final int idActividad;
  
  /// ID de la asignación (usado para ST, null para TP)
  final int? idAsignacion;
  
  final int idEmpleado;
  final String nombreActividad;
  final String nombreEmpleado;
  final String cargoEmpleado;
  final DateTime fechaInicio;
  final DateTime fechaFin;
  final int minutosTotal;
  final String? observaciones;
  final DateTime createdAt; // Timestamp cuando se guardó en cola
  final int retryCount; // Contador de intentos fallidos

  PendingSyncActivity({
    this.tipo = "TP", // Default para compatibilidad
    required this.idActividad,
    this.idAsignacion,
    required this.idEmpleado,
    required this.nombreActividad,
    required this.nombreEmpleado,
    required this.cargoEmpleado,
    required this.fechaInicio,
    required this.fechaFin,
    required this.minutosTotal,
    this.observaciones,
    required this.createdAt,
    this.retryCount = 0,
  });

  /// Verifica si es una Sub-Tarea
  bool get esSubTarea => tipo == "ST";

  /// Verifica si es una Tarea Principal
  bool get esTareaPrincipal => tipo == "TP" || tipo.isEmpty;

  /// Serialización a JSON para SharedPreferences
  Map<String, dynamic> toJson() {
    return {
      'tipo': tipo,
      'idActividad': idActividad,
      'idAsignacion': idAsignacion,
      'idEmpleado': idEmpleado,
      'nombreActividad': nombreActividad,
      'nombreEmpleado': nombreEmpleado,
      'cargoEmpleado': cargoEmpleado,
      'fechaInicio': fechaInicio.toIso8601String(),
      'fechaFin': fechaFin.toIso8601String(),
      'minutosTotal': minutosTotal,
      'observaciones': observaciones,
      'createdAt': createdAt.toIso8601String(),
      'retryCount': retryCount,
    };
  }

  /// Deserialización desde JSON
  factory PendingSyncActivity.fromJson(Map<String, dynamic> json) {
    return PendingSyncActivity(
      tipo: json['tipo'] as String? ?? "TP", // Default para datos antiguos
      idActividad: json['idActividad'] as int,
      idAsignacion: json['idAsignacion'] as int?,
      idEmpleado: json['idEmpleado'] as int,
      nombreActividad: json['nombreActividad'] as String,
      nombreEmpleado: json['nombreEmpleado'] as String,
      cargoEmpleado: json['cargoEmpleado'] as String,
      fechaInicio: DateTime.parse(json['fechaInicio'] as String),
      fechaFin: DateTime.parse(json['fechaFin'] as String),
      minutosTotal: json['minutosTotal'] as int,
      observaciones: json['observaciones'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
      retryCount: json['retryCount'] as int? ?? 0,
    );
  }

  String toJsonString() => jsonEncode(toJson());

  factory PendingSyncActivity.fromJsonString(String jsonString) {
    return PendingSyncActivity.fromJson(jsonDecode(jsonString));
  }

  /// Crea una copia con el contador de reintentos incrementado
  PendingSyncActivity incrementRetry() {
    return PendingSyncActivity(
      tipo: tipo,
      idActividad: idActividad,
      idAsignacion: idAsignacion,
      idEmpleado: idEmpleado,
      nombreActividad: nombreActividad,
      nombreEmpleado: nombreEmpleado,
      cargoEmpleado: cargoEmpleado,
      fechaInicio: fechaInicio,
      fechaFin: fechaFin,
      minutosTotal: minutosTotal,
      observaciones: observaciones,
      createdAt: createdAt,
      retryCount: retryCount + 1,
    );
  }
}

/// Resultado de un proceso de sincronización
class SyncResult {
  final int total;
  final int exitosos;
  final int fallidos;
  final List<String> errores;

  SyncResult({
    required this.total,
    required this.exitosos,
    required this.fallidos,
    required this.errores,
  });

  bool get todosExitosos => exitosos == total;
  bool get todosFallaron => exitosos == 0;
  bool get parcial => exitosos > 0 && fallidos > 0;
}
