import 'package:hgtrack/core/network/api_client.dart';
import 'package:hgtrack/features/authentication/data/models/empleado.dart';
import 'package:hgtrack/features/time_tracking/data/models/actividad.dart';
import 'package:hgtrack/features/time_tracking/data/models/detalle_orden_trabajo.dart';

class ActivityService {
  /// Obtiene las actividades del empleado y las agrupa por Orden de Trabajo
  ///
  /// [idEmpleado] - ID del empleado como String
  ///
  /// Retorna lista de OTs con sus actividades agrupadas y ordenadas
  /// Retorna null si no hay actividades o si ocurre un error
  Future<List<OrdenTrabajoConActividades>?> getOrdenesTrabajoConActividades(
    String idEmpleado,
  ) async {
    try {
      final api = TrackingApi();
      final actividades = await api.getAllActividadesEmpleado(idEmpleado);

      if (actividades == null || actividades.isEmpty) {
        return null;
      }

      // Agrupar actividades por ID de Orden de Trabajo
      Map<int, OrdenTrabajoConActividades> grupos = {};

      for (var actividad in actividades) {
        if (actividad.detalle == null || actividad.ordentrabajo == null) {
          continue; // Saltar actividades incompletas
        }

        int idOT = actividad.ordentrabajo!.id!;

        if (!grupos.containsKey(idOT)) {
          grupos[idOT] = OrdenTrabajoConActividades(
            ordentrabajo: actividad.ordentrabajo!,
            actividades: [],
          );
        }

        grupos[idOT]!.actividades.add(actividad.detalle!);
      }

      // Convertir a lista
      List<OrdenTrabajoConActividades> resultado = grupos.values.toList();

      // Ordenar actividades dentro de cada OT
      for (var grupo in resultado) {
        _ordenarActividades(grupo.actividades);
      }

      // Ordenar OTs: primero por estado (En Proceso > Pendiente > otros),
      // luego por fecha (más recientes primero)
      resultado.sort((a, b) {
        // Prioridad por estado
        int prioridadA = _obtenerPrioridadEstado(a.estadoBadge);
        int prioridadB = _obtenerPrioridadEstado(b.estadoBadge);

        if (prioridadA != prioridadB) {
          return prioridadA.compareTo(prioridadB);
        }

        // Si tienen mismo estado, ordenar por fecha (más reciente primero)
        int fechaA = a.ordentrabajo.dfecha ?? 0;
        int fechaB = b.ordentrabajo.dfecha ?? 0;
        return fechaB.compareTo(fechaA);
      });

      return resultado;
    } catch (e) {
      print("Error al obtener actividades: $e");
      return null;
    }
  }

  /// Ordena actividades: Pendientes → Cerradas → Backlog
  void _ordenarActividades(List<HgDetalleOrdenTrabajoDto> actividades) {
    actividades.sort((a, b) {
      // Pendientes primero (no cerradas, no backlog)
      bool aPendiente = a.bcerrada == false && a.bbacklog != true;
      bool bPendiente = b.bcerrada == false && b.bbacklog != true;
      if (aPendiente && !bPendiente) return -1;
      if (!aPendiente && bPendiente) return 1;

      // Cerradas segundo
      bool aCerrada = a.bcerrada == true;
      bool bCerrada = b.bcerrada == true;
      if (aCerrada && !bCerrada) return -1;
      if (!aCerrada && bCerrada) return 1;

      // Backlog último
      bool aBacklog = a.bbacklog == true;
      bool bBacklog = b.bbacklog == true;
      if (aBacklog && !bBacklog) return 1;
      if (!aBacklog && bBacklog) return -1;

      // Mismo estado: ordenar por fecha de registro (más reciente primero)
      int fechaA = a.dfecreg ?? 0;
      int fechaB = b.dfecreg ?? 0;
      return fechaB.compareTo(fechaA);
    });
  }

  /// Obtiene prioridad numérica del estado para ordenamiento
  /// Menor número = mayor prioridad
  int _obtenerPrioridadEstado(String estado) {
    switch (estado) {
      case 'En Proceso':
        return 1; // Mayor prioridad
      case 'Pendiente':
        return 2;
      case 'Backlog':
        return 3;
      case 'Cerrada':
        return 4; // Menor prioridad
      default:
        return 5;
    }
  }

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
