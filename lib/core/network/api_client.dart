import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

import 'package:hgtrack/features/authentication/data/models/empleado_con_actividades.dart';
import 'package:hgtrack/features/time_tracking/data/models/detalle_body.dart';
import 'package:hgtrack/features/time_tracking/data/models/detalle_orden_trabajo.dart';
import 'package:hgtrack/features/time_tracking/data/models/gestion_estado_response.dart';

/// Cliente HTTP para comunicacion con el backend HG API.
/// 
/// Endpoints disponibles:
/// - /empleadosactividades - Carga unificada de empleados con actividades (offline-first)
/// - /updatedetalleordentrabajo - Finalizar actividad
/// - /updatevariosdetalleordentrabajo - Actualizar multiples detalles
class TrackingApi {
  /// Obtiene la URL base del backend segun el modo de ejecucion
  /// - Release mode: URL de produccion
  /// - Debug mode: URL desde .env (ngrok o localhost)
  static String get _hgapiEndpoint {
    if (kReleaseMode) {
      return "https://extranetservicio.hagemsa.org/api/services";
    }
    // En modo debug, usar variable de entorno o fallback a localhost
    return dotenv.env['API_BASE_URL'] ?? 'http://localhost:8080/hgapi';
  }

  /// Actualiza multiples detalles de orden de trabajo
  Future<List<HgDetalleOrdenTrabajoDto>?> getAllTrackingDetalleOrdenTrabajo(
      List<HgDetalleOrdenTrabajoBodyDto> dotbody) async {
    var clientrf = http.Client();
    var url_rf = '$_hgapiEndpoint/updatevariosdetalleordentrabajo';
    var uri_rf = Uri.parse(url_rf);

    String jsonBody = hgDetalleOrdenTrabajoBodyDtoToJson(dotbody);

    try {
      var response = await clientrf.post(
        uri_rf,
        headers: {
          "Content-Type": "application/json",
        },
        body: jsonBody,
      );

      if (response.statusCode == 200) {
        if (response.body == "[]") {
          return null;
        } else {
          return hgDetalleOrdenTrabajoDtoFromJson(
              const Utf8Decoder().convert(response.bodyBytes));
        }
      } else {
        print("Error en la solicitud: Codigo ${response.statusCode}");
      }
    } catch (e) {
      print("Excepcion atrapada: $e");
    }
    return null;
  }

  /// Obtiene todos los empleados de mantenimiento con todas sus actividades
  /// en una sola llamada. Endpoint unificado para carga offline-first.
  /// 
  /// Reemplaza las llamadas separadas a:
  /// - /listarempleadosconactividades
  /// - /consultaractividadesempleado
  Future<List<EmpleadoConActividades>?> getAllEmpleadosConActividades() async {
    var client = http.Client();
    var url = '$_hgapiEndpoint/empleadosactividades';
    var uri = Uri.parse(url);

    String jsonBody = jsonEncode({});

    try {
      var response = await client.post(
        uri,
        headers: {
          "Content-Type": "application/json",
        },
        body: jsonBody,
      );

      if (response.statusCode == 200) {
        if (response.body == "[]" || response.body.isEmpty) {
          return null;
        } else {
          return empleadoConActividadesListFromJson(
              const Utf8Decoder().convert(response.bodyBytes));
        }
      } else {
        print("Error en la solicitud: Codigo ${response.statusCode}");
      }
    } catch (e) {
      print("Excepcion atrapada: $e");
    }
    return null;
  }

  /// Formatea fechas segun documentacion: yyyy-MM-dd HH:mm:ss.SSS
  String _formatFecha(DateTime fecha) {
    final year = fecha.year.toString().padLeft(4, '0');
    final month = fecha.month.toString().padLeft(2, '0');
    final day = fecha.day.toString().padLeft(2, '0');
    final hour = fecha.hour.toString().padLeft(2, '0');
    final minute = fecha.minute.toString().padLeft(2, '0');
    final second = fecha.second.toString().padLeft(2, '0');
    final millisecond = fecha.millisecond.toString().padLeft(3, '0');
    return '$year-$month-$day $hour:$minute:$second.$millisecond';
  }

