class Snapshot {
  final String id;
  final DateTime date;
  final String label; // es. "Conto Corrente"
  final double amount;
  final String? note;

  Snapshot({
    required this.id,
    required this.date,
    required this.label,
    required this.amount,
    this.note,
  });

  Snapshot copyWith({
    String? id,
    DateTime? date,
    String? label,
    double? amount,
    String? note,
  }) {
    return Snapshot(
      id: id ?? this.id,
      date: date ?? this.date,
      label: label ?? this.label,
      amount: amount ?? this.amount,
      note: note ?? this.note,
    );
  }

  @override
  String toString() =>
      'Snapshot(id: $id, date: $date, label: $label, amount: $amount, note: $note)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Snapshot &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          date == other.date &&
          label == other.label &&
          amount == other.amount &&
          note == other.note;

  @override
  int get hashCode =>
      id.hashCode ^
      date.hashCode ^
      label.hashCode ^
      amount.hashCode ^
      (note?.hashCode ?? 0);

  // Factory constructor per creare uno snapshot da JSON
  factory Snapshot.fromJson(Map<String, dynamic> json) {
    return Snapshot(
      id: json['id'] as String,
      date: DateTime.parse(json['date'] as String),
      label: json['label'] as String,
      amount: (json['amount'] as num).toDouble(),
      note: json['note'] as String?,
    );
  }

  // Metodo per convertire in JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'date': date.toIso8601String(),
      'label': label,
      'amount': amount,
      'note': note,
    };
  }
}

class Entity {
  final String id;
  final String type; // Conto, Dossier, Altro
  final String name;

  Entity({required this.id, required this.type, required this.name});

  Entity copyWith({String? id, String? type, String? name}) {
    return Entity(
      id: id ?? this.id,
      type: type ?? this.type,
      name: name ?? this.name,
    );
  }

  @override
  String toString() => 'Entity(id: $id, type: $type, name: $name)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Entity &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          type == other.type &&
          name == other.name;

  @override
  int get hashCode => id.hashCode ^ type.hashCode ^ name.hashCode;
}
