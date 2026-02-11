import 'package:hgtrack/features/time_tracking/data/models/actividad.dart';
import 'package:hgtrack/features/time_tracking/data/models/detalle_orden_trabajo.dart';
import 'package:hgtrack/features/time_tracking/data/models/orden_trabajo.dart';

/// Clase helper para mantener la relación entre actividad + OT
/// 
/// Se usa para agrupar una actividad con su orden de trabajo asociada,
/// facilitando el paso de datos entre pantallas y widgets.
/// 
/// Ahora soporta tanto Tareas Principales (TP) como Sub-Tareas (ST).
/// 
/// Incluye campos locales para enriquecer la UI con datos de SharedPreferences
/// cuando la actividad está en progreso pero aún no se ha enviado al backend.
class ActividadConOt {
  final HgDetalleOrdenTrabajoDto actividad;
  final HgOrdenTrabajoDto ordentrabajo;
  
  /// DTO completo con info de tipo, codigo, empleadoPrincipal, etc.
  /// Solo disponible cuando se construye desde ActividadEmpleadoDto
  final ActividadEmpleadoDto? actividadDto;

  /// Fecha/hora de inicio desde estado local (SharedPreferences)
  /// Se usa para mostrar en el card cuando la actividad está en proceso
  /// pero aún no se ha finalizado/enviado al backend.
  /// Tiene prioridad sobre actividad.dtiempoinicio para visualización.
  DateTime? localDtiempoinicio;

  /// Fecha/hora de fin desde estado local (SharedPreferences)
  /// Solo se llena cuando la actividad fue finalizada localmente
  /// pero aún no se ha sincronizado con el backend.
  DateTime? localDtiempofin;

  /// Minutos trabajados desde tracking local (ya calculado en ActividadTrackingState)
  /// Solo almacena el resultado, no recalcula
  int? localMinutosTrabajados;

  /// Indica si hay un estado de tracking activo en SharedPreferences
  bool tieneTrackingLocal;

  ActividadConOt({
    required this.actividad,
    required this.ordentrabajo,
    this.actividadDto,
    this.localDtiempoinicio,
    this.localDtiempofin,
    this.localMinutosTrabajados,
    this.tieneTrackingLocal = false,
  });

  /// Verifica si es una Sub-Tarea (asistencia)
  bool get esSubTarea => actividadDto?.esSubTarea ?? false;

  /// Verifica si es una Tarea Principal
  bool get esTareaPrincipal => actividadDto?.esTareaPrincipal ?? true;

  /// Obtiene el tipo de actividad: "TP" o "ST"
  String get tipo => actividadDto?.tipo ?? "TP";

  /// Obtiene el codigo formateado: "TP-1234" o "TP-1234 ST-5"
  String get codigoDisplay => actividadDto?.codigoDisplay ?? "TP-${actividad.id ?? 'N/A'}";

  /// Obtiene info del empleado principal (solo para ST)
  EmpleadoPrincipalDto? get empleadoPrincipal => actividadDto?.empleadoPrincipal;

  /// Obtiene la sub-actividad especifica (solo para ST)
  String? get subActividad => actividadDto?.subActividad;

  /// Obtiene el tiempo estimado en minutos (solo para ST)
  int? get tiempoEstimado => actividadDto?.tiempoEstimado;

  /// Obtiene el ID de asignacion (solo para ST)
  int? get idAsignacion => actividadDto?.idAsignacion;
}

/// Enumeración de estados de actividad para visualización en cards
/// Nota: Backlog ya NO es un estado visual, se muestra como texto en el título
enum EstadoActividadCard {
  noIniciada,
  enProceso,
}
