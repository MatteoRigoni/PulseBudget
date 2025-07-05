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
  final DateTime twoMonthsAgo = DateTime(now.year, now.month - 2, 1);

  for (final rule in rules) {
    // Calcola la data di partenza: max(startDate, due mesi fa)
    DateTime start =
        rule.startDate.isAfter(twoMonthsAgo) ? rule.startDate : twoMonthsAgo;
    DateTime? current = _firstOccurrenceOnOrAfter(rule, start);
    while (current != null && !current.isAfter(now)) {
      String transactionId = _transactionIdForRule(rule, current);
      final alreadyExists =
          existingTransactions.any((t) => t.id == transactionId);
      if (!alreadyExists) {
        result.add(_buildTransaction(
          rule,
          current,
          transactionId,
          '[Ricorrente] ${_descriptionForOccurrence(rule, current)}',
        ));
      }
      current = _nextOccurrence(rule, current);
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
    isRecurring: true,
    recurringRuleName: rule.name,
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

DateTime _firstOccurrenceOnOrAfter(RecurringRule rule, DateTime from) {
  if (rule.rrule.startsWith('FREQ=MONTHLY')) {
    return DateTime(from.year, from.month, 1);
  } else if (rule.rrule.startsWith('FREQ=WEEKLY')) {
    // Trova il prossimo lunedì
    int daysToAdd = (DateTime.monday - from.weekday) % 7;
    return from.add(Duration(days: daysToAdd));
  } else if (rule.rrule.startsWith('FREQ=YEARLY')) {
    return DateTime(from.year, 1, 1);
  }
  return from;
}

DateTime? _nextOccurrence(RecurringRule rule, DateTime prev) {
  if (rule.rrule.startsWith('FREQ=MONTHLY')) {
    return DateTime(prev.year, prev.month + 1, 1);
  } else if (rule.rrule.startsWith('FREQ=WEEKLY')) {
    return prev.add(const Duration(days: 7));
  } else if (rule.rrule.startsWith('FREQ=YEARLY')) {
    return DateTime(prev.year + 1, 1, 1);
  }
  return null;
}

String _transactionIdForRule(RecurringRule rule, DateTime date) {
  if (rule.rrule.startsWith('FREQ=MONTHLY')) {
    return '${rule.id}_${date.year}_${date.month}';
  } else if (rule.rrule.startsWith('FREQ=WEEKLY')) {
    return '${rule.id}_${date.year}_w${_weekOfYear(date)}';
  } else if (rule.rrule.startsWith('FREQ=YEARLY')) {
    return '${rule.id}_${date.year}';
  }
  return '${rule.id}_${date.toIso8601String()}';
}

String _descriptionForOccurrence(RecurringRule rule, DateTime date) {
  if (rule.rrule.startsWith('FREQ=MONTHLY')) {
    return '${date.month}/${date.year}';
  } else if (rule.rrule.startsWith('FREQ=WEEKLY')) {
    return 'Settimana ${_weekOfYear(date)}';
  } else if (rule.rrule.startsWith('FREQ=YEARLY')) {
    return '${date.year}';
  }
  return '';
}
