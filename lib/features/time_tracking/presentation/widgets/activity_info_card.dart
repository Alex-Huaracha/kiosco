import 'package:flutter/material.dart';

import 'package:hgtrack/core/theme/app_colors.dart';
import 'package:hgtrack/features/authentication/data/models/empleado.dart';
import 'package:hgtrack/features/time_tracking/data/models/detalle_orden_trabajo.dart';
import 'package:hgtrack/features/time_tracking/presentation/widgets/info_row.dart';

/// Card que muestra información detallada de la actividad
/// 
/// Muestra sistema, subsistema, empleado asignado, cargo, fecha de registro
/// y badge de falla reportada si aplica.
class ActivityInfoCard extends StatelessWidget {
  final HgDetalleOrdenTrabajoDto actividad;
  final HgEmpleadoMantenimientoDto empleado;

  const ActivityInfoCard({
    super.key,
    required this.actividad,
    required this.empleado,
  });

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
            const Row(
              children: [
                Icon(
                  Icons.assignment,
                  size: 20,
                  color: AppColors.primary,
                ),
                SizedBox(width: 8),
                Text(
                  'Detalles de la Actividad',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),
            const Divider(color: AppColors.divider, thickness: 1),
            const SizedBox(height: 12),

            // Detalles
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
              label: 'Asignado a',
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
              label: 'Registrado',
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

  String _formatearFecha(int? millis) {
    if (millis == null) return 'N/A';
    final fecha = DateTime.fromMillisecondsSinceEpoch(millis);
    String dosDigitos(int n) => n.toString().padLeft(2, '0');
    return '${dosDigitos(fecha.day)}/${dosDigitos(fecha.month)}/${fecha.year}';
  }
}
