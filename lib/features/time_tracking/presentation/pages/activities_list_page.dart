import 'dart:async';

import 'package:flutter/material.dart';

import 'package:hgtrack/core/network/connectivity_service.dart';
import 'package:hgtrack/core/theme/app_colors.dart';
import 'package:hgtrack/features/authentication/data/models/empleado.dart';
import 'package:hgtrack/features/authentication/data/models/empleado_con_actividades.dart';
import 'package:hgtrack/features/authentication/presentation/widgets/empleado_avatar.dart';
import 'package:hgtrack/features/time_tracking/data/models/pending_sync_activity.dart';
import 'package:hgtrack/features/time_tracking/data/services/pending_sync_service.dart';
import 'package:hgtrack/features/time_tracking/presentation/pages/activity_detail_page.dart';
import 'package:hgtrack/features/time_tracking/presentation/widgets/actividad_con_ot_model.dart';
import 'package:hgtrack/features/time_tracking/presentation/widgets/activity_card.dart';

/// Pantalla principal: Lista de actividades pendientes del empleado
/// Muestra todas las actividades activas (No Iniciadas + En Proceso) sin agrupar por OT
/// Al hacer tap en una actividad -> navega a pantalla de detalle
/// 
/// Recibe EmpleadoConActividades con las actividades ya cargadas desde el endpoint unificado.
class ActivitiesListPage extends StatefulWidget {
  final EmpleadoConActividades empleadoConActividades;

  const ActivitiesListPage({
    super.key,
    required this.empleadoConActividades,
  });

  /// Acceso directo al empleado (convenience getter)
  HgEmpleadoMantenimientoDto get empleado => empleadoConActividades.empleado;

  @override
  State<ActivitiesListPage> createState() =>
      _ActivitiesListPageState();
}

