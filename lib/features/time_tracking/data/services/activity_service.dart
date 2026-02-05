import 'package:hgtrack/core/network/api_client.dart';
import 'package:hgtrack/features/authentication/data/models/empleado.dart';
import 'package:hgtrack/features/time_tracking/data/models/detalle_orden_trabajo.dart';

/// Servicio para operaciones de actividades.
/// 
/// Con el endpoint unificado /empleadosactividades, las actividades
/// ya vienen cargadas junto con los empleados desde AuthService.
/// 
/// Este servicio solo maneja la finalizacion de actividades.
class ActivityService {
  /// Finaliza una actividad enviando datos de tiempo al backend
  ///
  /// [actividad] - Actividad a finalizar
  /// [empleado] - Empleado que ejecutó la actividad
  /// [tiempoInicio] - Fecha/hora del primer inicio
  /// [tiempoFin] - Fecha/hora de finalización
  /// [minutosEmpleado] - Total de minutos trabajados (calculado en frontend)
  /// [observaciones] - Observaciones opcionales del técnico
  ///
  /// Retorna el DTO actualizado en caso de éxito, null en caso de error
  Future<HgDetalleOrdenTrabajoDto?> finalizarActividad({
    required HgDetalleOrdenTrabajoDto actividad,
    required HgEmpleadoMantenimientoDto empleado,
    required DateTime tiempoInicio,
    required DateTime tiempoFin,
    required int minutosEmpleado,
    String? observaciones,
  }) async {
    try {
      final api = TrackingApi();

      // Construir nombre completo: APELLIDOS, NOMBRES
      final apellidoPaterno = empleado.apellidopaterno ?? '';
      final apellidoMaterno = empleado.apellidomaterno ?? '';
      final nombres = empleado.nombres ?? '';

      String nombreCompleto;
      if (apellidoPaterno.isNotEmpty || apellidoMaterno.isNotEmpty) {
        final apellidos = '$apellidoPaterno $apellidoMaterno'.trim();
        nombreCompleto = '$apellidos, $nombres'.toUpperCase().trim();
      } else {
        nombreCompleto = nombres.toUpperCase().trim();
      }

      return await api.finalizarActividadEmpleado(
        idDetalleOrdenTrabajo: actividad.id!,
        idEmpleadoExt: empleado.id.toString(),
        cargoEmpleado: empleado.cargo ?? 'TECNICO',
        nombreEmpleado: nombreCompleto,
        tiempoInicio: tiempoInicio,
        tiempoFin: tiempoFin,
        minutosEmpleado: minutosEmpleado,
        observaciones: observaciones,
      );
    } catch (e) {
      print("Error en servicio de finalización: $e");
      return null;
    }
  }
}
