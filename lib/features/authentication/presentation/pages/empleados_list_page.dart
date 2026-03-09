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

  // Filtro por cargo
  String? _cargoSeleccionado; // null = "Todos"

  // Búsqueda por nombre/DNI
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

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
    _searchController.dispose();
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

  /// Lista de cargos únicos con su contador de empleados, ordenados alfabéticamente
  List<({String cargo, int count})> get _cargosDisponibles {
    if (_empleadosConActividades == null || _empleadosConActividades!.isEmpty) {
      return [];
    }

    // Agrupar empleados por cargo
    final cargoCount = <String, int>{};
    for (final item in _empleadosConActividades!) {
      final cargo = item.empleado.cargo ?? 'Sin cargo';
      cargoCount[cargo] = (cargoCount[cargo] ?? 0) + 1;
    }

    // Convertir a lista de records y ordenar alfabéticamente
    final result = cargoCount.entries
        .map((e) => (cargo: e.key, count: e.value))
        .toList()
      ..sort((a, b) => a.cargo.toLowerCase().compareTo(b.cargo.toLowerCase()));

    return result;
  }

  /// Lista de empleados filtrados por búsqueda o cargo
  /// - Si hay búsqueda activa: filtra por nombre O DNI (ignora cargo)
  /// - Si no hay búsqueda: filtra por cargo seleccionado
  List<EmpleadoConActividades> get _empleadosFiltrados {
    if (_empleadosConActividades == null) return [];

    // Si hay búsqueda activa, filtrar por nombre o DNI (ignorar cargo)
    if (_searchQuery.isNotEmpty) {
      final query = _searchQuery.toLowerCase().trim();
      return _empleadosConActividades!.where((item) {
        final nombre = item.empleado.nombreCompleto.toLowerCase();
        final dni = item.empleado.numerodocumento?.toLowerCase() ?? '';
        return nombre.contains(query) || dni.contains(query);
      }).toList();
    }

    // Sin búsqueda, aplicar filtro de cargo
    if (_cargoSeleccionado == null) return _empleadosConActividades!;

    return _empleadosConActividades!
        .where((item) => (item.empleado.cargo ?? 'Sin cargo') == _cargoSeleccionado)
        .toList();
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
          const SizedBox(height: 12),
          _buildSearchBar(),
          const SizedBox(height: 12),
          _buildCargoDropdown(),
          const SizedBox(height: 12),
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

  /// SearchBar para buscar por nombre o DNI
  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: 'Buscar por nombre o DNI...',
          hintStyle: const TextStyle(
            color: AppColors.textSecondary,
            fontSize: 15,
          ),
          prefixIcon: const Icon(
            Icons.search,
            color: AppColors.textSecondary,
          ),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
                  onPressed: () {
                    setState(() {
                      _searchController.clear();
                      _searchQuery = '';
                    });
                  },
                  icon: const Icon(Icons.clear, color: AppColors.textSecondary),
                  tooltip: 'Limpiar búsqueda',
                )
              : null,
          filled: true,
          fillColor: AppColors.cardBackground,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(
              color: AppColors.primary.withAlpha(77),
              width: 1,
            ),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(
              color: AppColors.primary.withAlpha(77),
              width: 1,
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(
              color: AppColors.primary,
              width: 2,
            ),
          ),
        ),
        style: const TextStyle(
          fontSize: 15,
          color: AppColors.textPrimary,
        ),
        onChanged: (value) {
          setState(() {
            _searchQuery = value;
          });
        },
      ),
    );
  }

  /// Dropdown para filtrar por cargo
  Widget _buildCargoDropdown() {
    final cargos = _cargosDisponibles;
    final totalEmpleados = _empleadosConActividades?.length ?? 0;
    final isSearchActive = _searchQuery.isNotEmpty;

    // No mostrar dropdown si no hay datos o solo hay un cargo
    if (cargos.isEmpty || cargos.length == 1) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Fila del dropdown
          Opacity(
            opacity: isSearchActive ? 0.5 : 1.0,
            child: IgnorePointer(
              ignoring: isSearchActive,
              child: Row(
                children: [
                  Icon(
                    Icons.filter_list,
                    color: isSearchActive ? AppColors.textSecondary.withAlpha(128) : AppColors.textSecondary,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Filtrar por cargo:',
                    style: TextStyle(
                      fontSize: 15,
                      color: isSearchActive ? AppColors.textSecondary.withAlpha(128) : AppColors.textSecondary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        color: isSearchActive ? AppColors.cardBackground.withAlpha(128) : AppColors.cardBackground,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: AppColors.primary.withAlpha(isSearchActive ? 38 : 77),
                          width: 1,
                        ),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String?>(
                          value: _cargoSeleccionado,
                          isExpanded: true,
                          icon: Icon(
                            Icons.arrow_drop_down,
                            color: isSearchActive ? AppColors.primary.withAlpha(128) : AppColors.primary,
                          ),
                          style: TextStyle(
                            fontSize: 15,
                            color: isSearchActive ? AppColors.textPrimary.withAlpha(128) : AppColors.textPrimary,
                          ),
                          hint: Text(
                            'Todos ($totalEmpleados)',
                            style: TextStyle(
                              fontSize: 15,
                              color: isSearchActive ? AppColors.textPrimary.withAlpha(128) : AppColors.textPrimary,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          items: [
                            // Opcion "Todos"
                            DropdownMenuItem<String?>(
                              value: null,
                              child: Text(
                                'Todos ($totalEmpleados)',
                                style: const TextStyle(fontWeight: FontWeight.w500),
                              ),
                            ),
                            // Cargos disponibles
                            ...cargos.map((item) => DropdownMenuItem<String?>(
                                  value: item.cargo,
                                  child: Text('${item.cargo} (${item.count})'),
                                )),
                          ],
                          onChanged: (value) {
                            setState(() {
                              _cargoSeleccionado = value;
                            });
                          },
                        ),
                      ),
                    ),
                  ),
                  // Boton para limpiar filtro (solo visible si hay filtro activo y no hay búsqueda)
                  if (_cargoSeleccionado != null && !isSearchActive) ...[
                    const SizedBox(width: 8),
                    IconButton(
                      onPressed: () {
                        setState(() {
                          _cargoSeleccionado = null;
                        });
                      },
                      icon: const Icon(Icons.clear, color: AppColors.textSecondary),
                      tooltip: 'Limpiar filtro',
                      style: IconButton.styleFrom(
                        backgroundColor: AppColors.cardBackground,
                        side: BorderSide(
                          color: AppColors.textSecondary.withAlpha(77),
                          width: 1,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          // Mensaje informativo cuando hay búsqueda activa
          if (isSearchActive) ...[
            const SizedBox(height: 6),
            Row(
              children: [
                Icon(
                  Icons.info_outline,
                  size: 14,
                  color: AppColors.textSecondary.withAlpha(179),
                ),
                const SizedBox(width: 4),
                Text(
                  'Limpie la búsqueda para filtrar por cargo',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary.withAlpha(179),
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),
          ],
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
                '${_empleadosFiltrados.length}',
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

    // Obtener lista filtrada
    final empleadosFiltrados = _empleadosFiltrados;

    // Estado vacío cuando el filtro no tiene resultados
    if (empleadosFiltrados.isEmpty) {
      // Determinar si es por búsqueda o por filtro de cargo
      final isSearchActive = _searchQuery.isNotEmpty;
      final message = isSearchActive
          ? 'No se encontró empleado con "$_searchQuery"'
          : 'No hay empleados con el cargo "$_cargoSeleccionado"';

      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.search_off,
                size: 72,
                color: AppColors.textSecondary,
              ),
              const SizedBox(height: 24),
              Text(
                message,
                style: const TextStyle(
                  fontSize: 18,
                  color: AppColors.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              TextButton.icon(
                onPressed: () {
                  setState(() {
                    if (isSearchActive) {
                      _searchController.clear();
                      _searchQuery = '';
                    } else {
                      _cargoSeleccionado = null;
                    }
                  });
                },
                icon: const Icon(Icons.clear),
                label: Text(isSearchActive ? 'Limpiar búsqueda' : 'Limpiar filtro'),
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
          itemCount: empleadosFiltrados.length,
          itemBuilder: (context, index) {
            final item = empleadosFiltrados[index];
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
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ActivitiesListPage(
          empleadoConActividades: item,
        ),
      ),
    );

    // Siempre refrescar datos al regresar de la lista de actividades
    if (mounted) {
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

                        const SizedBox(height: 8),

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
