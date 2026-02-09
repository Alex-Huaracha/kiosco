import 'package:flutter/material.dart';

import 'package:hgtrack/core/theme/app_colors.dart';
import 'package:hgtrack/features/time_tracking/data/models/detalle_orden_trabajo.dart';
import 'package:hgtrack/features/time_tracking/data/models/orden_trabajo.dart';
import 'package:hgtrack/features/time_tracking/presentation/widgets/actividad_con_ot_model.dart';

/// Card individual de actividad con información completa de la OT
/// 
/// Muestra:
/// - Mini-header: Placa + Codigo (TP-1234 o TP-1234 ST-5) + Badge de estado
/// - Header: Título de actividad + Fecha de OT
/// - Info empleado principal (solo para ST)
/// - Tiempo trabajado (si aplica)
/// - Sistema/Subsistema
/// - Badge de falla reportada (si aplica)
/// - Footer: Horas de inicio/fin + Chevron
class ActividadConOtCard extends StatelessWidget {
  final ActividadConOt item;
  final VoidCallback onTap;

  const ActividadConOtCard({
    super.key,
    required this.item,
    required this.onTap,
  });

  HgDetalleOrdenTrabajoDto get actividad => item.actividad;
  HgOrdenTrabajoDto get ot => item.ordentrabajo;

  /// Verifica si es una Sub-Tarea
  bool get _esSubTarea => item.esSubTarea;

  /// Determina el estado visual de la actividad
  /// Considera tanto datos de BD como tracking local de SharedPreferences
  EstadoActividadCard get _estado {
    // Backlog (prioridad máxima en detección)
    if (actividad.bbacklog == true) {
      return EstadoActividadCard.backlog;
    }

    // En proceso: considera tracking local O datos de BD
    // Si tiene tracking local activo, está en proceso
    if (item.tieneTrackingLocal && item.localDtiempoinicio != null) {
      return EstadoActividadCard.enProceso;
    }
    // Si tiene inicio en BD pero no fin, está en proceso
    if (actividad.dtiempoinicio != null && actividad.dtiempofin == null) {
      return EstadoActividadCard.enProceso;
    }

    // No iniciada (pendiente)
    return EstadoActividadCard.noIniciada;
  }

  /// Configuración de colores según estado
  _ConfigEstado get _config {
    switch (_estado) {
      case EstadoActividadCard.noIniciada:
        return _ConfigEstado(
          color: AppColors.textSecondary,
          texto: 'No Iniciada',
          icono: Icons.radio_button_unchecked,
        );
      case EstadoActividadCard.enProceso:
        return _ConfigEstado(
          color: AppColors.primary,
          texto: 'En Proceso',
          icono: Icons.play_circle,
        );
      case EstadoActividadCard.backlog:
        return _ConfigEstado(
          color: AppColors.warning,
          texto: 'Backlog',
          icono: Icons.warning_amber_rounded,
        );
    }
  }

  /// Minutos trabajados: prioriza BD, luego tracking local (ya calculado)
  int? get _minutosEstimados {
    // Tiempo registrado en BD (actividad finalizada)
    if (actividad.nminutosemp != null) {
      return actividad.nminutosemp;
    }

    // Tiempo desde tracking local (ya calculado, no recalcular)
    return item.localMinutosTrabajados;
  }

  /// Formatea minutos a texto compacto "2h 30m" o "45m"
  String _formatearMinutosCompacto(int minutos) {
    if (minutos < 60) {
      return '${minutos}m';
    }
    final horas = minutos ~/ 60;
    final mins = minutos % 60;
    return mins > 0 ? '${horas}h ${mins}m' : '${horas}h';
  }

  /// Formatea hora de DateTime a formato compacto AM/PM
  String _formatearHoraCompacta(DateTime? fecha) {
    if (fecha == null) return '';
    final hora = fecha.hour;
    final minuto = fecha.minute.toString().padLeft(2, '0');
    final periodo = hora >= 12 ? 'PM' : 'AM';
    final hora12 = hora > 12 ? hora - 12 : (hora == 0 ? 12 : hora);
    return '$hora12:$minuto $periodo';
  }

  /// Formatea fecha de milisegundos a formato "DD/MM/YYYY"
  String _formatearFechaCompacta(int? millis) {
    if (millis == null) return '';
    final fecha = DateTime.fromMillisecondsSinceEpoch(millis);
    String dosDigitos(int n) => n.toString().padLeft(2, '0');
    return '${dosDigitos(fecha.day)}/${dosDigitos(fecha.month)}/${fecha.year}';
  }

