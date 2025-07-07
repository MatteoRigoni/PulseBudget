import 'dart:io';
import 'dart:convert';
import 'package:file_picker/file_picker.dart';
import '../model/imported_transaction.dart';
import '../model/payment_type.dart';

class PdfParserService {
  /// Estrae il testo da un file PDF (simulato per ora)
  static Future<String> extractTextFromPdf(File file) async {
    // Per ora simuliamo l'estrazione del testo
    // In futuro si può integrare una libreria PDF più stabile
    return '''
    INTESTATARIO: MARIO ROSSI
    CONTO CORRENTE: IT60 X054 2811 1010 0000 0123 456
    PERIODO: GENNAIO 2024
    
    01/01/2024;PRELIEVO CARTA;50.00;EUR
    01/01/2024;PAGAMENTO CARTA;50.00;EUR
    02/01/2024;SUPERMERCATO COOP;25.30;EUR
    03/01/2024;PAGAMENTO BONIFICO;100.00;EUR
    04/01/2024;RIMBORSO ASSICURAZIONE;-150.00;EUR
    05/01/2024;PAGAMENTO LUCE;45.20;EUR
    15/01/2024;STIPENDIO GENNAIO;2500.00;EUR
    20/01/2024;PAGAMENTO AFFITTO;-800.00;EUR
    25/01/2024;SPESA FARMACIA;35.50;EUR
    31/01/2024;PAGAMENTO BOLLETTA GAS;-120.00;EUR
    ''';
  }

