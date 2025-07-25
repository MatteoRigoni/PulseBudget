import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../model/category.dart';
import '../../model/transaction.dart';
import '../../providers/transactions_provider.dart';
import '../../providers/categories_provider.dart';
import '../../providers/snapshot_provider.dart';
import '../../model/snapshot.dart';
import 'category_detail_page.dart';
import 'package:intl/intl.dart';
import 'dart:math' as Math;
import '../widgets/app_title_widget.dart';

class AnalysisSheet extends ConsumerStatefulWidget {
  @override
  ConsumerState<AnalysisSheet> createState() => _AnalysisSheetState();
}

class _AnalysisSheetState extends ConsumerState<AnalysisSheet> {
  DateTimeRange? selectedRange;
  String selectedType = 'expense'; // 'expense' o 'income'
  String selectedReport = 'category'; // 'category' o 'patrimony'

  @override
  void initState() {
    super.initState();
    // Default: ultimo anno
    final now = DateTime.now();
    selectedRange = DateTimeRange(
      start: DateTime(now.year - 1, now.month, now.day),
      end: now,
    );
  }

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
    final entities = ref.watch(entityProvider);
    final transactionsAsync = ref.watch(transactionsProvider);
    final categoriesAsync = ref.watch(categoriesProvider);
    final snapshotsAsync = ref.watch(snapshotProvider);

