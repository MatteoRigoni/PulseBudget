import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import '../model/imported_transaction.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';
import 'dart:typed_data';

class PdfParserService {
  static Future<String> extractTextFromPdf(File file) async {
    try {
      if (!await file.exists()) {
        throw const FileSystemException('File does not exist');
      }

      final Uint8List bytes = await file.readAsBytes();
      final PdfDocument document = PdfDocument(inputBytes: bytes);
      final String text = PdfTextExtractor(document).extractText();
      document.dispose();

      return text;
    } catch (e, s) {
      _log('[PDF PARSER][ERROR] Failed to read PDF – using stub. $e', s);
      return _mockText;
    }
  }

  /// Opens a file picker that only shows PDF documents.
  static Future<File?> pickPdfFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: const ['pdf'],
      );

      final path = result?.files.single.path;
      return path == null ? null : File(path);
    } catch (e, s) {
      _log('[PDF PARSER][ERROR] File picking failed: $e', s);
      return null;
    }
  }

  /// Extracts *account holder* name.
  static String extractAccountHolder(String text) {
    for (final regExp in _accountHolderPatterns) {
      final match = regExp.firstMatch(text);
      if (match != null) return match.group(1)!.trim();
    }

    // Fallback – guess the first capitalised *First Last* sequence.
    final guess = _nameGuessRegExp.firstMatch(text);
    return guess?.group(1)?.trim() ?? 'Intestatario non trovato';
  }

  /// Extracts the statement *period* (e.g. "GENNAIO 2024").
  static String extractMonth(String text) {
    for (final regExp in _periodPatterns) {
      final m = regExp.firstMatch(text);
      if (m != null) {
        return _normalisePeriod(m);
      }
    }

    // Heuristic fallback: use the **last** transaction date and convert.
    final dates = _dateRegExp.allMatches(text).map((m) => m.group(0)!).toList();
    if (dates.isNotEmpty) {
      return _monthYearFromDateString(dates.last);
    }
    return 'Periodo non trovato';
  }

  /// Convenience method that bundles holder + period.
  static Map<String, String> extractStatementInfo(String text) => {
        'accountHolder': extractAccountHolder(text),
        'month': extractMonth(text),
      };

  /// Parses all transactions in [text]. Lines that don’t match the expected
  /// pattern will be logged and skipped.
  static List<ImportedTransaction> parseTransactions(String text) {
    final List<ImportedTransaction> result = [];
    int totalLines = 0;
    int skippedLines = 0;
    print('[PDF PARSER][INFO] Inizio parsing testo PDF...');
    for (final line in LineSplitter.split(text)) {
      totalLines++;
      if (line.trim().isEmpty) continue;
      final match = _transactionLineRegExp.firstMatch(line);
      if (match == null) {
        skippedLines++;
        print('[PDF PARSER][WARNING] Riga non riconosciuta: "$line"');
        continue;
      }
      try {
        final date = _parseDate(match.group(1)!);
        final description = match.group(2)!.trim();
        final amount = _parseAmount(match.group(3)!);
        final currency = match.group(4) ?? 'EUR';
        result.add(
          ImportedTransaction(
            date: date,
            description: description,
            amount: amount,
            currency: currency,
            categoryId: '',
            confidence: 0.8,
          ),
        );
      } catch (e, s) {
        skippedLines++;
        print('[PDF PARSER][ERROR] Errore parsing riga: "$line" – $e');
      }
    }
    print('[PDF PARSER][INFO] Parsing completato. Righe totali: '
        ' [1m$totalLines [0m, transazioni riconosciute: '
        ' [1m${result.length} [0m, righe scartate: '
        ' [1m$skippedLines [0m');
    return result;
  }

  /// Parses the whole PDF and returns *transactions only*.
  static Future<List<ImportedTransaction>> parsePdfFile(File file) async {
    final text = await extractTextFromPdf(file);
    return parseTransactions(text);
  }

  /// Parses the whole PDF and returns transactions **and** basic header info.
  static Future<Map<String, dynamic>> parsePdfFileWithInfo(File file) async {
    final text = await extractTextFromPdf(file);
    return {
      'transactions': parseTransactions(text),
      ...extractStatementInfo(text),
    };
  }

  /* ----------------------------------------------------------------------- */
  /*  Private helpers                                                        */
  /* ----------------------------------------------------------------------- */

  /// Regexes – extracted to top level for clarity & easier maintenance.
  static final List<RegExp> _accountHolderPatterns = [
    RegExp(r'INTESTATARIO:\s*([^\n\r]+)', caseSensitive: false),
    RegExp(r'TITOLARE:\s*([^\n\r]+)', caseSensitive: false),
    RegExp(r'CLIENTE:\s*([^\n\r]+)', caseSensitive: false),
    RegExp(r'COGNOME E NOME:\s*([^\n\r]+)', caseSensitive: false),
    RegExp(r'SIG\.\s*([^\n\r]+)', caseSensitive: false),
  ];

  static final RegExp _nameGuessRegExp =
      RegExp(r'\b([A-Z][a-zÀ-ÖØ-öø-ÿ]+ [A-Z][a-zÀ-ÖØ-öø-ÿ]+)\b');

  static final List<RegExp> _periodPatterns = [
    RegExp(r'PERIODO:\s*([^\n\r]+)', caseSensitive: false),
    RegExp(
        r'DAL\s+(\d{1,2}[/-]\d{1,2}[/-]\d{4})\s+AL\s+(\d{1,2}[/-]\d{1,2}[/-]\d{4})',
        caseSensitive: false),
    RegExp(
        r'(\d{1,2}[/-]\d{1,2}[/-]\d{4})\s*-\s*(\d{1,2}[/-]\d{1,2}[/-]\d{4})'),
    // "GENNAIO 2024" or "Gennaio 2024"
    RegExp(r'([A-ZÀ-ÖØ-öø-ÿ]+)\s+(\d{4})', caseSensitive: false),
  ];

  static final RegExp _dateRegExp = RegExp(r'(\d{1,2}[/-]\d{1,2}[/-]\d{2,4})');

  /// Matches typical CSV‑style row. Captures:
  ///   1 – date            2 – description   3 – amount   4? – currency
  static final RegExp _transactionLineRegExp = RegExp(
    r'^\s*(\d{1,2}[/-]\d{1,2}[/-]\d{2,4})\s*[;|\t]\s*(.+?)\s*[;|\t]\s*([+-]?\d[\d.,]*)\s*(?:[;|\t]\s*([A-Z]{3}))?\s*\$',
    caseSensitive: false,
  );

  static DateTime _parseDate(String raw) {
    final normalised = raw.replaceAll('-', '/');
    final parts = normalised.split('/').map(int.parse).toList();
    return DateTime(
        parts[2] < 100 ? parts[2] + 2000 : parts[2], parts[1], parts[0]);
  }

  static double _parseAmount(String raw) {
    final cleaned = raw.replaceAll('.', '').replaceAll(',', '.');
    return double.parse(cleaned);
  }

  static String _normalisePeriod(RegExpMatch m) {
    // Pattern with two dates → take *end* date.
    if (m.groupCount >= 2 && m.group(2)!.contains('/')) {
      return _monthYearFromDateString(m.group(2)!);
    }
    // Pattern "GENNAIO 2024".
    if (m.groupCount == 2 && !m.group(1)!.contains('/')) {
      return '${m.group(1)!.toUpperCase()} ${m.group(2)}';
    }
    // Single date.
    return _monthYearFromDateString(m.group(1)!);
  }

  static String _monthYearFromDateString(String dateStr) {
    final parts =
        dateStr.replaceAll('-', '/').split('/').map(int.parse).toList();
    return _formatMonth(parts[1], parts[2]);
  }

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
    return month >= 1 && month <= 12
        ? '${months[month - 1]} $year'
        : '$month/$year';
  }

  static void _log(String msg, [StackTrace? s]) =>
      // ignore: avoid_print
      s == null ? print(msg) : print('$msg\n$s');

  /* ----------------------------------------------------------------------- */
  /*  Stub data – helps running the app without a real PDF                   */
  /* ----------------------------------------------------------------------- */
  static const String _mockText = '''
INTESTATARIO: MARIO ROSSI
CONTO CORRENTE: IT60 X054 2811 1010 0000 0123 456
PERIODO: GENNAIO 2024

01/01/2024;PRELIEVO CARTA;50.00;EUR
01/01/2024;PAGAMENTO CARTA;50.00;EUR
02/01/2024;SUPERMERCATO COOP;25,30;EUR
03/01/2024;PAGAMENTO BONIFICO;100.00;EUR
04/01/2024;RIMBORSO ASSICURAZIONE;-150.00;EUR
05/01/2024;PAGAMENTO LUCE;45,20;EUR
15/01/2024;STIPENDIO GENNAIO;2.500,00;EUR
20/01/2024;PAGAMENTO AFFITTO;-800.00;EUR
25/01/2024;SPESA FARMACIA;35.50;EUR
31/01/2024;PAGAMENTO BOLLETTA GAS;-120.00;EUR
''';
}
