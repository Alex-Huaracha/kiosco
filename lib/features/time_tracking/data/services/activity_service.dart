import 'package:hgtrack/core/network/api_client.dart';
import 'package:hgtrack/features/authentication/data/models/empleado.dart';
import 'package:hgtrack/features/time_tracking/data/models/actividad.dart';
import 'package:hgtrack/features/time_tracking/data/models/detalle_orden_trabajo.dart';
import 'package:hgtrack/features/time_tracking/data/models/gestion_estado_response.dart';

/// Servicio para operaciones de actividades.
///
/// Con el endpoint unificado /empleadosactividades, las actividades
/// ya vienen cargadas junto con los empleados desde AuthService.
///
/// Este servicio maneja la finalizacion de actividades tanto TP como ST.
class ActivityService {
  // ========================================================================
  // NUEVOS MÉTODOS - Endpoint Unificado /gestionarestadoactividad
  // ========================================================================

  /// Inicia una Tarea Principal (TP) en el backend usando endpoint unificado.
  ///
  /// [idDetalleOrdenTrabajo] - ID del detalle de orden de trabajo
  /// [timestamp] - Fecha/hora de inicio
  ///
  /// Retorna [GestionEstadoResponse] en caso de éxito, null en caso de error.
  Future<GestionEstadoResponse?> iniciarActividadTP({
    required int idDetalleOrdenTrabajo,
    required DateTime timestamp,
  }) async {
    try {
      final api = TrackingApi();
      return await api.gestionarEstadoActividadTP(
        idDetalleOrdenTrabajo: idDetalleOrdenTrabajo,
        accion: "INICIAR",
        timestamp: timestamp,
      );
    } catch (e) {
      print("Error al iniciar actividad TP: $e");
      return null;
    }
  }

  /// Pausa una Tarea Principal (TP) en el backend usando endpoint unificado.
  ///
  /// [idDetalleOrdenTrabajo] - ID del detalle de orden de trabajo
  /// [motivo] - Motivo de la pausa (requerido)
  /// [timestamp] - Fecha/hora de la pausa
  ///
  /// Retorna [GestionEstadoResponse] con idpausa en caso de éxito, null en caso de error.
  Future<GestionEstadoResponse?> pausarActividadTP({
    required int idDetalleOrdenTrabajo,
    required String motivo,
    required DateTime timestamp,
  }) async {
    try {
      final api = TrackingApi();
      return await api.gestionarEstadoActividadTP(
        idDetalleOrdenTrabajo: idDetalleOrdenTrabajo,
        accion: "PAUSAR",
        timestamp: timestamp,
        cmotivo: motivo,
      );
    } catch (e) {
      print("Error al pausar actividad TP: $e");
      return null;
    }
  }

  /// Reanuda una Tarea Principal (TP) en el backend usando endpoint unificado.
  ///
  /// [idDetalleOrdenTrabajo] - ID del detalle de orden de trabajo
  /// [timestamp] - Fecha/hora de reanudación
  ///
  /// NOTA: No enviamos idpausa - el backend busca automáticamente la pausa
  /// activa más reciente. Solo en casos especiales se necesitaría enviar idpausa.
  ///
  /// Retorna [GestionEstadoResponse] en caso de éxito, null en caso de error.
  Future<GestionEstadoResponse?> reanudarActividadTP({
    required int idDetalleOrdenTrabajo,
    required DateTime timestamp,
  }) async {
    try {
      final api = TrackingApi();
      return await api.gestionarEstadoActividadTP(
        idDetalleOrdenTrabajo: idDetalleOrdenTrabajo,
        accion: "REANUDAR",
        timestamp: timestamp,
        // NO enviar idpausa - el backend lo maneja automáticamente
      );
    } catch (e) {
      print("Error al reanudar actividad TP: $e");
      return null;
    }
  }

  /// Finaliza una Tarea Principal (TP) en el backend usando endpoint unificado.
  ///
  /// IMPORTANTE: El backend calcula automáticamente el tiempo efectivo trabajado
  /// como: (tiempo_fin - tiempo_inicio) - suma_pausas
  ///
  /// [idDetalleOrdenTrabajo] - ID del detalle de orden de trabajo
  /// [timestamp] - Fecha/hora de finalización
  /// [minutosEmpleado] - OPCIONAL: Total de minutos trabajados (sin contar pausas).
  ///                     Si se omite, el backend lo calcula automáticamente.
  /// [observaciones] - Observaciones opcionales del técnico
  ///
  /// Retorna [GestionEstadoResponse] en caso de éxito, null en caso de error.
  Future<GestionEstadoResponse?> finalizarActividadTPNuevo({
    required int idDetalleOrdenTrabajo,
    required DateTime timestamp,
    int? minutosEmpleado,
    String? observaciones,
  }) async {
    try {
      final api = TrackingApi();
      return await api.gestionarEstadoActividadTP(
        idDetalleOrdenTrabajo: idDetalleOrdenTrabajo,
        accion: "FINALIZAR",
        timestamp: timestamp,
        nminutosemp: minutosEmpleado?.toString(),
        cobservaciones: observaciones,
      );
    } catch (e) {
      print("Error al finalizar actividad TP: $e");
      return null;
    }
  }

  // ========================================================================
  // MÉTODOS EXISTENTES (Mantenidos para compatibilidad)
  // ========================================================================

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
