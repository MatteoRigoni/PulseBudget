import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../theme/app_theme.dart';
import '../../providers/transactions_provider.dart';
import '../movements/new_transaction_sheet.dart';

import '../movements/movements_screen.dart';
import '../../model/transaction.dart';
import '../../model/category.dart';
import '../../providers/categories_provider.dart';
import '../../providers/snapshot_provider.dart';
import '../../providers/recurring_rules_provider.dart';
import '../report/analysis_sheet.dart';
import '../categories/categories_screen.dart';
import 'package:intl/intl.dart';
import '../../providers/period_filter_provider.dart';
import '../../services/backup_service.dart';
import '../../services/database_service.dart';
import '../../services/seed_data_service.dart';
import '../widgets/app_title_widget.dart';
import '../../providers/recurring_bootstrap_provider.dart';
import '../import/payment_type_sheet.dart';
import '../import/preview_screen.dart';
import '../../providers/pdf_import_providers.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';
import '../../providers/pdf_import_provider.dart';
import '../widgets/custom_snackbar.dart';
import 'package:url_launcher/url_launcher.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  static const kAppGreen = Color(0xFF2ECC71); // verde bilancio
  static const kAppRed = Color(0xFFd32f2f); // rosso acceso

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen>
    with TickerProviderStateMixin {
  String _period = 'Mese';
  int _selectedMonth = 0;
  int _selectedYear = DateTime.now().year;
  bool _isRefreshing = false;
  bool _hasInitialized = false;

  late AnimationController _balanceAnimController;
  late Animation<double> _balanceScale;
  late AnimationController _fabFeedbackController;
  late Animation<double> _fabFade;

  final NumberFormat currencyFormat = NumberFormat('###,##0.00', 'it_IT');
  late final ScrollController _monthScrollController;
  late List<DateTime> _monthsList;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _monthsList = List.generate(36, (i) {
      final date = DateTime(now.year, now.month - 35 + i, 1);
      return date;
    });
    final currentIndex =
        _monthsList.indexWhere((d) => d.year == now.year && d.month == now.month);
    if (currentIndex >= 0) {
      _selectedYear = _monthsList[currentIndex].year;
      _selectedMonth = _monthsList[currentIndex].month - 1;
    } else {
      _selectedYear = now.year;
      _selectedMonth = now.month - 1;
    }
    _monthScrollController = ScrollController(
      initialScrollOffset: (currentIndex >= 0 ? currentIndex : 35) * 84.0,
    );
    _balanceAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
      lowerBound: 0.95,
      upperBound: 1.0,
    );
    _balanceScale = _balanceAnimController.drive(Tween(begin: 0.95, end: 1.0));
    _balanceAnimController.value = 1.0;

    _fabFeedbackController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _fabFade = Tween(begin: 1.0, end: 0.3).animate(
      CurvedAnimation(parent: _fabFeedbackController, curve: Curves.easeOut),
    );
    _fabFeedbackController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _fabFeedbackController.reverse();
      }
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_hasInitialized) {
        _hasInitialized = true;
        executeRecurringBootstrapFromWidget(ref);
      }
    });
  }

  @override
  void dispose() {
    _balanceAnimController.dispose();
    _fabFeedbackController.dispose();
    _monthScrollController.dispose();
    super.dispose();
  }

  void _showNewTransactionSheet(bool isIncome) async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => NewTransactionSheet(
        isIncome: isIncome,
        onSaved: () {
          _balanceAnimController.forward(from: 0.95);
          _fabFeedbackController.forward(from: 0.0);
        },
      ),
    );
  }

  void _refreshData() async {
    if (_isRefreshing) return;
    setState(() {
      _isRefreshing = true;
    });

    try {
      final databaseService = DatabaseService();
      await databaseService.triggerProviderUpdate();
      if (mounted) {
        CustomSnackBar.show(context, message: 'Dati aggiornati');
      }
    } catch (e) {
      if (mounted) {
        CustomSnackBar.show(context,
            message: 'Errore durante l\'aggiornamento: $e',
            type: SnackBarType.error);
      }
    } finally {
      if (mounted) {
        setState(() {
          _isRefreshing = false;
        });
      }
    }
  }

  Future<void> _showImportFlow() async {
    try {
      final shouldContinue = await showModalBottomSheet<bool>(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (context) => const PaymentTypeSheet(),
      );
      if (shouldContinue != true) return;

      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
        allowMultiple: false,
      );
      if (result == null || result.files.isEmpty) return;

      final file = result.files.first;
      if (file.path == null) {
        CustomSnackBar.show(context, message: 'Errore nella selezione del file');
        return;
      }

      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(),
        ),
      );

      final pdfFile = File(file.path!);
      final notifier = ref.read(importedTransactionsProvider.notifier);
      final categories = ref.read(categoriesProvider).value ?? [];
      final paymentType =
          ref.read(PdfImportProviders.selectedPaymentTypeProvider);

      if (paymentType == null) {
        if (mounted) {
          CustomSnackBar.show(context, message: 'Seleziona un tipo di pagamento');
        }
        return;
      }
      await notifier.loadFromPdf(pdfFile, paymentType, categories);
      ref.invalidate(PdfImportProviders.allStatementInfosProvider);

      if (mounted) {
        Navigator.of(context).pop();
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => const PreviewScreen(),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.of(context).pop();
        CustomSnackBar.show(context,
            message: 'Errore durante l\'importazione: $e',
            type: SnackBarType.error);
      }
    }
  }

  void _showUploadMenu() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              margin: const EdgeInsets.only(top: 8),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.upload_file, color: Color(0xFF87CEEB)),
              title: const Text('Carica da Estratto Conto'),
              subtitle: const Text('Importa transazioni da PDF'),
              onTap: () {
                Navigator.of(context).pop();
                _showImportFlow();
              },
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final now = DateTime.now();
    final transactionsAsync = ref.watch(transactionsProvider);

    if (transactionsAsync.isLoading) {
      return const Scaffold(
        body: Center(
          child: SizedBox(
            width: 64,
            height: 64,
            child: CircularProgressIndicator(
              strokeWidth: 4,
              color: HomeScreen.kAppGreen,
            ),
          ),
        ),
      );
    }

    if (transactionsAsync.hasError) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              Text('Errore nel caricamento: ${transactionsAsync.error}'),
            ],
          ),
        ),
      );
    }

    final transactions = transactionsAsync.value ?? [];
    final filtered = transactions.where((t) {
      if (_period == 'Mese') {
        return t.date.month == _selectedMonth + 1 && t.date.year == _selectedYear;
      } else {
        return t.date.year == _selectedYear;
      }
    }).toList();

    final entrate =
        filtered.where((t) => t.amount > 0).fold<double>(0, (s, t) => s + t.amount);
    final uscite =
        filtered.where((t) => t.amount < 0).fold<double>(0, (s, t) => s + t.amount);
    final saldo = entrate + uscite;

    Color byBalance(double value) {
      if (value > 0) return HomeScreen.kAppGreen;
      if (value < 0) return HomeScreen.kAppRed;
      return Colors.white;
    }

    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        scrolledUnderElevation: 0,
        shadowColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        centerTitle: false,
        title: Row(
          mainAxisAlignment: MainAxisAlignment.start,
          mainAxisSize: MainAxisSize.max,
          children: [
            Icon(
              Icons.account_balance_wallet,
              size: 24,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(width: 8),
            const Text(
              'BilancioMe',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.support_agent),
            tooltip: 'Assistenza',
            onPressed: () async {
              final Uri emailLaunchUri = Uri(
                scheme: 'mailto',
                path: 'matteo.rigoni2@gmail.com',
                query: Uri.encodeFull('subject=Segnalazione BilancioMe'),
              );
              await launchUrl(emailLaunchUri);
            },
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.menu),
            onSelected: (value) async {
              if (value == 'categories') {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const CategoriesScreen()),
                );
              } else if (value == 'backup') {
                final databaseService = DatabaseService();
                final backupService = BackupService(databaseService);
                BackupService.showBackupDialog(context, backupService);
              } else if (value == 'seed') {
                final databaseService = DatabaseService();
                final seedService = SeedDataService(databaseService);
                await seedService.seedTestData();

                ref.invalidate(transactionsProvider);
                ref.invalidate(snapshotProvider);
                ref.invalidate(recurringRulesProvider);

                if (context.mounted) {
                  CustomSnackBar.show(context,
                      message: 'Dati di test inseriti con successo!');
                }
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'categories',
                child: Row(
                  children: [
                    Icon(Icons.category, size: 20),
                    SizedBox(width: 8),
                    Text('Categorie'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'backup',
                child: Row(
                  children: [
                    Icon(Icons.backup, size: 20),
                    SizedBox(width: 8),
                    Text('Backup & Ripristino'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // PeriodSegmented
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  child: SegmentedButton<String>(
                    segments: const [
                      ButtonSegment(value: 'Mese', label: Text('Mese')),
                      ButtonSegment(value: 'Anno', label: Text('Anno')),
                    ],
                    selected: <String>{_period},
                    onSelectionChanged: (s) {
                      setState(() {
                        _period = s.first;
                      });

                      if (_period == 'Mese') {
                        final now = DateTime.now();
                        _selectedYear = now.year;
                        _selectedMonth = now.month - 1;

                        WidgetsBinding.instance.addPostFrameCallback((_) {
                          _monthScrollController.animateTo(
                            _monthScrollController.position.maxScrollExtent,
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeInOut,
                          );
                        });
                      }

                      final periodFilter = ref.read(periodFilterProvider.notifier);
                      periodFilter.state = PeriodFilter(
                        period: _period,
                        month: _selectedMonth + 1,
                        year: _selectedYear,
                      );
                    },
                  ),
                ),
                // MonthChipsRow or YearChipsRow
                SizedBox(
                  height: 56,
                  child: _period == 'Mese'
                      ? ListView.builder(
                          controller: _monthScrollController,
                          scrollDirection: Axis.horizontal,
                          padding:
                              const EdgeInsets.symmetric(horizontal: 8),
                          itemExtent: 84,
                          itemCount: _monthsList.length,
                          itemBuilder: (context, idx) {
                            final date = _monthsList[idx];
                            final isSelected = date.year == _selectedYear &&
                                date.month == _selectedMonth + 1;
                            final months = [
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
                            return Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 2),
                              child: ChoiceChip(
                                showCheckmark: false,
                                label: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Transform.translate(
                                      offset: const Offset(0, -7),
                                      child: Column(
                                        children: [
                                          SizedBox(
                                            width: 84,
                                            child: Padding(
                                              padding:
                                                  const EdgeInsets.only(top: 0),
                                              child: Center(
                                                child: Text(
                                                  months[date.month - 1],
                                                  style: const TextStyle(
                                                      fontSize: 15),
                                                ),
                                              ),
                                            ),
                                          ),
                                          const SizedBox(height: 0),
                                          Text('${date.year}',
                                              style: TextStyle(
                                                  fontSize: 11,
                                                  color:
                                                      Colors.grey.shade500)),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                                selected: isSelected,
                                onSelected: (_) {
                                  setState(() {
                                    _selectedYear = date.year;
                                    _selectedMonth = date.month - 1;
                                  });
                                  final periodFilter = ref
                                      .read(periodFilterProvider.notifier);
                                  periodFilter.state = PeriodFilter(
                                    period: _period,
                                    month: _selectedMonth + 1,
                                    year: _selectedYear,
                                  );
                                },
                              ),
                            );
                          },
                        )
                      : ListView.separated(
                          scrollDirection: Axis.horizontal,
                          padding:
                              const EdgeInsets.symmetric(horizontal: 8),
                          itemCount: 3,
                          separatorBuilder: (_, __) =>
                              const SizedBox(width: 8),
                          itemBuilder: (context, i) {
                            final year =
                                DateTime.now().year - (2 - i);
                            return FilterChip(
                              label: Text(year.toString()),
                              selected: year == _selectedYear,
                              onSelected: (_) {
                                setState(() {
                                  _selectedYear = year;
                                });
                                final periodFilter = ref
                                    .read(periodFilterProvider.notifier);
                                periodFilter.state = PeriodFilter(
                                  period: _period,
                                  month: _selectedMonth + 1,
                                  year: _selectedYear,
                                );
                              },
                            );
                          },
                        ),
                ),
                const SizedBox(height: 20),
                // BalanceCard
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: GestureDetector(
                    onTapDown: (_) => _balanceAnimController.reverse(),
                    onTapUp: (_) => _balanceAnimController.forward(),
                    onTapCancel: () => _balanceAnimController.forward(),
                    child: ScaleTransition(
                      scale: _balanceScale,
                      child: Container(
                        height: 160,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          gradient: const LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              Colors.black,
                              Color(0xFF0A174E),
                            ],
                            stops: [0.0, 1.0],
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.blue.withOpacity(0.18),
                              blurRadius: 32,
                              spreadRadius: 2,
                              offset: const Offset(0, 8),
                            ),
                          ],
                          border: Border.all(
                              color: Colors.white.withOpacity(0.08),
                              width: 1.2),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                // Chip con immagine o icona refresh
                                Container(
                                  width: 38,
                                  height: 32,
                                  margin: const EdgeInsets.only(
                                      bottom: 10, top: 0),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  clipBehavior: Clip.hardEdge,
                                  child: _isRefreshing
                                      ? Container(
                                          color: Colors.amber.shade700,
                                          child: const Icon(
                                            Icons.refresh,
                                            color: Colors.white,
                                            size: 20,
                                          ),
                                        )
                                      : Image.asset(
                                          'assets/chip.jpg',
                                          fit: BoxFit.cover,
                                        ),
                                ),
                                const Spacer(),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text('Saldo',
                                        style: theme.textTheme.labelLarge
                                            ?.copyWith(
                                                color: Colors.white70,
                                                fontSize: 14)),
                                    Text(
                                      '€ ${currencyFormat.format(saldo)}',
                                      style: theme.textTheme.displayMedium
                                          ?.copyWith(
                                              color: saldo > 0
                                                  ? HomeScreen.kAppGreen
                                                  : saldo < 0
                                                      ? HomeScreen.kAppRed
                                                      : Colors.white,
                                              fontSize: 28,
                                              fontWeight: FontWeight.w700),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            const Spacer(),
                            Row(
                              mainAxisAlignment:
                                  MainAxisAlignment.spaceBetween,
                              children: [
                                // Entrate
                                Row(
                                  children: [
                                    const Icon(Icons.add,
                                        color: Colors.white, size: 22),
                                    const SizedBox(width: 6),
                                    Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Text('Entrate',
                                            style: theme.textTheme.labelLarge
                                                ?.copyWith(
                                                    color: Colors.white,
                                                    fontSize: 13)),
                                        const SizedBox(height: 2),
                                        Text(
                                            '€ ${currencyFormat.format(entrate)}',
                                            style: theme.textTheme.bodyLarge
                                                ?.copyWith(
                                                    color: Colors.white,
                                                    fontSize: 15)),
                                      ],
                                    ),
                                  ],
                                ),
                                // Uscite
                                Row(
                                  children: [
                                    const Icon(Icons.remove,
                                        color: Colors.white, size: 22),
                                    const SizedBox(width: 6),
                                    Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Text('Uscite',
                                            style: theme.textTheme.labelLarge
                                                ?.copyWith(
                                                    color: Colors.white,
                                                    fontSize: 13)),
                                        const SizedBox(height: 2),
                                        Text(
                                            '€ ${currencyFormat.format(uscite.abs())}',
                                            style: theme.textTheme.bodyLarge
                                                ?.copyWith(
                                                    color: Colors.white,
                                                    fontSize: 15)),
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
                ),
                const SizedBox(height: 8),
                // Pannello categorie principali
                Expanded(
                  child: Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
                    child: _MainCategoriesPanel(
                      period: _period,
                      selectedMonth: _selectedMonth,
                      selectedYear: _selectedYear,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
              ],
            ),
          ],
        ),
      ),
      // Action FABs
      floatingActionButton: Stack(
        children: [
          // Upload FAB (sinistra)
          Align(
            alignment: Alignment.bottomLeft,
            child: Padding(
              padding: const EdgeInsets.only(left: 16, bottom: 24),
              child: FloatingActionButton(
                heroTag: "upload",
                backgroundColor: const Color(0xCC87CEEB),
                foregroundColor: Colors.white,
                elevation: 8,
                onPressed: _showImportFlow,
                child: const Icon(Icons.upload),
              ),
            ),
          ),
          // Più (entrata)
          Align(
            alignment: Alignment.bottomRight,
            child: Padding(
              padding: const EdgeInsets.only(right: 16, bottom: 24),
              child: SizedBox(
                width: 54,
                height: 54,
                child: FadeTransition(
                  opacity: _fabFade,
                  child: FloatingActionButton(
                    heroTag: "entrata",
                    backgroundColor: const Color(0xCC7EE787),
                    foregroundColor: Colors.white,
                    elevation: 8,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                    onPressed: () => _showNewTransactionSheet(true),
                    child: const Icon(Icons.add,
                        size: 28, color: Colors.white, weight: 800),
                  ),
                ),
              ),
            ),
          ),
          // Meno (uscita)
          Align(
            alignment: Alignment.bottomRight,
            child: Padding(
              padding: const EdgeInsets.only(right: 88, bottom: 24),
              child: SizedBox(
                width: 54,
                height: 54,
                child: FadeTransition(
                  opacity: _fabFade,
                  child: FloatingActionButton(
                    heroTag: "uscita",
                    backgroundColor: const Color(0xCCFF8A80),
                    foregroundColor: Colors.white,
                    elevation: 8,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                    onPressed: () => _showNewTransactionSheet(false),
                    child: const Icon(Icons.remove,
                        size: 28, color: Colors.white, weight: 800),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      floatingActionButtonAnimator: FloatingActionButtonAnimator.noAnimation,
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
    );
  }
}

class _MainCategoriesPanel extends ConsumerStatefulWidget {
  final String period;
  final int selectedMonth;
  final int selectedYear;
  const _MainCategoriesPanel({
    required this.period,
    required this.selectedMonth,
    required this.selectedYear,
    Key? key,
  }) : super(key: key);

  @override
  ConsumerState<_MainCategoriesPanel> createState() =>
      _MainCategoriesPanelState();
}

class _MainCategoriesPanelState extends ConsumerState<_MainCategoriesPanel> {
  bool showExpenses = true;
  final NumberFormat currencyFormat = NumberFormat('###,##0.00', 'it_IT');

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final categoriesAsync = ref.watch(categoriesProvider);
    final transactionsAsync = ref.watch(transactionsProvider);

    if (transactionsAsync.isLoading || categoriesAsync.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (transactionsAsync.hasError || categoriesAsync.hasError) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            const Text('Errore nel caricamento'),
          ],
        ),
      );
    }

    final categories = categoriesAsync.value ?? [];
    final transactions = transactionsAsync.value ?? [];
    List<Transaction> filtered = transactions;
    if (widget.period == 'Mese') {
      filtered = transactions
          .where((t) =>
              t.date.month == widget.selectedMonth + 1 &&
              t.date.year == widget.selectedYear)
          .toList();
    } else {
      filtered =
          transactions.where((t) => t.date.year == widget.selectedYear).toList();
    }

    final filteredCategories = categories
        .where((c) => c.type == (showExpenses ? 'expense' : 'income'))
        .toList();

    final Map<String, double> totals = {};
    for (final t in filtered) {
      if ((showExpenses && t.amount < 0) || (!showExpenses && t.amount > 0)) {
        totals[t.categoryId] = (totals[t.categoryId] ?? 0) + t.amount;
      }
    }
    final List<MapEntry<Category, double>> sorted = [
      for (final c in filteredCategories)
        if (totals.containsKey(c.id)) MapEntry(c, totals[c.id]!)
    ]..sort((a, b) => b.value.abs().compareTo(a.value.abs()));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(showExpenses ? Icons.trending_down : Icons.trending_up,
                color: showExpenses ? Colors.red : Colors.green),
            const SizedBox(width: 8),
            Text(
              showExpenses ? 'Spese principali' : 'Incassi principali',
              style:
                  const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const Spacer(),
            IconButton(
              icon: Icon(
                showExpenses ? Icons.arrow_circle_up : Icons.arrow_circle_down,
                color: Theme.of(context).colorScheme.primary,
              ),
              tooltip: showExpenses ? 'Mostra incassi' : 'Mostra spese',
              onPressed: () => setState(() => showExpenses = !showExpenses),
            ),
          ],
        ),
        if (sorted.isEmpty)
          SizedBox(
            height: 265,
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.emoji_objects,
                      size: 64, color: Colors.amber.shade400),
                  const SizedBox(height: 16),
                  Text(
                    'Nessuna transazione significativa!',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.titleMedium
                        ?.copyWith(color: Colors.grey.shade600),
                  ),
                ],
              ),
            ),
          )
        else
          SizedBox(
            height: 265,
            child: Stack(
              children: [
                ListView.separated(
                  padding: const EdgeInsets.only(bottom: 90),
                  itemCount: sorted.length,
                  separatorBuilder: (context, idx) => Divider(
                    height: 1,
                    thickness: 0.5,
                    color: Colors.grey.shade300,
                  ),
                  itemBuilder: (context, idx) {
                    final entry = sorted[idx];
                    return SizedBox(
                      height: 38,
                      child: ListTile(
                        dense: true,
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 4, vertical: 0),
                        leading: Icon(entry.key.icon,
                            color: entry.key.color, size: 22),
                        title: Text(entry.key.name,
                            style: const TextStyle(fontSize: 15)),
                        trailing: Text(
                          (entry.value < 0 ? '-' : '+') +
                              currencyFormat.format(entry.value.abs()) +
                              ' €',
                          style: TextStyle(
                            color: entry.value < 0
                                ? HomeScreen.kAppRed
                                : HomeScreen.kAppGreen,
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                        ),
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => MovementsScreen(
                                  initialCategoryId: entry.key.id),
                            ),
                          );
                        },
                      ),
                    );
                  },
                ),
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  height: 32,
                  child: IgnorePointer(
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            theme.colorScheme.surface.withOpacity(0.0),
                            theme.colorScheme.surface.withOpacity(0.85),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}
