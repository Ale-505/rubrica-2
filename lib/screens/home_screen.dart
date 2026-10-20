import 'package:flutter/material.dart';
import '../data/parking_repository.dart';
import '../theme/app_theme.dart';
import '../widgets/stat_card.dart';

/// Pantalla Principal (Inicio) de ParkingUni.
/// Presenta el encabezado institucional, los contadores de disponibilidad en tiempo real,
/// la justificación del problema universitario que resuelve, y accesos directos rápidos.
class HomeScreen extends StatelessWidget {
  final Function(int targetTab, {String? preselectedZone, String? preselectedSpaceNumber})? onNavigateTab;

  const HomeScreen({
    super.key,
    this.onNavigateTab,
  });

  @override
  Widget build(BuildContext context) {
    final repository = ParkingRepository();

    return Scaffold(
      body: SafeArea(
        child: ListenableBuilder(
          listenable: repository,
          builder: (context, _) {
            return SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.only(bottom: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // 1. Encabezado principal oscuro con identidad visual
                  _buildHeader(context),

                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 16),

                        // 2. Título de sección de estadísticas
                        const Text(
                          'Disponibilidad actual',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 10),

                        // Resumen en tarjetas (4 contadores en vivo)
                        LayoutBuilder(
                          builder: (context, constraints) {
                            final cardWidth = (constraints.maxWidth - 12) / 2;
                            return Wrap(
                              spacing: 12,
                              runSpacing: 12,
                              children: [
                                SizedBox(
                                  width: cardWidth,
                                  child: StatCard(
                                    title: 'Total espacios',
                                    count: repository.totalSpaces,
                                    icon: Icons.local_parking_rounded,
                                    color: AppTheme.darkHeader,
                                    backgroundColor:
                                        AppTheme.borderLight.withValues(alpha: 0.5),
                                  ),
                                ),
                                SizedBox(
                                  width: cardWidth,
                                  child: StatCard(
                                    title: 'Disponibles',
                                    count: repository.availableCount,
                                    icon: Icons.check_circle_rounded,
                                    color: AppTheme.availableGreen,
                                    backgroundColor:
                                        AppTheme.availableGreenLight,
                                  ),
                                ),
                                SizedBox(
                                  width: cardWidth,
                                  child: StatCard(
                                    title: 'Ocupados',
                                    count: repository.occupiedCount,
                                    icon: Icons.directions_car_rounded,
                                    color: AppTheme.occupiedRed,
                                    backgroundColor: AppTheme.occupiedRedLight,
                                  ),
                                ),
                                SizedBox(
                                  width: cardWidth,
                                  child: StatCard(
                                    title: 'Reservados',
                                    count: repository.reservedCount,
                                    icon: Icons.access_time_filled_rounded,
                                    color: AppTheme.reservedAmber,
                                    backgroundColor:
                                        AppTheme.reservedAmberLight,
                                  ),
                                ),
                              ],
                            );
                          },
                        ),

                        const SizedBox(height: 20),

                        // 3. Mini descripción del problema resuelto
                        _buildProblemDescriptionCard(),

                        const SizedBox(height: 20),

                        // 4. Accesos directos y botones de navegación
                        const Text(
                          'Acciones rápidas',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 12),

                        // Botón/Tarjeta: Reservar un espacio
                        _buildActionCard(
                          context: context,
                          title: 'Reservar un espacio',
                          subtitle:
                              'Registra tu vehículo y asegura tu lugar antes de llegar',
                          icon: Icons.bookmark_add_rounded,
                          accentColor: AppTheme.darkHeader,
                          buttonLabel: 'Ir al formulario',
                          onTap: () {
                            if (onNavigateTab != null) {
                              onNavigateTab!(1);
                            } else {
                              Navigator.pushNamed(context, '/reservar');
                            }
                          },
                        ),

                        const SizedBox(height: 12),

                        // Botón/Tarjeta: Ver mapa y mis reservas
                        _buildActionCard(
                          context: context,
                          title: 'Ver mapa y mis reservas',
                          subtitle:
                              'Consulta el diagrama esquemático de zonas A y B',
                          icon: Icons.map_rounded,
                          accentColor: AppTheme.darkHeader,
                          buttonLabel: 'Ver mapa interactivo',
                          onTap: () {
                            if (onNavigateTab != null) {
                              onNavigateTab!(2);
                            } else {
                              Navigator.pushNamed(context, '/mapa');
                            }
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  /// Encabezado oscuro con logotipo, título y subtítulo institucional
  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
      decoration: const BoxDecoration(
        color: AppTheme.darkHeader,
        borderRadius: BorderRadius.vertical(
          bottom: Radius.circular(24),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Center(
                      child: Text(
                        'P',
                        style: TextStyle(
                          color: AppTheme.darkHeader,
                          fontSize: 26,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text(
                        'ParkingUni',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.3,
                        ),
                      ),
                      Text(
                        'Gestión de parqueadero universitario',
                        style: TextStyle(
                          color: Color(0xFF94A3B8),
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.school_rounded, color: Colors.white, size: 14),
                    SizedBox(width: 4),
                    Text(
                      'Campus',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Text(
            '¡Bienvenido al sistema de parqueadero!',
            style: TextStyle(
              color: Colors.white,
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Consulta el estado de las zonas y reserva tu puesto sin filas.',
            style: TextStyle(
              color: Color(0xFFCBD5E1),
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  /// Tarjeta explicativa de la problemática resuelta
  Widget _buildProblemDescriptionCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.borderLight),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppTheme.darkHeader.withValues(alpha: 0.06),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.info_outline_rounded,
              color: AppTheme.darkHeader,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Optimiza tu tiempo en el campus',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textPrimary,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'No pierdas tiempo buscando puesto manualmente. Consulta los espacios libres en el mapa esquemático y reserva con anticipación para evitar congestión vehicular.',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppTheme.textSecondary,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Tarjeta de acción personalizada para navegar a las pantallas 2 y 3
  Widget _buildActionCard({
    required BuildContext context,
    required String title,
    required String subtitle,
    required IconData icon,
    required Color accentColor,
    required String buttonLabel,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppTheme.borderLight),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppTheme.darkHeader,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: Colors.white, size: 24),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.arrow_forward_ios_rounded,
                size: 16,
                color: AppTheme.textSecondary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