  /// Obtiene la hora de inicio efectiva (prioriza tracking local sobre BD)
  DateTime? get _horaInicioEfectiva {
    // Priorizar tracking local sobre BD
    if (item.localDtiempoinicio != null) {
      return item.localDtiempoinicio;
    }
    // Fallback a BD
    if (actividad.dtiempoinicio != null) {
      return DateTime.fromMillisecondsSinceEpoch(actividad.dtiempoinicio!);
    }
    return null;
  }

  /// Obtiene la hora de fin efectiva (prioriza tracking local sobre BD)
  DateTime? get _horaFinEfectiva {
    // Priorizar tracking local sobre BD
    if (item.localDtiempofin != null) {
      return item.localDtiempofin;
    }
    // Fallback a BD
    if (actividad.dtiempofin != null) {
      return DateTime.fromMillisecondsSinceEpoch(actividad.dtiempofin!);
    }
    return null;
  }

  /// Getters para condiciones de visualización
  bool get _tieneSistema =>
      actividad.csistema != null || actividad.csubsistema != null;

  bool get _esFallaReportada => actividad.bfallareportada == true;

  /// Muestra hora de inicio si hay tracking local O dato en BD
  bool get _mostrarHoraInicio => _horaInicioEfectiva != null;

  /// Muestra hora de fin si hay tracking local finalizado O dato en BD
  bool get _mostrarHoraFin => _horaFinEfectiva != null;

  bool get _mostrarTiempo =>
      _minutosEstimados != null && _estado == EstadoActividadCard.enProceso;

