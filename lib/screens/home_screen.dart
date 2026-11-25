import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../models/parking_space.dart';
import '../models/space_status.dart';
import '../services/auth_service.dart';
import '../services/error_messages.dart';
import '../services/spaces_repository.dart';
import '../theme/app_theme.dart';
import '../widgets/stat_card.dart';
import '../widgets/sync_status_badge.dart';

/// Pantalla 1 (Obligatoria): Pantalla Principal / Inicio conectada a Cloud Firestore.
class HomeScreen extends StatefulWidget {
  final Function(int targetTab)? onNavigateTab;
  final VoidCallback? onOpenVehicles;

  const HomeScreen({
    super.key,
    this.onNavigateTab,
    this.onOpenVehicles,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _spacesRepo = SpacesRepository();
  bool _isInitializing = false;

  void _confirmSignOut() {
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.logout_rounded, color: AppTheme.darkHeader),
              SizedBox(width: 8),
              Text('Cerrar sesión'),
            ],
          ),
          content: const Text(
            '¿Estás seguro de que deseas cerrar tu sesión en ParkingUni?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(ctx);
                await AuthService().signOut();
              },
              child: const Text('Cerrar sesión'),
            ),
          ],
        );
      },
    );
  }

  void _confirmResetSpaces() {
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.cleaning_services_rounded, color: AppTheme.availableGreen),
              SizedBox(width: 8),
              Text('Liberar espacios'),
            ],
          ),
          content: const Text(
            '¿Deseas restablecer todos los 24 espacios de parqueadero a estado DISPONIBLE (100% libres)?\n\nEsto dejará Ocupados en 0 para que puedas probar reservas limpias.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(ctx);
                _resetAllSpaces();
              },
              child: const Text('Liberar todos'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _resetAllSpaces() async {
    setState(() => _isInitializing = true);
    final messenger = ScaffoldMessenger.of(context);
    try {
      await _spacesRepo.resetAllSpacesToAvailable();
      if (!mounted) return;
      messenger.showSnackBar(
        const SnackBar(
          content: Text('¡Todos los 24 espacios han sido liberados (100% disponibles, 0 ocupados)!'),
          backgroundColor: AppTheme.availableGreen,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(content: Text('Error al liberar espacios: $e'), backgroundColor: AppTheme.occupiedRed),
      );
    } finally {
      if (mounted) setState(() => _isInitializing = false);
    }
  }

  Future<void> _initializeParkingSpaces({bool withMockOccupied = false}) async {
    setState(() => _isInitializing = true);
    final messenger = ScaffoldMessenger.of(context);
    try {
      final created = await _spacesRepo.initializeSpacesIfEmpty(withMockOccupied: withMockOccupied);
      if (!mounted) return;
      if (created) {
        messenger.showSnackBar(
          const SnackBar(
            content: Text('¡Parqueadero inicializado con éxito en Firestore (24 espacios 100% disponibles)!'),
            backgroundColor: AppTheme.availableGreen,
          ),
        );
      } else {
        messenger.showSnackBar(
          const SnackBar(
            content: Text('Los espacios ya existen en Firestore. Puedes usar el botón de escoba para liberarlos a 100% disponibles.'),
            backgroundColor: AppTheme.reservedAmber,
          ),
        );
      }
    } on FirebaseException catch (e) {
      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(
          content: Text(FirebaseErrorMessages.getFirestoreErrorMessage(e)),
          backgroundColor: AppTheme.occupiedRed,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: AppTheme.occupiedRed),
      );
    } finally {
      if (mounted) setState(() => _isInitializing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = AuthService().currentUser;
    final userName = user?.displayName ?? 'Comunidad Universitaria';
    final userEmail = user?.email ?? '';

    return Scaffold(
      body: SafeArea(
        child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: FirebaseFirestore.instance.collection('parking_spaces').snapshots(),
          builder: (context, snapshot) {
            final querySnapshot = snapshot.data;
            final spaces = querySnapshot != null
                ? querySnapshot.docs.map((d) => ParkingSpace.fromDoc(d)).toList()
                : <ParkingSpace>[];

            final total = spaces.length;
            final available = spaces.where((s) => s.status == SpaceStatus.disponible).length;
            final occupied = spaces.where((s) => s.status == SpaceStatus.ocupado).length;
            final reserved = spaces.where((s) => s.status == SpaceStatus.reservado).length;

            return SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.only(bottom: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // 1. Encabezado principal oscuro con identidad institucional y usuario
                  _buildHeader(userName, userEmail),

                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 12),

                        // Indicador de sincronización en tiempo real
                        if (querySnapshot != null)
                          SyncStatusBadge(
                            hasPendingWrites: querySnapshot.metadata.hasPendingWrites,
                            isFromCache: querySnapshot.metadata.isFromCache,
                          ),

                        // Botón de Inicialización si Firestore está vacío
                        if (total == 0) ...[
                          Container(
                            padding: const EdgeInsets.all(16),
                            margin: const EdgeInsets.only(bottom: 16),
                            decoration: BoxDecoration(
                              color: AppTheme.reservedAmberLight.withValues(alpha: 0.5),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: AppTheme.reservedAmber.withValues(alpha: 0.4)),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Row(
                                  children: [
                                    Icon(Icons.warning_amber_rounded, color: AppTheme.reservedAmber),
                                    SizedBox(width: 8),
                                    Text(
                                      'Parqueadero sin inicializar',
                                      style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                const Text(
                                  'Crea los 24 espacios iniciales (Zona A y B) en Cloud Firestore con un solo clic.',
                                  style: TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                                ),
                                const SizedBox(height: 12),
                                ElevatedButton.icon(
                                  onPressed: _isInitializing ? null : _initializeParkingSpaces,
                                  icon: _isInitializing
                                      ? const SizedBox(
                                          width: 16,
                                          height: 16,
                                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                        )
                                      : const Icon(Icons.add_task_rounded, size: 18),
                                  label: Text(_isInitializing ? 'Inicializando...' : 'Inicializar parqueadero'),
                                ),
                              ],
                            ),
                          ),
                        ],

                        // 2. Contadores en tiempo real desde Firestore
                        const Text(
                          'Disponibilidad en vivo (Firestore)',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 10),

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
                                    count: total,
                                    icon: Icons.local_parking_rounded,
                                    color: AppTheme.darkHeader,
                                    backgroundColor: AppTheme.borderLight.withValues(alpha: 0.5),
                                  ),
                                ),
                                SizedBox(
                                  width: cardWidth,
                                  child: StatCard(
                                    title: 'Disponibles',
                                    count: available,
                                    icon: Icons.check_circle_rounded,
                                    color: AppTheme.availableGreen,
                                    backgroundColor: AppTheme.availableGreenLight,
                                  ),
                                ),
                                SizedBox(
                                  width: cardWidth,
                                  child: StatCard(
                                    title: 'Ocupados',
                                    count: occupied,
                                    icon: Icons.directions_car_rounded,
                                    color: AppTheme.occupiedRed,
                                    backgroundColor: AppTheme.occupiedRedLight,
                                  ),
                                ),
                                SizedBox(
                                  width: cardWidth,
                                  child: StatCard(
                                    title: 'Reservados',
                                    count: reserved,
                                    icon: Icons.access_time_filled_rounded,
                                    color: AppTheme.reservedAmber,
                                    backgroundColor: AppTheme.reservedAmberLight,
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                        const SizedBox(height: 20),

                        // 3. Problemática y propósito
                        _buildProblemDescriptionCard(),
                        const SizedBox(height: 20),

                        // 4. Accesos directos y navegación
                        const Text(
                          'Gestión y Servicios',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 12),

                        // Tarjeta: Reservar un espacio
                        _buildActionCard(
                          title: 'Reservar un espacio',
                          subtitle: 'Asegura tu lugar con transacción atómica en Firestore',
                          icon: Icons.bookmark_add_rounded,
                          onTap: () {
                            if (widget.onNavigateTab != null) {
                              widget.onNavigateTab!(1);
                            }
                          },
                        ),
                        const SizedBox(height: 10),

                        // Tarjeta: Ver mapa en vivo
                        _buildActionCard(
                          title: 'Mapa en vivo del parqueadero',
                          subtitle: 'Diagrama esquemático sincronizado en tiempo real',
                          icon: Icons.map_rounded,
                          onTap: () {
                            if (widget.onNavigateTab != null) {
                              widget.onNavigateTab!(3);
                            }
                          },
                        ),
                        const SizedBox(height: 10),

                        // Tarjeta: Mis reservas
                        _buildActionCard(
                          title: 'Mis reservas',
                          subtitle: 'Historial, detalles, edición y cancelación de reservas',
                          icon: Icons.history_rounded,
                          onTap: () {
                            if (widget.onNavigateTab != null) {
                              widget.onNavigateTab!(2);
                            }
                          },
                        ),
                        const SizedBox(height: 10),

                        // Tarjeta: Mis vehículos
                        _buildActionCard(
                          title: 'Mis vehículos',
                          subtitle: 'Registra tus automóviles y motocicletas',
                          icon: Icons.directions_car_filled_rounded,
                          onTap: () {
                            if (widget.onOpenVehicles != null) {
                              widget.onOpenVehicles!();
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

  Widget _buildHeader(String userName, String userEmail) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
      decoration: const BoxDecoration(
        color: AppTheme.darkHeader,
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(24)),
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
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
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
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    tooltip: 'Liberar todos los espacios (0 ocupados)',
                    icon: const Icon(Icons.cleaning_services_rounded, color: Colors.white),
                    onPressed: _isInitializing ? null : _confirmResetSpaces,
                  ),
                  IconButton(
                    tooltip: 'Cerrar sesión',
                    icon: const Icon(Icons.logout_rounded, color: Colors.white),
                    onPressed: _confirmSignOut,
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            '¡Hola, $userName!',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            userEmail,
            style: const TextStyle(
              color: Color(0xFFCBD5E1),
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProblemDescriptionCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.borderLight),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline_rounded, color: AppTheme.darkHeader, size: 22),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Ahorra tiempo y evita congestiones',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textPrimary,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Consulta la disponibilidad de espacios en tiempo real o reserva con anticipación antes de desplazarte al campus universitario.',
                  style: TextStyle(fontSize: 12, color: AppTheme.textSecondary, height: 1.4),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionCard({
    required String title,
    required String subtitle,
    required IconData icon,
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
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppTheme.darkHeader,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: Colors.white, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: AppTheme.textSecondary),
            ],
          ),
        ),
      ),
    );
  }
}
