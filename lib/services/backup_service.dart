import 'dart:convert';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter/material.dart';
import 'database_service.dart';

class BackupService {
  final DatabaseService _databaseService;

  BackupService(this._databaseService);

  // Esporta dati in formato JSON
  Future<String> exportToJson() async {
    final data = await _databaseService.exportData();
    return jsonEncode(data);
  }

  // Salva backup su file locale
  Future<File> saveBackupLocally() async {
    final data = await _databaseService.exportData();
    final jsonString = jsonEncode(data);

    final directory = await getApplicationDocumentsDirectory();
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final file = File('${directory.path}/bilanciome_backup_$timestamp.json');

    await file.writeAsString(jsonString);
    return file;
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
  Future<File> exportToCsv() async {
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

    final directory = await getApplicationDocumentsDirectory();
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final file = File('${directory.path}/bilanciome_export_$timestamp.csv');

    await file.writeAsString(csvData.toString());
    return file;
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
                        SnackBar(
                          content: Text('Backup salvato: ${file.path}'),
                          action: SnackBarAction(
                            label: 'Condividi',
                            onPressed: () {
                              // TODO: Implementare condivisione file
                            },
                          ),
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
                leading: const Icon(Icons.upload_file),
                title: const Text('Carica backup'),
                subtitle: const Text('Ripristina da file JSON'),
                onTap: () async {
                  Navigator.of(context).pop();
                  try {
                    await backupService.loadBackupFromFile();
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content: Text('Backup caricato con successo')),
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
                leading: const Icon(Icons.table_chart),
                title: const Text('Esporta in CSV'),
                subtitle: const Text('Per Excel o altri programmi'),
                onTap: () async {
                  Navigator.of(context).pop();
                  try {
                    final file = await backupService.exportToCsv();
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('CSV esportato: ${file.path}'),
                          action: SnackBarAction(
                            label: 'Condividi',
                            onPressed: () {
                              // TODO: Implementare condivisione file
                            },
                          ),
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
