import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../model/transaction.dart';
import '../../model/payment_type.dart';
import '../../providers/categories_provider.dart';
import '../../model/category.dart';
import '../home/home_screen.dart';

class TransactionCard extends ConsumerStatefulWidget {
  final Transaction transaction;
  final String? highlight;
  const TransactionCard({Key? key, required this.transaction, this.highlight})
      : super(key: key);

  @override
  ConsumerState<TransactionCard> createState() => _TransactionCardState();
}

class _TransactionCardState extends ConsumerState<TransactionCard> {
  bool _isExpanded = false;
  bool _isTextOverflowing = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isIncome = widget.transaction.amount > 0;
    final amountColor =
        isIncome ? HomeScreen.kAppGreen : const Color(0xFFd32f2f);
    final categoriesAsync = ref.watch(categoriesProvider);

    // Gestisci stati di loading e error
    if (categoriesAsync.isLoading) {
      return const Card(
        child: ListTile(
          leading: CircularProgressIndicator(),
          title: Text('Caricamento...'),
        ),
      );
    }

    final categories = categoriesAsync.value ?? [];
    final category = categories.firstWhere(
      (c) => c.id == widget.transaction.categoryId,
      orElse: () => categories.isNotEmpty
          ? categories.first
          : Category(
              id: 'default',
              name: 'Altro',
              icon: Icons.category_outlined,
              colorHex: '#BDBDBD',
              type: 'expense',
            ),
    );
    final iconWidget = category != null
        ? Icon(category.icon, color: category.color, size: 28)
        : const Icon(Icons.category_outlined, size: 28);
    final paymentTypeLabel =
        _labelForPaymentType(widget.transaction.paymentType);
    final paymentTypeIcon = _iconForPaymentType(widget.transaction.paymentType);
    final dateStr = _formatDate(widget.transaction.date);

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          // Solo se il testo è espanso, permette di comprimerlo
          // Altrimenti, se è compresso, lo espande
          setState(() {
            _isExpanded = !_isExpanded;
          });
        },
        child: ListTile(
          isThreeLine: _isExpanded,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
          leading: Stack(
            children: [
              iconWidget,
              if (widget.transaction.isRecurring)
                Positioned(
                  top: 0,
                  right: 0,
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      color: Colors.orange,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.repeat,
                      size: 12,
                      color: Colors.white,
                    ),
                  ),
                ),
            ],
          ),
          title: widget.transaction.isRecurring &&
                  widget.transaction.recurringRuleName != null
              ? Text(
                  widget.transaction.recurringRuleName!,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                )
              : _buildExpandableDescription(
                  widget.transaction.description, widget.highlight, theme),
          subtitle: Text(
            widget.transaction.isRecurring
                ? 'Frequenza: ${_getRecurringFrequencyText(widget.transaction.description)}'
                : dateStr,
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
                    _formatAmount(widget.transaction.amount.abs()),
                style: theme.textTheme.titleMedium
                    ?.copyWith(color: amountColor, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 2),
              Chip(
                label:
                    Text(paymentTypeLabel, style: theme.textTheme.labelSmall),
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
      ),
    );
  }

  Widget _buildExpandableDescription(
      String text, String? highlight, ThemeData theme) {
    Widget textWidget;

    if (highlight == null || highlight.isEmpty) {
      textWidget = _isExpanded
          ? Text(text, style: theme.textTheme.titleMedium)
          : Text(
              text,
              style: theme.textTheme.titleMedium,
              overflow: TextOverflow.ellipsis,
              maxLines: 2,
            );
    } else {
      final lower = text.toLowerCase();
      final query = highlight.toLowerCase();
      final start = lower.indexOf(query);
      if (start < 0) {
        textWidget = _isExpanded
            ? Text(text, style: theme.textTheme.titleMedium)
            : Text(
                text,
                style: theme.textTheme.titleMedium,
                overflow: TextOverflow.ellipsis,
                maxLines: 2,
              );
      } else {
        final end = start + query.length;
        if (_isExpanded) {
          textWidget = RichText(
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
        } else {
          textWidget = RichText(
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
            overflow: TextOverflow.ellipsis,
            maxLines: 2,
          );
        }
      }
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        return textWidget;
      },
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

  String _getRecurringFrequencyText(String description) {
    if (description.contains('Mensile') || description.contains('/')) {
      return 'mensile';
    } else if (description.contains('Settimana')) {
      return 'settimanale';
    } else if (description.contains('Annuale') ||
        description.contains('2024') ||
        description.contains('2025')) {
      return 'annuale';
    }
    return 'sconosciuta';
  }
}
