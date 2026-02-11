import 'dart:async';

import 'package:flutter/material.dart';

import 'package:hgtrack/core/network/api_client.dart';
import 'package:hgtrack/core/network/connectivity_service.dart';
import 'package:hgtrack/core/theme/app_colors.dart';
import 'package:hgtrack/features/authentication/data/models/empleado.dart';
import 'package:hgtrack/features/time_tracking/data/models/detalle_orden_trabajo.dart';
import 'package:hgtrack/features/time_tracking/data/models/orden_trabajo.dart';
import 'package:hgtrack/features/time_tracking/data/models/pending_sync_activity.dart';
import 'package:hgtrack/features/time_tracking/data/services/activity_service.dart';
import 'package:hgtrack/features/time_tracking/data/services/local_storage_service.dart';
import 'package:hgtrack/features/time_tracking/data/services/pending_sync_service.dart';
import 'package:hgtrack/features/time_tracking/domain/tracking_state.dart';
import 'package:hgtrack/features/time_tracking/presentation/widgets/actividad_con_ot_model.dart'
    hide EstadoActividadCard;
import 'package:hgtrack/features/time_tracking/presentation/widgets/activity_info_card.dart';
import 'package:hgtrack/features/time_tracking/presentation/widgets/current_state_card.dart';
import 'package:hgtrack/features/time_tracking/presentation/widgets/observations_field.dart';
import 'package:hgtrack/features/time_tracking/presentation/widgets/order_info_card.dart';
import 'package:hgtrack/features/time_tracking/presentation/widgets/pause_reason_dialog.dart';
import 'package:hgtrack/features/time_tracking/presentation/widgets/timeline_widget.dart';

/// Pantalla de detalle de actividad con control de tiempo
/// Permite iniciar, pausar, reanudar y finalizar actividades
/// Soporta tanto Tareas Principales (TP) como Sub-Tareas (ST)
class ActivityDetailPage extends StatefulWidget {
  final HgDetalleOrdenTrabajoDto actividad;
  final HgOrdenTrabajoDto ordentrabajo;
  final HgEmpleadoMantenimientoDto empleado;

  /// Información completa de la actividad (incluye tipo TP/ST, empleadoPrincipal, etc.)
  /// Puede ser null para compatibilidad con navegación directa sin el modelo completo
  final ActividadConOt? actividadConOt;

  const ActivityDetailPage({
    super.key,
    required this.actividad,
    required this.ordentrabajo,
    required this.empleado,
    this.actividadConOt,
  });

  @override
  State<ActivityDetailPage> createState() => _ActivityDetailPageState();
}

class _ActivityDetailPageState extends State<ActivityDetailPage> {
  final _storageService = ActividadLocalStorageService();
  final _observacionesController = TextEditingController();

  ActividadTrackingState? _trackingState;
  Timer? _refreshTimer;
  bool _isLoading = true;
  bool _isSaving = false;

  // Conectividad
  bool _isOnline = true;
  StreamSubscription<bool>? _connectivitySubscription;

  @override
  void initState() {
    super.initState();
    _initConnectivity();
    _loadState();
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    _connectivitySubscription?.cancel();
    _observacionesController.dispose();
    super.dispose();
  }

