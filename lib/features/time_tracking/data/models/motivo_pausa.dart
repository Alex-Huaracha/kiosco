import 'dart:convert';

/// Modelo para un motivo de pausa del catálogo del backend.
///
/// Representa un ítem de la respuesta de GET /api/v1/catalogomotivopausas.
///
/// El motivo con [id] = 8 corresponde a "Otro" y requiere que el usuario
/// ingrese una descripción libre ([cmotivoOtro] al registrar la pausa).
class MotivoPausa {
  final int id;
  final String cnombre;
  final bool bactivo;

  const MotivoPausa({
    required this.id,
    required this.cnombre,
    required this.bactivo,
  });

  /// El id=8 representa "Otro" y habilita el campo de texto libre
  bool get esOtro => id == 8;

  factory MotivoPausa.fromJson(Map<String, dynamic> json) {
    return MotivoPausa(
      id: json['id'] as int,
      cnombre: json['cnombre'] as String,
      bactivo: json['bactivo'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'cnombre': cnombre,
        'bactivo': bactivo,
      };
}

/// Parsea la lista de motivos desde el JSON de respuesta del catálogo
List<MotivoPausa> motivoPausaListFromJson(String str) {
  final List<dynamic> jsonList = json.decode(str);
  return jsonList
      .map((j) => MotivoPausa.fromJson(j as Map<String, dynamic>))
      .toList();
}

/// Resultado tipado que retorna [PauseReasonDialog] al confirmar.
///
/// - [idmotivo]: ID del motivo seleccionado del catálogo (1-8)
/// - [cmotivoOtro]: Descripción libre. Solo presente cuando [idmotivo] == 8,
///   null para cualquier otro motivo.
class PauseReasonResult {
  final int idmotivo;
  final String? cmotivoOtro;

  const PauseReasonResult({
    required this.idmotivo,
    this.cmotivoOtro,
  });

  /// true si el motivo seleccionado es "Otro" (id=8)
  bool get esOtro => idmotivo == 8;
}
