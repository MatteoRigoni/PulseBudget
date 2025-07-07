import 'package:uuid/uuid.dart';
import 'payment_type.dart';
import 'transaction.dart';

class ImportedTransaction {
  final String id;
  final DateTime date;
  final String description;
  final double amount;
  final String currency;
  String categoryId;
  String? suggestedCategoryId;
  double confidence;
  bool isCorrected;

  ImportedTransaction({
    String? id,
    required this.date,
    required this.description,
    required this.amount,
    required this.currency,
    required this.categoryId,
    this.suggestedCategoryId,
    this.confidence = 0.0,
    this.isCorrected = false,
  }) : id = id ?? const Uuid().v4();

  // Factory constructor per creare da una riga di testo
  factory ImportedTransaction.fromLine({
    required String line,
    required DateTime date,
    required double amount,
    required String currency,
    String categoryId = '',
    double confidence = 0.0,
  }) {
    return ImportedTransaction(
      date: date,
      description: line.trim(),
      amount: amount,
      currency: currency,
      categoryId: categoryId,
      confidence: confidence,
    );
  }

  // Metodo per convertire in Transaction (richiede PaymentType)
  Transaction toTransaction(PaymentType paymentType) {
    return Transaction(
      amount: amount,
      date: date,
      description: description,
      categoryId: categoryId,
      paymentType: paymentType,
    );
  }

  // Metodo per creare una copia con modifiche
  ImportedTransaction copyWith({
    String? id,
    DateTime? date,
    String? description,
    double? amount,
    String? currency,
    String? categoryId,
    String? suggestedCategoryId,
    double? confidence,
    bool? isCorrected,
  }) {
    return ImportedTransaction(
      id: id ?? this.id,
      date: date ?? this.date,
      description: description ?? this.description,
      amount: amount ?? this.amount,
      currency: currency ?? this.currency,
      categoryId: categoryId ?? this.categoryId,
      suggestedCategoryId: suggestedCategoryId ?? this.suggestedCategoryId,
      confidence: confidence ?? this.confidence,
      isCorrected: isCorrected ?? this.isCorrected,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ImportedTransaction && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'ImportedTransaction(id: $id, date: $date, description: $description, amount: $amount, confidence: $confidence)';
  }
}