  /// Inicializa suscripcion a ConnectivityService
  void _initConnectivity() {
    final connectivity = ConnectivityService();
    _isOnline = connectivity.isOnline;

    _connectivitySubscription = connectivity.onlineStream.listen((isOnline) {
      if (mounted) {
        setState(() => _isOnline = isOnline);
      }
    });
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

      // Iniciar timer si está en proceso (para actualizar UI cada segundo)
      _startTimerIfNeeded();
    } catch (e) {
      print('Error al cargar estado: $e');
      setState(() {
        _trackingState = ActividadTrackingState.inicial(widget.actividad.id!);
        _isLoading = false;
      });
    }
  }

  /// Inicia un timer de actualización si la actividad está en proceso
  void _startTimerIfNeeded() {
    _refreshTimer?.cancel();

    if (_trackingState?.estado == EstadoActividad.enProceso) {
      _refreshTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
        if (_trackingState?.estado == EstadoActividad.enProceso) {
          setState(() {}); // Actualizar UI para reflejar tiempo transcurrido
        } else {
          timer.cancel();
        }
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
      _startTimerIfNeeded(); // Iniciar timer para actualizar UI

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

    // 1. Mostrar dialog para seleccionar motivo
    final motivo = await PauseReasonDialog.show(context);
    
    // Si el usuario canceló, no hacer nada
    if (motivo == null) return;

    // 2. Verificar conexión (requerida para pausar)
    if (!_isOnline) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Se requiere conexión a internet para pausar'),
            backgroundColor: AppColors.error,
            duration: Duration(seconds: 3),
          ),
        );
      }
      return;
    }

    setState(() => _isSaving = true);

    try {
      final ahora = DateTime.now();
      
      // 3. Registrar pausa en el backend
      int? idPausaBackend;
      
      if (widget.actividadConOt?.esSubTarea ?? false) {
        // Sub-Tarea (ST) - usar endpoint de asignación
        final idAsignacion = widget.actividadConOt?.idAsignacion;
        if (idAsignacion == null) {
          throw Exception('ID de asignación no disponible para Sub-Tarea');
        }
        
        idPausaBackend = await TrackingApi().registrarPausaST(
          idDetalleAsignacion: idAsignacion,
          motivo: motivo,
          tiempoInicio: ahora,
        );
      } else {
        // Tarea Principal (TP) - usar endpoint de detalle orden trabajo
        idPausaBackend = await TrackingApi().registrarPausaTP(
          idDetalleOrdenTrabajo: widget.actividad.id!,
          motivo: motivo,
          tiempoInicio: ahora,
        );
      }

      if (idPausaBackend == null) {
        throw Exception('No se pudo registrar la pausa en el servidor');
      }

      // 4. Actualizar estado local con motivo e ID de pausa
      setState(() {
        _trackingState = _trackingState!.pausar(
          motivo: motivo,
          idPausaBackend: idPausaBackend,
        );
      });
      
      await _saveState();
      _refreshTimer?.cancel(); // Detener timer al pausar

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Actividad pausada: $motivo'),
            backgroundColor: AppColors.warning,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al pausar: $e'),
            backgroundColor: AppColors.error,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } finally {
      setState(() => _isSaving = false);
    }
  }

  /// Acción: Reanudar actividad
  Future<void> _onReanudar() async {
    if (_trackingState == null) return;

    // 1. Verificar que exista ID de pausa en backend
    final idPausaBackend = _trackingState!.idPausaBackend;
    if (idPausaBackend == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Error: No se encontró el ID de pausa'),
            backgroundColor: AppColors.error,
            duration: Duration(seconds: 3),
          ),
        );
      }
      return;
    }

    // 2. Verificar conexión (requerida para reanudar)
    if (!_isOnline) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Se requiere conexión a internet para reanudar'),
            backgroundColor: AppColors.error,
            duration: Duration(seconds: 3),
          ),
        );
      }
      return;
    }

    setState(() => _isSaving = true);

    try {
      final ahora = DateTime.now();

      // 3. Reanudar pausa en el backend
      bool exitoso = false;

      if (widget.actividadConOt?.esSubTarea ?? false) {
        // Sub-Tarea (ST) - usar endpoint de asignación
        exitoso = await TrackingApi().reanudarPausaST(
          idPausa: idPausaBackend,
          tiempoFin: ahora,
        );
      } else {
        // Tarea Principal (TP) - usar endpoint de detalle orden trabajo
        exitoso = await TrackingApi().reanudarPausaTP(
          idPausa: idPausaBackend,
          tiempoFin: ahora,
        );
      }

      if (!exitoso) {
        throw Exception('No se pudo reanudar la pausa en el servidor');
      }

      // 4. Actualizar estado local (limpia idPausaBackend automáticamente)
      setState(() {
        _trackingState = _trackingState!.reanudar();
      });
      
      await _saveState();
      _startTimerIfNeeded(); // Reiniciar timer al reanudar

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
            content: Text('Error al reanudar: $e'),
            backgroundColor: AppColors.error,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } finally {
      setState(() => _isSaving = false);
    }
  }

  /// Acción: Cancelar actividad (antes de 5 minutos)
  Future<void> _onCancelar() async {
    if (_trackingState == null) return;

    final confirmar = await _mostrarDialogConfirmacion(
      titulo: '¿Cancelar actividad?',
      mensaje:
          'Se descartará todo el progreso registrado y la actividad volverá a estado inicial.',
      textoConfirmar: 'Sí, Cancelar',
    );

    if (confirmar != true) return;

    try {
      setState(() {
        _trackingState = _trackingState!.cancelar();
      });
      await _saveState();
      _refreshTimer?.cancel(); // Detener timer al cancelar

      // Limpiar observaciones
      _observacionesController.clear();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Actividad cancelada. Progreso descartado.'),
            backgroundColor: AppColors.warning,
            duration: Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al cancelar: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  /// Acción: Finalizar actividad (soporta TP y ST)
  Future<void> _onFinalizar() async {
    if (_trackingState == null) return;

    // Validar tiempo mínimo de 5 minutos
    final tiempoTotal = _trackingState!.tiempoTotalTrabajado;
    if (tiempoTotal.inMinutes < 5) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Debe trabajar al menos 5 minutos antes de finalizar'),
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
      _trackingState = _trackingState!.finalizar(
        observacionesFinales: _observacionesController.text.trim(),
      );

      // Enviar al backend
      final estadoFinalizado = _trackingState!;
      final service = ActivityService();

      // Calcular datos para el request
      final DateTime fechaInicio = estadoFinalizado.periodos.first.inicio;
      final DateTime fechaFin = DateTime.now();
      final int minutosTotal = estadoFinalizado.tiempoTotalTrabajado.inMinutes;

      // Detectar si es TP o ST
      final esSubTarea = widget.actividadConOt?.esSubTarea ?? false;
      final tipoLabel = esSubTarea ? 'Sub-Tarea ST' : 'Tarea Principal TP';

      print('Enviando $tipoLabel al backend:');
      print('  - ID Detalle: ${widget.actividad.id}');
      if (esSubTarea) {
        print('  - ID Asignacion: ${widget.actividadConOt?.idAsignacion}');
      }
      print('  - Empleado: ${widget.empleado.id}');
      print('  - Inicio: $fechaInicio');
      print('  - Fin: $fechaFin');
      print('  - Minutos: $minutosTotal');

      bool exito = false;

      if (esSubTarea && widget.actividadConOt?.actividadDto != null) {
        // Sub-Tarea (ST) - usar servicio unificado
        exito = await service.finalizarActividadUnificado(
          actividadDto: widget.actividadConOt!.actividadDto!,
          empleado: widget.empleado,
          tiempoInicio: fechaInicio,
          tiempoFin: fechaFin,
          minutosEmpleado: minutosTotal,
          observaciones: _observacionesController.text.trim(),
        );
      } else {
        // Tarea Principal (TP) - usar método original
        final resultado = await service.finalizarActividad(
          actividad: widget.actividad,
          empleado: widget.empleado,
          tiempoInicio: fechaInicio,
          tiempoFin: fechaFin,
          minutosEmpleado: minutosTotal,
          observaciones: _observacionesController.text.trim(),
        );
        exito = resultado != null;
      }

      if (!exito) {
        // Error al enviar al backend - Guardar en cola de pendientes
        final pendingActivity = PendingSyncActivity(
          tipo: esSubTarea ? "ST" : "TP",
          idActividad: widget.actividad.id!,
          idAsignacion: widget.actividadConOt?.idAsignacion,
          idEmpleado: widget.empleado.id!,
          nombreActividad: widget.actividad.cactividad ?? 'Sin nombre',
          nombreEmpleado: widget.empleado.nombreCompleto,
          cargoEmpleado: widget.empleado.cargo ?? 'Sin cargo',
          fechaInicio: fechaInicio,
          fechaFin: fechaFin,
          minutosTotal: minutosTotal,
          observaciones: _observacionesController.text.trim(),
          createdAt: DateTime.now(),
        );

        final syncService = PendingSyncService();
        await syncService.addToPendingQueue(pendingActivity);

        // Limpiar el tracking state local (ya está finalizado)
        await _storageService.clearState(widget.actividad.id!);

        setState(() => _isSaving = false);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                '$tipoLabel finalizada. Se sincronizara cuando haya conexion.',
              ),
              backgroundColor: AppColors.success,
              duration: const Duration(seconds: 4),
            ),
          );

          // Volver a la lista con info de la actividad finalizada
          Navigator.pop(context, {
            'success': true,
            'actividadId': widget.actividad.id,
            'idAsignacion': widget.actividadConOt?.idAsignacion,
            'esSubTarea': esSubTarea,
          });
        }
        return;
      }

      // Éxito: limpiar estado local
      await _storageService.clearState(widget.actividad.id!);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$tipoLabel finalizada correctamente'),
            backgroundColor: AppColors.success,
          ),
        );

        // Volver a la lista con info de la actividad finalizada
        Navigator.pop(context, {
          'success': true,
          'actividadId': widget.actividad.id,
          'idAsignacion': widget.actividadConOt?.idAsignacion,
          'esSubTarea': esSubTarea,
        });
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

  /// Acción: Marcar actividad como backlog (sin completar)
  Future<void> _onMarcarBacklog() async {
    if (_trackingState == null) return;

    // Mostrar dialog de confirmación con campo opcional de observaciones
    final resultado = await _mostrarDialogBacklog();
    if (resultado == null) return; // Usuario canceló

    final observaciones = resultado['observaciones'] as String?;
    final confirmar = resultado['confirmar'] as bool? ?? false;

    if (!confirmar) return;

    setState(() => _isSaving = true);

    try {
      final service = ActivityService();

      // Enviar al backend
      final resultadoApi = await service.marcarComoBacklog(
        actividad: widget.actividad,
        observaciones: observaciones,
      );

      if (resultadoApi == null) {
        // Error al enviar al backend
        setState(() => _isSaving = false);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Error al marcar como backlog. Verifica tu conexión e intenta nuevamente.',
              ),
              backgroundColor: AppColors.error,
              duration: Duration(seconds: 4),
            ),
          );
        }
        return;
      }

      // Éxito: limpiar estado local
      await _storageService.clearState(widget.actividad.id!);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Actividad enviada a backlog para reprogramación'),
            backgroundColor: AppColors.success,
            duration: Duration(seconds: 3),
          ),
        );

        // Volver a la lista con info de backlog
        Navigator.pop(context, {
          'backlog': true,
          'actividadId': widget.actividad.id,
        });
      }
    } catch (e) {
      setState(() => _isSaving = false);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al marcar como backlog: $e'),
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
            _obtenerTituloActividad(),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          centerTitle: true,
        ),
        body: Column(
          children: [
            // Banner offline
            if (!_isOnline) _buildOfflineBanner(),

            // Contenido principal
            Expanded(
              child: _isLoading
                  ? const Center(
                      child:
                          CircularProgressIndicator(color: AppColors.primary),
                    )
                  : _isSaving
                      ? _buildSavingOverlay()
                      : _buildBody(),
            ),
          ],
        ),
      ),
    );
  }

  /// Banner rojo de sin conexion
  Widget _buildOfflineBanner() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      color: AppColors.error,
      child: const Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.wifi_off, color: Colors.white, size: 20),
          SizedBox(width: 8),
          Text(
            'Sin conexion a internet',
            style: TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
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

  /// Verifica si debe mostrar info del empleado principal (solo ST con empleado asignado)
  bool get _mostrarEmpleadoPrincipal =>
      widget.actividadConOt?.esSubTarea == true &&
      widget.actividadConOt?.empleadoPrincipal != null &&
      !widget.actividadConOt!.empleadoPrincipal!.sinAsignar;

  /// Obtiene el título apropiado para el AppBar según el tipo de actividad
  ///
  /// - Para Sub-Tareas (ST): Muestra la sub-actividad específica del empleado
  /// - Para Tareas Principales (TP): Muestra el nombre de la actividad principal
  String _obtenerTituloActividad() {
    // Si es sub-tarea y tiene sub-actividad específica, mostrarla
    if (widget.actividadConOt?.esSubTarea == true &&
        widget.actividadConOt?.subActividad != null) {
      return widget.actividadConOt!.subActividad!;
    }

    // Tarea principal o fallback
    return widget.actividad.cactividad ?? 'Detalle de Actividad';
  }

  /// Card con información del empleado principal (solo para Sub-Tareas)
  Widget _buildEmpleadoPrincipalCard() {
    final empleado = widget.actividadConOt?.empleadoPrincipal;
    if (empleado == null) return const SizedBox.shrink();

    return Card(
      elevation: 2,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border(
            left: BorderSide(
              color: AppColors.subtarea,
              width: 4,
            ),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header con badge de asistencia
            Row(
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.subtarea,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.person_outline, size: 14, color: Colors.white),
                      SizedBox(width: 4),
                      Text(
                        'Asistencia',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    widget.actividadConOt?.codigoDisplay ?? '',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: AppColors.subtarea,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Empleado principal
            Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: AppColors.subtareaBackground,
                  child: Icon(
                    Icons.person,
                    size: 24,
                    color: AppColors.subtarea,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Responsable de la tarea:',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      Text(
                        empleado.cnombreemp ?? 'Sin nombre',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (empleado.ccargoemp != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          empleado.ccargoemp!,
                          style: const TextStyle(
                            fontSize: 13,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),

            // Sub-actividad (si existe)
            if (widget.actividadConOt?.subActividad != null) ...[
              const SizedBox(height: 12),
              const Divider(color: AppColors.divider),
              const SizedBox(height: 8),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.assignment_outlined,
                    size: 18,
                    color: AppColors.subtarea,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Tu sub-actividad:',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        Text(
                          widget.actividadConOt!.subActividad!,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: AppColors.subtarea,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],

            // Tiempo estimado (si existe)
            if (widget.actividadConOt?.tiempoEstimado != null) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(
                    Icons.timer_outlined,
                    size: 16,
                    color: AppColors.textSecondary,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Tiempo estimado: ${_formatearMinutos(widget.actividadConOt!.tiempoEstimado!)}',
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// Formatea minutos a texto legible
  String _formatearMinutos(int minutos) {
    if (minutos < 60) return '$minutos min';
    final horas = minutos ~/ 60;
    final mins = minutos % 60;
    return mins > 0 ? '${horas}h ${mins}min' : '${horas}h';
  }

  /// Layout vertical (portrait) - Una columna con todos los elementos
  Widget _buildVerticalLayout() {
    return Center(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 800),
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // 0. Empleado Principal (solo para ST)
            if (_mostrarEmpleadoPrincipal) ...[
              _buildEmpleadoPrincipalCard(),
              const SizedBox(height: 16),
            ],

            // 1. Info de la OT
            OrderInfoCard(ordenTrabajo: widget.ordentrabajo),
            const SizedBox(height: 16),

            // 2. Info de la Actividad
            ActivityInfoCard(
              actividad: widget.actividad,
              empleado: widget.empleado,
              actividadConOt: widget.actividadConOt,
            ),
            const SizedBox(height: 16),

            // 3. Estado Actual
            if (_trackingState != null)
              CurrentStateCard(estado: _trackingState!.estado),
            const SizedBox(height: 16),

            // 4. Acciones
            _buildAccionesCard(),
            const SizedBox(height: 16),

            // 5. Observaciones
            ObservationsField(
              controller: _observacionesController,
              onChanged: _onObservacionesChanged,
            ),
            const SizedBox(height: 16),

            // 6. Historial
            if (_trackingState != null)
              TimelineWidget(
                periodos: _trackingState!.periodos,
                tiempoTotalTrabajado: _trackingState!.tiempoTotalTrabajado,
              ),

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
            // 0. Empleado Principal (solo para ST) - Full width
            if (_mostrarEmpleadoPrincipal) ...[
              _buildEmpleadoPrincipalCard(),
              const SizedBox(height: 16),
            ],

            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Columna 1: Info OT, Info Actividad, Observaciones (60%)
                Expanded(
                  flex: 3,
                  child: Column(
                    children: [
                      // 1. Info de la OT
                      OrderInfoCard(ordenTrabajo: widget.ordentrabajo),
                      const SizedBox(height: 16),

                      // 2. Info de la Actividad
                      ActivityInfoCard(
                        actividad: widget.actividad,
                        empleado: widget.empleado,
                        actividadConOt: widget.actividadConOt,
                      ),
                      const SizedBox(height: 16),

                      // 5. Observaciones
                      ObservationsField(
                        controller: _observacionesController,
                        onChanged: _onObservacionesChanged,
                      ),
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
                      if (_trackingState != null)
                        CurrentStateCard(estado: _trackingState!.estado),
                      const SizedBox(height: 16),

                      // 4. Acciones
                      _buildAccionesCard(),
                      const SizedBox(height: 16),

                      // 6. Historial
                      if (_trackingState != null)
                        TimelineWidget(
                          periodos: _trackingState!.periodos,
                          tiempoTotalTrabajado:
                              _trackingState!.tiempoTotalTrabajado,
                        ),
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
    // Calcular si tiene más de 5 minutos trabajados
    final tiempoTotal = _trackingState?.tiempoTotalTrabajado ?? Duration.zero;
    final tieneMasDe5Minutos = tiempoTotal.inMinutes >= 5;

    switch (estado) {
      case EstadoActividad.noIniciada:
        return Column(
          children: [
            // Botón principal: Iniciar Actividad
            SizedBox(
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
            ),
            const SizedBox(height: 12),
            // Botón secundario: Marcar como Backlog
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _onMarcarBacklog,
                icon: const Icon(Icons.archive_outlined),
                label: const Text('Marcar como Backlog'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.warning,
                  side: const BorderSide(color: AppColors.warning, width: 2),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  textStyle: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        );

      case EstadoActividad.enProceso:
        return Row(
          children: [
            // Botón Pausar
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
            // Botón Cancelar (< 5 min) o Finalizar (>= 5 min)
            Expanded(
              child: tieneMasDe5Minutos
                  ? ElevatedButton.icon(
                      onPressed: _onFinalizar,
                      icon: const Icon(Icons.stop),
                      label: const Text('Finalizar'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.error,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                    )
                  : ElevatedButton.icon(
                      onPressed: _onCancelar,
                      icon: const Icon(Icons.close),
                      label: const Text('Cancelar'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.textSecondary,
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
            // En estado pausado siempre mostrar Finalizar
            // (solo se puede pausar después de 5 min, por lo tanto siempre se puede finalizar)
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

  /// Diálogo para marcar como backlog con campo opcional de observaciones
  Future<Map<String, dynamic>?> _mostrarDialogBacklog() {
    final observacionesController = TextEditingController();

    return showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('¿Marcar como backlog?'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Esta actividad será marcada como pendiente y será reprogramada en una futura orden de trabajo.',
              style: TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: observacionesController,
              decoration: const InputDecoration(
                labelText: 'Observaciones (opcional)',
                hintText: 'Ej: Falta repuesto especial',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
              maxLength: 500,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, null),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, {
              'confirmar': true,
              'observaciones': observacionesController.text.trim(),
            }),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.warning,
              foregroundColor: Colors.white,
            ),
            child: const Text('Sí, Marcar como Backlog'),
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

  /// Helper para formatear duración (usado en diálogos)
  String _formatearDuracion(Duration duracion) {
    final horas = duracion.inHours;
    final minutos = duracion.inMinutes.remainder(60);

    if (horas > 0) {
      return '${horas}h ${minutos}min';
    } else {
      return '${minutos}min';
    }
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
