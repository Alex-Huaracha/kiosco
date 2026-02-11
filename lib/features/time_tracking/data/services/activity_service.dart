import 'package:hgtrack/core/network/api_client.dart';
import 'package:hgtrack/features/authentication/data/models/empleado.dart';
import 'package:hgtrack/features/time_tracking/data/models/actividad.dart';
import 'package:hgtrack/features/time_tracking/data/models/detalle_orden_trabajo.dart';

/// Servicio para operaciones de actividades.
///
/// Con el endpoint unificado /empleadosactividades, las actividades
/// ya vienen cargadas junto con los empleados desde AuthService.
///
/// Este servicio maneja la finalizacion de actividades tanto TP como ST.
class ActivityService {
  /// Finaliza una Tarea Principal (TP) enviando datos de tiempo al backend
  ///
  /// [actividad] - Detalle de la actividad a finalizar
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
      final nombreCompleto = _construirNombreCompleto(empleado);

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
      print("Error en servicio de finalizacion TP: $e");
      return null;
    }
  }

  /// Finaliza una Sub-Tarea (ST) enviando datos de tiempo al backend.
  /// Usa el endpoint /adddetalleasignacion con el idAsignacion.
  ///
  /// [actividadDto] - Actividad completa con info de tipo y idAsignacion
  /// [tiempoInicio] - Fecha/hora del primer inicio
  /// [tiempoFin] - Fecha/hora de finalización
  /// [minutosEmpleado] - Total de minutos trabajados (calculado en frontend)
  /// [observaciones] - Observaciones opcionales del técnico
  ///
  /// Retorna true en caso de éxito, false en caso de error
  Future<bool> finalizarSubTarea({
    required ActividadEmpleadoDto actividadDto,
    required DateTime tiempoInicio,
    required DateTime tiempoFin,
    required int minutosEmpleado,
    String? observaciones,
  }) async {
    if (actividadDto.idAsignacion == null) {
      print("Error: idAsignacion es null para Sub-Tarea");
      return false;
    }

    try {
      final api = TrackingApi();

      return await api.finalizarAsignacion(
        idAsignacion: actividadDto.idAsignacion!,
        tiempoInicio: tiempoInicio,
        tiempoFin: tiempoFin,
        minutosEmpleado: minutosEmpleado,
        observaciones: observaciones,
      );
    } catch (e) {
      print("Error en servicio de finalizacion ST: $e");
      return false;
    }
  }

  /// Finaliza una actividad detectando automaticamente si es TP o ST.
  ///
  /// [actividadDto] - Actividad completa del endpoint unificado
  /// [empleado] - Empleado que ejecutó la actividad
  /// [tiempoInicio] - Fecha/hora del primer inicio
  /// [tiempoFin] - Fecha/hora de finalización
  /// [minutosEmpleado] - Total de minutos trabajados
  /// [observaciones] - Observaciones opcionales
  ///
  /// Retorna true en caso de éxito, false en caso de error
  Future<bool> finalizarActividadUnificado({
    required ActividadEmpleadoDto actividadDto,
    required HgEmpleadoMantenimientoDto empleado,
    required DateTime tiempoInicio,
    required DateTime tiempoFin,
    required int minutosEmpleado,
    String? observaciones,
  }) async {
    if (actividadDto.esSubTarea) {
      // Es Sub-Tarea (ST) - usar endpoint de asignacion
      print(
          "Finalizando Sub-Tarea ST (idAsignacion: ${actividadDto.idAsignacion})");
      return await finalizarSubTarea(
        actividadDto: actividadDto,
        tiempoInicio: tiempoInicio,
        tiempoFin: tiempoFin,
        minutosEmpleado: minutosEmpleado,
        observaciones: observaciones,
      );
    } else {
      // Es Tarea Principal (TP) - usar endpoint de detalle
      print(
          "Finalizando Tarea Principal TP (idDetalle: ${actividadDto.detalle?.id})");
      final resultado = await finalizarActividad(
        actividad: actividadDto.detalle!,
        empleado: empleado,
        tiempoInicio: tiempoInicio,
        tiempoFin: tiempoFin,
        minutosEmpleado: minutosEmpleado,
        observaciones: observaciones,
      );
      return resultado != null;
    }
  }

  /// Marca una actividad como backlog (no completada).
  /// 
  /// La actividad sera reprogramada en una futura orden de trabajo.
  /// Usado cuando el empleado no puede completar la actividad por razones
  /// externas (falta repuesto, herramienta, etc.)
  ///
  /// [actividad] - Detalle de la actividad a marcar como backlog
  /// [observaciones] - Razon opcional por la cual no se pudo completar
  ///
  /// Retorna el DTO actualizado en caso de éxito, null en caso de error
  Future<HgDetalleOrdenTrabajoDto?> marcarComoBacklog({
    required HgDetalleOrdenTrabajoDto actividad,
    String? observaciones,
  }) async {
    try {
      final api = TrackingApi();

      return await api.marcarActividadComoBacklog(
        idDetalleOrdenTrabajo: actividad.id!,
        observaciones: observaciones,
      );
    } catch (e) {
      print("Error en servicio de marcar como backlog: $e");
      return null;
    }
  }

  /// Construye el nombre completo del empleado en formato: APELLIDOS, NOMBRES
  String _construirNombreCompleto(HgEmpleadoMantenimientoDto empleado) {
    final apellidoPaterno = empleado.apellidopaterno ?? '';
    final apellidoMaterno = empleado.apellidomaterno ?? '';
    final nombres = empleado.nombres ?? '';

    if (apellidoPaterno.isNotEmpty || apellidoMaterno.isNotEmpty) {
      final apellidos = '$apellidoPaterno $apellidoMaterno'.trim();
      return '$apellidos, $nombres'.toUpperCase().trim();
    } else {
      return nombres.toUpperCase().trim();
    }
  }
}
