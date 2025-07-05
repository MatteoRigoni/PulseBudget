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

enum CloudProvider { oneDrive, googleDrive, dropbox, iCloud, custom }

class CloudSyncService {
  final DatabaseService _databaseService;
  static const String _syncFileName = 'bilanciome_sync.json';
  static const String _lastSyncKey = 'last_sync_timestamp';

  CloudSyncService(this._databaseService);

  // Verifica se ci sono modifiche locali
  Future<bool> hasLocalChanges() async {
    final lastSync = await _getLastSyncTime();
    final dbPath = await _getDatabasePath();
    final dbFile = File(dbPath);

    if (!await dbFile.exists()) return false;

    final lastModified = dbFile.lastModifiedSync();
    return lastModified.isAfter(lastSync);
  }

  // Sincronizza con OneDrive
  Future<void> syncWithOneDrive(BuildContext context) async {
    try {
      // 1. Esporta dati correnti
      final data = await _databaseService.exportData();
      final jsonString = jsonEncode(data);

      // 2. Salva file temporaneo
      final tempFile = await _saveTempFile(jsonString);

      // 3. Condividi con OneDrive
      await Share.shareXFiles(
        [XFile(tempFile.path)],
        text: 'BilancioMe - Backup automatico ${DateTime.now().toString()}',
        subject: 'BilancioMe Sync',
      );

      // 4. Aggiorna timestamp sincronizzazione
      await _updateLastSyncTime();

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Sincronizzazione con OneDrive completata!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Errore sincronizzazione: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // Sincronizza con Google Drive
  Future<void> syncWithGoogleDrive(BuildContext context) async {
    try {
      // 1. Esporta dati correnti
      final data = await _databaseService.exportData();
      final jsonString = jsonEncode(data);

      // 2. Salva file temporaneo
      final tempFile = await _saveTempFile(jsonString);

      // 3. Condividi con Google Drive
      await Share.shareXFiles(
        [XFile(tempFile.path)],
        text: 'BilancioMe - Backup automatico ${DateTime.now().toString()}',
        subject: 'BilancioMe Sync',
      );

      // 4. Aggiorna timestamp sincronizzazione
      await _updateLastSyncTime();

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Sincronizzazione con Google Drive completata!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Errore sincronizzazione: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // Ripristina da file cloud
  Future<void> restoreFromCloud(BuildContext context) async {
    try {
      // 1. Richiedi permessi
      final status = await Permission.storage.request();
      if (!status.isGranted) {
        throw Exception('Permessi di accesso ai file non concessi');
      }

      // 2. Apri file picker per selezionare file di backup
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
        allowMultiple: false,
      );

      if (result != null && result.files.isNotEmpty) {
        final file = File(result.files.first.path!);
        final jsonString = await file.readAsString();
        final data = jsonDecode(jsonString) as Map<String, dynamic>;

        // 3. Ripristina dati
        await _databaseService.importData(data);

        // 4. Aggiorna timestamp sincronizzazione
        await _updateLastSyncTime();

        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Ripristino da cloud completato!'),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Errore ripristino: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // Configurazione automatica
  Future<void> setupAutoSync(
      BuildContext context, CloudProvider provider) async {
    // Mostra dialog per configurazione
    await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Sincronizzazione automatica',
              maxLines: 1, overflow: TextOverflow.ellipsis),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Cloud: ${_getProviderName(provider)}',
                  maxLines: 1, overflow: TextOverflow.ellipsis),
              const SizedBox(height: 12),
              const Text(
                'I dati verranno salvati automaticamente nel cloud ogni volta che li modifichi.',
                style: TextStyle(fontSize: 14),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
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
                await _enableAutoSync(provider, context);
              },
              child: const Text('Attiva'),
            ),
          ],
        );
      },
    );
  }

  // Abilita sincronizzazione automatica
  Future<void> _enableAutoSync(
      CloudProvider provider, BuildContext context) async {
    try {
      // Salva configurazione
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('auto_sync_provider', provider.toString());
      await prefs.setBool('auto_sync_enabled', true);

      // Prima sincronizzazione
      switch (provider) {
        case CloudProvider.oneDrive:
          await syncWithOneDrive(context);
          break;
        case CloudProvider.googleDrive:
          await syncWithGoogleDrive(context);
          break;
        default:
          throw Exception('Provider non supportato');
      }

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                'Sincronizzazione automatica attivata con ${_getProviderName(provider)}'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Errore configurazione: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // Verifica se la sincronizzazione automatica è attiva
  Future<bool> isAutoSyncEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('auto_sync_enabled') ?? false;
  }

  // Ottieni provider configurato
  Future<CloudProvider?> getConfiguredProvider() async {
    final prefs = await SharedPreferences.getInstance();
    final providerString = prefs.getString('auto_sync_provider');
    if (providerString != null) {
      return CloudProvider.values.firstWhere(
        (p) => p.toString() == providerString,
        orElse: () => CloudProvider.oneDrive,
      );
    }
    return null;
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

  // Mostra dialog per scegliere provider
  static Future<CloudProvider?> showProviderDialog(BuildContext context) async {
    return showDialog<CloudProvider>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Scegli Cloud Storage'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.cloud, color: Colors.blue),
                title: const Text('OneDrive'),
                subtitle: const Text('Microsoft'),
                onTap: () => Navigator.of(context).pop(CloudProvider.oneDrive),
              ),
              ListTile(
                leading: const Icon(Icons.cloud, color: Colors.green),
                title: const Text('Google Drive'),
                subtitle: const Text('Google'),
                onTap: () =>
                    Navigator.of(context).pop(CloudProvider.googleDrive),
              ),
              ListTile(
                leading: const Icon(Icons.cloud, color: Colors.blue),
                title: const Text('Dropbox'),
                subtitle: const Text('Dropbox Inc.'),
                onTap: () => Navigator.of(context).pop(CloudProvider.dropbox),
              ),
              ListTile(
                leading: const Icon(Icons.cloud, color: Colors.grey),
                title: const Text('iCloud'),
                subtitle: const Text('Apple'),
                onTap: () => Navigator.of(context).pop(CloudProvider.iCloud),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Annulla'),
            ),
          ],
        );
      },
    );
  }
}
