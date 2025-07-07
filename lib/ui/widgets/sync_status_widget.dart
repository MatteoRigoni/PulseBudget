import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../services/auto_sync_service.dart';
import 'custom_snackbar.dart';

class SyncStatusWidget extends ConsumerWidget {
  const SyncStatusWidget({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final syncStatusAsync = ref.watch(syncStatusProvider);

    return syncStatusAsync.when(
      data: (status) {
        final isEnabled = status['enabled'] as bool? ?? false;
        final provider = status['provider'] as String?;
        final lastSync = status['lastSync'] as DateTime?;
        final hasChanges = status['hasChanges'] as bool? ?? false;

        if (!isEnabled) {
          return const SizedBox.shrink();
        }

        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceVariant,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: hasChanges ? Colors.orange : Colors.green,
              width: 1,
            ),
          ),
          child: Row(
            children: [
              Icon(
                hasChanges ? Icons.cloud_sync : Icons.cloud_done,
                color: hasChanges ? Colors.orange : Colors.green,
                size: 20,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Sincronizzazione ${_getProviderName(provider)}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    if (lastSync != null)
                      Text(
                        'Ultima sincronizzazione: ${_formatDate(lastSync)}',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    if (hasChanges)
                      Text(
                        'Modifiche non sincronizzate',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Colors.orange,
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                  ],
                ),
              ),
              if (hasChanges)
                IconButton(
                  icon: const Icon(Icons.sync, size: 16),
                  onPressed: () {
                    // TODO: Implementare sincronizzazione manuale
                    CustomSnackBar.show(
                      context,
                      message: 'Sincronizzazione in corso...',
                      type: SnackBarType.info,
                    );
                  },
                  tooltip: 'Sincronizza ora',
                ),
            ],
          ),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }

  String _getProviderName(String? provider) {
    if (provider == null) return 'Cloud';

    switch (provider) {
      case 'CloudProvider.oneDrive':
        return 'OneDrive';
      case 'CloudProvider.googleDrive':
        return 'Google Drive';
      case 'CloudProvider.dropbox':
        return 'Dropbox';
      case 'CloudProvider.iCloud':
        return 'iCloud';
      default:
        return 'Cloud';
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays > 0) {
      return '${difference.inDays} giorni fa';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} ore fa';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} minuti fa';
    } else {
      return 'Ora';
    }
  }
}
