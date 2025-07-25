import 'package:flutter/material.dart';
import '../../model/snapshot.dart';
import 'package:intl/intl.dart';

class SnapshotCard extends StatelessWidget {
  final Snapshot snapshot;
  final Snapshot? previous;
  final VoidCallback onDelete;

  const SnapshotCard({
    Key? key,
    required this.snapshot,
    required this.previous,
    required this.onDelete,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final dateStr = DateFormat('dd/MM/yyyy').format(snapshot.date);
    final amountStr = NumberFormat.currency(locale: 'it_IT', symbol: '\u20ac')
        .format(snapshot.amount);
    double? delta;
    double? deltaPerc;
    if (previous != null) {
      delta = snapshot.amount - previous!.amount;
      if (previous!.amount != 0) {
        deltaPerc = delta / previous!.amount * 100;
      }
    }
    final isPositive = (delta ?? 0) >= 0;
    final deltaColor = isPositive ? Colors.green : Colors.red;
    final deltaIcon = isPositive ? Icons.trending_up : Icons.trending_down;
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
      leading: CircleAvatar(
        backgroundColor: isPositive && delta != null && delta != 0
            ? Colors.green.withOpacity(0.13)
            : !isPositive && delta != null && delta != 0
                ? Colors.red.withOpacity(0.13)
                : Theme.of(context).colorScheme.primary.withOpacity(0.13),
        child: (delta != null && delta != 0)
            ? Icon(
                isPositive ? Icons.trending_up : Icons.trending_down,
                color: isPositive ? Colors.green : Colors.red,
                size: 24,
              )
            : const Icon(Icons.account_balance_wallet_outlined,
                color: Colors.blueGrey, size: 24),
      ),
      title: Text(
        amountStr,
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: Theme.of(context).colorScheme.onSurface,
        ),
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            dateStr,
            style: TextStyle(
              fontSize: 13,
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
            ),
          ),
          if (snapshot.note != null && snapshot.note!.trim().isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Text(
                snapshot.note!,
                style: TextStyle(
                  fontSize: 14,
                  color:
                      Theme.of(context).colorScheme.onSurface.withOpacity(0.8),
                ),
              ),
            ),
        ],
      ),
      trailing: (delta != null && delta != 0)
          ? Text(
              '${isPositive ? '+ ' : '- '}${NumberFormat.currency(locale: 'it_IT', symbol: '\u20ac').format(delta!.abs())}',
              style: TextStyle(
                color: deltaColor,
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
            )
          : null,
    );
  }
}
