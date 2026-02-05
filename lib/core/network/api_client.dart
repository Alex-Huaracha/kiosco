import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

import 'package:hgtrack/features/authentication/data/models/empleado_con_actividades.dart';
import 'package:hgtrack/features/time_tracking/data/models/detalle_body.dart';
import 'package:hgtrack/features/time_tracking/data/models/detalle_orden_trabajo.dart';

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

  /// Finaliza una actividad de empleado enviando tiempos y observaciones al backend.
  /// 
  /// [idDetalleOrdenTrabajo] - ID del detalle de orden de trabajo
  /// [idEmpleadoExt] - ID externo del empleado
  /// [cargoEmpleado] - Cargo del empleado
  /// [nombreEmpleado] - Nombre completo del empleado (APELLIDOS, NOMBRES)
  /// [tiempoInicio] - Fecha/hora de inicio del trabajo
  /// [tiempoFin] - Fecha/hora de fin del trabajo
  /// [minutosEmpleado] - Total de minutos trabajados
  /// [observaciones] - Observaciones opcionales
  /// 
  /// Retorna el DTO actualizado en caso de exito, null en caso de error
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

    // Formatear fechas segun documentacion: yyyy-MM-dd HH:mm:ss.SSS
    String formatFecha(DateTime fecha) {
      final year = fecha.year.toString().padLeft(4, '0');
      final month = fecha.month.toString().padLeft(2, '0');
      final day = fecha.day.toString().padLeft(2, '0');
      final hour = fecha.hour.toString().padLeft(2, '0');
      final minute = fecha.minute.toString().padLeft(2, '0');
      final second = fecha.second.toString().padLeft(2, '0');
      final millisecond = fecha.millisecond.toString().padLeft(3, '0');
      return '$year-$month-$day $hour:$minute:$second.$millisecond';
    }

    String jsonBody = jsonEncode({
      "iddetalleordentrabajo": idDetalleOrdenTrabajo.toString(),
      "idempleadoext": idEmpleadoExt,
      "ccargoemp": cargoEmpleado,
      "cnombreemp": nombreEmpleado,
      "dtiempoinicio": formatFecha(tiempoInicio),
      "dtiempofin": formatFecha(tiempoFin),
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
        print("Actividad finalizada exitosamente");

        // Parsear respuesta a DTO
        final jsonResponse =
            jsonDecode(const Utf8Decoder().convert(response.bodyBytes));
        return HgDetalleOrdenTrabajoDto.fromJson(jsonResponse);
      } else {
        print("Error al finalizar actividad: Codigo ${response.statusCode}");
        print("Mensaje: ${response.body}");
        return null;
      }
    } catch (e) {
      print("Excepcion al finalizar actividad: $e");
      return null;
    }
  }
}