  @override
  Widget build(BuildContext context) {
    final config = _config;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        splashColor: AppColors.rippleOverlay,
        highlightColor: AppColors.hoverOverlay,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 0. Mini-header: Placa + OT + Badge Estado
              _buildMiniHeader(config),

              const SizedBox(height: 8),

              // 1. Header: Solo título de la actividad
              _buildHeader(),

              const SizedBox(height: 8),

              // 2. Placa del vehículo
              _buildPlacaVehiculo(),

              const SizedBox(height: 8),

              // 3. Divider
              const Divider(
                color: AppColors.divider,
                thickness: 1,
              ),

              const SizedBox(height: 8),

              // 4. Sistema/Subsistema (si existe)
              if (_tieneSistema) ...[
                _buildSistemaSubsistema(),
                const SizedBox(height: 6),
              ],

              // 5. Badge Falla Reportada (si aplica)
              if (_esFallaReportada) ...[
                _buildBadgeFalla(),
                const SizedBox(height: 6),
              ],

              // 6. Footer compacto: Fecha + Hora Inicio + Hora Fin + Minutos + Chevron
              _buildFooter(config),
            ],
          ),
        ),
      ),
    );
  }

  /// Mini-header con Placa + Codigo (TP/ST) + Badge Estado
  Widget _buildMiniHeader(_ConfigEstado config) {
    // Color de fondo: morado claro para ST, azul claro para TP
    final bgColor = _esSubTarea 
        ? AppColors.subtareaBackground 
        : AppColors.bannerBackground;
    final borderColor = _esSubTarea 
        ? AppColors.subtarea.withAlpha(51) 
        : AppColors.primary.withAlpha(51);
    final iconColor = _esSubTarea ? AppColors.subtarea : AppColors.primary;
    final textColor = _esSubTarea ? AppColors.subtarea : AppColors.primary;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: borderColor,
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.max,
        children: [
          // Icono: construction para todos (representa trabajo/mantenimiento)
          Icon(
            Icons.construction,
            size: 16,
            color: iconColor,
          ),
          const SizedBox(width: 6),
          // Codigo (sin placa)
          Expanded(
            child: Text(
              item.codigoDisplay,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: textColor,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 8),
          // Badge de tipo - Principal (solo para TP)
          if (!_esSubTarea) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text(
                'Principal',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(width: 8),
          ],
          // Badge de tipo - Asistencia (solo para ST)
          if (_esSubTarea) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.subtarea,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text(
                'Asistencia',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(width: 8),
          ],
          // Badge de estado
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: config.color,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              config.texto,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Calcula el color de la fecha de asignación según antigüedad
  /// - Azul (AppColors.primary): Asignada hoy o ayer
  /// - Naranja (AppColors.warning): Asignada hace más de 1 día (tarea antigua pendiente)
  Color _calcularColorFecha(int? millis) {
    if (millis == null) return AppColors.textSecondary;

    final fechaAsignacion = DateTime.fromMillisecondsSinceEpoch(millis);
    final hoy = DateTime.now();
    final diferenciaDias = hoy.difference(fechaAsignacion).inDays;

    // Si tiene más de 1 día → naranja (advertencia: tarea antigua pendiente)
    if (diferenciaDias > 1) {
      return AppColors.warning; // Naranja
    }

    // Hoy o ayer → azul normal
    return AppColors.primary;
  }

  /// Header: Título de la actividad
  /// - Para TP: Muestra el título de la actividad principal
  /// - Para ST: Muestra la sub-actividad específica (sin contexto de actividad principal)
  Widget _buildHeader() {
    // Para Sub-Tareas (ST): Mostrar solo la sub-actividad
    if (_esSubTarea && item.subActividad != null && item.subActividad!.isNotEmpty) {
      return Text(
        item.subActividad!,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: AppColors.textPrimary,
        ),
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      );
    }

    // Para Tareas Principales (TP): Mostrar título normal
    return Text(
      actividad.cactividad ?? 'Sin descripción',
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: AppColors.textPrimary,
      ),
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
    );
  }

  /// Muestra la placa del vehículo
  Widget _buildPlacaVehiculo() {
    return Row(
      children: [
        const Icon(
          Icons.local_shipping,
          size: 16,
          color: AppColors.textSecondary,
        ),
        const SizedBox(width: 6),
        Text(
          ot.idplacatracto ?? 'N/A',
          style: const TextStyle(
            fontSize: 14,
            color: AppColors.textSecondary,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  /// Sistema y Subsistema
  Widget _buildSistemaSubsistema() {
    return Row(
      children: [
        const Icon(
          Icons.category,
          size: 16,
          color: AppColors.textSecondary,
        ),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            [
              if (actividad.csistema != null) actividad.csistema!,
              if (actividad.csubsistema != null) actividad.csubsistema!,
            ].join(' • '),
            style: const TextStyle(
              fontSize: 14,
              color: AppColors.textSecondary,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  /// Badge Falla Reportada
  Widget _buildBadgeFalla() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.error,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.warning,
            size: 14,
            color: Colors.white,
          ),
          const SizedBox(width: 4),
          const Text(
            'Falla Reportada',
            style: TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  /// Footer compacto: [Fecha] [Hora Inicio] [Hora Fin] [Minutos] [Tiempo Estimado ST] + Chevron
  /// Todos los elementos temporales en una sola fila para mejor uso del espacio
  Widget _buildFooter(_ConfigEstado config) {
    final colorFecha = _calcularColorFecha(actividad.dfecreg);
    final hayFecha = actividad.dfecreg != null;
    final hayMinutos = _mostrarTiempo && _minutosEstimados != null;
    final hayTiempoEstimado = _esSubTarea && item.tiempoEstimado != null;

    return Row(
      children: [
        // Contenedor de elementos temporales
        Expanded(
          child: Wrap(
            spacing: 16,
            runSpacing: 4,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              // 1. Fecha de asignación (DD/MM)
              if (hayFecha)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.calendar_today,
                      size: 14,
                      color: colorFecha,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      _formatearFechaCompacta(actividad.dfecreg),
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: colorFecha,
                      ),
                    ),
                  ],
                ),

              // 2. Tiempo estimado (solo para ST antes de iniciar)
              if (hayTiempoEstimado && !_mostrarHoraInicio)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.schedule,
                      size: 14,
                      color: AppColors.subtarea,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${_formatearMinutosCompacto(item.tiempoEstimado!)} est.',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.subtarea,
                      ),
                    ),
                  ],
                ),

              // 3. Hora de inicio
              if (_mostrarHoraInicio)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.play_circle_outline,
                      size: 14,
                      color: AppColors.success,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      _formatearHoraCompacta(_horaInicioEfectiva),
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: AppColors.success,
                      ),
                    ),
                  ],
                ),

              // 4. Hora de fin
              if (_mostrarHoraFin)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.stop_circle_outlined,
                      size: 14,
                      color: AppColors.textSecondary,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      _formatearHoraCompacta(_horaFinEfectiva),
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),

              // 5. Minutos trabajados (solo si está en proceso)
              if (hayMinutos)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.timer_outlined,
                      size: 14,
                      color: AppColors.primary,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      _formatearMinutosCompacto(_minutosEstimados!),
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ),

        // Chevron (siempre presente)
        const Icon(
          Icons.chevron_right,
          color: AppColors.primary,
          size: 28,
        ),
      ],
    );
  }
}

/// Configuración visual por estado
class _ConfigEstado {
  final Color color;
  final String texto;
  final IconData icono;

  _ConfigEstado({
    required this.color,
    required this.texto,
    required this.icono,
  });
}