    // Gestisci stati di loading e error
    if (transactionsAsync.isLoading ||
        categoriesAsync.isLoading ||
        snapshotsAsync.isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (transactionsAsync.hasError ||
        categoriesAsync.hasError ||
        snapshotsAsync.hasError) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              Text('Errore nel caricamento'),
            ],
          ),
        ),
      );
    }

    final transactions = transactionsAsync.value ?? [];
    final categories = categoriesAsync.value ?? [];
    final snapshots = snapshotsAsync.value ?? [];

    // Filtra snapshots per periodo selezionato
    List<dynamic> filteredSnapshots = snapshots;
    if (selectedRange != null) {
      filteredSnapshots = snapshots
          .where((s) =>
              s.date.isAfter(
                  selectedRange!.start.subtract(const Duration(days: 1))) &&
              s.date.isBefore(selectedRange!.end.add(const Duration(days: 1))))
          .toList();
    }

    List<Transaction> filtered = transactions;
    if (selectedRange != null) {
      filtered = transactions
          .where((t) =>
              t.date.isAfter(
                  selectedRange!.start.subtract(const Duration(days: 1))) &&
              t.date.isBefore(selectedRange!.end.add(const Duration(days: 1))))
          .toList();
    }
    // Filtro per tipo
    filtered = filtered
        .where((t) => selectedType == 'expense' ? t.amount < 0 : t.amount > 0)
        .toList();
    final Map<Category, double> categoryTotals =
        aggregateByCategory(filtered, categories);
    final sortedCategories = categoryTotals.entries.toList()
      ..sort((a, b) => b.value.abs().compareTo(a.value.abs()));

    // Filtra solo le categorie significative (>3%) o le prime 6
    final total =
        sortedCategories.fold<double>(0, (sum, e) => sum + e.value.abs());
    final significant = sortedCategories
        .where((e) => (e.value.abs() / (total == 0 ? 1 : total)) >= 0.03)
        .toList();
    final shown = significant.length >= 6
        ? significant
        : sortedCategories.take(6).toList();
    final shownTotal = shown.fold<double>(0, (sum, e) => sum + e.value.abs());

    // Ottieni il titolo dinamico
    String getTitle() {
      switch (selectedReport) {
        case 'category':
          return 'Ripartizione categorie';
        case 'patrimony':
          return 'Andamento patrimonio';
        default:
          return 'Report';
      }
    }

    // Determina se mostrare il toggle entrate/uscite
    bool showTypeToggle() {
      return selectedReport == 'category';
    }

    // Determina se ci sono dati da mostrare
    bool hasData() {
      switch (selectedReport) {
        case 'category':
          return shown.isNotEmpty;
        case 'patrimony':
          return filteredSnapshots.isNotEmpty;
        default:
          return false;
      }
    }

    return Scaffold(
      appBar: AppBar(
        centerTitle: false,
        title: Row(
          mainAxisAlignment: MainAxisAlignment.start,
          mainAxisSize: MainAxisSize.max,
          children: [
            Icon(Icons.bar_chart,
                size: 24, color: Theme.of(context).colorScheme.primary),
            const SizedBox(width: 8),
            const Text('Report', style: TextStyle(fontWeight: FontWeight.w600)),
          ],
        ),
        actions: [
          PopupMenuButton<String>(
            icon: Icon(Icons.tune),
            onSelected: (value) {
              setState(() {
                selectedReport = value;
              });
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'category',
                child: Text('Ripartizione categorie'),
              ),
              PopupMenuItem(
                value: 'patrimony',
                child: Text('Andamento patrimonio'),
              ),
            ],
          ),
        ],
      ),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          // Titolo sempre visibile
          Padding(
            padding: const EdgeInsets.only(top: 24, bottom: 8),
            child: Text(
              getTitle(),
              style: Theme.of(context)
                  .textTheme
                  .headlineSmall
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
          ),
          // Filtro periodo sempre visibile
          Padding(
            padding: const EdgeInsets.only(left: 10.0),
            child: Row(
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
          ),
          // Toggle entrate/uscite sempre visibile
          if (showTypeToggle())
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SegmentedButton<String>(
                    segments: [
                      ButtonSegment(
                        value: 'expense',
                        label: const Text('Uscite'),
                        icon: Icon(
                          Icons.arrow_downward,
                          color: selectedType == 'expense'
                              ? Colors.red
                              : Colors.grey,
                        ),
                      ),
                      ButtonSegment(
                        value: 'income',
                        label: const Text('Entrate'),
                        icon: Icon(
                          Icons.arrow_upward,
                          color: selectedType == 'income'
                              ? Colors.green
                              : Colors.grey,
                        ),
                      ),
                    ],
                    selected: {selectedType},
                    onSelectionChanged: (s) {
                      setState(() => selectedType = s.first);
                    },
                    showSelectedIcon: false, // Nessuna spunta
                  ),
                ],
              ),
            ),
          const SizedBox(height: 8),
          // Area del grafico - placeholder solo se non ci sono dati
          Expanded(
            child: hasData()
                ? selectedReport == 'category'
                    ? _FullScreenPie(
                        shown: shown,
                        shownTotal: shownTotal,
                      )
                    : _PatrimonyBarChart(
                        snapshots: filteredSnapshots,
                      )
                : Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.bar_chart,
                            size: 64, color: Colors.amber.shade400),
                        const SizedBox(height: 16),
                        Text('Nessun dato per il periodo selezionato!',
                            textAlign: TextAlign.center,
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(color: Colors.grey.shade600)),
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

