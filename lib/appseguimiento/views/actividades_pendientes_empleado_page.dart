import 'package:flutter/material.dart';
import 'package:hgtrack/appseguimiento/model/hgempleadomantenimiento_model.dart';
import 'package:hgtrack/appseguimiento/model/hgdetalleordentrabajodto_model.dart';
import 'package:hgtrack/appseguimiento/model/hgordentrabajodto_model.dart';
import 'package:hgtrack/appseguimiento/service/tracking_service_actividades_empleado.dart';
import 'package:hgtrack/appseguimiento/views/actividad_detalle_page.dart';
import 'package:hgtrack/utils/app_colors.dart';

/// Pantalla principal: Lista de actividades pendientes del empleado
/// Muestra todas las actividades activas (No Iniciadas + En Proceso) sin agrupar por OT
/// Al hacer tap en una actividad → navega a pantalla de detalle
class ActividadesPendientesEmpleadoPage extends StatefulWidget {
  final HgEmpleadoMantenimientoDto empleado;

  const ActividadesPendientesEmpleadoPage({
    super.key,
    required this.empleado,
  });

  @override
  State<ActividadesPendientesEmpleadoPage> createState() =>
      _ActividadesPendientesEmpleadoPageState();
}

class _ActividadesPendientesEmpleadoPageState
    extends State<ActividadesPendientesEmpleadoPage> {
  List<ActividadConOt>? actividadesPendientes;
  bool isLoading = true;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    loadActividades();
  }

  Future<void> loadActividades() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      final service = TrackingServiceActividadesEmpleado();
      final ordenesConActividades =
          await service.getOrdenesTrabajoConActividades(
        widget.empleado.id.toString(),
      );

      if (ordenesConActividades == null || ordenesConActividades.isEmpty) {
        setState(() {
          isLoading = false;
          errorMessage = 'No tienes actividades asignadas';
        });
        return;
      }

      // Desagrupar OTs: convertir a lista plana de actividades con su OT
      List<ActividadConOt> todasActividades = [];
      for (var orden in ordenesConActividades) {
        for (var actividad in orden.actividades) {
          todasActividades.add(
            ActividadConOt(
              actividad: actividad,
              ordentrabajo: orden.ordentrabajo,
            ),
          );
        }
      }

      // Filtrar solo actividades activas (no cerradas, incluye backlog)
      List<ActividadConOt> actividadesActivas = todasActividades.where((item) {
        return item.actividad.bcerrada == false;
      }).toList();

      if (actividadesActivas.isEmpty) {
        setState(() {
          isLoading = false;
          errorMessage = 'No tienes actividades pendientes';
        });
        return;
      }

      // Ordenar actividades por prioridad
      _ordenarActividades(actividadesActivas);

      setState(() {
        isLoading = false;
        actividadesPendientes = actividadesActivas;
      });
    } catch (e) {
      setState(() {
        isLoading = false;
        errorMessage = 'Error al cargar actividades: $e';
      });
    }
  }

  /// Ordena actividades por prioridad:
  /// 1. Actividades normales (no backlog) primero
  /// 2. Backlog al final
  /// Dentro de cada grupo:
  ///   - En Proceso primero
  ///   - No Iniciadas segundo
  ///   - Por fecha más reciente
  void _ordenarActividades(List<ActividadConOt> actividades) {
    actividades.sort((a, b) {
      // Prioridad MÁXIMA: Backlog siempre al final
      bool aBacklog = a.actividad.bbacklog == true;
      bool bBacklog = b.actividad.bbacklog == true;
      if (aBacklog && !bBacklog) return 1; // a es backlog, va al final
      if (!aBacklog && bBacklog) return -1; // b es backlog, va al final

      // Prioridad 1: En proceso (iniciada pero no finalizada)
      bool aEnProceso =
          a.actividad.dtiempoinicio != null && a.actividad.dtiempofin == null;
      bool bEnProceso =
          b.actividad.dtiempoinicio != null && b.actividad.dtiempofin == null;
      if (aEnProceso && !bEnProceso) return -1;
      if (!aEnProceso && bEnProceso) return 1;

      // Prioridad 2: No iniciadas (pendientes sin tiempo inicio)
      bool aNoIniciada = a.actividad.dtiempoinicio == null;
      bool bNoIniciada = b.actividad.dtiempoinicio == null;
      if (aNoIniciada && !bNoIniciada) return -1;
      if (!aNoIniciada && bNoIniciada) return 1;

      // Mismo nivel: ordenar por fecha de registro (más reciente primero)
      int fechaA = a.actividad.dfecreg ?? 0;
      int fechaB = b.actividad.dfecreg ?? 0;
      return fechaB.compareTo(fechaA);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Mis Actividades Pendientes'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: loadActividades,
            tooltip: 'Actualizar',
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (isLoading) {
      return const Center(
        child: CircularProgressIndicator(
          color: AppColors.primary,
          strokeWidth: 3,
        ),
      );
    }

    if (errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.assignment_outlined,
                size: 72,
                color: AppColors.textSecondary,
              ),
              const SizedBox(height: 24),
              Text(
                errorMessage!,
                style: const TextStyle(
                  fontSize: 18,
                  color: AppColors.textPrimary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: loadActividades,
                icon: const Icon(Icons.refresh),
                label: const Text('Reintentar'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 16,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Center(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 800),
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Card del empleado
            _buildEmpleadoCard(),

            const SizedBox(height: 16),

            // Título de sección con contador
            _buildTituloSeccion(),

            const SizedBox(height: 12),

            // Lista de actividades
            ...actividadesPendientes!.map((item) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: ActividadConOtCard(
                  item: item,
                  onTap: () => _onActividadTapped(item),
                ),
              );
            }),

            const SizedBox(height: 80), // Espacio final para scroll
          ],
        ),
      ),
    );
  }

  /// Card con información del empleado (foto, nombre, cargo)
  Widget _buildEmpleadoCard() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            // Avatar con iniciales
            EmpleadoAvatar(iniciales: widget.empleado.iniciales),
            const SizedBox(width: 16),
            // Información del empleado
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.empleado.nombreCompleto,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    widget.empleado.cargo ?? 'Sin cargo',
                    style: const TextStyle(
                      fontSize: 14,
                      color: AppColors.textSecondary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Título de sección con contador de actividades
  Widget _buildTituloSeccion() {
    final count = actividadesPendientes?.length ?? 0;
    return Row(
      children: [
        const Icon(
          Icons.assignment,
          size: 20,
          color: AppColors.primary,
        ),
        const SizedBox(width: 8),
        Text(
          'Actividades del día',
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: AppColors.primary,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            '$count',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
        ),
      ],
    );
  }

  /// Callback al hacer tap en una actividad
  void _onActividadTapped(ActividadConOt item) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ActividadDetallePage(
          actividad: item.actividad,
          ordentrabajo: item.ordentrabajo,
          empleado: widget.empleado,
        ),
      ),
    );

    // Si se finalizó la actividad, recargar la lista
    if (result == true && mounted) {
      loadActividades();
    }
  }
}

