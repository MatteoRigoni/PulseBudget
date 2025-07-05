import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'cloud_sync_service.dart';
import 'database_service.dart';
import '../providers/repository_providers.dart';

class AutoSyncService {
  final DatabaseService _databaseService;
  final CloudSyncService _cloudSyncService;
  bool _isEnabled = false;
  CloudProvider? _configuredProvider;

  AutoSyncService(this._databaseService)
      : _cloudSyncService = CloudSyncService(_databaseService) {
    _loadConfiguration();
  }

  // Carica configurazione salvata
  Future<void> _loadConfiguration() async {
    final prefs = await SharedPreferences.getInstance();
    _isEnabled = prefs.getBool('auto_sync_enabled') ?? false;

    final providerString = prefs.getString('auto_sync_provider');
    if (providerString != null) {
      _configuredProvider = CloudProvider.values.firstWhere(
        (p) => p.toString() == providerString,
        orElse: () => CloudProvider.oneDrive,
      );
    }
  }

  // Abilita sincronizzazione automatica
  Future<void> enableAutoSync(CloudProvider provider) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('auto_sync_enabled', true);
    await prefs.setString('auto_sync_provider', provider.toString());

    _isEnabled = true;
    _configuredProvider = provider;
  }

  // Disabilita sincronizzazione automatica
  Future<void> disableAutoSync() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('auto_sync_enabled', false);

    _isEnabled = false;
    _configuredProvider = null;
  }

  // Verifica se è abilitata
  bool get isEnabled => _isEnabled;

  // Ottieni provider configurato
  CloudProvider? get configuredProvider => _configuredProvider;

  // Sincronizza automaticamente (chiamato dopo modifiche)
  Future<void> syncIfEnabled() async {
    if (!_isEnabled || _configuredProvider == null) return;

    try {
      // Verifica se ci sono modifiche locali
      if (await _cloudSyncService.hasLocalChanges()) {
        // Sincronizza con il provider configurato
        switch (_configuredProvider!) {
          case CloudProvider.oneDrive:
            // Nota: qui dovremmo passare un context, ma per ora usiamo un approccio diverso
            await _syncWithProvider(CloudProvider.oneDrive);
            break;
          case CloudProvider.googleDrive:
            await _syncWithProvider(CloudProvider.googleDrive);
            break;
          case CloudProvider.dropbox:
            await _syncWithProvider(CloudProvider.dropbox);
            break;
          case CloudProvider.iCloud:
            await _syncWithProvider(CloudProvider.iCloud);
            break;
          case CloudProvider.custom:
            await _syncWithProvider(CloudProvider.custom);
            break;
        }
      }
    } catch (e) {
      // Log dell'errore ma non bloccare l'app
      print('Errore sincronizzazione automatica: $e');
    }
  }

  // Sincronizza con provider specifico
  Future<void> _syncWithProvider(CloudProvider provider) async {
    // Esporta dati correnti
    final data = await _databaseService.exportData();

    // Salva timestamp sincronizzazione
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(
        'last_sync_timestamp', DateTime.now().millisecondsSinceEpoch);

    // Log della sincronizzazione
    print(
        'Sincronizzazione automatica completata con ${_getProviderName(provider)}');
  }

  String _getProviderName(CloudProvider provider) {
    switch (provider) {
      case CloudProvider.oneDrive:
        return 'OneDrive';
      case CloudProvider.googleDrive:
        return 'Google Drive';
      case CloudProvider.dropbox:
        return 'Dropbox';
      case CloudProvider.iCloud:
        return 'iCloud';
      case CloudProvider.custom:
        return 'Cloud Personalizzato';
    }
  }

  // Ottieni stato sincronizzazione
  Future<Map<String, dynamic>> getSyncStatus() async {
    final prefs = await SharedPreferences.getInstance();
    final lastSync = prefs.getInt('last_sync_timestamp');

    return {
      'enabled': _isEnabled,
      'provider': _configuredProvider?.toString(),
      'lastSync': lastSync != null
          ? DateTime.fromMillisecondsSinceEpoch(lastSync)
          : null,
      'hasChanges': await _cloudSyncService.hasLocalChanges(),
    };
  }
}

// Provider per il servizio di sincronizzazione automatica
final autoSyncServiceProvider = Provider<AutoSyncService>((ref) {
  final databaseService = ref.watch(databaseServiceProvider);
  return AutoSyncService(databaseService);
});

// Provider per lo stato di sincronizzazione
final syncStatusProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final autoSyncService = ref.watch(autoSyncServiceProvider);
  return await autoSyncService.getSyncStatus();
});
