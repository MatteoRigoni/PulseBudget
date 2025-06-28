import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String _period = 'Mese';
  int _selectedMonth = 0;
  int _selectedYear = DateTime.now().year;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final now = DateTime.now();
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: const Text('Pulse Budget'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {},
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // PeriodSegmented
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: SegmentedButton<String>(
                segments: const [
                  ButtonSegment(value: 'Mese', label: Text('Mese')),
                  ButtonSegment(value: 'Anno', label: Text('Anno')),
                ],
                selected: <String>{_period},
                onSelectionChanged: (s) {
                  setState(() => _period = s.first);
                },
                style: ButtonStyle(
                  backgroundColor:
                      MaterialStateProperty.resolveWith<Color?>((states) {
                    if (states.contains(MaterialState.selected)) {
                      return theme.colorScheme.surface;
                    }
                    return theme.colorScheme.surfaceVariant;
                  }),
                ),
              ),
            ),
            // MonthChipsRow or YearChipsRow
            SizedBox(
              height: 48,
              child: _period == 'Mese'
                  ? ListView.separated(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      itemCount: 12,
                      separatorBuilder: (_, __) => const SizedBox(width: 8),
                      itemBuilder: (context, i) {
                        const months = [
                          'Gennaio',
                          'Febbraio',
                          'Marzo',
                          'Aprile',
                          'Maggio',
                          'Giugno',
                          'Luglio',
                          'Agosto',
                          'Settembre',
                          'Ottobre',
                          'Novembre',
                          'Dicembre',
                        ];
                        return FilterChip(
                          label: Text(months[i]),
                          selected: i == _selectedMonth,
                          onSelected: (_) {
                            setState(() => _selectedMonth = i);
                          },
                        );
                      },
                    )
                  : ListView.separated(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      itemCount: 3,
                      separatorBuilder: (_, __) => const SizedBox(width: 8),
                      itemBuilder: (context, i) {
                        final year = now.year - (2 - i);
                        return FilterChip(
                          label: Text(year.toString()),
                          selected: year == _selectedYear,
                          onSelected: (_) {
                            setState(() => _selectedYear = year);
                          },
                        );
                      },
                    ),
            ),
            const SizedBox(height: 16),
            SizedBox(height: 32),
            // BalanceCard
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: GestureDetector(
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text('Analysis non ancora implementato')),
                  );
                },
                child: Container(
                  height: 200,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    gradient: const LinearGradient(
                      colors: [Colors.black, Color(0xFF222222)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(child: Container()),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text('Saldo',
                                  style: theme.textTheme.labelLarge
                                      ?.copyWith(color: Colors.white70)),
                              Text(
                                '€ 0,00',
                                style: theme.textTheme.displayMedium
                                    ?.copyWith(color: byBalance(0)),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const Spacer(),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          // Entrate
                          Row(
                            children: [
                              Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.add,
                                      color: Colors.white, size: 28),
                                ],
                              ),
                              const SizedBox(width: 8),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text('Entrate',
                                      style: theme.textTheme.labelLarge
                                          ?.copyWith(color: Colors.white)),
                                  const SizedBox(height: 2),
                                  Text('€ 0,00',
                                      style: theme.textTheme.bodyLarge
                                          ?.copyWith(color: Colors.white)),
                                ],
                              ),
                            ],
                          ),
                          // Uscite
                          Row(
                            children: [
                              Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.remove,
                                      color: Colors.white, size: 28),
                                ],
                              ),
                              const SizedBox(width: 8),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text('Uscite',
                                      style: theme.textTheme.labelLarge
                                          ?.copyWith(color: Colors.white)),
                                  const SizedBox(height: 2),
                                  Text('€ 0,00',
                                      style: theme.textTheme.bodyLarge
                                          ?.copyWith(color: Colors.white)),
                                ],
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            // UploadButton
            Center(
              child: FilledButton.tonal(
                style: FilledButton.styleFrom(
                  backgroundColor: theme.colorScheme.tertiaryContainer,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                ),
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text('Import non ancora implementato')),
                  );
                },
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.upload, size: 20),
                    SizedBox(width: 8),
                    Text('Carica dati Carta'),
                  ],
                ),
              ),
            ),
            const Spacer(),
          ],
        ),
      ),
      // Action FABs
      floatingActionButton: Stack(
        children: [
          // Entrata FAB
          Align(
            alignment: Alignment.bottomLeft,
            child: Padding(
              padding: const EdgeInsets.only(left: 16, bottom: 120),
              child: SizedBox(
                width: 72,
                height: 72,
                child: FloatingActionButton(
                  heroTag: "entrata",
                  backgroundColor: Colors.greenAccent.shade200,
                  foregroundColor: Colors.white,
                  elevation: 12,
                  shape: const CircleBorder(),
                  child: const Icon(Icons.add, size: 44, weight: 800),
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text('Sheet non ancora implementata')),
                    );
                  },
                ),
              ),
            ),
          ),
          // Uscita FAB
          Align(
            alignment: Alignment.bottomRight,
            child: Padding(
              padding: const EdgeInsets.only(right: 16, bottom: 120),
              child: SizedBox(
                width: 72,
                height: 72,
                child: FloatingActionButton(
                  heroTag: "uscita",
                  backgroundColor: Colors.redAccent.shade100,
                  foregroundColor: Colors.white,
                  elevation: 12,
                  shape: const CircleBorder(),
                  child: const Icon(Icons.remove, size: 44, weight: 800),
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text('Sheet non ancora implementata')),
                    );
                  },
                ),
              ),
            ),
          ),
        ],
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: NavigationBar(
        selectedIndex: 0,
        onDestinationSelected: (int index) {
          // Qui puoi aggiungere la logica di navigazione
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.list_alt_outlined),
            selectedIcon: Icon(Icons.list_alt),
            label: 'Movimenti',
          ),
          NavigationDestination(
            icon: Icon(Icons.bar_chart_outlined),
            selectedIcon: Icon(Icons.bar_chart),
            label: 'Report',
          ),
          NavigationDestination(
            icon: Icon(Icons.repeat_outlined),
            selectedIcon: Icon(Icons.repeat),
            label: 'Ricorrenti',
          ),
          NavigationDestination(
            icon: Icon(Icons.category_outlined),
            selectedIcon: Icon(Icons.category),
            label: 'Categorie',
          ),
        ],
      ),
    );
  }
}
