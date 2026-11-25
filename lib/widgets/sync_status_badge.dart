import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Indicador discreto de sincronización y estado de caché con Cloud Firestore.
/// Muestra "Sincronizando..." si hay escrituras pendientes o "Modo sin conexión" si viene de caché.
class SyncStatusBadge extends StatelessWidget {
  final bool hasPendingWrites;
  final bool isFromCache;

  const SyncStatusBadge({
    super.key,
    required this.hasPendingWrites,
    required this.isFromCache,
  });

  @override
  Widget build(BuildContext context) {
    // Si no hay escrituras pendientes, no mostramos nada para no confundir al usuario
    if (!hasPendingWrites) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: AppTheme.reservedAmber.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.reservedAmber.withValues(alpha: 0.3)),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.sync_rounded, size: 14, color: AppTheme.reservedAmber),
          SizedBox(width: 6),
          Text(
            'Sincronizando con Firestore...',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: AppTheme.reservedAmber,
            ),
          ),
        ],
      ),
    );
  }
}
