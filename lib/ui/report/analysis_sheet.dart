import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../model/category.dart';
import '../../model/transaction.dart';
import '../../providers/transactions_provider.dart';
import '../../providers/categories_provider.dart';
import 'category_detail_page.dart';

class AnalysisSheet extends ConsumerStatefulWidget {
  @override
  ConsumerState<AnalysisSheet> createState() => _AnalysisSheetState();
}

class _AnalysisSheetState extends ConsumerState<AnalysisSheet> {
  DateTimeRange? selectedRange;

  // Funzione di aggregazione per categoria
  Map<Category, double> aggregateByCategory(
      List<Transaction> transactions, List<Category> categories) {
    final Map<String, double> totals = {};
    for (final t in transactions) {
      totals[t.categoryId] = (totals[t.categoryId] ?? 0) + t.amount;
    }
    final Map<Category, double> result = {};
    for (final c in categories) {
      if (totals.containsKey(c.id)) {
        result[c] = totals[c.id]!;
      }
    }
    return result;
  }

  @override
  Widget build(BuildContext context) {
    final transactions = ref.watch(transactionsProvider);
    final categories = ref.watch(categoriesProvider);
    List<Transaction> filtered = transactions;
    if (selectedRange != null) {
      filtered = transactions
          .where((t) =>
              t.date.isAfter(
                  selectedRange!.start.subtract(const Duration(days: 1))) &&
              t.date.isBefore(selectedRange!.end.add(const Duration(days: 1))))
          .toList();
    }
    final Map<Category, double> categoryTotals =
        aggregateByCategory(filtered, categories);
    final sortedCategories = categoryTotals.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return Scaffold(
      appBar: AppBar(
        title: Text('Report'),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Periodo:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                TextButton(
                  onPressed: () async {
                    final range = await showDateRangePicker(
                      context: context,
                      firstDate: DateTime(2020),
                      lastDate: DateTime.now(),
                      initialDateRange: selectedRange,
                    );
                    if (range != null) {
                      setState(() => selectedRange = range);
                    }
                  },
                  child: Text(selectedRange == null
                      ? 'Seleziona periodo'
                      : '${selectedRange!.start.day}/${selectedRange!.start.month}/${selectedRange!.start.year} - ${selectedRange!.end.day}/${selectedRange!.end.month}/${selectedRange!.end.year}'),
                ),
              ],
            ),
            SizedBox(height: 16),
            if (categoryTotals.isNotEmpty)
              SizedBox(
                height: 200,
                child: PieChart(
                  PieChartData(
                    sections: [
                      for (final entry in sortedCategories)
                        PieChartSectionData(
                          value: entry.value.abs(),
                          title: entry.key.name,
                          color: entry.key.color,
                          radius: 60,
                        ),
                    ],
                  ),
                ),
              ),
            SizedBox(height: 24),
            Text('Categorie',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            Expanded(
              child: ListView.builder(
                itemCount: sortedCategories.length,
                itemBuilder: (context, idx) {
                  final entry = sortedCategories[idx];
                  return ListTile(
                    leading: Icon(entry.key.icon, color: entry.key.color),
                    title: Text(entry.key.name),
                    trailing: Text(
                      (entry.value < 0 ? '-' : '+') +
                          entry.value.abs().toStringAsFixed(2) +
                          ' €',
                      style: TextStyle(
                        color: entry.value < 0 ? Colors.red : Colors.green,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => CategoryDetailPage(
                          category: entry.key,
                          range: selectedRange,
                        ),
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
