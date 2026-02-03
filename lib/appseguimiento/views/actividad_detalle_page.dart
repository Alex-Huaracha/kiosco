import 'dart:async';
import 'package:flutter/material.dart';
import 'package:hgtrack/appseguimiento/model/hgempleadomantenimiento_model.dart';
import 'package:hgtrack/appseguimiento/model/hgdetalleordentrabajodto_model.dart';
import 'package:hgtrack/appseguimiento/model/hgordentrabajodto_model.dart';
import 'package:hgtrack/appseguimiento/model/actividad_tracking_state.dart';
import 'package:hgtrack/appseguimiento/service/actividad_local_storage_service.dart';
import 'package:hgtrack/appseguimiento/service/tracking_service_actividades_empleado.dart';
import 'package:hgtrack/utils/app_colors.dart';

/// Pantalla de detalle de actividad con control de tiempo
/// Permite iniciar, pausar, reanudar y finalizar actividades
class ActividadDetallePage extends StatefulWidget {
  final HgDetalleOrdenTrabajoDto actividad;
  final HgOrdenTrabajoDto ordentrabajo;
  final HgEmpleadoMantenimientoDto empleado;

  const ActividadDetallePage({
    super.key,
    required this.actividad,
    required this.ordentrabajo,
    required this.empleado,
  });

  @override
  State<ActividadDetallePage> createState() => _ActividadDetallePageState();
}

class _ActividadDetallePageState extends State<ActividadDetallePage> {
  final _storageService = ActividadLocalStorageService();
  final _observacionesController = TextEditingController();

