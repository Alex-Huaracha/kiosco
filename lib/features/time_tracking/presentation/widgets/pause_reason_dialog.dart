import 'package:flutter/material.dart';

import 'package:hgtrack/core/theme/app_colors.dart';

/// Motivos predefinidos de pausa
enum MotivosPausa {
  serviciosHigienicos('Servicios higiénicos', Icons.wc),
  reasignacionTarea('Re-asignación de tarea', Icons.swap_horiz),
  faltaRepuesto('Falta de repuesto', Icons.inventory_2),
  faltaHerramienta('Falta de herramienta', Icons.build),
  alimentacion('Alimentación', Icons.restaurant),
  finTurno('Fin de turno', Icons.access_time),
  auxilioMecanico('Auxilio mecánico', Icons.engineering),
  otro('Otro (especificar)', Icons.edit_note);

  final String label;
  final IconData icon;

  const MotivosPausa(this.label, this.icon);
}

/// Dialog para seleccionar el motivo de pausa
/// Muestra lista de motivos predefinidos optimizados para tablet
/// Si se selecciona "Otro", permite ingresar texto libre
class PauseReasonDialog extends StatefulWidget {
  const PauseReasonDialog({super.key});

  /// Muestra el dialog y retorna el motivo seleccionado
  /// Retorna null si el usuario cancela
  static Future<String?> show(BuildContext context) async {
    return showDialog<String>(
      context: context,
      barrierDismissible: false, // No cerrar al tocar fuera
      builder: (context) => const PauseReasonDialog(),
    );
  }

  @override
  State<PauseReasonDialog> createState() => _PauseReasonDialogState();
}

class _PauseReasonDialogState extends State<PauseReasonDialog> {
  MotivosPausa? _motivoSeleccionado;
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

    // Si seleccionó "Otro", validar que ingresó texto
    if (_motivoSeleccionado == MotivosPausa.otro) {
      if (!_formKey.currentState!.validate()) {
        return;
      }

      // Retornar el texto ingresado
      Navigator.of(context).pop(_otroMotivoController.text.trim());
    } else {
      // Retornar el label del motivo predefinido
      Navigator.of(context).pop(_motivoSeleccionado!.label);
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

                // Grid de botones de motivos
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: isLandscape ? 2 : 1,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: isLandscape ? 3.2 : 4.5,
                  ),
                  itemCount: MotivosPausa.values.length,
                  itemBuilder: (context, index) {
                    final motivo = MotivosPausa.values[index];
                    final isSelected = _motivoSeleccionado == motivo;

                    return InkWell(
                      onTap: () {
                        setState(() {
                          _motivoSeleccionado = motivo;
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
                              motivo.icon,
                              color: isSelected
                                  ? AppColors.primary
                                  : AppColors.textSecondary,
                              size: 28,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                motivo.label,
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

                // Campo de texto para "Otro"
                if (_motivoSeleccionado == MotivosPausa.otro) ...[
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _otroMotivoController,
                    autofocus: true,
                    maxLength: 100,
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
