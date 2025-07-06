import 'dart:convert';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter/material.dart';
import 'package:restart_app/restart_app.dart';
import 'database_service.dart';
import 'cloud_sync_service.dart';

class BackupService {
  final DatabaseService _databaseService;

  BackupService(this._databaseService);

  // Esporta dati in formato JSON
  Future<String> exportToJson() async {
    final data = await _databaseService.exportData();
    return jsonEncode(data);
  }

  // Salva backup su file locale
  Future<File?> saveBackupLocally() async {
    try {
      final data = await _databaseService.exportData();
      final jsonString = jsonEncode(data);

      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fileName = 'bilanciome_backup_$timestamp.json';

      // Crea un file temporaneo nella directory temporanea
      final tempDir = await getTemporaryDirectory();
      final tempFile = File('${tempDir.path}/$fileName');
      await tempFile.writeAsString(jsonString);

      // Usa share_plus per permettere all'utente di scegliere dove salvare
      await Share.shareXFiles(
        [XFile(tempFile.path)],
        text: 'Backup BilancioMe',
        subject: 'Dati backup',
      );

      return tempFile;
    } catch (e) {
      throw Exception('Errore nel salvataggio del backup: $e');
    }
  }

  // Carica backup da file
  Future<void> loadBackupFromFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
        allowMultiple: false,
      );

      if (result != null && result.files.isNotEmpty) {
        final file = File(result.files.first.path!);
        final jsonString = await file.readAsString();
        final data = jsonDecode(jsonString) as Map<String, dynamic>;

        await _databaseService.importData(data);
      }
    } catch (e) {
      throw Exception('Errore nel caricamento del backup: $e');
    }
  }

  // Esporta in CSV per Excel
  Future<File?> exportToCsv() async {
    try {
      final data = await _databaseService.exportData();
      final transactions = data['transactions'] as List;

      final csvData = StringBuffer();
      csvData.writeln('Data,Descrizione,Importo,Categoria,Tipo Pagamento');

      for (final transaction in transactions) {
        final date = DateTime.parse(transaction['date']).toLocal();
        final formattedDate =
            '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';

        csvData.writeln([
          formattedDate,
          transaction['description'],
          transaction['amount'].toString(),
          transaction['categoryId'],
          transaction['paymentType'],
        ].map((field) => '"${field.replaceAll('"', '""')}"').join(','));
      }

      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fileName = 'bilanciome_export_$timestamp.csv';

      // Crea un file temporaneo nella directory temporanea
      final tempDir = await getTemporaryDirectory();
      final tempFile = File('${tempDir.path}/$fileName');
      await tempFile.writeAsString(csvData.toString());

      // Usa share_plus per permettere all'utente di scegliere dove salvare
      await Share.shareXFiles(
        [XFile(tempFile.path)],
        text: 'Esportazione CSV da BilancioMe',
        subject: 'Dati transazioni',
      );

      return tempFile;
    } catch (e) {
      throw Exception('Errore nell\'esportazione CSV: $e');
    }
  }

  // Mostra dialog per scegliere opzioni di backup
  static Future<void> showBackupDialog(
      BuildContext context, BackupService backupService) async {
    return showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Backup e Ripristino'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.save),
                title: const Text('Salva backup locale'),
                subtitle: const Text('Salva i dati in un file JSON'),
                onTap: () async {
                  Navigator.of(context).pop();
                  try {
                    final file = await backupService.saveBackupLocally();
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Backup pronto per il salvataggio'),
                        ),
                      );
                    }
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Errore: $e')),
                      );
                    }
                  }
                },
              ),
              ListTile(
                leading: const Icon(Icons.schedule),
                title: const Text('Backup automatico'),
                subtitle: const Text('Crea backup ogni 30 giorni'),
                onTap: () async {
                  Navigator.of(context).pop();
                  final databaseService = DatabaseService();
                  final cloudSyncService = CloudSyncService(databaseService);

                  // Controlla se è già attivo
                  final isEnabled =
                      await cloudSyncService.isAutoBackupEnabled();
                  if (isEnabled) {
                    // Mostra opzioni per disabilitare
                    final action = await showDialog<String>(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        title: const Text('Backup Automatico'),
                        content: const Text(
                            'Il backup automatico è già attivo. Vuoi disabilitarlo?'),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.of(ctx).pop('cancel'),
                            child: const Text('Annulla'),
                          ),
                          ElevatedButton(
                            onPressed: () => Navigator.of(ctx).pop('disable'),
                            child: const Text('Disabilita'),
                          ),
                        ],
                      ),
                    );

                    if (action == 'disable') {
                      await cloudSyncService.disableAutoBackup();
                    }
                  } else {
                    // Configura nuovo backup automatico
                    await CloudSyncService.showAutoBackupConfigDialog(context);
                  }
                },
              ),
              ListTile(
                leading: const Icon(Icons.upload_file),
                title: const Text('Carica backup'),
                subtitle: const Text('Ripristina da file JSON'),
                onTap: () async {
                  Navigator.of(context).pop();
                  try {
                    await backupService.loadBackupFromFile();
                    if (context.mounted) {
                      // Mostra alert di conferma per riavviare l'app
                      final shouldRestart = await showDialog<bool>(
                        context: context,
                        builder: (BuildContext context) {
                          return AlertDialog(
                            title: const Text('Backup ripristinato'),
                            content: const Text(
                              'Il backup è stato caricato con successo. L\'app deve essere riavviata per applicare le modifiche. Vuoi riavviare ora?',
                            ),
                            actions: [
                              TextButton(
                                onPressed: () =>
                                    Navigator.of(context).pop(false),
                                child: const Text('Più tardi'),
                              ),
                              ElevatedButton(
                                onPressed: () =>
                                    Navigator.of(context).pop(true),
                                child: const Text('Riavvia ora'),
                              ),
                            ],
                          );
                        },
                      );

                      if (shouldRestart == true) {
                        Restart.restartApp();
                      }
                    }
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Errore: $e')),
                      );
                    }
                  }
                },
              ),
              ListTile(
                leading: const Icon(Icons.table_chart),
                title: const Text('Esporta in CSV'),
                subtitle: const Text('Per Excel o altri programmi'),
                onTap: () async {
                  Navigator.of(context).pop();
                  try {
                    final file = await backupService.exportToCsv();
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('CSV pronto per il salvataggio'),
                        ),
                      );
                    }
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Errore: $e')),
                      );
                    }
                  }
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Chiudi'),
            ),
          ],
        );
      },
    );
  }
}
