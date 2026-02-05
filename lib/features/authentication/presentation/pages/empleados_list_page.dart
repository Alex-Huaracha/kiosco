import 'package:flutter/material.dart';

import 'package:hgtrack/core/theme/app_colors.dart';
import 'package:hgtrack/features/authentication/data/models/empleado.dart';
import 'package:hgtrack/features/authentication/data/services/auth_service.dart';
import 'package:hgtrack/features/authentication/presentation/widgets/empleado_avatar.dart';
import 'package:hgtrack/features/time_tracking/presentation/pages/activities_list_page.dart';

class EmpleadosListPage extends StatefulWidget {
  const EmpleadosListPage({super.key});

  @override
  State<EmpleadosListPage> createState() => _EmpleadosListPageState();
}

class _EmpleadosListPageState extends State<EmpleadosListPage> {
  List<HgEmpleadoMantenimientoDto>? empleados;
  bool isLoading = true;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    loadEmpleados();
  }

  Future<void> loadEmpleados() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      final trackingService = AuthService();
      final result = await trackingService.getAllEmpleadosMantenimiento();

      setState(() {
        isLoading = false;
        if (result != null && result.isNotEmpty) {
          empleados = result;
        } else {
          errorMessage = 'No hay empleados con actividades pendientes en este momento';
        }
      });
    } catch (e) {
      setState(() {
        isLoading = false;
        errorMessage = 'Error al cargar los empleados: $e';
      });
    }
  }

  int _calculateCrossAxisCount(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    return width < 900 ? 2 : 3;
  }

  double _calculateAspectRatio(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    return width < 900 ? 2.3 : 2.5;  // Vertical: 2.3 (previene overflow), Horizontal: 2.5
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
          Flexible(
            child: Text(
              'Personal de Mantenimiento',
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
              ),
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
              textAlign: TextAlign.center,
            ),
          ),
          if (empleados != null && empleados!.isNotEmpty) ...[
            const SizedBox(width: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                '${empleados!.length}',
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
                onPressed: loadEmpleados,
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

    if (empleados == null || empleados!.isEmpty) {
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
          itemCount: empleados!.length,
          itemBuilder: (context, index) {
            return EmpleadoCard(
              empleado: empleados![index],
              onTap: () => _onEmpleadoSelected(empleados![index]),
            );
          },
        );
      },
    );
  }

  void _onEmpleadoSelected(HgEmpleadoMantenimientoDto empleado) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ActivitiesListPage(empleado: empleado),
      ),
    );
  }
}

class EmpleadoCard extends StatelessWidget {
  final HgEmpleadoMantenimientoDto empleado;
  final VoidCallback onTap;

  const EmpleadoCard({
    super.key,
    required this.empleado,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
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
                    size: EmpleadoAvatar.sizeLarge,  // 80px para máxima visibilidad
                  ),

                  const SizedBox(width: 12),

                  // Información del empleado a la derecha
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

            // Badge con contador de actividades (si existe)
            if (empleado.cantidadTotal != null && empleado.cantidadTotal! > 0)
              Positioned(
                top: 12,
                right: 12,
                child: _buildActivityBadge(empleado),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildActivityBadge(HgEmpleadoMantenimientoDto empleado) {
    final hasBacklog = empleado.cantidadBacklog != null && empleado.cantidadBacklog! > 0;

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
            '${empleado.cantidadTotal}',
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
