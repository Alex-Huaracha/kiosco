import 'package:flutter/material.dart';

import 'package:hgtrack/core/theme/app_colors.dart';
import 'package:hgtrack/features/authentication/data/models/empleado.dart';
import 'package:hgtrack/features/authentication/presentation/widgets/empleado_avatar.dart';
import 'package:hgtrack/features/time_tracking/data/services/activity_service.dart';
import 'package:hgtrack/features/time_tracking/data/services/pending_sync_service.dart';
import 'package:hgtrack/features/time_tracking/presentation/pages/activity_detail_page.dart';
import 'package:hgtrack/features/time_tracking/presentation/widgets/actividad_con_ot_model.dart';
import 'package:hgtrack/features/time_tracking/presentation/widgets/activity_card.dart';

/// Pantalla principal: Lista de actividades pendientes del empleado
/// Muestra todas las actividades activas (No Iniciadas + En Proceso) sin agrupar por OT
/// Al hacer tap en una actividad → navega a pantalla de detalle
class ActivitiesListPage extends StatefulWidget {
  final HgEmpleadoMantenimientoDto empleado;

  const ActivitiesListPage({
    super.key,
    required this.empleado,
  });

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
  bool _isSyncing = false;
  bool _backlogExpanded = false;

  @override
  void initState() {
    super.initState();
    loadActividades();
    _loadPendingCount();
  }

  Future<void> _loadPendingCount() async {
    final syncService = PendingSyncService();
    final count = await syncService.getPendingCount();
    setState(() {
      _pendingSyncCount = count;
    });
  }

  Future<void> loadActividades() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      final service = ActivityService();
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
      // Incluye bcerrada == false Y bcerrada == null
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

            const SizedBox(height: 24), // Espaciado antes de backlog

            // Sección de Backlog (colapsable)
            _buildSeccionBacklog(),

            const SizedBox(height: 80), // Espacio final para scroll
          ],
        ),
      ),
    );
  }

  /// Card con información del empleado (foto, nombre, cargo) y botón de sincronización
  Widget _buildEmpleadoCard() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // COLUMNA 1: Info personal (70%)
            Expanded(
              flex: 7,
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

            const SizedBox(width: 16),

            // COLUMNA 2: Botón de sincronización (30%)
            Expanded(
              flex: 3,
              child: _buildSyncButton(),
            ),
          ],
        ),
      ),
    );
  }

  /// Botón de sincronización vertical compacto
  Widget _buildSyncButton() {
    // Estado 1: Sincronizando
    if (_isSyncing) {
      return Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color: AppColors.primary.withAlpha(26),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.primary, width: 2),
        ),
        child: const Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: 28,
              height: 28,
              child: CircularProgressIndicator(
                strokeWidth: 3,
                valueColor: AlwaysStoppedAnimation(AppColors.primary),
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Enviando...',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    // Estado 2: Todo sincronizado
    if (_pendingSyncCount == 0) {
      return Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color: Colors.grey[200],
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.cloud_done,
              size: 32,
              color: Colors.grey[600],
            ),
            const SizedBox(height: 6),
            Text(
              'Todo OK',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: Colors.grey[700],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    // Estado 3: Pendientes de sincronizar
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: _onSyncPendingActivities,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
          decoration: BoxDecoration(
            color: AppColors.warning.withAlpha(26),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.warning, width: 2),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Stack(
                alignment: Alignment.center,
                clipBehavior: Clip.none,
                children: [
                  const Icon(
                    Icons.cloud_upload,
                    size: 32,
                    color: AppColors.warning,
                  ),
                  Positioned(
                    right: -6,
                    top: -6,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: AppColors.error,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                      constraints: const BoxConstraints(
                        minWidth: 22,
                        minHeight: 22,
                      ),
                      child: Center(
                        child: Text(
                          '$_pendingSyncCount',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              const Text(
                'Sincronizar',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: AppColors.warning,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Handler de sincronización de actividades pendientes
  Future<void> _onSyncPendingActivities() async {
    setState(() => _isSyncing = true);

    final syncService = PendingSyncService();

    // Mostrar SnackBar de progreso
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Row(
            children: [
              SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation(Colors.white),
                ),
              ),
              SizedBox(width: 16),
              Text('Sincronizando actividades...'),
            ],
          ),
          duration: Duration(seconds: 30),
        ),
      );
    }

    // Intentar sincronizar todas
    final result = await syncService.syncAllPending();

    setState(() => _isSyncing = false);

    // Actualizar contador
    await _loadPendingCount();

    // Recargar lista (por si cambiaron estados)
    await loadActividades();

    // Mostrar resultado
    if (!mounted) return;

    ScaffoldMessenger.of(context).clearSnackBars();

    if (result.todosExitosos) {
      // ✅ Todas exitosas
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('✓ ${result.exitosos} actividades sincronizadas'),
          backgroundColor: AppColors.success,
          duration: const Duration(seconds: 3),
        ),
      );
    } else if (result.parcial) {
      // ⚠️ Parcial
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '⚠️ ${result.exitosos} de ${result.total} sincronizadas',
          ),
          backgroundColor: AppColors.warning,
          duration: const Duration(seconds: 5),
        ),
      );
    } else {
      // ❌ Todas fallaron
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✗ No se pudo sincronizar. Verifica tu conexión.'),
          backgroundColor: AppColors.error,
          duration: Duration(seconds: 5),
        ),
      );
    }
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

  /// Sección de Backlog (colapsable)
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
        ),
      ),
    );

    // Si se finalizó la actividad, recargar la lista y contador de pendientes
    if (result == true && mounted) {
      loadActividades();
      _loadPendingCount();
    }
  }
}
