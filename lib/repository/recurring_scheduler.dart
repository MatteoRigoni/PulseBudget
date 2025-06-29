import '../model/recurring_rule.dart';
import '../model/transaction.dart';
import '../model/payment_type.dart';
import 'package:intl/intl.dart';

/// Genera le transazioni ricorrenti "scadute" (solo se la data corrente corrisponde alla ricorrenza e non esistono già).
/// Supporta FREQ=MONTHLY (1 del mese), FREQ=WEEKLY (lunedì), FREQ=YEARLY (1 gennaio).
/// [existingTransactions] serve per evitare duplicati.
List<Transaction> generateDueRecurringTransactions({
  required List<RecurringRule> rules,
  required List<Transaction> existingTransactions,
  required DateTime now,
}) {
  final List<Transaction> result = [];
  final int year = now.year;
  final int month = now.month;
  final int day = now.day;
  final int weekday = now.weekday; // 1 = lunedì

  for (final rule in rules) {
    if (rule.rrule.startsWith('FREQ=MONTHLY')) {
      // Solo il 1 del mese
      if (day == 1) {
        final dueDate = DateTime(year, month, 1);
        final transactionId = '${rule.id}_${year}_${month}';
        final alreadyExists =
            existingTransactions.any((t) => t.id == transactionId);
        if (!alreadyExists) {
          result.add(_buildTransaction(rule, dueDate, transactionId,
              '[Ricorrente] ${dueDate.month}/${dueDate.year}'));
        }
      }
    } else if (rule.rrule.startsWith('FREQ=WEEKLY')) {
      // Solo il lunedì
      if (weekday == DateTime.monday) {
        final dueDate = DateTime(year, month, day);
        final transactionId = '${rule.id}_${year}_w${_weekOfYear(now)}';
        final alreadyExists =
            existingTransactions.any((t) => t.id == transactionId);
        if (!alreadyExists) {
          result.add(_buildTransaction(rule, dueDate, transactionId,
              '[Ricorrente] Settimana ${_weekOfYear(now)}'));
        }
      }
    } else if (rule.rrule.startsWith('FREQ=YEARLY')) {
      // Solo il 1 gennaio
      if (month == 1 && day == 1) {
        final dueDate = DateTime(year, 1, 1);
        final transactionId = '${rule.id}_${year}';
        final alreadyExists =
            existingTransactions.any((t) => t.id == transactionId);
        if (!alreadyExists) {
          result.add(_buildTransaction(
              rule, dueDate, transactionId, '[Ricorrente] $year'));
        }
      }
    }
  }
  return result;
}

Transaction _buildTransaction(
    RecurringRule rule, DateTime date, String id, String description) {
  PaymentType paymentType;
  try {
    paymentType = PaymentType.values.firstWhere(
      (e) => e.toString() == 'PaymentType.${rule.paymentType}',
    );
  } catch (_) {
    paymentType = PaymentType.cash;
  }
  return Transaction(
    id: id,
    amount: rule.amount,
    categoryId: rule.categoryId,
    paymentType: paymentType,
    date: date,
    description: description,
  );
}

// Calcola la settimana dell'anno (ISO 8601)
int _weekOfYear(DateTime date) {
  final firstDayOfYear = DateTime(date.year, 1, 1);
  final daysOffset = DateTime.monday - firstDayOfYear.weekday;
  final firstMonday = firstDayOfYear.add(Duration(days: daysOffset));
  if (date.isBefore(firstMonday)) {
    return 1;
  }
  final diff = date.difference(firstMonday).inDays;
  return 1 + (diff ~/ 7);
}
