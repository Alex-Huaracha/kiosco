import 'package:flutter/material.dart';

import 'package:hgtrack/core/theme/app_colors.dart';

/// Widget reutilizable para mostrar una fila de información con icono, label y valor
/// 
/// Se usa en cards de información para mostrar datos estructurados.
/// 
/// Ejemplo:
/// ```dart
/// InfoRow(
///   icon: Icons.calendar_today,
///   label: 'Fecha',
///   value: '03/02/2026',
/// )
/// ```
class InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const InfoRow({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 16, color: AppColors.textSecondary),
        const SizedBox(width: 8),
        Text(
          '$label: ',
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: AppColors.textSecondary,
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              color: AppColors.textPrimary,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
