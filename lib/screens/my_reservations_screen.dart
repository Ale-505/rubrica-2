import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../models/reservation.dart';
import '../services/auth_service.dart';
import '../services/error_messages.dart';
import '../services/reservations_repository.dart';
import '../theme/app_theme.dart';
import '../widgets/reservation_card.dart';
import '../widgets/sync_status_badge.dart';
import 'reservation_detail_screen.dart';

/// Pantalla 2 (Obligatoria): Consulta o listado de reservas en tiempo real desde Cloud Firestore.
class MyReservationsScreen extends StatefulWidget {
  final VoidCallback? onGoToNewReservation;

  const MyReservationsScreen({
    super.key,
    this.onGoToNewReservation,
  });

  @override
  State<MyReservationsScreen> createState() => _MyReservationsScreenState();
}

class _MyReservationsScreenState extends State<MyReservationsScreen> {
  final _repository = ReservationsRepository();
  final _searchController = TextEditingController();

  String _selectedFilter = 'Todas';
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _confirmCancelReservation(Reservation reservation) {
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: AppTheme.occupiedRed),
              SizedBox(width: 8),
              Text('Cancelar reserva'),
            ],
          ),
          content: Text(
            '¿Deseas cancelar la reserva del Espacio ${reservation.spaceNumber} (${reservation.zone})?\nEl espacio quedará inmediatamente libre en Firestore.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Volver'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: AppTheme.occupiedRed),
              onPressed: () async {
                Navigator.pop(ctx);
                try {
                  await _repository.cancelReservationAtomic(reservation.id);
                  if (!mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Reserva cancelada y espacio liberado en Firestore.'),
                      backgroundColor: AppTheme.availableGreen,
                    ),
                  );
                } on FirebaseException catch (e) {
                  if (!mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(FirebaseErrorMessages.getFirestoreErrorMessage(e)),
                      backgroundColor: AppTheme.occupiedRed,
                    ),
                  );
                } catch (e) {
                  if (!mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error: $e'), backgroundColor: AppTheme.occupiedRed),
                  );
                }
              },
              child: const Text('Sí, cancelar'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final uid = AuthService().currentUid;
    if (uid == null) {
      return const Scaffold(
        body: Center(child: Text('Debes iniciar sesión para consultar tus reservas.')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mis Reservas'),
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance
            .collection('reservations')
            .where('ownerId', isEqualTo: uid)
            .snapshots(),
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
                      'Error al sincronizar reservas: ${snapshot.error}',
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
          final allReservations = querySnapshot != null
              ? querySnapshot.docs.map((d) => Reservation.fromDoc(d)).toList()
              : <Reservation>[];

          // Ordenar en memoria por fecha y creación descendente
          allReservations.sort((a, b) => b.createdAt.compareTo(a.createdAt));

          // Filtrar por estado
          final filteredByStatus = allReservations.where((r) {
            if (_selectedFilter == 'Activas') return r.status == ReservationStatus.activa;
            if (_selectedFilter == 'Completadas') return r.status == ReservationStatus.completada;
            if (_selectedFilter == 'Canceladas') return r.status == ReservationStatus.cancelada;
            return true;
          }).toList();

          // Filtrar por placa en búsqueda
          final filtered = filteredByStatus.where((r) {
            if (_searchQuery.isEmpty) return true;
            return r.plate.toUpperCase().contains(_searchQuery.toUpperCase().trim());
          }).toList();

          return RefreshIndicator(
            onRefresh: () async {
              setState(() {});
            },
            child: Column(
              children: [
                // Indicador de sincronización y caché
                if (querySnapshot != null)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                    child: SyncStatusBadge(
                      hasPendingWrites: querySnapshot.metadata.hasPendingWrites,
                      isFromCache: querySnapshot.metadata.isFromCache,
                    ),
                  ),

                // Barra de búsqueda por placa
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                  child: TextField(
                    controller: _searchController,
                    onChanged: (val) => setState(() => _searchQuery = val),
                    decoration: InputDecoration(
                      hintText: 'Buscar reserva por placa...',
                      prefixIcon: const Icon(Icons.search_rounded, size: 20),
                      suffixIcon: _searchQuery.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear, size: 18),
                              onPressed: () {
                                _searchController.clear();
                                setState(() => _searchQuery = '');
                              },
                            )
                          : null,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    ),
                  ),
                ),

                // Filtros de estado con ChoiceChips
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      _buildChip('Todas', allReservations.length),
                      const SizedBox(width: 8),
                      _buildChip(
                        'Activas',
                        allReservations.where((r) => r.status == ReservationStatus.activa).length,
                      ),
                      const SizedBox(width: 8),
                      _buildChip(
                        'Completadas',
                        allReservations.where((r) => r.status == ReservationStatus.completada).length,
                      ),
                      const SizedBox(width: 8),
                      _buildChip(
                        'Canceladas',
                        allReservations.where((r) => r.status == ReservationStatus.cancelada).length,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                const Divider(height: 1, color: AppTheme.borderLight),

                // Listado o Estado Vacío
                Expanded(
                  child: filtered.isEmpty
                      ? _buildEmptyState()
                      : ListView.builder(
                          padding: const EdgeInsets.all(16),
                          physics: const AlwaysScrollableScrollPhysics(
                            parent: BouncingScrollPhysics(),
                          ),
                          itemCount: filtered.length,
                          itemBuilder: (context, index) {
                            final res = filtered[index];
                            return InkWell(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => ReservationDetailScreen(
                                      reservationId: res.id,
                                    ),
                                  ),
                                );
                              },
                              borderRadius: BorderRadius.circular(16),
                              child: ReservationCard(
                                reservation: res,
                                onCancel: res.isActive
                                    ? () => _confirmCancelReservation(res)
                                    : null,
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildChip(String label, int count) {
    final isSelected = _selectedFilter == label;
    return ChoiceChip(
      label: Text('$label ($count)'),
      selected: isSelected,
      onSelected: (val) {
        if (val) setState(() => _selectedFilter = label);
      },
      selectedColor: AppTheme.darkHeader,
      backgroundColor: Colors.white,
      labelStyle: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: isSelected ? Colors.white : AppTheme.textPrimary,
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
            Text(
              _searchQuery.isNotEmpty
                  ? 'No se encontraron reservas con la placa "$_searchQuery".'
                  : 'No tienes reservas registradas en esta categoría.',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: () {
                if (widget.onGoToNewReservation != null) {
                  widget.onGoToNewReservation!();
                }
              },
              icon: const Icon(Icons.add_rounded, size: 18),
              label: const Text('Crear nueva reserva'),
            ),
          ],
        ),
      ),
    );
  }
}
