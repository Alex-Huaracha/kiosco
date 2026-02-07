import 'dart:async';

import 'package:flutter/material.dart';

import 'package:hgtrack/core/network/connectivity_service.dart';
import 'package:hgtrack/core/theme/app_colors.dart';
import 'package:hgtrack/features/authentication/data/models/empleado_con_actividades.dart';
import 'package:hgtrack/features/authentication/data/services/auth_service.dart';
import 'package:hgtrack/features/authentication/presentation/widgets/empleado_avatar.dart';
import 'package:hgtrack/features/time_tracking/presentation/pages/activities_list_page.dart';

class EmpleadosListPage extends StatefulWidget {
  const EmpleadosListPage({super.key});

  @override
  State<EmpleadosListPage> createState() => _EmpleadosListPageState();
}

class _EmpleadosListPageState extends State<EmpleadosListPage> {
  /// Lista de empleados con sus actividades (cargados juntos)
  List<EmpleadoConActividades>? _empleadosConActividades;
  bool isLoading = true;
  String? errorMessage;

  // Conectividad
  bool _isOnline = true;
  StreamSubscription<bool>? _connectivitySubscription;

  @override
  void initState() {
    super.initState();
    _initConnectivity();
    _loadAllData();
  }

  @override
  void dispose() {
    _connectivitySubscription?.cancel();
    super.dispose();
  }

  /// Inicializa ConnectivityService (primera pantalla de la app)
  void _initConnectivity() {
    final connectivity = ConnectivityService();
    connectivity.initialize();
    _isOnline = connectivity.isOnline;

    _connectivitySubscription = connectivity.onlineStream.listen((isOnline) {
      if (mounted) {
        final wasOffline = !_isOnline;
        setState(() => _isOnline = isOnline);

        // Si volvio online, refrescar datos en background
        if (wasOffline && isOnline) {
          _backgroundRefresh();
        }
      }
    });
  }

  /// Carga todos los datos (empleados + actividades) con estrategia cache-first
  Future<void> _loadAllData() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      final authService = AuthService();
      // cache-first: retorna cache si existe, o llama API si es primera vez
      final result = await authService.getAllEmpleadosConActividades();

      setState(() {
        isLoading = false;
        if (result != null && result.isNotEmpty) {
          _empleadosConActividades = result;
        } else {
          errorMessage = 'No hay empleados con actividades pendientes en este momento';
        }
      });

