import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'ui/home/home_screen.dart';
import 'ui/categories/categories_screen.dart';
import 'theme/app_theme.dart';
import 'ui/recurring/recurring_rules_page.dart';
import 'ui/movements/movements_screen.dart';
import 'ui/report/analysis_sheet.dart';
import 'ui/patrimonio/patrimonio_screen.dart';
import 'services/database_service.dart';
import 'services/seed_data_service.dart';
import 'providers/recurring_bootstrap_provider.dart';
import 'repository/recurring_scheduler.dart';
import 'providers/transactions_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  print('[DEBUG] ===== APP STARTING =====');

  // Avvia l'app direttamente
  runApp(const ProviderScope(child: PulseBudgetApp()));
}

void _initializeInBackground() async {
  try {
    print('[DEBUG] Inizializzazione in background...');

    final databaseService = DatabaseService();
    final categories = await databaseService.getCategories();

    // Se non ci sono categorie, inserisci quelle default
    if (categories.isEmpty) {
      final seedService = SeedDataService(databaseService);
      await seedService.seedData();
      print('[DEBUG] Categorie default inserite');
    }

    // Bootstrap ricorrenti
    final rules = await databaseService.getRecurringRules();
    final existingTransactions = await databaseService.getTransactions();
    final now = DateTime.now();
    final newTransactions = generateDueRecurringTransactions(
      rules: rules,
      existingTransactions: existingTransactions,
      now: now,
    );

    if (newTransactions.isNotEmpty) {
      for (final transaction in newTransactions) {
        await databaseService.insertTransaction(transaction);
      }
      print(
        '[DEBUG] Transazioni ricorrenti inserite: ${newTransactions.length}',
      );
    }

    print('[DEBUG] Inizializzazione completata');
  } catch (e) {
    print('[ERROR] Errore inizializzazione: $e');
  }
}

class PulseBudgetApp extends StatelessWidget {
  const PulseBudgetApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'BilancioMe',
      theme: ThemeData.light(useMaterial3: true),
      darkTheme: ThemeData.dark(useMaterial3: true),
      themeMode: ThemeMode.system,
      locale: const Locale('it', 'IT'),
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('it', 'IT'),
        Locale('en', 'US'),
      ],
      home: const MainNavigationScreen(),
    );
  }
}

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _selectedIndex = 0;

  final List<Widget> _screens = [
    const HomeScreen(),
    const MovementsScreen(),
    const PatrimonioScreen(),
    AnalysisSheet(),
    const RecurringRulesPage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: _screens,
      ),
      bottomNavigationBar: NavigationBar(
        height: 64,
        selectedIndex: _selectedIndex,
        onDestinationSelected: (int index) {
          setState(() {
            _selectedIndex = index;
          });
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
            icon: Icon(Icons.account_balance_wallet_outlined),
            selectedIcon: Icon(Icons.account_balance_wallet),
            label: 'Patrimonio',
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
        ],
      ),
    );
  }
}
