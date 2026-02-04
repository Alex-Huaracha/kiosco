import 'package:flutter/material.dart';

import 'package:hgtrack/core/theme/app_colors.dart';
import 'package:hgtrack/features/time_tracking/domain/tracking_state.dart';

/// Widget de botones de acción según el estado de la actividad
/// 
/// Muestra diferentes botones dependiendo del estado:
/// - No Iniciada: Botón "Iniciar"
/// - En Proceso: Botones "Pausar" y "Finalizar"
/// - Pausada: Botones "Reanudar" y "Finalizar"
/// - Finalizada: Mensaje de estado
class ActionButtons extends StatelessWidget {
  final EstadoActividad estado;
  final VoidCallback? onIniciar;
  final VoidCallback? onPausar;
  final VoidCallback? onReanudar;
  final VoidCallback? onFinalizar;

  const ActionButtons({
    super.key,
    required this.estado,
    this.onIniciar,
    this.onPausar,
    this.onReanudar,
    this.onFinalizar,
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
              'Acciones',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: AppColors.textPrimary,
              ),
            ),

            const SizedBox(height: 12),

            // Botones de acción
            _buildButtons(),
          ],
        ),
      ),
    );
  }

  Widget _buildButtons() {
    switch (estado) {
      case EstadoActividad.noIniciada:
        return SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: onIniciar,
            icon: const Icon(Icons.play_arrow),
            label: const Text('Iniciar Actividad'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              textStyle: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        );

      case EstadoActividad.enProceso:
        return Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: onPausar,
                icon: const Icon(Icons.pause),
                label: const Text('Pausar'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.warning,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: onFinalizar,
                icon: const Icon(Icons.stop),
                label: const Text('Finalizar'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.error,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ),
          ],
        );

      case EstadoActividad.pausada:
        return Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: onReanudar,
                icon: const Icon(Icons.play_arrow),
                label: const Text('Reanudar'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.success,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: onFinalizar,
                icon: const Icon(Icons.stop),
                label: const Text('Finalizar'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.error,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ),
          ],
        );

      case EstadoActividad.finalizada:
        return const Center(
          child: Text(
            'Actividad finalizada',
            style: TextStyle(
              fontSize: 16,
              color: AppColors.textSecondary,
              fontStyle: FontStyle.italic,
            ),
          ),
        );
    }
  }
}
