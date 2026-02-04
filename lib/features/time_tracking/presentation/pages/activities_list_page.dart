import 'package:flutter/material.dart';

import 'package:hgtrack/core/theme/app_colors.dart';
import 'package:hgtrack/features/authentication/data/models/empleado.dart';
import 'package:hgtrack/features/authentication/presentation/widgets/empleado_avatar.dart';
import 'package:hgtrack/features/time_tracking/data/services/activity_service.dart';
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
        builder: (context) => ActivityDetailPage(
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
