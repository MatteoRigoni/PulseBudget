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

  // Avvia subito l'app con lo splash screen
  runApp(const ProviderScope(child: PulseBudgetApp()));
}

class PulseBudgetApp extends StatelessWidget {
  const PulseBudgetApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'BilancioMe',
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
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
      home: const SplashScreen(),
    );
  }
}

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    print('[DEBUG] Inizializzazione categorie default...');

    print('[DEBUG] Inizializzazione completata, navigazione alla home...');

    // SEMPRE naviga alla home, anche se c'è un errore
    if (mounted) {
      setState(() {
        _isInitialized = true;
      });

      // Forza la navigazione dopo un breve delay per sicurezza
      Future.delayed(const Duration(milliseconds: 100), () {
        if (mounted) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
                builder: (context) => const MainNavigationScreen()),
          );
        }
      });
    }
  }

  Future<void> _performInitialization() async {
    // Inizializza le categorie default al primo avvio
    await _initializeDefaultCategories();

    print('[DEBUG] Esecuzione bootstrap ricorrenti...');

    // Esegui il bootstrap delle ricorrenti una sola volta all'avvio
    await _executeRecurringBootstrap();
  }

  Future<void> _initializeDefaultCategories() async {
    try {
      final databaseService = DatabaseService();
      final categories = await databaseService.getCategories();

      // Se non ci sono categorie, inserisci quelle default
      if (categories.isEmpty) {
        final seedService = SeedDataService(databaseService);
        await seedService.seedData(); // Solo categorie default
        print(
            '[DEBUG] Categorie default inserite automaticamente al primo avvio');
      }
    } catch (e) {
      print('[ERROR] Errore durante l\'inizializzazione delle categorie: $e');
    }
  }

  Future<void> _executeRecurringBootstrap() async {
    try {
      print('[DEBUG] ===== BOOTSTRAP MAIN.DART INIZIATO =====');
      final databaseService = DatabaseService();

      // Ottieni le regole ricorrenti
      final rules = await databaseService.getRecurringRules();
      print('[DEBUG] Regole ricorrenti trovate: ${rules.length}');

      // Ottieni le transazioni esistenti
      final existingTransactions = await databaseService.getTransactions();
      print('[DEBUG] Transazioni esistenti: ${existingTransactions.length}');

      // Genera le transazioni ricorrenti scadute
      final now = DateTime.now();
      final newTransactions = generateDueRecurringTransactions(
        rules: rules,
        existingTransactions: existingTransactions,
        now: now,
      );

      print(
          '[DEBUG] Transazioni ricorrenti da generare: ${newTransactions.length}');

      // Inserisci le nuove transazioni usando il database service direttamente
      // (nel main.dart non abbiamo accesso al provider, quindi usiamo il database service)
      if (newTransactions.isNotEmpty) {
        for (final transaction in newTransactions) {
          await databaseService.insertTransaction(transaction);
        }
        print(
            '[DEBUG] Transazioni ricorrenti inserite: ${newTransactions.length}');
      }
      print('[DEBUG] ===== BOOTSTRAP MAIN.DART COMPLETATO =====');
    } catch (e) {
      print('[ERROR] Errore durante il bootstrap delle ricorrenti: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[900], // Grigio scuro invece di rosso
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Logo placeholder
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(60),
              ),
              child: Icon(
                Icons.account_balance_wallet,
                size: 60,
                color: Colors.grey[900], // Grigio scuro per il contrasto
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'BilancioMe',
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 16),
            if (_isInitialized)
              const Icon(
                Icons.check_circle,
                color: Colors.white,
                size: 32,
              )
            else
              const CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
          ],
        ),
      ),
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
