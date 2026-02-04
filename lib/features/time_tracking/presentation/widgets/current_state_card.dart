import 'package:flutter/material.dart';

import 'package:hgtrack/core/theme/app_colors.dart';
import 'package:hgtrack/features/time_tracking/domain/tracking_state.dart';
import 'package:hgtrack/features/time_tracking/presentation/widgets/state_badge.dart';

/// Card que muestra el estado actual de la actividad
/// 
/// Muestra un badge centrado con el estado visual de la actividad
/// (No Iniciada, En Proceso, En Pausa, Finalizada).
class CurrentStateCard extends StatelessWidget {
  final EstadoActividad estado;

  const CurrentStateCard({
    super.key,
    required this.estado,
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
            const Text(
              'Estado Actual',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: AppColors.textPrimary,
              ),
            ),

            const SizedBox(height: 12),

            // Badge de estado en contenedor gris
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 16),
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Center(
                child: StateBadge(estado: estado),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
