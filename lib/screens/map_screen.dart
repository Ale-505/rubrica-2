import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../models/parking_space.dart';
import '../models/space_status.dart';
import '../services/spaces_repository.dart';
import '../theme/app_theme.dart';
import '../widgets/parking_space_tile.dart';
import '../widgets/status_legend.dart';
import '../widgets/sync_status_badge.dart';

/// Pantalla 6 (Funcionalidad Principal): Mapa esquemático en tiempo real conectado a Firestore.
class MapScreen extends StatefulWidget {
  final Function(String zone, String spaceNumber)? onReserveSpace;

  const MapScreen({
    super.key,
    this.onReserveSpace,
  });

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  final _spacesRepo = SpacesRepository();

  void _handleSpaceTap(ParkingSpace space) {
    if (space.status == SpaceStatus.disponible) {
      _showSpaceBottomSheet(space);
    } else if (space.status == SpaceStatus.ocupado) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.block, color: Colors.white, size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'El Espacio ${space.number} (${space.zone}) está ocupado${space.occupiedByPlate != null ? " por el vehículo ${space.occupiedByPlate}" : ""}.',
                ),
              ),
            ],
          ),
          backgroundColor: AppTheme.occupiedRed,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.lock_clock, color: Colors.white, size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'El Espacio ${space.number} (${space.zone}) se encuentra reservado en Firestore. Selecciona uno en verde.',
                ),
              ),
            ],
          ),
          backgroundColor: AppTheme.reservedAmber,
        ),
      );
    }
  }

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
                Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: AppTheme.availableGreenLight,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppTheme.availableGreen.withValues(alpha: 0.4)),
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
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
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
                  'Este espacio se encuentra completamente libre en Firestore. Al seleccionarlo, se verificará atómicamente que nadie más lo tome antes de confirmar tu reserva.',
                  style: TextStyle(fontSize: 13, color: AppTheme.textSecondary, height: 1.4),
                ),
                const SizedBox(height: 20),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mapa en Vivo'),
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance.collection('parking_spaces').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.error_outline, size: 48, color: AppTheme.occupiedRed),
                    const SizedBox(height: 12),
                    Text(
                      'Error al sincronizar mapa: ${snapshot.error}',
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () => setState(() {}),
                      child: const Text('Reintentar'),
                    ),
                  ],
                ),
              ),
            );
          }

          final querySnapshot = snapshot.data;
          final allSpaces = querySnapshot != null
              ? querySnapshot.docs.map((d) => ParkingSpace.fromDoc(d)).toList()
              : <ParkingSpace>[];
          allSpaces.sort((a, b) => a.number.compareTo(b.number));

          if (allSpaces.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.layers_clear_outlined, size: 48, color: AppTheme.textSecondary),
                    const SizedBox(height: 16),
                    const Text(
                      'El parqueadero aún no ha sido inicializado en Firestore',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Puedes inicializar los 24 espacios desde la pantalla de Inicio.',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 13, color: AppTheme.textSecondary),
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton.icon(
                      onPressed: () async {
                        await _spacesRepo.initializeSpacesIfEmpty();
                      },
                      icon: const Icon(Icons.add_task_rounded),
                      label: const Text('Inicializar ahora'),
                    ),
                  ],
                ),
              ),
            );
          }

          final spacesA = allSpaces.where((s) => s.zone == 'Zona A').toList();
          final spacesB = allSpaces.where((s) => s.zone == 'Zona B').toList();

          return SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (querySnapshot != null)
                  SyncStatusBadge(
                    hasPendingWrites: querySnapshot.metadata.hasPendingWrites,
                    isFromCache: querySnapshot.metadata.isFromCache,
                  ),

                _buildEntranceExitBanner(),
                const SizedBox(height: 16),

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
                      _buildZoneSection(zoneTitle: 'Zona A', spaces: spacesA),
                      const SizedBox(height: 16),
                      _buildMainDriveway(),
                      const SizedBox(height: 16),
                      _buildZoneSection(zoneTitle: 'Zona B', spaces: spacesB),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                const StatusLegend(),
                const SizedBox(height: 12),
                const Center(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.touch_app_rounded, size: 16, color: AppTheme.textSecondary),
                      SizedBox(width: 6),
                      Text(
                        'Toca un espacio en verde para ver su detalle y apartarlo.',
                        style: TextStyle(fontSize: 12, color: AppTheme.textSecondary, fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ),
          );
        },
      ),
    );
  }

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
          const Row(
            children: [
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
          const Row(
            children: [
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

  Widget _buildZoneSection({
    required String zoneTitle,
    required List<ParkingSpace> spaces,
  }) {
    final row1 = spaces.take(6).toList();
    final row2 = spaces.skip(6).take(6).toList();
    final availableCount = spaces.where((s) => s.isAvailable).length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
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
                color: availableCount > 0 ? AppTheme.availableGreen : AppTheme.occupiedRed,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        _buildSpacesRow(row1),
        _buildDrivingLane(),
        _buildSpacesRow(row2),
      ],
    );
  }

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
                    (_) => Container(width: 6, height: 2, color: const Color(0xFFCBD5E1)),
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
                    (_) => Container(width: 6, height: 2, color: const Color(0xFFCBD5E1)),
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

  Widget _buildMainDriveway() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFE2E8F0),
        borderRadius: BorderRadius.circular(10),
      ),
      child: const Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
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
}