class _LinePainter extends CustomPainter {
  final Offset start;
  final Offset end;
  final Color color;
  _LinePainter(this.start, this.end, this.color);
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 2;
    canvas.drawLine(start, end, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _FullScreenPie extends StatelessWidget {
  final List<MapEntry<Category, double>> shown;
  final double shownTotal;
  const _FullScreenPie({required this.shown, required this.shownTotal});
  @override
  Widget build(BuildContext context) {
    if (shown.isEmpty) return const SizedBox.shrink();
    // Mostra solo le 10 categorie più significative
    final shownLimited = shown.take(10).toList();
    final shownTotalLimited =
        shownLimited.fold<double>(0, (sum, e) => sum + e.value.abs());
    return LayoutBuilder(
      builder: (context, constraints) {
        final size =
            Math.min(constraints.maxWidth, constraints.maxHeight) * 0.7;
        final center =
            Offset(constraints.maxWidth / 2, constraints.maxHeight / 2);
        final radius = size / 2.1;
        double startRadian = -1.5708; // -pi/2
        // Precalcola sweep per ogni fetta
        final sweeps = shownLimited
            .map((e) => (e.value.abs() / shownTotalLimited) * 6.28319)
            .toList();
        return Stack(
          children: [
            Center(
              child: SizedBox(
                width: size,
                height: size,
                child: PieChart(
                  PieChartData(
                    sectionsSpace: 2,
                    centerSpaceRadius: 0,
                    startDegreeOffset: -90,
                    sections: [
                      for (final entry in shownLimited)
                        PieChartSectionData(
                          value: entry.value.abs(),
                          color: entry.key.color,
                          radius: radius,
                          showTitle: true,
                          title: () {
                            final percent = shownTotalLimited > 0
                                ? (entry.value.abs() / shownTotalLimited * 100)
                                : 0;
                            return percent > 5
                                ? '${percent.toStringAsFixed(1)}%'
                                : '';
                          }(),
                          titleStyle: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                            color: Colors.white,
                            shadows: [
                              Shadow(
                                  blurRadius: 3,
                                  color: Colors.black.withOpacity(0.5)),
                            ],
                          ),
                          titlePositionPercentageOffset: 0.7,
                        ),
                    ],
                  ),
                ),
              ),
            ),
            // Overlay: linee e label esterne (solo nome categoria)
            ..._buildExternalLabels(
              shown: shownLimited,
              shownTotal: shownTotalLimited,
              center: center,
              radius: radius,
              sweeps: sweeps,
            ),
          ],
        );
      },
    );
  }
}

List<Widget> _buildExternalLabels({
  required List<MapEntry<Category, double>> shown,
  required double shownTotal,
  required Offset center,
  required double radius,
  required List<double> sweeps,
}) {
  final List<Widget> widgets = [];
  double startRadian = -1.5708;
  for (int i = 0; i < shown.length; i++) {
    final entry = shown[i];
    final sweep = sweeps[i];
    final midRadian = startRadian + sweep / 2;
    // Punto di partenza linea (bordo fetta)
    final lineStart = Offset(
      center.dx + radius * Math.cos(midRadian),
      center.dy + radius * Math.sin(midRadian),
    );
    // Punto di arrivo label (fuori dal cerchio)
    final labelDx = center.dx + (radius + 36) * Math.cos(midRadian);
    final labelDy = center.dy + (radius + 36) * Math.sin(midRadian);
    final labelPos = Offset(labelDx, labelDy);
    // Linea
    widgets.add(
      CustomPaint(
        painter: _LinePainter(lineStart, labelPos, entry.key.color),
      ),
    );
    // Label (solo nome categoria)
    widgets.add(
      Positioned(
        left: labelPos.dx - 60,
        top: labelPos.dy - 18,
        width: 120,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.92),
            borderRadius: BorderRadius.circular(8),
            boxShadow: [
              BoxShadow(color: Colors.black12, blurRadius: 4),
            ],
            border:
                Border.all(color: entry.key.color.withOpacity(0.7), width: 1.2),
          ),
          child: Text(
            entry.key.name,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: entry.key.color,
            ),
          ),
        ),
      ),
    );
    startRadian += sweep;
  }
  return widgets;
}

class _CategoryPieData {
  final String name;
  final double value;
  final Color color;
  _CategoryPieData(
      {required this.name, required this.value, required this.color});
}

class _PatrimonyBarChart extends ConsumerStatefulWidget {
  final List<dynamic> snapshots;
  const _PatrimonyBarChart({required this.snapshots});

  @override
  ConsumerState<_PatrimonyBarChart> createState() => _PatrimonyBarChartState();
}

class _PatrimonyBarChartState extends ConsumerState<_PatrimonyBarChart> {
  Set<String> _selectedAccounts = {};

  @override
  void initState() {
    super.initState();
    final accounts = widget.snapshots.map((s) => s.label).toSet();
    _selectedAccounts = accounts.cast<String>();
  }

