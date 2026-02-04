import 'package:flutter/material.dart';

import 'package:hgtrack/core/theme/app_colors.dart';

/// Campo de observaciones para registrar notas del técnico
/// 
/// Widget que muestra un TextField multi-línea para que el técnico
/// pueda agregar observaciones sobre la actividad realizada.
class ObservationsField extends StatelessWidget {
  final TextEditingController controller;
  final ValueChanged<String>? onChanged;

  const ObservationsField({
    super.key,
    required this.controller,
    this.onChanged,
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
            const Row(
              children: [
                Icon(
                  Icons.edit_note,
                  size: 20,
                  color: AppColors.primary,
                ),
                SizedBox(width: 8),
                Text(
                  'Observaciones',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              onChanged: onChanged,
              maxLines: 5,
              decoration: const InputDecoration(
                hintText:
                    'Ej: Se encontró desgaste en la soldadura del marco...',
                border: OutlineInputBorder(),
                enabledBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: AppColors.divider),
                ),
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: AppColors.primary, width: 2),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
