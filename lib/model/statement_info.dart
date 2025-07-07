class StatementInfo {
  final String id;
  final String accountHolder;
  final String month;
  final DateTime processedDate;
  final int transactionCount;
  final String paymentType;

  StatementInfo({
    required this.id,
    required this.accountHolder,
    required this.month,
    required this.processedDate,
    required this.transactionCount,
    required this.paymentType,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'accountHolder': accountHolder,
      'month': month,
      'processedDate': processedDate.toIso8601String(),
      'transactionCount': transactionCount,
      'paymentType': paymentType,
    };
  }

  factory StatementInfo.fromJson(Map<String, dynamic> json) {
    return StatementInfo(
      id: json['id'] as String,
      accountHolder: json['accountHolder'] as String,
      month: json['month'] as String,
      processedDate: DateTime.parse(json['processedDate'] as String),
      transactionCount: json['transactionCount'] as int,
      paymentType: json['paymentType'] as String,
    );
  }

  StatementInfo copyWith({
    String? id,
    String? accountHolder,
    String? month,
    DateTime? processedDate,
    int? transactionCount,
    String? paymentType,
  }) {
    return StatementInfo(
      id: id ?? this.id,
      accountHolder: accountHolder ?? this.accountHolder,
      month: month ?? this.month,
      processedDate: processedDate ?? this.processedDate,
      transactionCount: transactionCount ?? this.transactionCount,
      paymentType: paymentType ?? this.paymentType,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is StatementInfo && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'StatementInfo(id: $id, accountHolder: $accountHolder, month: $month, transactionCount: $transactionCount)';
  }
}
