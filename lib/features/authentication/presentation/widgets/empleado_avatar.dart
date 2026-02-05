import 'package:flutter/material.dart';

import 'package:hgtrack/core/theme/app_colors.dart';

/// Avatar circular con iniciales del empleado
/// 
/// Muestra las iniciales del empleado en un círculo con el color primario.
/// Se usa en la lista de empleados, header de actividades, y otros contextos.
/// 
/// El tamaño es configurable mediante el parámetro [size]:
/// - 60px (default): Para headers y contextos compactos
/// - 80px: Para listas destacadas con alta visibilidad
/// - Otros tamaños personalizados según necesidad
class EmpleadoAvatar extends StatelessWidget {
  final String iniciales;
  final double size;

  /// Tamaños predefinidos recomendados
  static const double sizeSmall = 50;
  static const double sizeMedium = 60;  // Default
  static const double sizeLarge = 80;
  static const double sizeXLarge = 100;

  const EmpleadoAvatar({
    super.key,
    required this.iniciales,
    this.size = sizeMedium,  // Default: 60px
  });

  @override
  Widget build(BuildContext context) {
    // Calcular tamaño de fuente proporcionalmente (40% del tamaño del avatar)
    final fontSize = size * 0.4;
    
    return Container(
      width: size,
      height: size,
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
          style: TextStyle(
            color: Colors.white,
            fontSize: fontSize,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.5,
          ),
        ),
      ),
    );
  }
}