  /// OBSOLETO: Reemplazado por gestionarEstadoActividadTP() con acción FINALIZAR.
  /// Mantenido temporalmente para referencia, pero NO debe usarse en código nuevo.
  @Deprecated('Usar gestionarEstadoActividadTP() con accion FINALIZAR')
  Future<HgDetalleOrdenTrabajoDto?> finalizarActividadEmpleado({
    required int idDetalleOrdenTrabajo,
    required String idEmpleadoExt,
    required String cargoEmpleado,
    required String nombreEmpleado,
    required DateTime tiempoInicio,
    required DateTime tiempoFin,
    required int minutosEmpleado,
    String? observaciones,
  }) async {
    var client = http.Client();
    var url = '$_hgapiEndpoint/updatedetalleordentrabajo';
    var uri = Uri.parse(url);

    String jsonBody = jsonEncode({
      "iddetalleordentrabajo": idDetalleOrdenTrabajo.toString(),
      "idempleadoext": idEmpleadoExt,
      "ccargoemp": cargoEmpleado,
      "cnombreemp": nombreEmpleado,
      "dtiempoinicio": _formatFecha(tiempoInicio),
      "dtiempofin": _formatFecha(tiempoFin),
      "nminutosemp": minutosEmpleado.toString(),
      "cobservaciones": observaciones ?? "",
      "bcerrada": "1",
    });

    try {
      var response = await client.post(
        uri,
        headers: {"Content-Type": "application/json"},
        body: jsonBody,
      );

      if (response.statusCode == 200) {
        print("Actividad TP finalizada exitosamente");

        // Parsear respuesta a DTO
        final jsonResponse =
            jsonDecode(const Utf8Decoder().convert(response.bodyBytes));
        return HgDetalleOrdenTrabajoDto.fromJson(jsonResponse);
      } else {
        print("Error al finalizar actividad TP: Codigo ${response.statusCode}");
        print("Mensaje: ${response.body}");
        return null;
      }
    } catch (e) {
      print("Excepcion al finalizar actividad TP: $e");
      return null;
    }
  }

  /// Finaliza una Sub-Tarea (ST) enviando tiempos al backend.
  /// Usa el endpoint /adddetalleasignacion con el idAsignacion.
  /// 
  /// [idAsignacion] - ID de la asignacion (DetalleAsignacion)
  /// [tiempoInicio] - Fecha/hora de inicio del trabajo
  /// [tiempoFin] - Fecha/hora de fin del trabajo
  /// [minutosEmpleado] - Total de minutos trabajados (calculado por Flutter)
  /// [observaciones] - Observaciones opcionales
  /// 
  /// Retorna true en caso de exito, false en caso de error
  Future<bool> finalizarAsignacion({
    required int idAsignacion,
    required DateTime tiempoInicio,
    required DateTime tiempoFin,
    required int minutosEmpleado,
    String? observaciones,
  }) async {
    var client = http.Client();
    var url = '$_hgapiEndpoint/adddetalleasignacion';
    var uri = Uri.parse(url);

    String jsonBody = jsonEncode({
      "id": idAsignacion.toString(),
      "dtiempoinicio": _formatFecha(tiempoInicio),
      "dtiempofin": _formatFecha(tiempoFin),
      "nminutosemp": minutosEmpleado.toString(),
      "cobservaciones": observaciones ?? "",
      "bcerrada": "1",
    });

    try {
      var response = await client.post(
        uri,
        headers: {"Content-Type": "application/json"},
        body: jsonBody,
      );

      if (response.statusCode == 200) {
        print("Sub-Tarea ST finalizada exitosamente (idAsignacion: $idAsignacion)");
        return true;
      } else {
        print("Error al finalizar Sub-Tarea ST: Codigo ${response.statusCode}");
        print("Mensaje: ${response.body}");
        return false;
      }
    } catch (e) {
      print("Excepcion al finalizar Sub-Tarea ST: $e");
      return false;
    }
  }

  /// Marca una actividad como backlog (no completada, para reprogramacion).
  /// 
  /// Envia solo el ID de la actividad y el flag de backlog al backend.
  /// La actividad sera reprogramada en una futura orden de trabajo.
  /// 
  /// [idDetalleOrdenTrabajo] - ID del detalle de orden de trabajo
  /// [observaciones] - Observaciones opcionales (ej: "Falta repuesto X")
  /// 
  /// Retorna el DTO actualizado en caso de exito, null en caso de error
  Future<HgDetalleOrdenTrabajoDto?> marcarActividadComoBacklog({
    required int idDetalleOrdenTrabajo,
    String? observaciones,
  }) async {
    var client = http.Client();
    var url = '$_hgapiEndpoint/updatedetalleordentrabajo';
    var uri = Uri.parse(url);

    // Request minimo: solo ID y flag de backlog
    final Map<String, dynamic> requestBody = {
      "iddetalleordentrabajo": idDetalleOrdenTrabajo.toString(),
      "bbacklog": "true",
    };

    // Agregar observaciones si existen
    if (observaciones != null && observaciones.isNotEmpty) {
      requestBody["cobservaciones"] = observaciones;
    }

    String jsonBody = jsonEncode(requestBody);

    try {
      var response = await client.post(
        uri,
        headers: {"Content-Type": "application/json"},
        body: jsonBody,
      );

      if (response.statusCode == 200) {
        print("Actividad marcada como backlog exitosamente (ID: $idDetalleOrdenTrabajo)");

        // Parsear respuesta a DTO
        final jsonResponse =
            jsonDecode(const Utf8Decoder().convert(response.bodyBytes));
        return HgDetalleOrdenTrabajoDto.fromJson(jsonResponse);
      } else {
        print("Error al marcar como backlog: Codigo ${response.statusCode}");
        print("Mensaje: ${response.body}");
        return null;
      }
    } catch (e) {
      print("Excepcion al marcar como backlog: $e");
      return null;
    }
  }

