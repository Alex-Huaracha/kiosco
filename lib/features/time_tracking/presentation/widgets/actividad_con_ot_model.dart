import 'package:hgtrack/features/time_tracking/data/models/detalle_orden_trabajo.dart';
import 'package:hgtrack/features/time_tracking/data/models/orden_trabajo.dart';

/// Clase helper para mantener la relación entre actividad + OT
/// 
/// Se usa para agrupar una actividad con su orden de trabajo asociada,
/// facilitando el paso de datos entre pantallas y widgets.
class ActividadConOt {
  final HgDetalleOrdenTrabajoDto actividad;
  final HgOrdenTrabajoDto ordentrabajo;

  ActividadConOt({
    required this.actividad,
    required this.ordentrabajo,
  });
}

/// Enumeración de estados de actividad para visualización
enum EstadoActividad {
  noIniciada,
  enProceso,
  backlog,
}
