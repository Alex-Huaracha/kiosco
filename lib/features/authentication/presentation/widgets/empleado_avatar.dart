import 'package:flutter/material.dart';

import 'package:hgtrack/core/theme/app_colors.dart';

/// Avatar circular con iniciales del empleado
/// 
/// Muestra las iniciales del empleado en un círculo con el color primario.
/// Se usa típicamente en la lista de empleados y en el header de actividades.
class EmpleadoAvatar extends StatelessWidget {
  final String iniciales;

  const EmpleadoAvatar({
    super.key,
    required this.iniciales,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 60,
      height: 60,
      decoration: BoxDecoration(
        color: AppColors.primary,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: AppColors.shadowLight,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Center(
        child: Text(
          iniciales.toUpperCase(),
          style: const TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.5,
          ),
        ),
      ),
    );
  }
}
