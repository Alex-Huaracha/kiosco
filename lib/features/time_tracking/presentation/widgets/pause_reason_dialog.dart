import 'package:flutter/material.dart';

import 'package:hgtrack/core/theme/app_colors.dart';
import 'package:hgtrack/features/time_tracking/data/models/motivo_pausa.dart';

/// Mapeo local de ID de motivo → icono visual.
/// Mantiene la experiencia visual del grid aunque el catálogo venga del backend.
const Map<int, IconData> _iconosPorMotivo = {
  1: Icons.wc,              // Servicios Higiénicos
  2: Icons.swap_horiz,      // Re-asignación de Tarea
  3: Icons.inventory_2,     // Falta de Repuesto
  4: Icons.build,           // Falta de Herramienta
  5: Icons.restaurant,      // Alimentación
  6: Icons.access_time,     // Fin de Turno
  7: Icons.engineering,     // Auxilio Mecánico
  8: Icons.edit_note,       // Otro
};

IconData _iconoParaMotivo(int id) {
  return _iconosPorMotivo[id] ?? Icons.help_outline;
}

/// Dialog para seleccionar el motivo de pausa.
///
/// Recibe [catalogoMotivos] desde [ActivityDetailPage] (ya cacheado).
/// Muestra un grid de botones con los motivos del catálogo.
/// Si el usuario selecciona "Otro" (id=8), muestra un TextField adicional.
///
/// Retorna [PauseReasonResult] con [idmotivo] y [cmotivoOtro], o null si cancela.
class PauseReasonDialog extends StatefulWidget {
  final List<MotivoPausa> catalogoMotivos;

  const PauseReasonDialog({
    super.key,
    required this.catalogoMotivos,
  });

  /// Muestra el dialog y retorna el resultado de la selección.
  /// Retorna null si el usuario cancela.
  ///
  /// [catalogoMotivos] debe estar cacheado en la página que llama.
  static Future<PauseReasonResult?> show(
    BuildContext context,
    List<MotivoPausa> catalogoMotivos,
  ) async {
    return showDialog<PauseReasonResult>(
      context: context,
      barrierDismissible: false,
      builder: (context) => PauseReasonDialog(catalogoMotivos: catalogoMotivos),
    );
  }

  @override
  State<PauseReasonDialog> createState() => _PauseReasonDialogState();
}

class _PauseReasonDialogState extends State<PauseReasonDialog> {
  MotivoPausa? _motivoSeleccionado;
  final _otroMotivoController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _otroMotivoController.dispose();
    super.dispose();
  }

  void _confirmar() {
    if (_motivoSeleccionado == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Por favor seleccione un motivo de pausa'),
          backgroundColor: AppColors.warning,
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    // Si seleccionó "Otro" (id=8), validar que ingresó texto
    if (_motivoSeleccionado!.esOtro) {
      if (!_formKey.currentState!.validate()) return;
      Navigator.of(context).pop(PauseReasonResult(
        idmotivo: _motivoSeleccionado!.id,
        cmotivoOtro: _otroMotivoController.text.trim(),
      ));
    } else {
      Navigator.of(context).pop(PauseReasonResult(
        idmotivo: _motivoSeleccionado!.id,
      ));
    }
  }

  void _cancelar() {
    Navigator.of(context).pop(null);
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final isLandscape = width > 800;

    return AlertDialog(
      title: const Row(
        children: [
          Icon(Icons.pause_circle, color: AppColors.warning, size: 28),
          SizedBox(width: 12),
          Text(
            'Motivo de Pausa',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
      content: SizedBox(
        width: isLandscape ? 600 : 400,
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Seleccione el motivo por el cual está pausando la actividad:',
                  style: TextStyle(
                    fontSize: 16,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 20),

                // Grid de botones con motivos del catálogo
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: isLandscape ? 2 : 1,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: isLandscape ? 3.2 : 4.5,
                  ),
                  itemCount: widget.catalogoMotivos.length,
                  itemBuilder: (context, index) {
                    final motivo = widget.catalogoMotivos[index];
                    final isSelected = _motivoSeleccionado?.id == motivo.id;

                    return InkWell(
                      onTap: () {
                        setState(() {
                          _motivoSeleccionado = motivo;
                          // Limpiar texto de "Otro" si cambia de motivo
                          if (!motivo.esOtro) {
                            _otroMotivoController.clear();
                          }
                        });
                      },
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: isSelected
                                ? AppColors.primary
                                : AppColors.divider,
                            width: isSelected ? 2.5 : 1.5,
                          ),
                          borderRadius: BorderRadius.circular(8),
                          color: isSelected
                              ? AppColors.primary.withAlpha(26)
                              : Colors.transparent,
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        child: Row(
                          children: [
                            Icon(
                              _iconoParaMotivo(motivo.id),
                              color: isSelected
                                  ? AppColors.primary
                                  : AppColors.textSecondary,
                              size: 28,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                motivo.cnombre,
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: isSelected
                                      ? FontWeight.bold
                                      : FontWeight.normal,
                                  color: isSelected
                                      ? AppColors.primary
                                      : AppColors.textPrimary,
                                ),
                              ),
                            ),
                            if (isSelected)
                              const Icon(
                                Icons.check_circle,
                                color: AppColors.primary,
                                size: 24,
                              ),
                          ],
                        ),
                      ),
                    );
                  },
                ),

                // Campo de texto adicional cuando se selecciona "Otro" (id=8)
                if (_motivoSeleccionado?.esOtro == true) ...[
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _otroMotivoController,
                    autofocus: true,
                    maxLength: 500,
                    decoration: const InputDecoration(
                      labelText: 'Especifique el motivo',
                      hintText: 'Ingrese el motivo de la pausa',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.edit),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Por favor ingrese el motivo';
                      }
                      if (value.trim().length < 3) {
                        return 'El motivo debe tener al menos 3 caracteres';
                      }
                      return null;
                    },
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _cancelar,
          child: const Text(
            'Cancelar',
            style: TextStyle(
              fontSize: 16,
              color: AppColors.textSecondary,
            ),
          ),
        ),
        ElevatedButton.icon(
          onPressed: _confirmar,
          icon: const Icon(Icons.pause),
          label: const Text('Confirmar Pausa'),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.warning,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            textStyle: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }
}
