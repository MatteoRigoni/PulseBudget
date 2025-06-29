import 'package:flutter/foundation.dart';

class RecurringRule {
  final String id;
  final double amount;
  final String categoryId;
  final String paymentType;
  final String rrule; // iCalendar RRULE

  RecurringRule({
    required this.id,
    required this.amount,
    required this.categoryId,
    required this.paymentType,
    required this.rrule,
  });

  RecurringRule copyWith({
    String? id,
    double? amount,
    String? categoryId,
    String? paymentType,
    String? rrule,
  }) {
    return RecurringRule(
      id: id ?? this.id,
      amount: amount ?? this.amount,
      categoryId: categoryId ?? this.categoryId,
      paymentType: paymentType ?? this.paymentType,
      rrule: rrule ?? this.rrule,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RecurringRule &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          amount == other.amount &&
          categoryId == other.categoryId &&
          paymentType == other.paymentType &&
          rrule == other.rrule;

  @override
  int get hashCode =>
      id.hashCode ^
      amount.hashCode ^
      categoryId.hashCode ^
      paymentType.hashCode ^
      rrule.hashCode;
}