  ActividadTrackingState? _trackingState;
  Timer? _refreshTimer;
  bool _isLoading = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadState();
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    _observacionesController.dispose();
    super.dispose();
  }

  /// Carga el estado guardado o crea uno nuevo
  Future<void> _loadState() async {
    setState(() => _isLoading = true);

    try {
      final savedState = await _storageService.loadState(widget.actividad.id!);

      setState(() {
        _trackingState =
            savedState ?? ActividadTrackingState.inicial(widget.actividad.id!);
        _observacionesController.text = _trackingState?.observaciones ?? '';
        _isLoading = false;
      });

      // No hay timer automático según tus especificaciones
    } catch (e) {
      print('Error al cargar estado: $e');
      setState(() {
        _trackingState = ActividadTrackingState.inicial(widget.actividad.id!);
        _isLoading = false;
      });
    }
  }

  /// Guarda el estado actual
  Future<void> _saveState() async {
    if (_trackingState == null) return;

    try {
      await _storageService.saveState(_trackingState!);
    } catch (e) {
      print('Error al guardar estado: $e');
    }
  }

  /// Acción: Iniciar actividad
  Future<void> _onIniciar() async {
    if (_trackingState == null) return;

    final confirmar = await _mostrarDialogConfirmacion(
      titulo: '¿Iniciar actividad?',
      mensaje: 'Se registrará el tiempo de inicio.',
      textoConfirmar: 'Iniciar',
    );

    if (confirmar != true) return;

    try {
      setState(() {
        _trackingState = _trackingState!.iniciar();
      });
      await _saveState();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Actividad iniciada'),
            backgroundColor: AppColors.success,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  /// Acción: Pausar actividad
  Future<void> _onPausar() async {
    if (_trackingState == null) return;

    try {
      setState(() {
        _trackingState = _trackingState!.pausar();
      });
      await _saveState();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Actividad pausada'),
            backgroundColor: AppColors.warning,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  /// Acción: Reanudar actividad
  Future<void> _onReanudar() async {
    if (_trackingState == null) return;

    try {
      setState(() {
        _trackingState = _trackingState!.reanudar();
      });
      await _saveState();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Actividad reanudada'),
            backgroundColor: AppColors.success,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  /// Acción: Finalizar actividad
  Future<void> _onFinalizar() async {
    if (_trackingState == null) return;

    // Validar tiempo mínimo
    final tiempoTotal = _trackingState!.tiempoTotalTrabajado;
    if (tiempoTotal.inSeconds < 60) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Debe trabajar al menos 1 minuto antes de finalizar'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    // Mostrar dialog de confirmación con resumen
    final confirmar = await _mostrarDialogFinalizacion();
    if (confirmar != true) return;

    setState(() => _isSaving = true);

    try {
      // Finalizar con observaciones actuales
      _trackingState!.finalizar(
        observacionesFinales: _observacionesController.text.trim(),
      );

      // Enviar al backend
      final estadoFinalizado = _trackingState!;
      final service = TrackingServiceActividadesEmpleado();

      // Calcular datos para el request
      final DateTime fechaInicio = estadoFinalizado.periodos.first.inicio;
      final DateTime fechaFin = DateTime.now();
      final int minutosTotal = estadoFinalizado.tiempoTotalTrabajado.inMinutes;

      print('Enviando actividad al backend:');
      print('  - ID: ${widget.actividad.id}');
      print('  - Empleado: ${widget.empleado.id}');
      print('  - Inicio: $fechaInicio');
      print('  - Fin: $fechaFin');
      print('  - Minutos: $minutosTotal');

      // Llamar al servicio
      final resultado = await service.finalizarActividad(
        actividad: widget.actividad,
        empleado: widget.empleado,
        tiempoInicio: fechaInicio,
        tiempoFin: fechaFin,
        minutosEmpleado: minutosTotal,
        observaciones: _observacionesController.text.trim(),
      );

      if (resultado == null) {
        // Error al enviar al backend
        setState(() => _isSaving = false);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text(
                'Error al enviar al servidor. Los datos se guardaron localmente. '
                'Reintenta más tarde.',
              ),
              backgroundColor: AppColors.warning,
              duration: const Duration(seconds: 6),
              action: SnackBarAction(
                label: 'Reintentar',
                textColor: Colors.white,
                onPressed: _onFinalizar,
              ),
            ),
          );
        }
        return; // No limpiar el storage local (para retry)
      }

      // Éxito: limpiar estado local
      await _storageService.clearState(widget.actividad.id!);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Actividad finalizada correctamente'),
            backgroundColor: AppColors.success,
          ),
        );

        // Volver a la pantalla anterior indicando que se finalizó
        Navigator.pop(context, true);
      }
    } catch (e) {
      setState(() => _isSaving = false);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al finalizar: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  /// Actualiza observaciones
  void _onObservacionesChanged(String value) {
    if (_trackingState == null) return;

    setState(() {
      _trackingState = _trackingState!.actualizarObservaciones(value.trim());
    });
    _saveState();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) async {
        if (didPop) return;
        final shouldPop = await _onWillPop();
        if (shouldPop && context.mounted) {
          Navigator.of(context).pop();
        }
      },
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          title: Text(
            widget.actividad.cactividad ?? 'Detalle de Actividad',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          centerTitle: true,
        ),
        body: _isLoading
            ? const Center(
                child: CircularProgressIndicator(color: AppColors.primary),
              )
            : _isSaving
                ? _buildSavingOverlay()
                : _buildBody(),
      ),
    );
  }

  Widget _buildSavingOverlay() {
    return Center(
      child: Card(
        margin: const EdgeInsets.all(24),
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(color: AppColors.primary),
              const SizedBox(height: 24),
              const Text(
                'Finalizando actividad...',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Enviando datos al servidor',
                style: TextStyle(
                  fontSize: 14,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBody() {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Determinar si es horizontal (landscape) o vertical (portrait)
        // Consideramos horizontal si el ancho es mayor a 800px
        final isHorizontal = constraints.maxWidth > 800;

        if (isHorizontal) {
          return _buildHorizontalLayout();
        } else {
          return _buildVerticalLayout();
        }
      },
    );
  }

  /// Layout vertical (portrait) - Una columna con todos los elementos
  Widget _buildVerticalLayout() {
    return Center(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 800),
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // 1. Info de la OT
            _buildInfoOtCard(),
            const SizedBox(height: 16),

            // 2. Info de la Actividad
            _buildInfoActividadCard(),
            const SizedBox(height: 16),

            // 3. Estado Actual
            _buildEstadoActualCard(),
            const SizedBox(height: 16),

            // 4. Acciones
            _buildAccionesCard(),
            const SizedBox(height: 16),

            // 5. Observaciones
            _buildObservacionesField(),
            const SizedBox(height: 16),

            // 6. Historial
            _buildHistorialTimeline(),

            const SizedBox(height: 80),
          ],
        ),
      ),
    );
  }

  /// Layout horizontal (landscape) - Dos columnas
  Widget _buildHorizontalLayout() {
    return Center(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 1400),
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Columna 1: Info OT, Info Actividad, Observaciones (60%)
                Expanded(
                  flex: 3,
                  child: Column(
                    children: [
                      // 1. Info de la OT
                      _buildInfoOtCard(),
                      const SizedBox(height: 16),

                      // 2. Info de la Actividad
                      _buildInfoActividadCard(),
                      const SizedBox(height: 16),

                      // 5. Observaciones
                      _buildObservacionesField(),
                    ],
                  ),
                ),

                const SizedBox(width: 16),

                // Columna 2: Estado Actual, Acciones, Historial (40%)
                Expanded(
                  flex: 2,
                  child: Column(
                    children: [
                      // 3. Estado Actual
                      _buildEstadoActualCard(),
                      const SizedBox(height: 16),

                      // 4. Acciones
                      _buildAccionesCard(),
                      const SizedBox(height: 16),

                      // 6. Historial
                      _buildHistorialTimeline(),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 80),
          ],
        ),
      ),
    );
  }

  /// Card con información de la OT
  Widget _buildInfoOtCard() {
    final ot = widget.ordentrabajo;

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header con placa y OT
            Row(
              children: [
                const Icon(
                  Icons.local_shipping,
                  size: 20,
                  color: AppColors.primary,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '${ot.idplacatracto ?? "N/A"} • OT-${ot.id}',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),
            const Divider(color: AppColors.divider, thickness: 1),
            const SizedBox(height: 12),

            // Detalles de la OT
            _buildInfoRow(
              Icons.calendar_today,
              'Fecha',
              _formatearFecha(ot.dfecha),
            ),
            const SizedBox(height: 8),
            _buildInfoRow(
              Icons.person,
              'Supervisor',
              ot.supervisor ?? 'N/A',
            ),
            const SizedBox(height: 8),
            _buildInfoRow(
              Icons.warehouse,
              'Taller',
              ot.taller ?? 'N/A',
            ),
            const SizedBox(height: 8),
            _buildInfoRow(
              Icons.speed,
              'Kilometraje',
              ot.nkilometraje != null ? '${ot.nkilometraje} km' : 'N/A',
            ),
            const SizedBox(height: 8),
            _buildInfoRow(
              Icons.business,
              'Centro Costo',
              ot.ccentrocosto ?? 'N/A',
            ),
          ],
        ),
      ),
    );
  }

  /// Card con información de la actividad
  Widget _buildInfoActividadCard() {
    final act = widget.actividad;
    final emp = widget.empleado;

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            const Row(
              children: [
                Icon(
                  Icons.assignment,
                  size: 20,
                  color: AppColors.primary,
                ),
                SizedBox(width: 8),
                Text(
                  'Detalles de la Actividad',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),
            const Divider(color: AppColors.divider, thickness: 1),
            const SizedBox(height: 12),

            // Detalles
            if (act.csistema != null || act.csubsistema != null) ...[
              _buildInfoRow(
                Icons.category,
                'Sistema',
                [
                  if (act.csistema != null) act.csistema!,
                  if (act.csubsistema != null) act.csubsistema!,
                ].join(' • '),
              ),
              const SizedBox(height: 8),
            ],

            _buildInfoRow(
              Icons.person,
              'Asignado a',
              emp.nombreCompleto,
            ),
            const SizedBox(height: 8),
            _buildInfoRow(
              Icons.badge,
              'Cargo',
              emp.cargo ?? 'N/A',
            ),
            const SizedBox(height: 8),
            _buildInfoRow(
              Icons.calendar_month,
              'Registrado',
              _formatearFecha(act.dfecreg),
            ),

            // Badge Falla Reportada
            if (act.bfallareportada == true) ...[
              const SizedBox(height: 12),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.error,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.warning, size: 16, color: Colors.white),
                    SizedBox(width: 6),
                    Text(
                      'Falla Reportada',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// Card con estado actual (solo badge)
  Widget _buildEstadoActualCard() {
    if (_trackingState == null) {
      return const SizedBox.shrink();
    }

    final estado = _trackingState!.estado;

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            const Text(
              'Estado Actual',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: AppColors.textPrimary,
              ),
            ),

            const SizedBox(height: 12),

            // Badge de estado en contenedor gris
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 16),
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Center(
                child: _buildEstadoBadge(estado),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Card con acciones (botones)
  Widget _buildAccionesCard() {
    if (_trackingState == null) {
      return const SizedBox.shrink();
    }

    final estado = _trackingState!.estado;

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            const Text(
              'Acciones',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: AppColors.textPrimary,
              ),
            ),

            const SizedBox(height: 12),

            // Botones de acción
            _buildBotonesAccion(estado),
          ],
        ),
      ),
    );
  }

  /// Botones de acción según el estado
  Widget _buildBotonesAccion(EstadoActividad estado) {
    switch (estado) {
      case EstadoActividad.noIniciada:
        return SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: _onIniciar,
            icon: const Icon(Icons.play_arrow),
            label: const Text('Iniciar Actividad'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              textStyle: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        );

      case EstadoActividad.enProceso:
        return Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: _onPausar,
                icon: const Icon(Icons.pause),
                label: const Text('Pausar'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.warning,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: _onFinalizar,
                icon: const Icon(Icons.stop),
                label: const Text('Finalizar'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.error,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ),
          ],
        );

      case EstadoActividad.pausada:
        return Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: _onReanudar,
                icon: const Icon(Icons.play_arrow),
                label: const Text('Reanudar'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.success,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: _onFinalizar,
                icon: const Icon(Icons.stop),
                label: const Text('Finalizar'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.error,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ),
          ],
        );

      case EstadoActividad.finalizada:
        return const Center(
          child: Text(
            'Actividad finalizada',
            style: TextStyle(
              fontSize: 16,
              color: AppColors.textSecondary,
              fontStyle: FontStyle.italic,
            ),
          ),
        );
    }
  }

  /// Badge de estado visual
  Widget _buildEstadoBadge(EstadoActividad estado) {
    Color color;
    String texto;
    IconData icono;

    switch (estado) {
      case EstadoActividad.noIniciada:
        color = AppColors.textSecondary;
        texto = 'No Iniciada';
        icono = Icons.radio_button_unchecked;
        break;
      case EstadoActividad.enProceso:
        color = AppColors.success;
        texto = 'En Proceso';
        icono = Icons.play_circle;
        break;
      case EstadoActividad.pausada:
        color = AppColors.warning;
        texto = 'En Pausa';
        icono = Icons.pause_circle;
        break;
      case EstadoActividad.finalizada:
        color = AppColors.primary;
        texto = 'Finalizada';
        icono = Icons.check_circle;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icono, color: Colors.white, size: 24),
          const SizedBox(width: 8),
          Text(
            texto,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  /// Campo de observaciones
  Widget _buildObservacionesField() {
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
              controller: _observacionesController,
              onChanged: _onObservacionesChanged,
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

  /// Timeline de historial (continuará en siguiente mensaje)
  Widget _buildHistorialTimeline() {
    if (_trackingState == null || _trackingState!.periodos.isEmpty) {
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

    final periodos = _trackingState!.periodos;

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

              return _buildTimelineItem(periodo, isLast);
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
                  _formatearDuracion(_trackingState!.tiempoTotalTrabajado),
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

  Widget _buildTimelineItem(PeriodoTrabajo periodo, bool isLast) {
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

  /// Helpers de formateo
  Widget _buildInfoRow(IconData icono, String label, String value) {
    return Row(
      children: [
        Icon(icono, size: 16, color: AppColors.textSecondary),
        const SizedBox(width: 8),
        Text(
          '$label: ',
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: AppColors.textSecondary,
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              color: AppColors.textPrimary,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  String _formatearFecha(int? millis) {
    if (millis == null) return 'N/A';
    final fecha = DateTime.fromMillisecondsSinceEpoch(millis);
    String dosDigitos(int n) => n.toString().padLeft(2, '0');
    return '${dosDigitos(fecha.day)}/${dosDigitos(fecha.month)}/${fecha.year}';
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

  /// Dialogs
  Future<bool?> _mostrarDialogConfirmacion({
    required String titulo,
    required String mensaje,
    required String textoConfirmar,
  }) {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(titulo),
        content: Text(mensaje),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(textoConfirmar),
          ),
        ],
      ),
    );
  }

  Future<bool?> _mostrarDialogFinalizacion() {
    final tiempoTotal = _trackingState!.tiempoTotalTrabajado;
    final cantPausas = _trackingState!.cantidadPausas;

    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('¿Finalizar actividad?'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Resumen de la actividad:'),
            const SizedBox(height: 12),
            _buildResumenRow(
                'Tiempo trabajado', _formatearDuracion(tiempoTotal)),
            _buildResumenRow('Pausas realizadas', cantPausas.toString()),
            if (_observacionesController.text.isEmpty) ...[
              const SizedBox(height: 12),
              const Text(
                'No hay observaciones registradas.',
                style: TextStyle(
                  fontSize: 13,
                  fontStyle: FontStyle.italic,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
            ),
            child: const Text('Sí, Finalizar'),
          ),
        ],
      ),
    );
  }

  Widget _buildResumenRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.w500),
          ),
          Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: AppColors.primary,
            ),
          ),
        ],
      ),
    );
  }

  Future<bool> _onWillPop() async {
    if (_trackingState == null) return true;

    // Si está finalizada, puede salir
    if (_trackingState!.estado == EstadoActividad.finalizada) {
      return true;
    }

    // Si está en proceso o pausada, confirmar
    if (_trackingState!.estado == EstadoActividad.enProceso ||
        _trackingState!.estado == EstadoActividad.pausada) {
      final confirmar = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('⚠️ Actividad en progreso'),
          content: const Text(
            'Si sales ahora, el progreso se guardará.\nPodrás continuar luego.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Quedarme'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Salir'),
            ),
          ],
        ),
      );

      return confirmar ?? false;
    }

    return true;
  }
}
