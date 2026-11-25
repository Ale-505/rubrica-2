import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../models/reservation.dart';
import '../services/error_messages.dart';
import '../services/reservations_repository.dart';
import '../theme/app_theme.dart';
import '../widgets/sync_status_badge.dart';
import 'reservation_edit_screen.dart';

/// Pantalla 4 (Obligatoria): Detalle completo de una reserva seleccionada.
class ReservationDetailScreen extends StatefulWidget {
  final String reservationId;

  const ReservationDetailScreen({
    super.key,
    required this.reservationId,
  });

  @override
  State<ReservationDetailScreen> createState() => _ReservationDetailScreenState();
}

class _ReservationDetailScreenState extends State<ReservationDetailScreen> {
  final _repository = ReservationsRepository();
  bool _isProcessing = false;

  void _confirmCancel(Reservation reservation) {
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
            '¿Deseas cancelar la reserva del Espacio ${reservation.spaceNumber} (${reservation.zone})?\nEl espacio quedará inmediatamente disponible en el mapa para otros usuarios.',
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
                setState(() => _isProcessing = true);
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
                    SnackBar(
                      content: Text('Error: $e'),
                      backgroundColor: AppTheme.occupiedRed,
                    ),
                  );
                } finally {
                  if (mounted) setState(() => _isProcessing = false);
                }
              },
              child: const Text('Sí, cancelar'),
            ),
          ],
        );
      },
    );
  }

  void _confirmDelete(Reservation reservation) {
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.delete_forever_rounded, color: AppTheme.occupiedRed),
              SizedBox(width: 8),
              Text('Eliminar reserva'),
            ],
          ),
          content: Text(
            '¿Seguro que deseas eliminar permanentemente la reserva ${reservation.id}?\nEsta acción no se puede deshacer y liberará el espacio en Firestore si estaba activa.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: AppTheme.occupiedRed),
              onPressed: () async {
                Navigator.pop(ctx);
                setState(() => _isProcessing = true);
                try {
                  await _repository.deleteReservationAtomic(reservation.id);
                  if (!mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Reserva eliminada de Firestore exitosamente.'),
                      backgroundColor: AppTheme.availableGreen,
                    ),
                  );
                  Navigator.pop(context); // Vuelve a la lista
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
                    SnackBar(
                      content: Text('Error: $e'),
                      backgroundColor: AppTheme.occupiedRed,
                    ),
                  );
                } finally {
                  if (mounted) setState(() => _isProcessing = false);
                }
              },
              child: const Text('Eliminar definitivamente'),
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
        title: const Text('Detalle de Reserva'),
      ),
      body: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance
            .collection('reservations')
            .doc(widget.reservationId)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text('Error al cargar reserva: ${snapshot.error}'),
              ),
            );
          }

          final doc = snapshot.data;
          if (doc == null || !doc.exists || doc.data() == null) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.info_outline, size: 48, color: AppTheme.textSecondary),
                    const SizedBox(height: 12),
                    const Text(
                      'Esta reserva ya no existe o fue eliminada de Firestore.',
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Volver al listado'),
                    ),
                  ],
                ),
              ),
            );
          }

          final reservation = Reservation.fromDoc(doc);
          final status = reservation.status;

          return SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Indicador de sincronización en vivo
                SyncStatusBadge(
                  hasPendingWrites: doc.metadata.hasPendingWrites,
                  isFromCache: doc.metadata.isFromCache,
                ),

                // Tarjeta Principal de Información
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Encabezado de Espacio y Estado
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: AppTheme.darkHeader,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Icon(
                                    reservation.vehicleType.icon,
                                    color: Colors.white,
                                    size: 24,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Espacio ${reservation.spaceNumber}',
                                      style: const TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.w800,
                                        color: AppTheme.textPrimary,
                                      ),
                                    ),
                                    Text(
                                      reservation.zone,
                                      style: const TextStyle(
                                        fontSize: 13,
                                        color: AppTheme.textSecondary,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),

                            // Chip de Estado
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: status.lightColor,
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: status.color.withValues(alpha: 0.4)),
                              ),
                              child: Text(
                                status.displayName.toUpperCase(),
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w800,
                                  color: status.color,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const Divider(height: 32, color: AppTheme.borderLight),

                        // Datos del Vehículo
                        const Text(
                          'Vehículo Asignado',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFACC15),
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(color: Colors.black, width: 1.5),
                              ),
                              child: Text(
                                reservation.plate,
                                style: const TextStyle(
                                  color: Colors.black,
                                  fontWeight: FontWeight.w900,
                                  fontSize: 14,
                                  letterSpacing: 2,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              reservation.vehicleType.displayName,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: AppTheme.textPrimary,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),

                        // Fecha y Horario
                        const Text(
                          'Fecha y Horario',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            const Icon(Icons.calendar_month_rounded, size: 18, color: AppTheme.darkHeader),
                            const SizedBox(width: 8),
                            Text(
                              reservation.formattedDate,
                              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                            ),
                            const SizedBox(width: 16),
                            const Icon(Icons.access_time_rounded, size: 18, color: AppTheme.darkHeader),
                            const SizedBox(width: 8),
                            Text(
                              reservation.formattedSchedule,
                              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),

                        // Titular de la Reserva
                        const Text(
                          'Titular Institucional',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '${reservation.ownerName} (${reservation.userType.displayName})',
                          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                        ),
                        Text(
                          reservation.ownerEmail,
                          style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary),
                        ),
                        const SizedBox(height: 20),

                        // Recordatorio
                        Row(
                          children: [
                            Icon(
                              reservation.wantsReminder
                                  ? Icons.notifications_active_rounded
                                  : Icons.notifications_off_outlined,
                              size: 18,
                              color: reservation.wantsReminder
                                  ? AppTheme.reservedAmber
                                  : AppTheme.textSecondary,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              reservation.wantsReminder
                                  ? 'Recordatorio de llegada activado'
                                  : 'Sin recordatorio',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: reservation.wantsReminder
                                  ? AppTheme.textPrimary
                                  : AppTheme.textSecondary,
                              ),
                            ),
                          ],
                        ),
                        const Divider(height: 32, color: AppTheme.borderLight),

                        // Metadatos de auditoría
                        Text(
                          'ID en Firestore: ${reservation.id}',
                          style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Fecha de registro: ${reservation.createdAt.toLocal().toString().split('.')[0]}',
                          style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Última modificación: ${reservation.updatedAt.toLocal().toString().split('.')[0]}',
                          style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // Botones de Acción (Editar / Cancelar / Eliminar)
                if (reservation.isActive) ...[
                  ElevatedButton.icon(
                    onPressed: _isProcessing
                        ? null
                        : () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => ReservationEditScreen(reservation: reservation),
                              ),
                            );
                          },
                    icon: const Icon(Icons.edit_rounded, size: 18),
                    label: const Text('Modificar reserva'),
                  ),
                  const SizedBox(height: 10),
                  OutlinedButton.icon(
                    onPressed: _isProcessing ? null : () => _confirmCancel(reservation),
                    icon: const Icon(Icons.cancel_outlined, size: 18, color: AppTheme.occupiedRed),
                    label: const Text(
                      'Cancelar reserva',
                      style: TextStyle(color: AppTheme.occupiedRed),
                    ),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: AppTheme.occupiedRedLight, width: 1.5),
                    ),
                  ),
                  const SizedBox(height: 10),
                ],

                // Botón Eliminar de Firestore
                TextButton.icon(
                  onPressed: _isProcessing ? null : () => _confirmDelete(reservation),
                  icon: const Icon(Icons.delete_outline, size: 18, color: AppTheme.occupiedRed),
                  label: const Text(
                    'Eliminar permanentemente de Firestore',
                    style: TextStyle(color: AppTheme.occupiedRed, fontWeight: FontWeight.w600),
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          );
        },
      ),
    );
  }
}
