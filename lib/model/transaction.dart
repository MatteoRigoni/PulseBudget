import 'package:uuid/uuid.dart';
import 'payment_type.dart';

class Transaction {
  final String id;
  final double amount;
  final DateTime date;
  final String description;
  final String descriptionLowercase;
  final String categoryId;
  final PaymentType paymentType;

  Transaction({
    String? id,
    required this.amount,
    required this.date,
    required this.description,
    required this.categoryId,
    required this.paymentType,
  })  : id = id ?? const Uuid().v4(),
        descriptionLowercase = description.toLowerCase();

  // Factory constructor per creare una transazione da JSON
  factory Transaction.fromJson(Map<String, dynamic> json) {
    return Transaction(
      id: json['id'] as String,
      amount: (json['amount'] as num).toDouble(),
      date: DateTime.parse(json['date'] as String),
      description: json['description'] as String,
      categoryId: json['categoryId'] as String,
      paymentType: PaymentType.values.firstWhere(
        (e) => e.toString() == 'PaymentType.${json['paymentType']}',
      ),
    );
  }

  // Metodo per convertire in JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'amount': amount,
      'date': date.toIso8601String(),
      'description': description,
      'categoryId': categoryId,
      'paymentType': paymentType.toString().split('.').last,
    };
  }

  // Metodo per creare una copia con modifiche
  Transaction copyWith({
    String? id,
    double? amount,
    DateTime? date,
    String? description,
    String? categoryId,
    PaymentType? paymentType,
  }) {
    return Transaction(
      id: id ?? this.id,
      amount: amount ?? this.amount,
      date: date ?? this.date,
      description: description ?? this.description,
      categoryId: categoryId ?? this.categoryId,
      paymentType: paymentType ?? this.paymentType,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Transaction && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'Transaction(id: $id, amount: $amount, description: $description, date: $date)';
  }
}
