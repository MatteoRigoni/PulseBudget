import 'package:flutter/foundation.dart';

class RecurringRule {
  final String id;
  final String name;
  final double amount;
  final String categoryId;
  final String paymentType;
  final String rrule; // iCalendar RRULE
  final DateTime startDate;

  RecurringRule({
    required this.id,
    required this.name,
    required this.amount,
    required this.categoryId,
    required this.paymentType,
    required this.rrule,
    required this.startDate,
  });

  RecurringRule copyWith({
    String? id,
    String? name,
    double? amount,
    String? categoryId,
    String? paymentType,
    String? rrule,
    DateTime? startDate,
  }) {
    return RecurringRule(
      id: id ?? this.id,
      name: name ?? this.name,
      amount: amount ?? this.amount,
      categoryId: categoryId ?? this.categoryId,
      paymentType: paymentType ?? this.paymentType,
      rrule: rrule ?? this.rrule,
      startDate: startDate ?? this.startDate,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RecurringRule &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          name == other.name &&
          amount == other.amount &&
          categoryId == other.categoryId &&
          paymentType == other.paymentType &&
          rrule == other.rrule &&
          startDate == other.startDate;

  @override
  int get hashCode =>
      id.hashCode ^
      name.hashCode ^
      amount.hashCode ^
      categoryId.hashCode ^
      paymentType.hashCode ^
      rrule.hashCode ^
      startDate.hashCode;

  // Factory constructor per creare una regola ricorrente da JSON
  factory RecurringRule.fromJson(Map<String, dynamic> json) {
    return RecurringRule(
      id: json['id'] as String,
      name: json['name'] as String,
      amount: (json['amount'] as num).toDouble(),
      categoryId: json['categoryId'] as String,
      paymentType: json['paymentType'] as String,
      rrule: json['rrule'] as String,
      startDate: DateTime.parse(json['startDate'] as String),
    );
  }

  // Metodo per convertire in JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'amount': amount,
      'categoryId': categoryId,
      'paymentType': paymentType,
      'rrule': rrule,
      'startDate': startDate.toIso8601String(),
    };
  }
}