  /// Gestiona el estado de una Tarea Principal (TP) usando endpoint unificado.
  ///
  /// Este método reemplaza los endpoints fragmentados anteriores:
  /// - INICIAR: Registra dtiempoinicio
  /// - PAUSAR: Crea nueva pausa (requiere cmotivo)
  /// - REANUDAR: Cierra pausa activa (idpausa es opcional - backend busca automáticamente)
  /// - FINALIZAR: Registra dtiempofin y bcerrada (backend calcula tiempo automáticamente)
  ///
  /// [idDetalleOrdenTrabajo] - ID del detalle de orden de trabajo
  /// [accion] - Acción a ejecutar: "INICIAR", "PAUSAR", "REANUDAR", "FINALIZAR"
  /// [timestamp] - Fecha/hora de la acción (formato: yyyy-MM-dd HH:mm:ss.SSS)
  /// [cmotivo] - Motivo de pausa (REQUERIDO para PAUSAR)
  /// [cobservaciones] - Observaciones opcionales (para FINALIZAR)
  /// [nminutosemp] - OPCIONAL: Minutos empleados. Si se omite, el backend calcula automáticamente
  /// [idpausa] - ID de pausa específica (OPCIONAL para REANUDAR)
  ///
  /// IMPORTANTE sobre idpausa:
  /// En el 99% de casos NO es necesario enviar idpausa en REANUDAR.
  /// El backend busca automáticamente la pausa activa más reciente.
  /// Solo usar idpausa para casos especiales de corrección manual.
  ///
  /// Retorna [GestionEstadoResponse] en caso de éxito, null en caso de error.
  Future<GestionEstadoResponse?> gestionarEstadoActividadTP({
    required int idDetalleOrdenTrabajo,
    required String accion,
    required DateTime timestamp,
    String? cmotivo,
    String? cobservaciones,
    String? nminutosemp,
    int? idpausa,
  }) async {
    var client = http.Client();
    var url = '$_hgapiEndpoint/gestionarestadoactividad';
    var uri = Uri.parse(url);

    // Construir request body con campos obligatorios
    Map<String, dynamic> requestBody = {
      "iddetalleordentrabajo": idDetalleOrdenTrabajo.toString(),
      "accion": accion,
      "timestamp": _formatFecha(timestamp),
    };

    // Agregar campos opcionales/condicionales
    if (cmotivo != null) requestBody["cmotivo"] = cmotivo;
    if (cobservaciones != null) requestBody["cobservaciones"] = cobservaciones;
    if (nminutosemp != null) requestBody["nminutosemp"] = nminutosemp;
    if (idpausa != null) requestBody["idpausa"] = idpausa.toString();

    String jsonBody = jsonEncode(requestBody);

    try {
      var response = await client.post(
        uri,
        headers: {"Content-Type": "application/json"},
        body: jsonBody,
      );

      if (response.statusCode == 200) {
        print("✅ Acción $accion ejecutada exitosamente (TP)");

        // Parsear respuesta a DTO
        final jsonResponse =
            jsonDecode(const Utf8Decoder().convert(response.bodyBytes));
        return GestionEstadoResponse.fromJson(jsonResponse);
      } else {
        print(
            "❌ Error al gestionar estado TP ($accion): Código ${response.statusCode}");
        print("Mensaje: ${response.body}");
        return null;
      }
    } catch (e) {
      print("❌ Excepción al gestionar estado TP ($accion): $e");
      return null;
    }
  }

  /// OBSOLETO: Reemplazado por gestionarEstadoActividadTP() con acción PAUSAR.
  /// Mantenido temporalmente para referencia, pero NO debe usarse en código nuevo.
  @Deprecated('Usar gestionarEstadoActividadTP() con accion PAUSAR')
  Future<int?> registrarPausaTP({
    required int idDetalleOrdenTrabajo,
    required String motivo,
    required DateTime tiempoInicio,
  }) async {
    var client = http.Client();
    var url = '$_hgapiEndpoint/gestionarpausadetalleordentrabajo';
    var uri = Uri.parse(url);

    String jsonBody = jsonEncode({
      "iddetalleordentrabajo": idDetalleOrdenTrabajo.toString(),
      "cmotivo": motivo,
      "dtiempoinicio": _formatFecha(tiempoInicio),
    });

    try {
      var response = await client.post(
        uri,
        headers: {"Content-Type": "application/json"},
        body: jsonBody,
      );

      if (response.statusCode == 200) {
        print("Pausa TP registrada exitosamente");

        final jsonResponse =
            jsonDecode(const Utf8Decoder().convert(response.bodyBytes));
        return jsonResponse['id'] as int?;
      } else {
        print("Error al registrar pausa TP: Codigo ${response.statusCode}");
        print("Mensaje: ${response.body}");
        return null;
      }
    } catch (e) {
      print("Excepcion al registrar pausa TP: $e");
      return null;
    }
  }