      // Refrescar desde API en background si hay conexion
      if (_isOnline && result != null) {
        _backgroundRefresh();
      }
    } catch (e) {
      setState(() {
        isLoading = false;
        errorMessage = 'Error al cargar los datos: $e';
      });
    }
  }

  /// Refresca datos desde la API en background (sin loading spinner)
  Future<void> _backgroundRefresh() async {
    try {
      final authService = AuthService();
      final freshData = await authService.refreshAllData();

      if (freshData != null && freshData.isNotEmpty && mounted) {
        setState(() {
          _empleadosConActividades = freshData;
          errorMessage = null;
        });
      }
    } catch (e) {
      print('Error en background refresh: $e');
    }
  }

  int _calculateCrossAxisCount(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    return width < 900 ? 2 : 3;
  }

  double _calculateAspectRatio(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    return width < 900 ? 2.3 : 2.5;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Image.asset(
            'assets/icon/logo.png',
            height: 40,
          ),
        ),
        title: const Text('Control Tiempo OT'),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // Banner offline
          if (!_isOnline) _buildOfflineBanner(),

          const SizedBox(height: 16),
          _buildBanner(),
          const SizedBox(height: 16),
          Expanded(
            child: _buildBody(),
          ),
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

  Widget _buildBanner() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      decoration: BoxDecoration(
        color: AppColors.bannerBackground,
        border: Border(
          bottom: BorderSide(
            color: AppColors.primary.withAlpha(51),
            width: 1,
          ),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.engineering,
            color: AppColors.primary,
            size: 24,
          ),
          const SizedBox(width: 8),
          const Flexible(
            child: Text(
              'Personal de Mantenimiento',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
              ),
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
              textAlign: TextAlign.center,
            ),
          ),
          if (_empleadosConActividades != null && _empleadosConActividades!.isNotEmpty) ...[
            const SizedBox(width: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                '${_empleadosConActividades!.length}',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
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
                Icons.error_outline,
                size: 72,
                color: AppColors.error,
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
                onPressed: _loadAllData,
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

    if (_empleadosConActividades == null || _empleadosConActividades!.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.work_off,
                size: 72,
                color: AppColors.textSecondary,
              ),
              SizedBox(height: 24),
              Text(
                'No hay empleados con actividades pendientes',
                style: TextStyle(
                  fontSize: 18,
                  color: AppColors.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    // GridView adaptativo con las cards de empleados
    return LayoutBuilder(
      builder: (context, constraints) {
        return GridView.builder(
          padding: const EdgeInsets.all(16),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: _calculateCrossAxisCount(context),
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: _calculateAspectRatio(context),
          ),
          itemCount: _empleadosConActividades!.length,
          itemBuilder: (context, index) {
            final item = _empleadosConActividades![index];
            return EmpleadoCard(
              empleadoConActividades: item,
              onTap: () => _onEmpleadoSelected(item),
            );
          },
        );
      },
    );
  }

  /// Navega a la lista de actividades pasando los datos ya cargados
  void _onEmpleadoSelected(EmpleadoConActividades item) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ActivitiesListPage(
          empleadoConActividades: item,
        ),
      ),
    );

    // Si hubo cambios (actividad finalizada), refrescar datos
    if (result == true && mounted) {
      _backgroundRefresh();
    }
  }
}

/// Card de empleado que muestra nombre, cargo y contador de actividades
class EmpleadoCard extends StatelessWidget {
  final EmpleadoConActividades empleadoConActividades;
  final VoidCallback onTap;

  const EmpleadoCard({
    super.key,
    required this.empleadoConActividades,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final empleado = empleadoConActividades.empleado;
    
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        splashColor: AppColors.rippleOverlay,
        highlightColor: AppColors.hoverOverlay,
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Avatar con iniciales a la izquierda
                  EmpleadoAvatar(
                    iniciales: empleado.iniciales,
                    size: EmpleadoAvatar.sizeLarge,
                  ),

                  const SizedBox(width: 12),

                  // Informacion del empleado a la derecha
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Nombre completo
                        Padding(
                          padding: const EdgeInsets.only(right: 40),
                          child: Text(
                            empleado.nombreCompleto,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                              height: 1.3,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),

                        const SizedBox(height: 4),

                        // DNI
                        Text(
                          'DNI: ${empleado.numerodocumento ?? "N/A"}',
                          style: const TextStyle(
                            fontSize: 15,
                            color: AppColors.textSecondary,
                          ),
                        ),

                        const SizedBox(height: 2),

                        // Cargo
                        Text(
                          empleado.cargo ?? "N/A",
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w500,
                            color: AppColors.textSecondary,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Badge con contador de actividades
            if (empleadoConActividades.actividades.isNotEmpty)
              Positioned(
                top: 12,
                right: 12,
                child: _buildActivityBadge(),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildActivityBadge() {
    final total = empleadoConActividades.actividades.length;
    final backlogCount = empleadoConActividades.actividades
        .where((a) => a.detalle?.bbacklog == true)
        .length;
    final hasBacklog = backlogCount > 0;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        // Badge principal con contador total
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: AppColors.primary,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: AppColors.shadowLight,
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Text(
            '$total',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),

        // Mini-badge de backlog (si aplica)
        if (hasBacklog)
          Positioned(
            top: -2,
            right: -2,
            child: Container(
              width: 14,
              height: 14,
              decoration: BoxDecoration(
                color: AppColors.warning,
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.white,
                  width: 2,
                ),
              ),
            ),
          ),
      ],
    );
  }
}
