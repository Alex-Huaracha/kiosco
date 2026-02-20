import 'dart:async';

import 'package:flutter/material.dart';

import 'package:hgtrack/core/network/connectivity_service.dart';
import 'package:hgtrack/core/theme/app_colors.dart';
import 'package:hgtrack/features/authentication/data/models/empleado.dart';
import 'package:hgtrack/features/authentication/data/models/empleado_con_actividades.dart';
import 'package:hgtrack/features/authentication/presentation/widgets/empleado_avatar.dart';
import 'package:hgtrack/features/time_tracking/data/models/actividad.dart';
import 'package:hgtrack/features/time_tracking/data/models/pending_sync_activity.dart';
import 'package:hgtrack/features/time_tracking/data/services/local_storage_service.dart';
import 'package:hgtrack/features/time_tracking/data/services/pending_sync_service.dart';
import 'package:hgtrack/features/time_tracking/domain/tracking_state.dart';
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
  bool isLoading = true;
  String? errorMessage;
  int _pendingSyncCount = 0;

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
  /// Filtra actividades que ya fueron finalizadas y están en cola de sync
  /// Enriquece con datos locales de SharedPreferences para mostrar horas de inicio
  Future<void> _processActividades() async {
    final actividades = widget.empleadoConActividades.actividades;

    if (actividades.isEmpty) {
      setState(() {
        isLoading = false;
        errorMessage = 'No tienes actividades asignadas';
      });
      return;
    }

    // Obtener IDs de actividades pendientes de sync (ya finalizadas offline)
    final pendingService = PendingSyncService();
    final pendingActivityIds = await pendingService.getPendingActivityIds();
    final pendingAsignacionIds = await pendingService.getPendingAsignacionIds();

    // Servicio para cargar estados locales de tracking
    final localStorageService = ActividadLocalStorageService();

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

    // Filtrar actividades que ya fueron finalizadas y están en cola de sync
    todasActividades = todasActividades.where((item) {
      if (item.esSubTarea) {
        // Para ST, verificar por idAsignacion
        return !pendingAsignacionIds.contains(item.idAsignacion);
      } else {
        // Para TP, verificar por id del detalle
        return !pendingActivityIds.contains(item.actividad.id);
      }
    }).toList();

    // Enriquecer con datos locales de SharedPreferences
    await _enriquecerConDatosLocales(todasActividades, localStorageService);

    // El backend ya filtra las actividades relevantes para el empleado
    // No aplicamos filtro adicional por bcerrada
    List<ActividadConOt> actividadesActivas = todasActividades;

    if (actividadesActivas.isEmpty) {
      setState(() {
        isLoading = false;
        errorMessage = 'No tienes actividades pendientes';
      });
      return;
    }

    // Ordenar todas las actividades (normales + backlog unificadas)
    _ordenarActividades(actividadesActivas);

    setState(() {
      isLoading = false;
      actividadesPendientes = actividadesActivas;
    });
  }

  /// Enriquece las actividades con datos locales de SharedPreferences
  /// Esto permite mostrar la hora de inicio en el card mientras la actividad
  /// está en proceso pero aún no se ha enviado al backend.
  Future<void> _enriquecerConDatosLocales(
    List<ActividadConOt> actividades,
    ActividadLocalStorageService storageService,
  ) async {
    for (var item in actividades) {
      final actividadId = item.actividad.id;
      if (actividadId == null) continue;

      try {
        // Intentar cargar estado local de tracking
        final trackingState = await storageService.loadState(actividadId);

        if (trackingState != null && trackingState.periodos.isNotEmpty) {
          // Tiene tracking local activo
          item.tieneTrackingLocal = true;

          // NUEVO: Guardar el estado completo (noIniciada, enProceso, pausada, finalizada)
          item.estadoLocal = trackingState.estado;

          // Obtener fecha/hora de inicio del primer periodo
          item.localDtiempoinicio = trackingState.periodos.first.inicio;

          // Extraer tiempo ya calculado (no recalcular)
          item.localMinutosTrabajados = trackingState.tiempoTotalTrabajado.inMinutes;

          // Si está finalizada localmente, obtener fecha/hora de fin
          if (trackingState.estado == EstadoActividad.finalizada) {
            final ultimoPeriodo = trackingState.periodos.last;
            if (ultimoPeriodo.fin != null) {
              item.localDtiempofin = ultimoPeriodo.fin;
            }
          }
        }
      } catch (e) {
        // Error al cargar estado local, continuar sin enriquecer
        print('Error al cargar estado local para actividad $actividadId: $e');
      }
    }
  }

  /// Ordena actividades por prioridad:
  /// 1. En Proceso primero (considera tracking local)
  /// 2. No Iniciadas segundo
  /// 3. Por fecha de registro (mas reciente primero)
  /// 
  /// Nota: Backlog ya NO se separa, se mezcla con actividades normales
  void _ordenarActividades(List<ActividadConOt> actividades) {
    actividades.sort((a, b) {
      // Prioridad 1: En proceso (considera tanto BD como tracking local)
      // Una actividad está en proceso si:
      // - Tiene dtiempoinicio en BD y no tiene dtiempofin, O
      // - Tiene tracking local activo (localDtiempoinicio != null)
      bool aEnProceso = _estaEnProceso(a);
      bool bEnProceso = _estaEnProceso(b);
      if (aEnProceso && !bEnProceso) return -1;
      if (!aEnProceso && bEnProceso) return 1;

      // Prioridad 2: No iniciadas (pendientes sin tiempo inicio ni tracking local)
      bool aNoIniciada = _noIniciada(a);
      bool bNoIniciada = _noIniciada(b);
      if (aNoIniciada && !bNoIniciada) return -1;
      if (!aNoIniciada && bNoIniciada) return 1;

      // Mismo nivel: ordenar por fecha de registro (mas reciente primero)
      int fechaA = a.actividad.dfecreg ?? 0;
      int fechaB = b.actividad.dfecreg ?? 0;
      return fechaB.compareTo(fechaA);
    });
  }

  /// Verifica si una actividad está en proceso o pausada (activa).
  /// Prioriza tracking local; cae en cestadomovil de BD.
  bool _estaEnProceso(ActividadConOt item) {
    if (item.tieneTrackingLocal && item.localDtiempoinicio != null) {
      return true;
    }
    final estado = item.actividadDto?.cestadomovil;
    return estado == EstadoMovil.enProceso || estado == EstadoMovil.pausada;
  }

  /// Verifica si una actividad no ha sido iniciada.
  bool _noIniciada(ActividadConOt item) {
    if (item.tieneTrackingLocal) return false;
    return item.actividadDto?.cestadomovil == EstadoMovil.noIniciada;
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

            // Lista de actividades (incluye backlog mezclado)
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

    // Si se finalizo la actividad o se marco como backlog, actualizar la lista
    if (result != null && result is Map && mounted) {
      if (result['success'] == true || result['backlog'] == true) {
        _onActividadFinalizada(result);
      }
      // Si hubo cambios de estado local (inicio/pausa/reanudación)
      else if (result['changed'] == true) {
        final String? action = result['action'] as String?;
        await _recargarEstadosLocales();
        
        // Mostrar feedback visual según la acción
        if (action != null) {
          _mostrarFeedbackAccion(action);
        }
      }
    }
  }

  /// Maneja la finalizacion de una actividad
  /// Remueve la actividad de la lista local y refresca en background
  void _onActividadFinalizada(Map<dynamic, dynamic> result) {
    final int? actividadId = result['actividadId'];
    final int? idAsignacion = result['idAsignacion'];
    final bool esSubTarea = result['esSubTarea'] ?? false;

    if (actividadId == null) return;

    setState(() {
      // Remover de la lista de pendientes
      actividadesPendientes?.removeWhere((item) {
        if (esSubTarea) {
          // Para ST, comparar por idAsignacion
          return item.idAsignacion == idAsignacion;
        } else {
          // Para TP, comparar por id del detalle
          return item.actividad.id == actividadId;
        }
      });
    });

    // Actualizar contador de pendientes de sync
    _loadPendingCount();

    // Si no quedan actividades, volver a la pantalla de empleados
    final totalActividades = actividadesPendientes?.length ?? 0;
    if (totalActividades == 0) {
      // Volver indicando que hubo cambios para que se recargue la lista de empleados
      Navigator.pop(context, true);
    }
  }

  /// Recarga solo los estados locales de las actividades actuales
  /// sin hacer llamada al backend.
  /// 
  /// Se ejecuta cuando el usuario regresa de la pantalla de detalle
  /// después de iniciar, pausar o reanudar una actividad.
  Future<void> _recargarEstadosLocales() async {
    if (actividadesPendientes == null) return;
    
    final localStorageService = ActividadLocalStorageService();
    
    // Re-enriquecer solo las actividades actuales (sin backend)
    await _enriquecerConDatosLocales(
      actividadesPendientes!,
      localStorageService,
    );
    
    // NO re-ordenar (mantener orden actual)
    // _ordenarActividades(actividadesPendientes!); ← Comentado intencionalmente
    
    // Refrescar UI
    if (mounted) {
      setState(() {
        // Solo trigger rebuild con los datos actualizados
      });
    }
  }

  /// Muestra SnackBar con feedback según la acción realizada
  void _mostrarFeedbackAccion(String action) {
    if (!mounted) return;
    
    String mensaje;
    Color backgroundColor;
    
    switch (action) {
      case 'iniciada':
        mensaje = 'Actividad iniciada';
        backgroundColor = AppColors.success;
        break;
      case 'pausada':
        mensaje = 'Actividad pausada';
        backgroundColor = AppColors.warning;
        break;
      case 'reanudada':
        mensaje = 'Actividad reanudada';
        backgroundColor = AppColors.success;
        break;
      case 'cancelada':
        mensaje = 'Actividad cancelada';
        backgroundColor = AppColors.textSecondary;
        break;
      default:
        return; // No mostrar nada si la acción es desconocida
    }
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(mensaje),
        backgroundColor: backgroundColor,
        duration: const Duration(seconds: 2),
      ),
    );
  }
}
