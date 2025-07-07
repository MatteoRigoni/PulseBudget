import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:file_picker/file_picker.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite/sqflite.dart';
import 'database_service.dart';
import 'package:flutter/material.dart';
import '../main.dart';
import '../ui/widgets/custom_snackbar.dart';

class CloudSyncService {
  final DatabaseService _databaseService;
  static const String _syncFileName = 'bilanciome_backup.json';
  static const String _lastSyncKey = 'last_auto_backup_timestamp';
  static const String _syncIntervalKey = 'auto_backup_interval_days';

  CloudSyncService(this._databaseService);

  // Verifica se è necessario fare il backup automatico (basato su intervallo)
  Future<bool> shouldAutoBackup() async {
    final prefs = await SharedPreferences.getInstance();
    final intervalDays = prefs.getInt(_syncIntervalKey) ?? 30;
    final lastBackup = await _getLastSyncTime();
    final now = DateTime.now();

    return now.difference(lastBackup).inDays >= intervalDays;
  }

  // Ottieni intervallo di backup automatico configurato
  Future<int> getAutoBackupInterval() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_syncIntervalKey) ?? 30;
  }

  // Imposta intervallo di backup automatico
  Future<void> setAutoBackupInterval(int days) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_syncIntervalKey, days);
  }

  // Esegue backup automatico
  Future<void> performAutoBackup() async {
    try {
      // 1. Esporta dati correnti
      final data = await _databaseService.exportData();
      final jsonString = jsonEncode(data);

      // 2. Salva file temporaneo
      final tempFile = await _saveTempFile(jsonString);

      // 3. Apre menu di condivisione con spiegazione
      await Share.shareXFiles(
        [XFile(tempFile.path)],
        text:
            'BilancioMe - Backup automatico ${DateTime.now().toString()}\n\nQuesto backup è stato generato automaticamente per mantenere i tuoi dati al sicuro. Puoi salvarlo nel cloud, inviarlo via email o archiviarlo localmente.',
        subject: 'BilancioMe - Backup Automatico',
      );

      // 4. Aggiorna timestamp backup
      await _updateLastSyncTime();

      print('Backup automatico completato');
    } catch (e) {
      print('Errore backup automatico: $e');
    }
  }

  // Verifica se il backup automatico è attivo
  Future<bool> isAutoBackupEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('auto_backup_enabled') ?? false;
  }

  // Abilita backup automatico
  Future<void> enableAutoBackup() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('auto_backup_enabled', true);

    if (navigatorKey.currentContext != null) {
      CustomSnackBar.show(
        navigatorKey.currentContext!,
        message: 'Backup automatico attivato',
        type: SnackBarType.success,
      );
    }
  }

  // Disabilita backup automatico
  Future<void> disableAutoBackup() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('auto_backup_enabled', false);

    if (navigatorKey.currentContext != null) {
      CustomSnackBar.show(
        navigatorKey.currentContext!,
        message: 'Backup automatico disabilitato',
        type: SnackBarType.warning,
      );
    }
  }

  // Esegue backup automatico se necessario (chiamato all'avvio app)
  Future<void> performAutoBackupIfNeeded(BuildContext context) async {
    try {
      final isEnabled = await isAutoBackupEnabled();
      if (!isEnabled) return;

      final shouldBackup = await shouldAutoBackup();
      if (shouldBackup) {
        await performAutoBackup();

        if (navigatorKey.currentContext != null) {
          CustomSnackBar.show(
            navigatorKey.currentContext!,
            message: 'Backup automatico completato',
            type: SnackBarType.success,
            duration: Duration(seconds: 2),
          );
        }
      }
    } catch (e) {
      print('Errore backup automatico: $e');
    }
  }

  // Mostra dialog per configurare backup automatico
  static Future<void> showAutoBackupConfigDialog(BuildContext context) async {
    return showDialog(
      context: navigatorKey.currentContext!,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Backup Automatico'),
          content: const Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Il backup automatico creerà un file di backup ogni 30 giorni e ti permetterà di scegliere dove salvarlo (cloud, email, locale, ecc.).',
                style: TextStyle(fontSize: 14),
              ),
              SizedBox(height: 12),
              Text(
                'Questo ti aiuta a mantenere i tuoi dati al sicuro senza dover ricordarti di fare backup manuali.',
                style: TextStyle(fontSize: 14, fontStyle: FontStyle.italic),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Annulla'),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.of(context).pop();
                final databaseService = DatabaseService();
                final cloudSyncService = CloudSyncService(databaseService);
                await cloudSyncService.enableAutoBackup();
              },
              child: const Text('Attiva'),
            ),
          ],
        );
      },
    );
  }

  // Metodi di utilità
  Future<File> _saveTempFile(String content) async {
    final tempDir = await getTemporaryDirectory();
    final file = File('${tempDir.path}/$_syncFileName');
    await file.writeAsString(content);
    return file;
  }

  Future<String> _getDatabasePath() async {
    final dbPath = await getDatabasesPath();
    return '$dbPath/bilanciome.db';
  }

  Future<DateTime> _getLastSyncTime() async {
    final prefs = await SharedPreferences.getInstance();
    final timestamp = prefs.getInt(_lastSyncKey);
    return timestamp != null
        ? DateTime.fromMillisecondsSinceEpoch(timestamp)
        : DateTime(1970);
  }

  Future<void> _updateLastSyncTime() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_lastSyncKey, DateTime.now().millisecondsSinceEpoch);
  }
}
