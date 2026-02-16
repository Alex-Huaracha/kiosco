/// Response del endpoint unificado /gestionarestadoactividad
///
/// Este modelo representa la respuesta del backend cuando se gestiona
/// el estado de una Tarea Principal (TP - DetalleOrdenTrabajo).
///
/// Acciones soportadas: INICIAR, PAUSAR, REANUDAR, FINALIZAR
class GestionEstadoResponse {
  /// Indica si la operación fue exitosa
  final bool exito;

  /// Mensaje descriptivo del resultado de la operación
  final String mensaje;

  /// ID del detalle de orden de trabajo afectado
  final int iddetalleordentrabajo;

  /// Acción ejecutada (INICIAR, PAUSAR, REANUDAR, FINALIZAR)
  final String accion;

  /// Estado actual después de ejecutar la acción
  /// Valores posibles: NO_INICIADA, EN_PROCESO, PAUSADA, TERMINADA
  final String estadoActual;

  /// ID de la pausa creada (solo para acción PAUSAR y REANUDAR)
  ///
  /// IMPORTANTE: Este campo es para logs y debugging. En el flujo normal
  /// de REANUDAR, NO es necesario enviar este ID - el backend busca
  /// automáticamente la pausa activa más reciente.
  final int? idpausa;

  /// Timestamp de cuando se ejecutó la acción
  final DateTime timestampAccion;

  GestionEstadoResponse({
    required this.exito,
    required this.mensaje,
    required this.iddetalleordentrabajo,
    required this.accion,
    required this.estadoActual,
    this.idpausa,
    required this.timestampAccion,
  });

  /// Crea una instancia desde JSON (response del backend)
  factory GestionEstadoResponse.fromJson(Map<String, dynamic> json) {
    return GestionEstadoResponse(
      exito: json['exito'] as bool,
      mensaje: json['mensaje'] as String,
      iddetalleordentrabajo: json['iddetalleordentrabajo'] as int,
      accion: json['accion'] as String,
      estadoActual: json['estadoActual'] as String,
      idpausa: json['idpausa'] as int?,
      timestampAccion: _parseTimestamp(json['timestampAccion']),
    );
  }

  /// Parsea el timestamp del backend.
  /// Soporta múltiples formatos:
  /// - Unix timestamp en milisegundos (int): 1771257698951
  /// - String ISO8601: "2026-02-16T10:00:00.000Z"
  /// - String custom: "2026-02-16 10:00:00.000"
  static DateTime _parseTimestamp(dynamic value) {
    if (value == null) {
      throw FormatException('timestampAccion no puede ser null');
    }

    if (value is int) {
      // Unix timestamp en milisegundos
      return DateTime.fromMillisecondsSinceEpoch(value);
    } else if (value is String) {
      // String ISO8601 o formato custom
      try {
        return DateTime.parse(value);
      } catch (e) {
        throw FormatException(
            'No se pudo parsear timestampAccion: "$value". Error: $e');
      }
    } else {
      throw FormatException(
          'timestampAccion debe ser String o int, recibido: ${value.runtimeType}');
    }
  }

  /// Convierte la instancia a JSON
  Map<String, dynamic> toJson() {
    return {
      'exito': exito,
      'mensaje': mensaje,
      'iddetalleordentrabajo': iddetalleordentrabajo,
      'accion': accion,
      'estadoActual': estadoActual,
      'idpausa': idpausa,
      'timestampAccion': timestampAccion.toIso8601String(),
    };
  }

  @override
  String toString() {
    return 'GestionEstadoResponse{exito: $exito, mensaje: $mensaje, accion: $accion, estadoActual: $estadoActual, idpausa: $idpausa}';
  }
}
