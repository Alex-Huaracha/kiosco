/// Response del endpoint unificado de gestión de estado.
///
/// Este modelo representa la respuesta del backend cuando se gestiona
/// el estado de una actividad, ya sea:
/// - Tarea Principal (TP): /gestionarestadoactividad
/// - Sub-Tarea (ST): /gestionarestadosubtarea
///
/// Acciones soportadas: INICIAR, PAUSAR, REANUDAR, FINALIZAR
class GestionEstadoResponse {
  /// Indica si la operación fue exitosa
  final bool exito;

  /// Mensaje descriptivo del resultado de la operación
  final String mensaje;

  /// ID del detalle de orden de trabajo afectado (solo para TP)
  final int? iddetalleordentrabajo;

  /// ID del detalle de asignación afectado (solo para ST)
  final int? iddetalleasignacion;

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
    this.iddetalleordentrabajo,
    this.iddetalleasignacion,
    required this.accion,
    required this.estadoActual,
    this.idpausa,
    required this.timestampAccion,
  });

  /// Retorna el ID afectado (TP o ST según corresponda)
  int get idAfectado => iddetalleasignacion ?? iddetalleordentrabajo!;

  /// Indica si es respuesta de una Sub-Tarea
  bool get esSubTarea => iddetalleasignacion != null;

  /// Crea una instancia desde JSON (response del backend)
  /// Soporta tanto TP (iddetalleordentrabajo) como ST (iddetalleasignacion)
  factory GestionEstadoResponse.fromJson(Map<String, dynamic> json) {
    return GestionEstadoResponse(
      exito: json['exito'] as bool,
      mensaje: json['mensaje'] as String,
      iddetalleordentrabajo: json['iddetalleordentrabajo'] as int?,
      iddetalleasignacion: json['iddetalleasignacion'] as int?,
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
    final Map<String, dynamic> data = {
      'exito': exito,
      'mensaje': mensaje,
      'accion': accion,
      'estadoActual': estadoActual,
      'idpausa': idpausa,
      'timestampAccion': timestampAccion.toIso8601String(),
    };
    
    // Agregar el ID correspondiente según el tipo
    if (iddetalleordentrabajo != null) {
      data['iddetalleordentrabajo'] = iddetalleordentrabajo;
    }
    if (iddetalleasignacion != null) {
      data['iddetalleasignacion'] = iddetalleasignacion;
    }
    
    return data;
  }

  @override
  String toString() {
    final idLabel = esSubTarea 
        ? 'iddetalleasignacion: $iddetalleasignacion'
        : 'iddetalleordentrabajo: $iddetalleordentrabajo';
    return 'GestionEstadoResponse{exito: $exito, mensaje: $mensaje, $idLabel, accion: $accion, estadoActual: $estadoActual, idpausa: $idpausa}';
  }
}