  @override
  Widget build(BuildContext context) {
    final entities = ref.watch(entityProvider);
    if (widget.snapshots.isEmpty) return const SizedBox.shrink();

    // Verifica che ci siano dati validi
    final validSnapshots =
        widget.snapshots.where((s) => s.amount.isFinite).toList();
    if (validSnapshots.isEmpty) {
      return const Center(
        child: Text('Nessun dato valido da visualizzare'),
      );
    }

    // Raggruppa gli snapshot per data
    final Map<DateTime, Map<String, double>> snapshotsByDate = {};
    for (final snapshot in validSnapshots) {
      final date =
          DateTime(snapshot.date.year, snapshot.date.month, snapshot.date.day);
      snapshotsByDate.putIfAbsent(date, () => {});
      snapshotsByDate[date]![snapshot.label] = snapshot.amount;
    }

    // Ottieni tutti gli account disponibili
    final allAccounts = validSnapshots.map((s) => s.label).toSet();

    // Se non ci sono account selezionati, seleziona tutti
    if (_selectedAccounts.isEmpty) {
      _selectedAccounts = allAccounts.cast<String>();
    }

    // Filtra solo gli account selezionati
    final selectedAccounts = allAccounts
        .where((account) => _selectedAccounts.contains(account))
        .toList();

    // Se non ci sono account selezionati, mostra messaggio
    if (selectedAccounts.isEmpty) {
      return const Center(
        child: Text('Nessun account selezionato'),
      );
    }

    // Ordina le date
    final sortedDates = snapshotsByDate.keys.toList()..sort();

    // Colori per gli account
    final colors = [
      const Color(0xFF2ECC71), // Verde
      const Color(0xFF3498DB), // Blu
      const Color(0xFFE74C3C), // Rosso
      const Color(0xFFF39C12), // Arancione
      const Color(0xFF9B59B6), // Viola
      const Color(0xFF1ABC9C), // Turchese
      const Color(0xFFE67E22), // Arancione scuro
      const Color(0xFF34495E), // Grigio scuro
    ];

    // Prepara i dati per il grafico a barre impilate
    final barGroups = sortedDates.asMap().entries.map((entry) {
      final index = entry.key;
      final date = entry.value;
      final dateSnapshots = snapshotsByDate[date]!;

      double currentY = 0;
      final stackItems = <BarChartRodStackItem>[];
      for (int i = 0; i < allAccounts.length; i++) {
        final account = allAccounts.elementAt(i);
        if (!_selectedAccounts.contains(account)) continue;
        final amount = dateSnapshots[account] ?? 0.0;
        if (amount.isFinite && amount > 0) {
          stackItems.add(
            BarChartRodStackItem(
              currentY,
              currentY + amount,
              colors[i % colors.length],
            ),
          );
          currentY += amount;
        }
      }
      return BarChartGroupData(
        x: index,
        barRods: [
          BarChartRodData(
            toY: currentY,
            rodStackItems: stackItems,
            width: 20,
            borderRadius: BorderRadius.circular(4),
          ),
        ],
      );
    }).toList();

    // Calcola valori per la scala Y in modo sicuro
    double maxValue = 1000;
    double minValue = 0;

    if (sortedDates.isNotEmpty) {
      // Calcola il totale massimo per ogni data
      final maxTotals = <double>[];

      for (final date in sortedDates) {
        final dateSnapshots = snapshotsByDate[date]!;
        double total = 0;
        bool hasValidData = false;

        for (final account in selectedAccounts) {
          final amount = dateSnapshots[account] ?? 0.0;
          if (amount.isFinite && amount > 0) {
            total += amount;
            hasValidData = true;
          }
        }

        if (hasValidData && total.isFinite) {
          maxTotals.add(total);
        }
      }

      if (maxTotals.isNotEmpty) {
        maxValue = maxTotals.reduce((a, b) => a > b ? a : b);

        // Verifica che maxValue sia finito e positivo
        if (maxValue.isFinite && maxValue > 0) {
          // Aggiungi margini sicuri
          maxValue = maxValue * 1.2;
        } else {
          maxValue = 1000;
        }
      } else {
        maxValue = 1000;
      }
    }

    // Verifica finale che i valori siano validi
    if (!maxValue.isFinite || maxValue <= 0) {
      maxValue = 1000;
    }
    minValue = 0;

    // Verifica che ci siano barre valide da mostrare
    final hasValidBars = barGroups.any((group) => group.barRods.isNotEmpty);
    if (!hasValidBars) {
      return const Center(
        child: Text('Nessun dato valido da visualizzare'),
      );
    }

    return Column(
      children: [
        // Legenda account - sempre visibile
        Container(
          padding: const EdgeInsets.all(16.0),
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: allAccounts.map((account) {
              final i = allAccounts.toList().indexOf(account);
              final isSelected = _selectedAccounts.contains(account);
              final color = colors[i % colors.length];
              final entity = entities.firstWhere(
                (e) => e.name == account,
                orElse: () => Entity(id: '', type: '', name: account),
              );
              return FilterChip(
                label: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (isSelected)
                      Padding(
                        padding: const EdgeInsets.only(right: 4),
                        child: Icon(Icons.check,
                            size: 16, color: Colors.grey.shade700),
                      ),
                    Text(
                      account,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade200,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        entity.type,
                        style: TextStyle(
                          fontSize: 10,
                          color: Colors.grey.shade700,
                        ),
                      ),
                    ),
                  ],
                ),
                selected: isSelected,
                onSelected: (selected) {
                  setState(() {
                    if (selected) {
                      _selectedAccounts.add(account);
                    } else {
                      _selectedAccounts.remove(account);
                    }
                  });
                },
                backgroundColor: Colors.grey.shade200,
                selectedColor: Theme.of(context).colorScheme.secondaryContainer,
                showCheckmark: false,
              );
            }).toList(),
          ),
        ),
        // Grafico
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(16.0),
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: maxValue,
                minY: minValue,
                barTouchData: BarTouchData(
                  touchTooltipData: BarTouchTooltipData(
                    tooltipBgColor: Colors.grey.shade800,
                    tooltipRoundedRadius: 8,
                    getTooltipItem: (group, groupIndex, rod, rodIndex) {
                      final date = sortedDates[group.x];
                      final dateSnapshots = snapshotsByDate[date]!;
                      final dateStr = DateFormat('dd/MM/yyyy').format(date);

                      // Trova l'account corrispondente a questa sezione della barra
                      final fromY = rod.fromY;
                      final toY = rod.toY;

                      // Trova l'account basandosi sulla posizione Y
                      String? account;
                      double amount = 0;
                      Color color = Colors.white;

                      double currentY = 0;
                      for (int i = 0; i < selectedAccounts.length; i++) {
                        final acc = selectedAccounts[i];
                        final accAmount = dateSnapshots[acc] ?? 0.0;
                        if (accAmount.isFinite && accAmount > 0) {
                          final accFromY = currentY;
                          final accToY = currentY + accAmount;

                          if (fromY >= accFromY && toY <= accToY) {
                            account = acc;
                            amount = accAmount;
                            color = colors[i % colors.length];
                            break;
                          }
                          currentY = accToY;
                        }
                      }

                      if (account != null) {
                        return BarTooltipItem(
                          '$dateStr\n',
                          const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                          children: [
                            TextSpan(
                              text: '$account: €${amount.toStringAsFixed(2)}',
                              style: TextStyle(
                                color: color,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        );
                      } else {
                        return BarTooltipItem(
                          '$dateStr\n',
                          const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                          children: [
                            const TextSpan(
                              text: 'Nessun dato',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        );
                      }
                    },
                  ),
                ),
                titlesData: FlTitlesData(
                  show: true,
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        if (value.toInt() >= 0 &&
                            value.toInt() < sortedDates.length) {
                          final date = sortedDates[value.toInt()];
                          return Padding(
                            padding: const EdgeInsets.only(top: 8.0),
                            child: Text(
                              DateFormat('dd/MM').format(date),
                              style: const TextStyle(
                                color: Colors.grey,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          );
                        }
                        return const Text('');
                      },
                      reservedSize: 40,
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 60,
                      getTitlesWidget: (value, meta) {
                        if (value.isFinite) {
                          return Text(
                            '€${value.toInt()}',
                            style: const TextStyle(
                              color: Colors.grey,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          );
                        }
                        return const Text('');
                      },
                    ),
                  ),
                ),
                borderData: FlBorderData(
                  show: true,
                  border: Border.all(
                    color: Colors.grey.shade300,
                    width: 1,
                  ),
                ),
                barGroups: barGroups,
                gridData: const FlGridData(
                  show: false,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