  /// Seleziona un file PDF
  static Future<File?> pickPdfFile() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
      );

      if (result != null && result.files.single.path != null) {
        return File(result.files.single.path!);
      }
      return null;
    } catch (e) {
      print('Errore nella selezione del file: $e');
      return null;
    }
  }

  /// Estrae l'intestatario dal testo del PDF
  static String extractAccountHolder(String text) {
    // Regex per trovare l'intestatario
    final patterns = [
      RegExp(r'INTESTATARIO:\s*([^\n\r]+)', caseSensitive: false),
      RegExp(r'TITOLARE:\s*([^\n\r]+)', caseSensitive: false),
      RegExp(r'CLIENTE:\s*([^\n\r]+)', caseSensitive: false),
      RegExp(r'COGNOME E NOME:\s*([^\n\r]+)', caseSensitive: false),
      RegExp(r'SIG\.\s*([^\n\r]+)', caseSensitive: false),
    ];

    for (final pattern in patterns) {
      final match = pattern.firstMatch(text);
      if (match != null) {
        return match.group(1)!.trim();
      }
    }

    // Se non trova pattern specifici, cerca nomi comuni italiani
    final namePattern = RegExp(r'\b([A-Z][a-z]+ [A-Z][a-z]+)\b');
    final matches = namePattern.allMatches(text);
    if (matches.isNotEmpty) {
      return matches.first.group(1)!;
    }

    return 'Intestatario non trovato';
  }

  /// Estrae il mese/periodo dall'estratto conto
  static String extractMonth(String text) {
    // Regex per trovare il mese/periodo
    final patterns = [
      RegExp(r'PERIODO:\s*([^\n\r]+)', caseSensitive: false),
      RegExp(r'DAL\s+(\d{1,2}/\d{1,2}/\d{4})\s+AL\s+(\d{1,2}/\d{1,2}/\d{4})',
          caseSensitive: false),
      RegExp(r'(\d{1,2}/\d{1,2}/\d{4})\s*-\s*(\d{1,2}/\d{1,2}/\d{4})',
          caseSensitive: false),
      RegExp(r'([A-Z]+)\s+(\d{4})', caseSensitive: false), // GENNAIO 2024
    ];

    for (final pattern in patterns) {
      final match = pattern.firstMatch(text);
      if (match != null) {
        if (match.groupCount >= 2) {
          // Se ha due date, prendi la seconda (fine periodo)
          final dateStr = match.group(2)!;
          return _formatMonthFromDate(dateStr);
        } else if (match.groupCount == 1) {
          final periodStr = match.group(1)!;
          if (periodStr.contains('/')) {
            return _formatMonthFromDate(periodStr);
          } else {
            return periodStr.trim();
          }
        }
      }
    }

    // Se non trova pattern specifici, cerca nelle date delle transazioni
    final datePattern = RegExp(r'(\d{1,2})/(\d{1,2})/(\d{4})');
    final matches = datePattern.allMatches(text);
    if (matches.isNotEmpty) {
      // Prendi l'ultima data trovata
      final lastMatch = matches.last;
      final day = int.parse(lastMatch.group(1)!);
      final month = int.parse(lastMatch.group(2)!);
      final year = int.parse(lastMatch.group(3)!);

      return _formatMonth(month, year);
    }

    return 'Periodo non trovato';
  }

  /// Formatta una data in formato mese/anno
  static String _formatMonthFromDate(String dateStr) {
    try {
      final parts = dateStr.split('/');
      if (parts.length == 3) {
        final month = int.parse(parts[1]);
        final year = int.parse(parts[2]);
        return _formatMonth(month, year);
      }
    } catch (e) {
      print('Errore nel parsing della data: $dateStr');
    }
    return dateStr;
  }

  /// Formatta mese e anno in italiano
  static String _formatMonth(int month, int year) {
    const months = [
      'GENNAIO',
      'FEBBRAIO',
      'MARZO',
      'APRILE',
      'MAGGIO',
      'GIUGNO',
      'LUGLIO',
      'AGOSTO',
      'SETTEMBRE',
      'OTTOBRE',
      'NOVEMBRE',
      'DICEMBRE'
    ];

    if (month >= 1 && month <= 12) {
      return '${months[month - 1]} $year';
    }
    return '$month/$year';
  }

  /// Estrae informazioni complete dall'estratto conto
  static Map<String, String> extractStatementInfo(String text) {
    return {
      'accountHolder': extractAccountHolder(text),
      'month': extractMonth(text),
    };
  }

  /// Parsa le transazioni dal testo estratto
  static List<ImportedTransaction> parseTransactions(String text) {
    final List<ImportedTransaction> transactions = [];
    final lines = text.split('\n');

    // Regex per estrarre data, descrizione, importo
    final regex = RegExp(r'(\d{2}/\d{2}/\d{4});(.+?);([+-]?\d+\.?\d*);(\w+)');

    for (final line in lines) {
      if (line.trim().isEmpty) continue;
      try {
        final match = regex.firstMatch(line);
        if (match != null) {
          final dateStr = match.group(1)!;
          final description = match.group(2)!.trim();
          final amountStr = match.group(3)!;
          final currency = match.group(4)!;

          final dateParts = dateStr.split('/');
          final date = DateTime(
            int.parse(dateParts[2]),
            int.parse(dateParts[1]),
            int.parse(dateParts[0]),
          );

          final amount = double.parse(amountStr);

          transactions.add(ImportedTransaction(
            date: date,
            description: description,
            amount: amount,
            currency: currency,
            categoryId: '', // Default empty category
            confidence: 0.8, // Default confidence
          ));
        } else {
          print('[PDF PARSER][WARNING] Riga non conforme: "$line"');
        }
      } catch (e, stack) {
        print(
            '[PDF PARSER][ERROR] Errore nel parsing della riga: "$line" -> $e\n$stack');
        // Continua con la prossima riga
      }
    }

    return transactions;
  }

  /// Parsa un file PDF e restituisce le transazioni
  static Future<List<ImportedTransaction>> parsePdfFile(File file) async {
    try {
      final text = await extractTextFromPdf(file);
      return parseTransactions(text);
    } catch (e, stack) {
      print('[PDF PARSER][ERROR] Errore nel parsing del PDF: $e\n$stack');
      return [];
    }
  }

  /// Parsa un file PDF e restituisce transazioni + info estratto conto
  static Future<Map<String, dynamic>> parsePdfFileWithInfo(File file) async {
    try {
      final text = await extractTextFromPdf(file);
      final transactions = parseTransactions(text);
      final info = extractStatementInfo(text);

      return {
        'transactions': transactions,
        'accountHolder': info['accountHolder']!,
        'month': info['month']!,
      };
    } catch (e, stack) {
      print(
          '[PDF PARSER][ERROR] Errore nel parsing del PDF (with info): $e\n$stack');
      return {
        'transactions': <ImportedTransaction>[],
        'accountHolder': 'Errore nel parsing',
        'month': 'Errore nel parsing',
      };
    }
  }
}
