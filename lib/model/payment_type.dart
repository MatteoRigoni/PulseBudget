import 'package:flutter/material.dart';

enum PaymentType { bancomat, creditCard, bankTransfer, cash }

extension PaymentTypeUI on PaymentType {
  String get sigla {
    switch (this) {
      case PaymentType.bancomat:
        return 'BAN';
      case PaymentType.creditCard:
        return 'CC';
      case PaymentType.bankTransfer:
        return 'TRF';
      case PaymentType.cash:
        return 'CASH';
    }
  }

  IconData get icon {
    switch (this) {
      case PaymentType.bancomat:
        return Icons.credit_card;
      case PaymentType.creditCard:
        return Icons.credit_card_outlined;
      case PaymentType.bankTransfer:
        return Icons.swap_horiz;
      case PaymentType.cash:
        return Icons.attach_money;
    }
  }
}
