import 'package:flutter/material.dart';

import 'package:hgtrack/core/theme/app_colors.dart';
import 'package:hgtrack/features/time_tracking/data/models/orden_trabajo.dart';
import 'package:hgtrack/features/time_tracking/presentation/widgets/info_row.dart';

/// Card que muestra información de la Orden de Trabajo (OT)
/// 
/// Muestra datos principales de la OT como placa, fecha, supervisor,
/// taller, kilometraje y centro de costo.
class OrderInfoCard extends StatelessWidget {
  final HgOrdenTrabajoDto ordenTrabajo;

  const OrderInfoCard({
    super.key,
    required this.ordenTrabajo,
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
            // Header con placa y OT
            Row(
              children: [
                const Icon(
                  Icons.local_shipping,
                  size: 20,
                  color: AppColors.primary,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '${ordenTrabajo.idplacatracto ?? "N/A"} • OT-${ordenTrabajo.id}',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),
            const Divider(color: AppColors.divider, thickness: 1),
            const SizedBox(height: 12),

            // Detalles de la OT
            InfoRow(
              icon: Icons.calendar_today,
              label: 'Fecha',
              value: _formatearFecha(ordenTrabajo.dfecha),
            ),
            const SizedBox(height: 8),
            InfoRow(
              icon: Icons.person,
              label: 'Supervisor',
              value: ordenTrabajo.supervisor ?? 'N/A',
            ),
            const SizedBox(height: 8),
            InfoRow(
              icon: Icons.warehouse,
              label: 'Taller',
              value: ordenTrabajo.taller ?? 'N/A',
            ),
            const SizedBox(height: 8),
            InfoRow(
              icon: Icons.speed,
              label: 'Kilometraje',
              value: ordenTrabajo.nkilometraje != null
                  ? '${ordenTrabajo.nkilometraje} km'
                  : 'N/A',
            ),
            const SizedBox(height: 8),
            InfoRow(
              icon: Icons.business,
              label: 'Centro Costo',
              value: ordenTrabajo.ccentrocosto ?? 'N/A',
            ),
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
