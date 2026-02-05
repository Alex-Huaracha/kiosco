import 'dart:convert';

/// Modelo para actividades finalizadas pendientes de sincronización con el backend
/// Se guarda en SharedPreferences cuando falla el envío al servidor
class PendingSyncActivity {
  final int idActividad;
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
    required this.idActividad,
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

  /// Serialización a JSON para SharedPreferences
  Map<String, dynamic> toJson() {
    return {
      'idActividad': idActividad,
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
      idActividad: json['idActividad'] as int,
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
      idActividad: idActividad,
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
