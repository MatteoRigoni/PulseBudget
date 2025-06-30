import 'package:flutter/material.dart';
import '../../model/transaction.dart';
import '../../model/payment_type.dart';

class TransactionCard extends StatelessWidget {
  final Transaction transaction;
  final String? highlight;
  const TransactionCard({Key? key, required this.transaction, this.highlight})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isIncome = transaction.amount > 0;
    final amountColor = isIncome ? Colors.green : Colors.red;
    final icon = _iconForCategory(transaction.categoryId);
    final paymentTypeLabel = _labelForPaymentType(transaction.paymentType);
    final paymentTypeIcon = _iconForPaymentType(transaction.paymentType);
    final dateStr = _formatDate(transaction.date);
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 0),
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ListTile(
        leading: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceVariant,
            borderRadius: BorderRadius.circular(12),
          ),
          child: icon,
        ),
        title: _highlightedText(transaction.description, highlight, theme),
        subtitle: Text(dateStr,
            style: theme.textTheme.bodySmall
                ?.copyWith(color: theme.colorScheme.primary)),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              (isIncome ? '+' : '-') +
                  '€' +
                  transaction.amount.abs().toStringAsFixed(2),
              style: theme.textTheme.titleMedium
                  ?.copyWith(color: amountColor, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 4),
            Chip(
              label: Text(paymentTypeLabel, style: theme.textTheme.labelSmall),
              avatar: paymentTypeIcon,
              backgroundColor: theme.colorScheme.surfaceVariant,
              visualDensity: VisualDensity.compact,
              padding: EdgeInsets.zero,
            ),
          ],
        ),
      ),
    );
  }

  Widget _highlightedText(String text, String? highlight, ThemeData theme) {
    if (highlight == null || highlight.isEmpty)
      return Text(text, style: theme.textTheme.titleMedium);
    final lower = text.toLowerCase();
    final query = highlight.toLowerCase();
    final start = lower.indexOf(query);
    if (start < 0) return Text(text, style: theme.textTheme.titleMedium);
    final end = start + query.length;
    return RichText(
      text: TextSpan(
        style: theme.textTheme.titleMedium,
        children: [
          TextSpan(text: text.substring(0, start)),
          TextSpan(
              text: text.substring(start, end),
              style: const TextStyle(backgroundColor: Color(0xFFB3E5FC))),
          TextSpan(text: text.substring(end)),
        ],
      ),
    );
  }

  Widget _iconForCategory(String categoryId) {
    // Placeholder: puoi mappare le icone in base alla categoria
    switch (categoryId) {
      case 'food':
        return const Icon(Icons.shopping_cart_outlined, size: 28);
      case 'salary':
        return const Icon(Icons.work_outline, size: 28);
      case 'utilities':
        return const Icon(Icons.lightbulb_outline, size: 28);
      case 'transport':
        return const Icon(Icons.directions_bus, size: 28);
      case 'restaurant':
        return const Icon(Icons.restaurant, size: 28);
      case 'online':
        return const Icon(Icons.local_shipping_outlined, size: 28);
      case 'fuel':
        return const Icon(Icons.local_gas_station, size: 28);
      case 'gym':
        return const Icon(Icons.fitness_center, size: 28);
      case 'coffee':
        return const Icon(Icons.coffee, size: 28);
      case 'cinema':
        return const Icon(Icons.movie_creation_outlined, size: 28);
      default:
        return const Icon(Icons.category_outlined, size: 28);
    }
  }

  String _labelForPaymentType(PaymentType type) {
    switch (type) {
      case PaymentType.cash:
        return 'Contanti';
      case PaymentType.bancomat:
        return 'Bancomat';
      case PaymentType.creditCard:
        return 'Carta';
      case PaymentType.bankTransfer:
        return 'Bonifico';
      default:
        return type.name;
    }
  }

  Widget _iconForPaymentType(PaymentType type) {
    switch (type) {
      case PaymentType.cash:
        return const Icon(Icons.payments_outlined, size: 16);
      case PaymentType.bancomat:
        return const Icon(Icons.credit_card, size: 16);
      case PaymentType.creditCard:
        return const Icon(Icons.credit_card, size: 16);
      case PaymentType.bankTransfer:
        return const Icon(Icons.account_balance, size: 16);
      default:
        return const Icon(Icons.payment, size: 16);
    }
  }

  String _formatDate(DateTime date) {
    return '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }
}
