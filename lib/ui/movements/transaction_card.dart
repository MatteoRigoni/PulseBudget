import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../model/transaction.dart';
import '../../model/payment_type.dart';
import '../../providers/categories_provider.dart';
import '../../model/category.dart';
import '../home/home_screen.dart';

class TransactionCard extends ConsumerWidget {
  final Transaction transaction;
  final String? highlight;
  const TransactionCard({Key? key, required this.transaction, this.highlight})
      : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isIncome = transaction.amount > 0;
    final amountColor =
        isIncome ? HomeScreen.kAppGreen : const Color(0xFFd32f2f);
    final categories = ref.watch(categoriesProvider);
    final category = categories.firstWhere(
      (c) => c.id == transaction.categoryId,
      orElse: () => categories.isNotEmpty
          ? categories.first
          : Category(
              id: 'default',
              name: 'Altro',
              iconCodePoint: Icons.category_outlined.codePoint,
              colorHex: '#BDBDBD',
              type: 'expense',
            ),
    );
    final iconWidget = category != null
        ? Icon(category.icon, color: category.color, size: 28)
        : const Icon(Icons.category_outlined, size: 28);
    final paymentTypeLabel = _labelForPaymentType(transaction.paymentType);
    final paymentTypeIcon = _iconForPaymentType(transaction.paymentType);
    final dateStr = _formatDate(transaction.date);
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ListTile(
        isThreeLine: false,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
        leading: iconWidget,
        title: _highlightedText(transaction.description, highlight, theme),
        subtitle: Text(
          dateStr,
          style: TextStyle(
            fontSize: 13,
            color: Colors.grey[700],
          ),
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              (isIncome ? '+' : '-') +
                  '€' +
                  _formatAmount(transaction.amount.abs()),
              style: theme.textTheme.titleMedium
                  ?.copyWith(color: amountColor, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 2),
            Chip(
              label: Text(paymentTypeLabel, style: theme.textTheme.labelSmall),
              avatar: paymentTypeIcon,
              backgroundColor: theme.colorScheme.surfaceVariant,
              visualDensity: VisualDensity(horizontal: -4, vertical: -4),
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              padding: EdgeInsets.symmetric(horizontal: 2, vertical: 0),
              labelPadding: EdgeInsets.zero,
              side: BorderSide.none,
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
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year.toString().padLeft(4, '0')}';
  }

  String _formatAmount(double amount) {
    return amount.toStringAsFixed(2).replaceAllMapped(
          RegExp(r'\B(?=(\d{3})+(?!\d))'),
          (match) => '.',
        );
  }
}