/// Avatar circular con iniciales del empleado
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

/// Clase helper para mantener la relación entre actividad + OT
class ActividadConOt {
  final HgDetalleOrdenTrabajoDto actividad;
  final HgOrdenTrabajoDto ordentrabajo;

  ActividadConOt({
    required this.actividad,
    required this.ordentrabajo,
  });
}

/// Card individual de actividad con información de la OT
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

  /// Determina el estado visual de la actividad
  EstadoActividad get _estado {
    // Backlog (prioridad máxima en detección)
    if (actividad.bbacklog == true) {
      return EstadoActividad.backlog;
    }

    // En proceso (tiene inicio pero no fin)
    if (actividad.dtiempoinicio != null && actividad.dtiempofin == null) {
      return EstadoActividad.enProceso;
    }

    // No iniciada (pendiente)
    return EstadoActividad.noIniciada;
  }

  /// Configuración de colores según estado
  _ConfigEstado get _config {
    switch (_estado) {
      case EstadoActividad.noIniciada:
        return _ConfigEstado(
          color: AppColors.textSecondary,
          texto: 'No Iniciada',
          icono: Icons.radio_button_unchecked,
        );
      case EstadoActividad.enProceso:
        return _ConfigEstado(
          color: AppColors.primary,
          texto: 'En Proceso',
          icono: Icons.play_circle,
        );
      case EstadoActividad.backlog:
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
      _minutosEstimados != null && _estado == EstadoActividad.enProceso;

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

              // 3. Tiempo trabajado (si aplica)
              if (_mostrarTiempo) ...[
                _buildTiempoTrabajado(),
                const SizedBox(height: 6),
              ],

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

              // 6. Hora inicio + Chevron
              _buildFooter(config),
            ],
          ),
        ),
      ),
    );
  }

  /// Mini-header con Placa + OT + Badge Estado
  Widget _buildMiniHeader(_ConfigEstado config) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.bannerBackground,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: AppColors.primary.withAlpha(51),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.max,
        children: [
          const Icon(
            Icons.local_shipping,
            size: 16,
            color: AppColors.primary,
          ),
          const SizedBox(width: 6),
          Text(
            '${ot.idplacatracto ?? "N/A"} • OT-${ot.id ?? "N/A"}',
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: AppColors.primary,
            ),
          ),
          const Spacer(),
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

/// Enumeración de estados de actividad
enum EstadoActividad {
  noIniciada,
  enProceso,
  backlog,
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
