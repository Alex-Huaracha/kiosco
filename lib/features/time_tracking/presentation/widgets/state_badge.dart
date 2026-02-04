import 'package:flutter/material.dart';

import 'package:hgtrack/core/theme/app_colors.dart';
import 'package:hgtrack/features/time_tracking/domain/tracking_state.dart';

/// Badge visual que muestra el estado actual de una actividad
/// 
/// Muestra un contenedor redondeado con icono y texto del estado.
/// Los colores varían según el estado:
/// - No Iniciada: Gris
/// - En Proceso: Verde
/// - En Pausa: Naranja
/// - Finalizada: Azul
class StateBadge extends StatelessWidget {
  final EstadoActividad estado;

  const StateBadge({
    super.key,
    required this.estado,
  });

  @override
  Widget build(BuildContext context) {
    Color color;
    String texto;
    IconData icono;

    switch (estado) {
      case EstadoActividad.noIniciada:
        color = AppColors.textSecondary;
        texto = 'No Iniciada';
        icono = Icons.radio_button_unchecked;
        break;
      case EstadoActividad.enProceso:
        color = AppColors.success;
        texto = 'En Proceso';
        icono = Icons.play_circle;
        break;
      case EstadoActividad.pausada:
        color = AppColors.warning;
        texto = 'En Pausa';
        icono = Icons.pause_circle;
        break;
      case EstadoActividad.finalizada:
        color = AppColors.primary;
        texto = 'Finalizada';
        icono = Icons.check_circle;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icono, color: Colors.white, size: 24),
          const SizedBox(width: 8),
          Text(
            texto,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
