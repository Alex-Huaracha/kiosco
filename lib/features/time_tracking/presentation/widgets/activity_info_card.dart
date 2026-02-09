import 'package:flutter/material.dart';

import 'package:hgtrack/core/theme/app_colors.dart';
import 'package:hgtrack/features/authentication/data/models/empleado.dart';
import 'package:hgtrack/features/time_tracking/data/models/detalle_orden_trabajo.dart';
import 'package:hgtrack/features/time_tracking/presentation/widgets/actividad_con_ot_model.dart';
import 'package:hgtrack/features/time_tracking/presentation/widgets/info_row.dart';

/// Card que muestra información detallada de la actividad
/// 
/// Muestra sistema, subsistema, empleado asignado, cargo, fecha de registro
/// y badge de falla reportada si aplica.
/// 
/// Para Sub-Tareas (ST), también muestra:
/// - La sub-actividad específica que debe realizar el empleado
/// - El empleado principal/responsable de la tarea
/// - El tiempo estimado de la sub-tarea
class ActivityInfoCard extends StatelessWidget {
  final HgDetalleOrdenTrabajoDto actividad;
  final HgEmpleadoMantenimientoDto empleado;
  
  /// Modelo completo con info de TP/ST (opcional para compatibilidad)
  final ActividadConOt? actividadConOt;

  const ActivityInfoCard({
    super.key,
    required this.actividad,
    required this.empleado,
    this.actividadConOt,
  });

  /// Verifica si es una Sub-Tarea
  bool get _esSubTarea => actividadConOt?.esSubTarea ?? false;

  /// Verifica si debe mostrar info del empleado principal
  bool get _mostrarEmpleadoPrincipal =>
      _esSubTarea && 
      actividadConOt?.empleadoPrincipal != null && 
      !(actividadConOt!.empleadoPrincipal!.sinAsignar);

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            _buildHeader(),

            const SizedBox(height: 12),
            const Divider(color: AppColors.divider, thickness: 1),
            const SizedBox(height: 12),

            // Para Sub-Tareas: Mostrar sección especial
            if (_esSubTarea) ...[
              _buildSeccionSubTarea(),
              const SizedBox(height: 12),
              const Divider(color: AppColors.divider, thickness: 1),
              const SizedBox(height: 12),
            ],

            // Detalles comunes
            if (actividad.csistema != null || actividad.csubsistema != null) ...[
              InfoRow(
                icon: Icons.category,
                label: 'Sistema',
                value: [
                  if (actividad.csistema != null) actividad.csistema!,
                  if (actividad.csubsistema != null) actividad.csubsistema!,
                ].join(' • '),
              ),
              const SizedBox(height: 8),
            ],

            InfoRow(
              icon: Icons.person,
              label: _esSubTarea ? 'Ejecutado por' : 'Asignado a',
              value: empleado.nombreCompleto,
            ),
            const SizedBox(height: 8),
            InfoRow(
              icon: Icons.badge,
              label: 'Cargo',
              value: empleado.cargo ?? 'N/A',
            ),
            const SizedBox(height: 8),
            InfoRow(
              icon: Icons.calendar_month,
              label: 'Creada el',
              value: _formatearFecha(actividad.dfecreg),
            ),

            // Badge Falla Reportada
            if (actividad.bfallareportada == true) ...[
              const SizedBox(height: 12),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.error,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.warning, size: 16, color: Colors.white),
                    SizedBox(width: 6),
                    Text(
                      'Falla Reportada',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// Header con título dinámico según tipo
  Widget _buildHeader() {
    final iconColor = _esSubTarea ? AppColors.subtarea : AppColors.primary;
    final titulo = _esSubTarea 
        ? 'Detalles de la Asistencia' 
        : 'Detalles de la Actividad';

    return Row(
      children: [
        Icon(
          _esSubTarea ? Icons.people : Icons.assignment,
          size: 20,
          color: iconColor,
        ),
        const SizedBox(width: 8),
        Text(
          titulo,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: iconColor,
          ),
        ),
      ],
    );
  }

  /// Sección especial para Sub-Tareas
  Widget _buildSeccionSubTarea() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.subtareaBackground,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: AppColors.subtarea.withAlpha(51),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Título destacado
          Row(
            children: [
              const Icon(
                Icons.check_circle_outline,
                size: 18,
                color: AppColors.subtarea,
              ),
              const SizedBox(width: 6),
              const Text(
                'TU TAREA',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: AppColors.subtarea,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Sub-actividad específica
          if (actividadConOt?.subActividad != null) ...[
            Text(
              actividadConOt!.subActividad!,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
          ],

          // Tiempo estimado
          if (actividadConOt?.tiempoEstimado != null) ...[
            Row(
              children: [
                const Icon(
                  Icons.schedule,
                  size: 16,
                  color: AppColors.subtarea,
                ),
                const SizedBox(width: 6),
                Text(
                  'Tiempo estimado: ${_formatearMinutos(actividadConOt!.tiempoEstimado!)}',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.subtarea,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
          ],

          // Divider interno
          const Divider(color: AppColors.subtarea, thickness: 1, height: 16),

          // Actividad principal (contexto)
          Row(
            children: [
              const Icon(
                Icons.folder_outlined,
                size: 16,
                color: AppColors.textSecondary,
              ),
              const SizedBox(width: 6),
              const Text(
                'Actividad Principal:',
                style: TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            actividad.cactividad ?? 'Sin descripción',
            style: const TextStyle(
              fontSize: 14,
              color: AppColors.textPrimary,
            ),
          ),

          // Empleado principal
          if (_mostrarEmpleadoPrincipal) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(
                  Icons.person,
                  size: 16,
                  color: AppColors.textSecondary,
                ),
                const SizedBox(width: 6),
                const Text(
                  'Responsable:',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              actividadConOt!.empleadoPrincipal!.cnombreemp ?? 'Sin nombre',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.subtarea,
              ),
            ),
            if (actividadConOt!.empleadoPrincipal!.ccargoemp != null) ...[
              const SizedBox(height: 2),
              Text(
                actividadConOt!.empleadoPrincipal!.ccargoemp!,
                style: const TextStyle(
                  fontSize: 13,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ],
        ],
      ),
    );
  }

  /// Formatea minutos a texto legible "1h 30min" o "45min"
  String _formatearMinutos(int minutos) {
    if (minutos < 60) {
      return '${minutos}min';
    }
    final horas = minutos ~/ 60;
    final mins = minutos % 60;
    return mins > 0 ? '${horas}h ${mins}min' : '${horas}h';
  }

  String _formatearFecha(int? millis) {
    if (millis == null) return 'N/A';
    final fecha = DateTime.fromMillisecondsSinceEpoch(millis);
    String dosDigitos(int n) => n.toString().padLeft(2, '0');
    return '${dosDigitos(fecha.day)}/${dosDigitos(fecha.month)}/${fecha.year}';
  }
}
