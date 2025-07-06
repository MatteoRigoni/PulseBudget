import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'cloud_sync_service.dart';
import 'database_service.dart';
import '../providers/repository_providers.dart';

class AutoSyncService {
  final DatabaseService _databaseService;
  final CloudSyncService _cloudSyncService;
  bool _isEnabled = false;
  int _backupInterval = 30; // giorni

  AutoSyncService(this._databaseService)
      : _cloudSyncService = CloudSyncService(_databaseService) {
    _loadConfiguration();
  }

  // Carica configurazione salvata
  Future<void> _loadConfiguration() async {
    final prefs = await SharedPreferences.getInstance();
    _isEnabled = prefs.getBool('auto_backup_enabled') ?? false;
    _backupInterval = await _cloudSyncService.getAutoBackupInterval();
  }

  // Abilita backup automatico
  Future<void> enableAutoBackup({int intervalDays = 30}) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('auto_backup_enabled', true);

    _isEnabled = true;
    _backupInterval = intervalDays;

    await _cloudSyncService.setAutoBackupInterval(intervalDays);
  }

  // Disabilita backup automatico
  Future<void> disableAutoBackup() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('auto_backup_enabled', false);

    _isEnabled = false;
  }

  // Imposta intervallo di backup
  Future<void> setBackupInterval(int days) async {
    _backupInterval = days;
    await _cloudSyncService.setAutoBackupInterval(days);
  }

  // Ottieni intervallo di backup
  int get backupInterval => _backupInterval;

  // Verifica se è abilitato
  bool get isEnabled => _isEnabled;

  // Esegue backup automatico se necessario
  Future<void> performBackupIfNeeded() async {
    if (!_isEnabled) return;

    try {
      // Verifica se è necessario fare il backup (basato su intervallo)
      if (await _cloudSyncService.shouldAutoBackup()) {
        await _cloudSyncService.performAutoBackup();
      }
    } catch (e) {
      // Log dell'errore ma non bloccare l'app
      print('Errore backup automatico: $e');
    }
  }

  // Forza backup (ignora intervallo)
  Future<void> forceBackup() async {
    if (!_isEnabled) return;

    try {
      await _cloudSyncService.performAutoBackup();
    } catch (e) {
      print('Errore backup forzato: $e');
    }
  }

  // Ottieni stato backup
  Future<Map<String, dynamic>> getBackupStatus() async {
    final prefs = await SharedPreferences.getInstance();
    final lastBackup = prefs.getInt('last_auto_backup_timestamp');

    return {
      'enabled': _isEnabled,
      'interval': _backupInterval,
      'lastBackup': lastBackup != null
          ? DateTime.fromMillisecondsSinceEpoch(lastBackup)
          : null,
      'shouldBackup': await _cloudSyncService.shouldAutoBackup(),
    };
  }
}

// Provider per il servizio di backup automatico
final autoSyncServiceProvider = Provider<AutoSyncService>((ref) {
  final databaseService = ref.watch(databaseServiceProvider);
  return AutoSyncService(databaseService);
});

// Provider per lo stato di backup
final syncStatusProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final autoSyncService = ref.watch(autoSyncServiceProvider);
  return await autoSyncService.getBackupStatus();
});
