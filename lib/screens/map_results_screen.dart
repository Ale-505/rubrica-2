import 'package:flutter/material.dart';
import '../data/parking_repository.dart';
import '../models/parking_space.dart';
import '../models/reservation.dart';
import '../models/space_status.dart';
import '../theme/app_theme.dart';
import '../widgets/parking_space_tile.dart';
import '../widgets/reservation_card.dart';
import '../widgets/status_legend.dart';

/// Pantalla 3: Consulta y Resultados.
/// Presenta dos pestañas principales mediante TabBar:
/// 1. Mapa esquemático del parqueadero con 24 espacios organizados en 2 zonas y carriles.
/// 2. Historial de "Mis reservas" con filtros interactivos y cancelación en vivo.
class MapResultsScreen extends StatefulWidget {
  final int initialTabIndex;
  final Function(String zone, String spaceNumber)? onReserveSpace;
  final VoidCallback? onGoToReservationForm;

  const MapResultsScreen({
    super.key,
    this.initialTabIndex = 0,
    this.onReserveSpace,
    this.onGoToReservationForm,
  });

  @override
  State<MapResultsScreen> createState() => _MapResultsScreenState();
}

class _MapResultsScreenState extends State<MapResultsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final ParkingRepository _repository = ParkingRepository();

  // Filtro seleccionado para Mis reservas: 'Todas', 'Activas', 'Canceladas'
  String _selectedFilter = 'Todas';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 2,
      vsync: this,
      initialIndex: widget.initialTabIndex,
    );
  }

  @override
  void didUpdateWidget(covariant MapResultsScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialTabIndex != oldWidget.initialTabIndex) {
      _tabController.animateTo(widget.initialTabIndex);
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  /// Maneja el toque sobre un espacio en el mapa interactivo
  void _handleSpaceTap(ParkingSpace space) {
    if (space.status == SpaceStatus.disponible) {
      // Abre BottomSheet con detalles y botón de acción para reservar
      _showSpaceBottomSheet(space);
    } else if (space.status == SpaceStatus.ocupado) {
      // Muestra SnackBar informativo de espacio ocupado
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.block, color: Colors.white, size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'El Espacio ${space.number} (${space.zone}) se encuentra actualmente ocupado por otro vehículo.',
                ),
              ),
            ],
          ),
          backgroundColor: AppTheme.occupiedRed,
          duration: const Duration(seconds: 3),
        ),
      );
    } else {
      // Muestra SnackBar informativo de espacio reservado
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.lock_clock, color: Colors.white, size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'El Espacio ${space.number} (${space.zone}) ya está reservado. Por favor selecciona uno disponible en verde.',
                ),
              ),
            ],
          ),
          backgroundColor: AppTheme.reservedAmber,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  /// BottomSheet modal para confirmar el interés en reservar el espacio tocado
  void _showSpaceBottomSheet(ParkingSpace space) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (bottomSheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Barra superior de arrastre
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppTheme.borderLight,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Encabezado de detalle
                Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: AppTheme.availableGreenLight,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: AppTheme.availableGreen.withValues(alpha: 0.4),
                        ),
                      ),
                      child: const Center(
                        child: Icon(
                          Icons.local_parking_rounded,
                          color: AppTheme.availableGreen,
                          size: 28,
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Espacio ${space.number}',
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                        Text(
                          space.zone,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: AppTheme.textSecondary,
                          ),
                        ),
                      ],
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: AppTheme.availableGreenLight,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Text(
                        'DISPONIBLE',
                        style: TextStyle(
                          color: AppTheme.availableGreen,
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const Text(
                  'Este espacio se encuentra completamente libre en este momento. Puedes apartarlo completando el formulario de reserva con los datos de tu vehículo.',
                  style: TextStyle(
                    fontSize: 13,
                    color: AppTheme.textSecondary,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 20),

                // Botón para ir al formulario con el espacio preseleccionado
                ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pop(bottomSheetContext);
                    if (widget.onReserveSpace != null) {
                      widget.onReserveSpace!(space.zone, space.number);
                    }
                  },
                  icon: const Icon(Icons.bookmark_add_rounded, size: 20),
                  label: Text('Reservar Espacio ${space.number}'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  /// Diálogo de confirmación para cancelar una reserva activa
  void _confirmCancelReservation(Reservation reservation) {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Row(
            children: const [
              Icon(Icons.warning_amber_rounded, color: AppTheme.occupiedRed),
              SizedBox(width: 10),
              Text(
                'Cancelar reserva',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
              ),
            ],
          ),
          content: Text(
            '¿Estás seguro de cancelar la reserva del Espacio ${reservation.spaceNumber} (${reservation.zone}) para el vehículo con placa ${reservation.plate}?\n\nEl espacio volverá a estar disponible de inmediato en el mapa.',
            style: const TextStyle(fontSize: 13, height: 1.4),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text(
                'No, mantener',
                style: TextStyle(color: AppTheme.textSecondary),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(dialogContext);
                final success = _repository.cancelReservation(reservation.id);
                if (success) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Row(
                        children: [
                          const Icon(Icons.check_circle, color: Colors.white),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Reserva cancelada. El Espacio ${reservation.spaceNumber} ha quedado disponible.',
                            ),
                          ),
                        ],
                      ),
                      backgroundColor: AppTheme.availableGreen,
                    ),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.occupiedRed,
                foregroundColor: Colors.white,
              ),
              child: const Text('Sí, cancelar'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Consulta y Resultados'),
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: const Color(0xFF94A3B8),
          indicatorColor: Colors.white,
          indicatorWeight: 3,
          labelStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
          tabs: const [
            Tab(
              icon: Icon(Icons.map_rounded, size: 20),
              text: 'Mapa',
            ),
            Tab(
              icon: Icon(Icons.history_rounded, size: 20),
              text: 'Mis reservas',
            ),
          ],
        ),
      ),
      body: ListenableBuilder(
        listenable: _repository,
        builder: (context, _) {
          return TabBarView(
            controller: _tabController,
            children: [
              _buildMapView(),
              _buildReservationsView(),
            ],
          );
        },
      ),
    );
  }

  // ==========================================
  // VISTA 1: MAPA ESQUEMÁTICO DEL PARQUEADERO
  // ==========================================
  Widget _buildMapView() {
    final spacesA = _repository.getSpacesByZone('Zona A');
    final spacesB = _repository.getSpacesByZone('Zona B');

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Rótulo superior institucional de "Entrada / Salida"
          _buildEntranceExitBanner(),
          const SizedBox(height: 16),

          // Contenedor principal del mapa esquemático
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppTheme.surfaceWhite,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: AppTheme.borderLight),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.03),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // ZONA A
                _buildZoneSection(
                  zoneTitle: 'Zona A',
                  spaces: spacesA,
                ),

                const SizedBox(height: 16),

                // Vía principal divisoria entre zonas
                _buildMainDriveway(),

                const SizedBox(height: 16),

                // ZONA B
                _buildZoneSection(
                  zoneTitle: 'Zona B',
                  spaces: spacesB,
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Leyenda explicativa de colores
          const StatusLegend(),
          const SizedBox(height: 12),

          // Mensaje de ayuda
          Center(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: const [
                Icon(Icons.touch_app_rounded, size: 16, color: AppTheme.textSecondary),
                SizedBox(width: 6),
                Text(
                  'Toca un espacio en verde para ver su detalle y reservarlo.',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppTheme.textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  /// Rótulo superior "Entrada / Salida"
  Widget _buildEntranceExitBanner() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppTheme.darkHeader,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: const [
              Icon(Icons.arrow_downward_rounded, color: AppTheme.availableGreen, size: 18),
              SizedBox(width: 4),
              Text(
                'ENTRADA',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  fontSize: 11,
                  letterSpacing: 1,
                ),
              ),
            ],
          ),
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Text(
                'PARQUEADERO CAMPUS',
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 11,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ),
          Row(
            children: const [
              Text(
                'SALIDA',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  fontSize: 11,
                  letterSpacing: 1,
                ),
              ),
              SizedBox(width: 4),
              Icon(Icons.arrow_upward_rounded, color: AppTheme.occupiedRed, size: 18),
            ],
          ),
        ],
      ),
    );
  }

  /// Construye una zona (12 casillas en dos filas de 6 con carril entre ellas)
  Widget _buildZoneSection({
    required String zoneTitle,
    required List<ParkingSpace> spaces,
  }) {
    // Fila 1: primeros 6 espacios
    final row1 = spaces.take(6).toList();
    // Fila 2: siguientes 6 espacios
    final row2 = spaces.skip(6).take(6).toList();

    final availableCount = spaces.where((s) => s.isAvailable).length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Encabezado de la zona
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              zoneTitle,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w800,
                color: AppTheme.textPrimary,
              ),
            ),
            Text(
              '$availableCount de ${spaces.length} disponibles',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: availableCount > 0
                    ? AppTheme.availableGreen
                    : AppTheme.occupiedRed,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),

        // Fila 1 (6 casillas)
        _buildSpacesRow(row1),

        // Carril de circulación vehicular interno
        _buildDrivingLane(),

        // Fila 2 (6 casillas)
        _buildSpacesRow(row2),
      ],
    );
  }

  /// Renderiza una fila horizontal de 6 casillas adaptables
  Widget _buildSpacesRow(List<ParkingSpace> spaces) {
    return Row(
      children: spaces.map((space) {
        return Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 2),
            child: AspectRatio(
              aspectRatio: 0.70,
              child: ParkingSpaceTile(
                space: space,
                onTap: () => _handleSpaceTap(space),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  /// Carril de circulación vehicular interno entre filas de 6
  Widget _buildDrivingLane() {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: [
          const Icon(Icons.arrow_forward_rounded, size: 14, color: Color(0xFF94A3B8)),
          const SizedBox(width: 4),
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final dashCount = (constraints.maxWidth / 12).floor().clamp(1, 8);
                return Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: List.generate(
                    dashCount,
                    (_) => Container(
                      width: 6,
                      height: 2,
                      color: const Color(0xFFCBD5E1),
                    ),
                  ),
                );
              },
            ),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 4),
            child: Text(
              'CARRIL DE CIRCULACIÓN',
              style: TextStyle(
                fontSize: 8.5,
                fontWeight: FontWeight.w700,
                color: Color(0xFF94A3B8),
                letterSpacing: 0.5,
              ),
            ),
          ),
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final dashCount = (constraints.maxWidth / 12).floor().clamp(1, 8);
                return Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: List.generate(
                    dashCount,
                    (_) => Container(
                      width: 6,
                      height: 2,
                      color: const Color(0xFFCBD5E1),
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(width: 4),
          const Icon(Icons.arrow_forward_rounded, size: 14, color: Color(0xFF94A3B8)),
        ],
      ),
    );
  }

  /// Vía principal divisoria entre Zona A y Zona B
  Widget _buildMainDriveway() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFE2E8F0),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: const [
          Icon(Icons.directions_car_rounded, size: 16, color: Color(0xFF64748B)),
          SizedBox(width: 8),
          Text(
            'VÍA PRINCIPAL INTERNA',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w800,
              color: Color(0xFF475569),
              letterSpacing: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // VISTA 2: MIS RESERVAS CON FILTRO
  // ==========================================
  Widget _buildReservationsView() {
    final allReservations = _repository.reservations;

    // Aplicar filtro por estado
    final filtered = allReservations.where((r) {
      if (_selectedFilter == 'Activas') {
        return r.status == ReservationStatus.activa;
      } else if (_selectedFilter == 'Canceladas') {
        return r.status == ReservationStatus.cancelada;
      }
      return true; // 'Todas'
    }).toList();

    return Column(
      children: [
        // Barra superior de filtros con ChoiceChips
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          color: Colors.white,
          child: Row(
            children: [
              const Text(
                'Filtrar:',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textPrimary,
                ),
              ),
              const SizedBox(width: 10),
              _buildFilterChip('Todas', allReservations.length),
              const SizedBox(width: 8),
              _buildFilterChip(
                'Activas',
                allReservations.where((r) => r.status == ReservationStatus.activa).length,
              ),
              const SizedBox(width: 8),
              _buildFilterChip(
                'Canceladas',
                allReservations.where((r) => r.status == ReservationStatus.cancelada).length,
              ),
            ],
          ),
        ),
        const Divider(height: 1, color: AppTheme.borderLight),

        // Listado de reservas o estado vacío
        Expanded(
          child: filtered.isEmpty
              ? _buildEmptyState()
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  physics: const BouncingScrollPhysics(),
                  itemCount: filtered.length,
                  itemBuilder: (context, index) {
                    final res = filtered[index];
                    return ReservationCard(
                      reservation: res,
                      onCancel: res.isActive
                          ? () => _confirmCancelReservation(res)
                          : null,
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildFilterChip(String label, int count) {
    final isSelected = _selectedFilter == label;
    return ChoiceChip(
      label: Text('$label ($count)'),
      selected: isSelected,
      onSelected: (selected) {
        if (selected) {
          setState(() {
            _selectedFilter = label;
          });
        }
      },
      selectedColor: AppTheme.darkHeader,
      backgroundColor: Colors.white,
      labelStyle: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: isSelected ? Colors.white : AppTheme.textPrimary,
      ),
      side: BorderSide(
        color: isSelected ? AppTheme.darkHeader : AppTheme.borderLight,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppTheme.darkHeader.withValues(alpha: 0.05),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.bookmark_border_rounded,
                size: 48,
                color: AppTheme.textSecondary,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'No hay reservas para mostrar',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Actualmente no tienes reservas en esta categoría. Puedes consultar el mapa y apartar un espacio libre.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: AppTheme.textSecondary,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: () {
                if (widget.onGoToReservationForm != null) {
                  widget.onGoToReservationForm!();
                } else {
                  _tabController.animateTo(0);
                }
              },
              icon: const Icon(Icons.add_rounded, size: 18),
              label: const Text('Reservar ahora'),
            ),
          ],
        ),
      ),
    );
  }
}