  /// OBSOLETO: Reemplazado por gestionarEstadoActividadTP() con acción REANUDAR.
  /// Mantenido temporalmente para referencia, pero NO debe usarse en código nuevo.
  @Deprecated('Usar gestionarEstadoActividadTP() con accion REANUDAR')
  Future<bool> reanudarPausaTP({
    required int idPausa,
    required DateTime tiempoFin,
  }) async {
    var client = http.Client();
    var url = '$_hgapiEndpoint/gestionarpausadetalleordentrabajo';
    var uri = Uri.parse(url);

    String jsonBody = jsonEncode({
      "id": idPausa.toString(),
      "dtiempofin": _formatFecha(tiempoFin),
    });

    try {
      var response = await client.post(
        uri,
        headers: {"Content-Type": "application/json"},
        body: jsonBody,
      );

      if (response.statusCode == 200) {
        print("Pausa TP reanudada exitosamente (ID: $idPausa)");
        return true;
      } else {
        print("Error al reanudar pausa TP: Codigo ${response.statusCode}");
        print("Mensaje: ${response.body}");
        return false;
      }
    } catch (e) {
      print("Excepcion al reanudar pausa TP: $e");
      return false;
    }
  }

  /// Registra una nueva pausa para Sub-Tarea (ST - DetalleAsignacion).
  /// 
  /// Llama al endpoint /gestionarpausadetalleasignacion para crear un registro de pausa.
  /// 
  /// [idDetalleAsignacion] - ID de la asignación (empleado asistente)
  /// [motivo] - Motivo de la pausa (máximo 500 caracteres)
  /// [tiempoInicio] - Timestamp de inicio de pausa
  /// 
  /// Retorna el ID de la pausa creada en caso de éxito, null en caso de error
  Future<int?> registrarPausaST({
    required int idDetalleAsignacion,
    required String motivo,
    required DateTime tiempoInicio,
  }) async {
    var client = http.Client();
    var url = '$_hgapiEndpoint/gestionarpausadetalleasignacion';
    var uri = Uri.parse(url);

    String jsonBody = jsonEncode({
      "iddetalleasignacion": idDetalleAsignacion.toString(),
      "cmotivo": motivo,
      "dtiempoinicio": _formatFecha(tiempoInicio),
    });

    try {
      var response = await client.post(
        uri,
        headers: {"Content-Type": "application/json"},
        body: jsonBody,
      );

      if (response.statusCode == 200) {
        print("Pausa ST registrada exitosamente");
        
        final jsonResponse =
            jsonDecode(const Utf8Decoder().convert(response.bodyBytes));
        return jsonResponse['id'] as int?;
      } else {
        print("Error al registrar pausa ST: Codigo ${response.statusCode}");
        print("Mensaje: ${response.body}");
        return null;
      }
    } catch (e) {
      print("Excepcion al registrar pausa ST: $e");
      return null;
    }
  }

  /// Reanuda una pausa existente para Sub-Tarea (ST - DetalleAsignacion).
  /// 
  /// Llama al endpoint /gestionarpausadetalleasignacion para actualizar el registro de pausa.
  /// El backend calcula automáticamente los minutos de pausa.
  /// 
  /// [idPausa] - ID de la pausa retornado al crearla
  /// [tiempoFin] - Timestamp de fin de pausa
  /// 
  /// Retorna true en caso de éxito, false en caso de error
  Future<bool> reanudarPausaST({
    required int idPausa,
    required DateTime tiempoFin,
  }) async {
    var client = http.Client();
    var url = '$_hgapiEndpoint/gestionarpausadetalleasignacion';
    var uri = Uri.parse(url);

    String jsonBody = jsonEncode({
      "id": idPausa.toString(),
      "dtiempofin": _formatFecha(tiempoFin),
    });

    try {
      var response = await client.post(
        uri,
        headers: {"Content-Type": "application/json"},
        body: jsonBody,
      );

      if (response.statusCode == 200) {
        print("Pausa ST reanudada exitosamente (ID: $idPausa)");
        return true;
      } else {
        print("Error al reanudar pausa ST: Codigo ${response.statusCode}");
        print("Mensaje: ${response.body}");
        return false;
      }
    } catch (e) {
      print("Excepcion al reanudar pausa ST: $e");
      return false;
    }
  }
}
