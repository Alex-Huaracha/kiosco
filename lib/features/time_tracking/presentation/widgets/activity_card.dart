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
  EstadoActividadCard get _estado {
    // Backlog (prioridad máxima en detección)
    if (actividad.bbacklog == true) {
      return EstadoActividadCard.backlog;
    }

    // En proceso (tiene inicio pero no fin)
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

  /// Calcula minutos trabajados (aproximado, sin pausas)
  int? get _minutosEstimados {
    if (actividad.nminutosemp != null) {
      return actividad.nminutosemp; // Tiempo registrado en BD
    }

    if (actividad.dtiempoinicio != null) {
      final inicio =
          DateTime.fromMillisecondsSinceEpoch(actividad.dtiempoinicio!);
      final fin = actividad.dtiempofin != null
          ? DateTime.fromMillisecondsSinceEpoch(actividad.dtiempofin!)
          : DateTime.now();
      return fin.difference(inicio).inMinutes;
    }

    return null;
  }

  /// Formatea minutos a texto legible "2h 30min" o "45min"
  String _formatearMinutos(int minutos) {
    if (minutos < 60) {
      return '$minutos min';
    }
    final horas = minutos ~/ 60;
    final mins = minutos % 60;
    return mins > 0 ? '${horas}h ${mins}min' : '${horas}h';
  }

  /// Formatea hora inicio a formato AM/PM
  String _formatearHoraInicio(int? millis) {
    if (millis == null) return '';
    final fecha = DateTime.fromMillisecondsSinceEpoch(millis);
    final hora = fecha.hour;
    final minuto = fecha.minute.toString().padLeft(2, '0');
    final periodo = hora >= 12 ? 'PM' : 'AM';
    final hora12 = hora > 12 ? hora - 12 : (hora == 0 ? 12 : hora);
    return '$hora12:$minuto $periodo';
  }

  /// Getters para condiciones de visualización
  bool get _tieneSistema =>
      actividad.csistema != null || actividad.csubsistema != null;

  bool get _esFallaReportada => actividad.bfallareportada == true;

  bool get _mostrarHoraInicio => actividad.dtiempoinicio != null;

  bool get _mostrarHoraFin => actividad.dtiempofin != null;

  bool get _mostrarTiempo =>
      _minutosEstimados != null && _estado == EstadoActividadCard.enProceso;

  /// Verifica si debe mostrar info del empleado principal (solo para ST con empleado asignado)
  bool get _mostrarEmpleadoPrincipal =>
      _esSubTarea && 
      item.empleadoPrincipal != null && 
      !item.empleadoPrincipal!.sinAsignar;

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

              // 1. Header: Título + Fecha
              _buildHeader(),

              const SizedBox(height: 8),

              // 2. Divider
              const Divider(
                color: AppColors.divider,
                thickness: 1,
              ),

              const SizedBox(height: 8),

              // 3. Empleado principal (solo para ST)
              if (_mostrarEmpleadoPrincipal) ...[
                _buildEmpleadoPrincipal(),
                const SizedBox(height: 6),
              ],

              // 4. Tiempo trabajado (si aplica)
              if (_mostrarTiempo) ...[
                _buildTiempoTrabajado(),
                const SizedBox(height: 6),
              ],

              // 5. Sistema/Subsistema (si existe)
              if (_tieneSistema) ...[
                _buildSistemaSubsistema(),
                const SizedBox(height: 6),
              ],

              // 6. Badge Falla Reportada (si aplica)
              if (_esFallaReportada) ...[
                _buildBadgeFalla(),
                const SizedBox(height: 6),
              ],

              // 7. Hora inicio + Chevron
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
          // Icono: persona para ST, camion para TP
          Icon(
            _esSubTarea ? Icons.person_outline : Icons.local_shipping,
            size: 16,
            color: iconColor,
          ),
          const SizedBox(width: 6),
          // Placa + Codigo
          Expanded(
            child: Text(
              '${ot.idplacatracto ?? "N/A"} • ${item.codigoDisplay}',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: textColor,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 8),
          // Badge de tipo (solo para ST)
          if (_esSubTarea) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: AppColors.subtarea,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text(
                'Asistencia',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 10,
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

  /// Formatea fecha de milisegundos a String "DD/MM/YYYY"
  String _formatearFechaOt(int? millis) {
    if (millis == null) return 'Sin fecha';
    final fecha = DateTime.fromMillisecondsSinceEpoch(millis);
    String dosDigitos(int n) => n.toString().padLeft(2, '0');
    return '${dosDigitos(fecha.day)}/${dosDigitos(fecha.month)}/${fecha.year}';
  }

  /// Calcula el color de la fecha según antigüedad
  /// - Normal (AppColors.primary): Hoy o ayer
  /// - Advertencia (AppColors.warning): Más de 1 día de antigüedad
  Color _calcularColorFecha(int? millis) {
    if (millis == null) return AppColors.textSecondary;

    final fechaOt = DateTime.fromMillisecondsSinceEpoch(millis);
    final hoy = DateTime.now();
    final diferenciaDias = hoy.difference(fechaOt).inDays;

    // Si tiene más de 1 día → naranja (advertencia)
    if (diferenciaDias > 1) {
      return AppColors.warning; // Naranja
    }

    // Hoy o ayer → azul normal
    return AppColors.primary;
  }

  /// Header: Título (izq) + Fecha (der)
  Widget _buildHeader() {
    final fechaOt = _formatearFechaOt(ot.dfecha);
    final colorFecha = _calcularColorFecha(ot.dfecha);

    return Row(
      children: [
        // Título de la actividad (izquierda)
        Expanded(
          child: Text(
            actividad.cactividad ?? 'Sin descripción',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),

        const SizedBox(width: 12),

        // Fecha de la OT (derecha)
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
              fechaOt,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: colorFecha,
              ),
            ),
          ],
        ),
      ],
    );
  }

  /// Info del empleado principal (solo para Sub-Tareas)
  Widget _buildEmpleadoPrincipal() {
    final empleado = item.empleadoPrincipal;
    if (empleado == null) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.subtareaBackground,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: AppColors.subtarea.withAlpha(51),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.person,
            size: 16,
            color: AppColors.subtarea,
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Responsable:',
                  style: TextStyle(
                    fontSize: 11,
                    color: AppColors.textSecondary,
                  ),
                ),
                Text(
                  empleado.cnombreemp ?? 'Sin nombre',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.subtarea,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Tiempo trabajado
  Widget _buildTiempoTrabajado() {
    return Row(
      children: [
        const Icon(
          Icons.access_time,
          size: 16,
          color: AppColors.textSecondary,
        ),
        const SizedBox(width: 6),
        Text(
          _formatearMinutos(_minutosEstimados!),
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: AppColors.textSecondary,
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

  /// Footer: Horas (inicio y/o fin) + Chevron
  Widget _buildFooter(_ConfigEstado config) {
    return Row(
      children: [
        // Horas de inicio y fin
        if (_mostrarHoraInicio || _mostrarHoraFin)
          Expanded(
            child: Wrap(
              spacing: 12,
              runSpacing: 4,
              children: [
                // Hora de inicio
                if (_mostrarHoraInicio)
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.access_time_filled,
                        size: 16,
                        color: AppColors.textSecondary,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Inicio: ${_formatearHoraInicio(actividad.dtiempoinicio)}',
                        style: const TextStyle(
                          fontSize: 14,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),

                // Hora de fin
                if (_mostrarHoraFin)
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.access_time,
                        size: 16,
                        color: AppColors.textSecondary,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Fin: ${_formatearHoraInicio(actividad.dtiempofin)}',
                        style: const TextStyle(
                          fontSize: 14,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          )
        else
          const Spacer(),

        // Chevron
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
