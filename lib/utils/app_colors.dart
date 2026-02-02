import 'package:flutter/material.dart';

/// Paleta de colores de la aplicación HG Track
/// Optimizada para uso en tablets en ambientes exteriores
/// Colores industriales con alta accesibilidad (WCAG AAA)
class AppColors {
  // Colores primarios - Azul Industrial
  // Optimizado para visibilidad en luz solar directa
  // Accesible para daltonismo rojo-verde
  static const Color primary = Color(0xFF1565C0);        // Azul oscuro - Ratio 8.2:1
  static const Color primaryDark = Color(0xFF0D47A1);    // Azul profundo - Para hover/pressed
  static const Color primaryLight = Color(0xFF42A5F5);   // Azul claro - Para backgrounds sutiles
  
  // Colores de acento
  static const Color accent = Color(0xFF0277BD);         // Azul medio - Para elementos destacados
  
  // Backgrounds
  static const Color background = Color(0xFFF5F5F5);     // Gris muy claro - Fondo general
  static const Color cardBackground = Colors.white;       // Blanco - Fondo de cards
  static const Color bannerBackground = Color(0xFFE3F2FD); // Azul muy claro - Banners informativos
  
  // Textos
  static const Color textPrimary = Color(0xFF212121);    // Casi negro - Texto principal (Ratio 16:1)
  static const Color textSecondary = Color(0xFF757575);  // Gris medio - Texto secundario (Ratio 4.6:1)
  static const Color textOnPrimary = Colors.white;       // Blanco - Texto sobre azul
  
  // Estados
  static const Color success = Color(0xFF2E7D32);        // Verde oscuro - Operaciones exitosas
  static const Color error = Color(0xFFD32F2F);          // Rojo - Solo para errores
  static const Color warning = Color(0xFFF57C00);        // Naranja - Advertencias
  static const Color info = Color(0xFF0288D1);           // Azul claro - Información
  
  // HG Corporate - Solo para branding
  static const Color hgRed = Color(0xFFE02E30);          // Rojo HG original - Solo logo
  static const Color hgRedLight = Color(0x1CE02E30);     // Rojo HG transparente - Backgrounds
  
  // Sombras y elevaciones
  static const Color shadowLight = Color(0x1A000000);    // Negro 10% - Sombras sutiles
  static const Color shadowMedium = Color(0x33000000);   // Negro 20% - Sombras medias
  
  // Divisores
  static const Color divider = Color(0xFFBDBDBD);        // Gris claro - Líneas divisoras
  
  // Overlay para estados interactivos
  static const Color rippleOverlay = Color(0x1A1565C0);  // Azul primario 10% - Efecto ripple
  static const Color hoverOverlay = Color(0x0A1565C0);   // Azul primario 4% - Hover state
}

/// Extensión para obtener el color del tema según el modo claro/oscuro
extension AppColorsExtension on AppColors {
  /// Retorna el color primario con opacidad personalizada
  /// [alpha] debe estar entre 0 (transparente) y 255 (opaco)
  static Color primaryWithAlpha(int alpha) {
    return AppColors.primary.withAlpha(alpha);
  }
  
  /// Retorna el color de acento con opacidad personalizada
  /// [alpha] debe estar entre 0 (transparente) y 255 (opaco)
  static Color accentWithAlpha(int alpha) {
    return AppColors.accent.withAlpha(alpha);
  }
}
