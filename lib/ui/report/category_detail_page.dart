import 'package:flutter/material.dart';
import '../../model/category.dart';
import '../../model/transaction.dart';

class CategoryDetailPage extends StatelessWidget {
  final Category category;
  final DateTimeRange? range;
  const CategoryDetailPage({required this.category, this.range, Key? key})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    // TODO: recupera le transazioni filtrate per categoria e periodo
    final List<Transaction> transactions = [];
    return Scaffold(
      appBar: AppBar(title: Text(category.name)),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              height: 180,
              child: Center(child: Text('Pie chart qui (stub)')),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton.icon(
                  onPressed: () {},
                  icon: Icon(Icons.edit),
                  label: Text('Edit'),
                ),
                TextButton.icon(
                  onPressed: () {},
                  icon: Icon(Icons.delete),
                  label: Text('Elimina'),
                ),
              ],
            ),
            SizedBox(height: 12),
            Text('Transazioni',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            Expanded(
              child: ListView.builder(
                itemCount: transactions.length,
                itemBuilder: (context, idx) {
                  final t = transactions[idx];
                  return ListTile(
                    title: Text(t.description ?? ''),
                    subtitle:
                        Text('${t.date.day}/${t.date.month}/${t.date.year}'),
                    trailing: Text(
                      (t.amount < 0 ? '-' : '+') +
                          t.amount.abs().toStringAsFixed(2) +
                          ' €',
                      style: TextStyle(
                        color: t.amount < 0 ? Colors.red : Colors.green,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