class _ActivitiesListPageState
    extends State<ActivitiesListPage> {
  List<ActividadConOt>? actividadesPendientes;
  List<ActividadConOt>? actividadesEnBacklog;
  bool isLoading = true;
  String? errorMessage;
  int _pendingSyncCount = 0;
  bool _backlogExpanded = false;

  // Conectividad
  bool _isOnline = true;
  StreamSubscription<bool>? _connectivitySubscription;
  StreamSubscription<SyncResult>? _syncResultSubscription;

  @override
  void initState() {
    super.initState();
    _initConnectivity();
    _processActividades(); // Procesar actividades ya cargadas
    _loadPendingCount();
    _autoSyncIfNeeded();
  }

  @override
  void dispose() {
    _connectivitySubscription?.cancel();
    _syncResultSubscription?.cancel();
    super.dispose();
  }

  /// Inicializa suscripciones a ConnectivityService
  void _initConnectivity() {
    final connectivity = ConnectivityService();
    _isOnline = connectivity.isOnline;

    // Escuchar cambios de conectividad
    _connectivitySubscription = connectivity.onlineStream.listen((isOnline) {
      if (mounted) {
        setState(() => _isOnline = isOnline);
      }
    });

    // Escuchar resultados de auto-sync
    _syncResultSubscription =
        connectivity.syncResultStream.listen((result) {
      if (mounted) {
        _loadPendingCount();
        _showSyncResultSnackBar(result);
      }
    });
  }

  /// Intenta sincronizar actividades pendientes al entrar a la pantalla
  Future<void> _autoSyncIfNeeded() async {
    final syncService = PendingSyncService();
    final count = await syncService.getPendingCount();

    if (count > 0 && _isOnline) {
      print('Auto-sync al entrar: $count actividades pendientes');
      final connectivity = ConnectivityService();
      final result = await connectivity.forceSync();

      if (result != null && mounted) {
        _loadPendingCount();
        if (result.total > 0) {
          _showSyncResultSnackBar(result);
        }
      }
    }
  }

  /// Muestra SnackBar con resultado de sincronizacion
  void _showSyncResultSnackBar(SyncResult result) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).clearSnackBars();

    if (result.todosExitosos && result.total > 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '${result.exitosos} actividad${result.exitosos > 1 ? "es" : ""} sincronizada${result.exitosos > 1 ? "s" : ""}',
          ),
          backgroundColor: AppColors.success,
          duration: const Duration(seconds: 3),
        ),
      );
    } else if (result.parcial) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '${result.exitosos} de ${result.total} sincronizadas',
          ),
          backgroundColor: AppColors.warning,
          duration: const Duration(seconds: 5),
        ),
      );
    } else if (result.todosFallaron && result.total > 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No se pudo sincronizar. Se reintentara automaticamente.'),
          backgroundColor: AppColors.error,
          duration: Duration(seconds: 5),
        ),
      );
    }
  }

  Future<void> _loadPendingCount() async {
    final syncService = PendingSyncService();
    final count = await syncService.getPendingCount();
    if (mounted) {
      setState(() {
        _pendingSyncCount = count;
      });
    }
  }

  /// Procesa las actividades ya cargadas desde EmpleadoConActividades
  /// Convierte ActividadEmpleadoDto a ActividadConOt y separa normales de backlog
  void _processActividades() {
    final actividades = widget.empleadoConActividades.actividades;

    if (actividades.isEmpty) {
      setState(() {
        isLoading = false;
        errorMessage = 'No tienes actividades asignadas';
      });
      return;
    }

    // Convertir ActividadEmpleadoDto a ActividadConOt
    List<ActividadConOt> todasActividades = [];
    for (var actividadDto in actividades) {
      if (actividadDto.detalle != null && actividadDto.ordentrabajo != null) {
        todasActividades.add(
          ActividadConOt(
            actividad: actividadDto.detalle!,
            ordentrabajo: actividadDto.ordentrabajo!,
            actividadDto: actividadDto, // Incluir DTO completo para info de tipo, empleadoPrincipal, etc.
          ),
        );
      }
    }

    // Filtrar solo actividades activas (no cerradas, incluye backlog)
    List<ActividadConOt> actividadesActivas = todasActividades.where((item) {
      return item.actividad.bcerrada != true;
    }).toList();

    if (actividadesActivas.isEmpty) {
      setState(() {
        isLoading = false;
        errorMessage = 'No tienes actividades pendientes';
      });
      return;
    }

    // Separar en dos grupos: normales y backlog
    List<ActividadConOt> actividadesNormales = actividadesActivas
        .where((item) => item.actividad.bbacklog != true)
        .toList();

    List<ActividadConOt> actividadesBacklogList = actividadesActivas
        .where((item) => item.actividad.bbacklog == true)
        .toList();

    // Ordenar cada grupo independientemente
    _ordenarActividades(actividadesNormales);
    _ordenarActividades(actividadesBacklogList);

    setState(() {
      isLoading = false;
      actividadesPendientes = actividadesNormales;
      actividadesEnBacklog = actividadesBacklogList;
    });
  }

  /// Ordena actividades por prioridad:
  /// 1. Actividades normales (no backlog) primero
  /// 2. Backlog al final
  /// Dentro de cada grupo:
  ///   - En Proceso primero
  ///   - No Iniciadas segundo
  ///   - Por fecha mas reciente
  void _ordenarActividades(List<ActividadConOt> actividades) {
    actividades.sort((a, b) {
      // Prioridad MAXIMA: Backlog siempre al final
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

      // Mismo nivel: ordenar por fecha de registro (mas reciente primero)
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
            onPressed: () => Navigator.pop(context, true), // Volver para recargar desde empleados
            tooltip: 'Actualizar',
          ),
        ],
      ),
      body: Column(
        children: [
          // Banner de conectividad offline
          if (!_isOnline) _buildOfflineBanner(),

          // Banner de actividades pendientes de sync
          if (_pendingSyncCount > 0) _buildPendingSyncBanner(),

          // Contenido principal
          Expanded(child: _buildBody()),
        ],
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

  /// Banner naranja de actividades pendientes de sincronizacion
  Widget _buildPendingSyncBanner() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      color: AppColors.warning.withAlpha(230),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.cloud_upload, color: Colors.white, size: 20),
          const SizedBox(width: 8),
          Text(
            '$_pendingSyncCount actividad${_pendingSyncCount > 1 ? "es" : ""} pendiente${_pendingSyncCount > 1 ? "s" : ""} de envio',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          if (_isOnline) ...[
            const SizedBox(width: 8),
            const SizedBox(
              width: 14,
              height: 14,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation(Colors.white),
              ),
            ),
          ],
        ],
      ),
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
                onPressed: () => Navigator.pop(context, true), // Volver para recargar
                icon: const Icon(Icons.refresh),
                label: const Text('Volver'),
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

            // Titulo de seccion con contador
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

            const SizedBox(height: 24), // Espaciado antes de backlog

            // Seccion de Backlog (colapsable)
            _buildSeccionBacklog(),

            const SizedBox(height: 80), // Espacio final para scroll
          ],
        ),
      ),
    );
  }

  /// Card con informacion del empleado
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
            // Informacion del empleado
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

  /// Titulo de seccion con contador de actividades
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
        const Text(
          'Actividades del dia',
          style: TextStyle(
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

  /// Seccion de Backlog (colapsable)
  Widget _buildSeccionBacklog() {
    if (actividadesEnBacklog == null || actividadesEnBacklog!.isEmpty) {
      return const SizedBox.shrink(); // No mostrar si no hay backlog
    }

    final count = actividadesEnBacklog!.length;

    return Column(
      children: [
        // Header clickeable
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () {
              setState(() {
                _backlogExpanded = !_backlogExpanded;
              });
            },
            borderRadius: BorderRadius.circular(8),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: AppColors.warning.withAlpha(26),
                border: Border.all(color: AppColors.warning, width: 1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.warning_amber_rounded,
                    size: 24,
                    color: AppColors.warning,
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'Backlog',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.warning,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.warning,
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
                  const SizedBox(width: 12),
                  Icon(
                    _backlogExpanded ? Icons.expand_less : Icons.expand_more,
                    size: 28,
                    color: AppColors.warning,
                  ),
                ],
              ),
            ),
          ),
        ),

        // Lista expandible
        AnimatedCrossFade(
          duration: const Duration(milliseconds: 300),
          crossFadeState: _backlogExpanded
              ? CrossFadeState.showSecond
              : CrossFadeState.showFirst,
          firstChild: const SizedBox.shrink(), // Colapsado
          secondChild: Column(
            children: [
              const SizedBox(height: 12),
              ...actividadesEnBacklog!.map((item) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: ActividadConOtCard(
                    item: item,
                    onTap: () => _onActividadTapped(item),
                  ),
                );
              }),
            ],
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
        builder: (context) => ActivityDetailPage(
          actividad: item.actividad,
          ordentrabajo: item.ordentrabajo,
          empleado: widget.empleado,
          actividadConOt: item, // Pasar item completo con info de TP/ST
        ),
      ),
    );

    // Si se finalizo la actividad, volver a pantalla de empleados para recargar
    if (result == true && mounted) {
      Navigator.pop(context, true); // Indica que hubo cambios
    }
  }
}
