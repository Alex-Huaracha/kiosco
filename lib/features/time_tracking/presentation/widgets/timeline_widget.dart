import 'package:flutter/material.dart';

import 'package:hgtrack/core/theme/app_colors.dart';
import 'package:hgtrack/features/time_tracking/data/models/motivo_pausa.dart';
import 'package:hgtrack/features/time_tracking/domain/tracking_state.dart';

/// Widget de timeline que muestra el historial de ejecución de la actividad.
///
/// Muestra todos los eventos (inicio, pausa, reanudación, finalización) con
/// iconos, tiempos y duraciones trabajadas. Incluye un resumen del tiempo total.
///
/// [catalogoMotivos] se usa para mostrar el nombre del motivo de pausa.
/// Si está vacío, se muestra el ID como fallback.
class TimelineWidget extends StatelessWidget {
  final List<PeriodoTrabajo> periodos;
  final Duration tiempoTotalTrabajado;
  final List<MotivoPausa> catalogoMotivos;

  const TimelineWidget({
    super.key,
    required this.periodos,
    required this.tiempoTotalTrabajado,
    this.catalogoMotivos = const [],
  });

  @override
  Widget build(BuildContext context) {
    if (periodos.isEmpty) {
      return Card(
        elevation: 2,
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const Icon(
                Icons.history,
                size: 64,
                color: AppColors.textSecondary,
              ),
              const SizedBox(height: 16),
              const Text(
                'Sin actividad registrada',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Inicie la actividad para ver el historial',
                style: TextStyle(
                  fontSize: 14,
                  color: AppColors.textSecondary.withAlpha(179),
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

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
                  Icons.history,
                  size: 20,
                  color: AppColors.primary,
                ),
                SizedBox(width: 8),
                Text(
                  'Historial de Ejecución',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Timeline
            ...periodos.asMap().entries.map((entry) {
              final index = entry.key;
              final periodo = entry.value;
              final isLast = index == periodos.length - 1;

              return _TimelineItem(
                periodo: periodo,
                isLast: isLast,
                catalogoMotivos: catalogoMotivos,
              );
            }),

            const SizedBox(height: 16),
            const Divider(color: AppColors.divider, thickness: 2),
            const SizedBox(height: 12),

            // Resumen total
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Tiempo total trabajado:',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                Text(
                  _formatearDuracion(tiempoTotalTrabajado),
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _formatearDuracion(Duration duracion) {
    final horas = duracion.inHours;
    final minutos = duracion.inMinutes.remainder(60);

    if (horas > 0) {
      return '${horas}h ${minutos}min';
    } else {
      return '${minutos}min';
    }
  }
}

/// Item individual del timeline
class _TimelineItem extends StatelessWidget {
  final PeriodoTrabajo periodo;
  final bool isLast;
  final List<MotivoPausa> catalogoMotivos;

  const _TimelineItem({
    required this.periodo,
    required this.isLast,
    this.catalogoMotivos = const [],
  });

  /// Resuelve el texto a mostrar para el motivo de una pausa.
  String _resolverMotivo(PeriodoTrabajo p) {
    final id = p.idmotivo;
    if (id == null) return '';
    if (id == 8) {
      return p.cmotivoOtro?.isNotEmpty == true ? p.cmotivoOtro! : 'Otro';
    }
    try {
      return catalogoMotivos.firstWhere((m) => m.id == id).cnombre;
    } catch (_) {
      return 'Motivo #$id';
    }
  }

  @override
  Widget build(BuildContext context) {
    Color color;
    IconData icono;
    String titulo;

    switch (periodo.tipo) {
      case TipoEvento.inicio:
        color = AppColors.success;
        icono = Icons.play_circle;
        titulo = 'Iniciado';
        break;
      case TipoEvento.pausa:
        color = AppColors.warning;
        icono = Icons.pause_circle;
        titulo = 'Pausado';
        break;
      case TipoEvento.reanudacion:
        color = AppColors.success;
        icono = Icons.play_circle;
        titulo = 'Reanudado';
        break;
      case TipoEvento.finalizacion:
        color = AppColors.error;
        icono = Icons.stop_circle;
        titulo = 'Finalizado';
        break;
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Icono timeline
          Column(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                ),
                child: Icon(icono, color: Colors.white, size: 24),
              ),
              if (!isLast)
                Container(
                  width: 2,
                  height: 40,
                  color: AppColors.divider,
                ),
            ],
          ),

          const SizedBox(width: 16),

          // Contenido
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  titulo,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _formatearHora(periodo.inicio),
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppColors.textSecondary,
                  ),
                ),
                // Mostrar motivo si es una pausa y tiene idmotivo
                if (periodo.tipo == TipoEvento.pausa &&
                    periodo.idmotivo != null) ...[
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(
                        Icons.label,
                        size: 14,
                        color: AppColors.warning,
                      ),
                      const SizedBox(width: 4),
                      Flexible(
                        child: Text(
                          'Motivo: ${_resolverMotivo(periodo)}',
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
                if (periodo.duracion != null) ...[
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(
                        Icons.timer,
                        size: 14,
                        color: AppColors.textSecondary,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Trabajado: ${_formatearDuracion(periodo.duracion!)}',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatearHora(DateTime fecha) {
    final hora = fecha.hour;
    final minuto = fecha.minute.toString().padLeft(2, '0');
    final segundo = fecha.second.toString().padLeft(2, '0');
    final periodo = hora >= 12 ? 'PM' : 'AM';
    final hora12 = hora > 12 ? hora - 12 : (hora == 0 ? 12 : hora);
    return '${hora12.toString().padLeft(2, '0')}:$minuto:$segundo $periodo';
  }

  String _formatearDuracion(Duration duracion) {
    final horas = duracion.inHours;
    final minutos = duracion.inMinutes.remainder(60);

    if (horas > 0) {
      return '${horas}h ${minutos}min';
    } else {
      return '${minutos}min';
    }
  }
}
