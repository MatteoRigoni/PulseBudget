import 'package:flutter/material.dart';
import '../model/category.dart';
import '../model/transaction.dart';
import '../model/snapshot.dart';
import '../model/recurring_rule.dart';
import '../model/payment_type.dart';
import 'database_service.dart';

class SeedDataService {
  final DatabaseService _databaseService;

  SeedDataService(this._databaseService);

  Future<void> seedData() async {
    // Categorie di esempio
    final categories = [
      // Categorie per entrate
      Category(
        id: 'income-salary',
        name: 'Stipendi',
        icon: Icons.work,
        colorHex: '#4CAF50',
        type: 'income',
      ),
      Category(
        id: 'income-gifts',
        name: 'Regali',
        icon: Icons.card_giftcard,
        colorHex: '#E91E63',
        type: 'income',
      ),
      Category(
        id: 'income-betting',
        name: 'Scommesse',
        icon: Icons.trending_up,
        colorHex: '#FF9800',
        type: 'income',
      ),
      Category(
        id: 'income-deposits',
        name: 'Depositi',
        icon: Icons.account_balance,
        colorHex: '#2196F3',
        type: 'income',
      ),
      Category(
        id: 'income-freelance',
        name: 'Freelance',
        icon: Icons.computer,
        colorHex: '#9C27B0',
        type: 'income',
      ),
      Category(
        id: 'income-investment',
        name: 'Investimenti',
        icon: Icons.trending_up,
        colorHex: '#FF9800',
        type: 'income',
      ),

      // Categorie per uscite
      Category(
        id: 'expense-clothing',
        name: 'Abbigliamento',
        icon: Icons.shopping_bag,
        colorHex: '#795548',
        type: 'expense',
      ),
      Category(
        id: 'expense-food',
        name: 'Alimentari',
        icon: Icons.shopping_cart,
        colorHex: '#4CAF50',
        type: 'expense',
      ),
      Category(
        id: 'expense-pets',
        name: 'Animali',
        icon: Icons.pets,
        colorHex: '#8BC34A',
        type: 'expense',
      ),
      Category(
        id: 'expense-car',
        name: 'Auto',
        icon: Icons.directions_car,
        colorHex: '#607D8B',
        type: 'expense',
      ),
      Category(
        id: 'expense-bar',
        name: 'Bar',
        icon: Icons.local_cafe,
        colorHex: '#FF5722',
        type: 'expense',
      ),
      Category(
        id: 'expense-bills',
        name: 'Bollette',
        icon: Icons.receipt,
        colorHex: '#F44336',
        type: 'expense',
      ),
      Category(
        id: 'expense-fuel',
        name: 'Carburante',
        icon: Icons.local_gas_station,
        colorHex: '#FF9800',
        type: 'expense',
      ),
      Category(
        id: 'expense-home',
        name: 'Casa',
        icon: Icons.home,
        colorHex: '#795548',
        type: 'expense',
      ),
      Category(
        id: 'expense-communication',
        name: 'Comunicazione',
        icon: Icons.phone,
        colorHex: '#2196F3',
        type: 'expense',
      ),
      Category(
        id: 'expense-family',
        name: 'Famiglia',
        icon: Icons.family_restroom,
        colorHex: '#E91E63',
        type: 'expense',
      ),
      Category(
        id: 'expense-hygiene',
        name: 'Igiene',
        icon: Icons.cleaning_services,
        colorHex: '#00BCD4',
        type: 'expense',
      ),
      Category(
        id: 'expense-investments',
        name: 'Investimenti',
        icon: Icons.trending_up,
        colorHex: '#FF9800',
        type: 'expense',
      ),
      Category(
        id: 'expense-work',
        name: 'Lavoro',
        icon: Icons.work,
        colorHex: '#607D8B',
        type: 'expense',
      ),
      Category(
        id: 'expense-eating-out',
        name: 'Mangiare fuori',
        icon: Icons.restaurant,
        colorHex: '#FF5722',
        type: 'expense',
      ),
      Category(
        id: 'expense-motorcycle',
        name: 'Motore',
        icon: Icons.motorcycle,
        colorHex: '#607D8B',
        type: 'expense',
      ),
      Category(
        id: 'expense-gifts',
        name: 'Regali',
        icon: Icons.card_giftcard,
        colorHex: '#E91E63',
        type: 'expense',
      ),
      Category(
        id: 'expense-health',
        name: 'Salute',
        icon: Icons.local_hospital,
        colorHex: '#F44336',
        type: 'expense',
      ),
      Category(
        id: 'expense-betting',
        name: 'Scommesse',
        icon: Icons.trending_up,
        colorHex: '#FF9800',
        type: 'expense',
      ),
      Category(
        id: 'expense-misc',
        name: 'Spese varie',
        icon: Icons.more_horiz,
        colorHex: '#9E9E9E',
        type: 'expense',
      ),
      Category(
        id: 'expense-sport',
        name: 'Sport',
        icon: Icons.sports_soccer,
        colorHex: '#4CAF50',
        type: 'expense',
      ),
      Category(
        id: 'expense-entertainment',
        name: 'Svago',
        icon: Icons.movie,
        colorHex: '#9C27B0',
        type: 'expense',
      ),
      Category(
        id: 'expense-transport',
        name: 'Trasporti',
        icon: Icons.directions_bus,
        colorHex: '#2196F3',
        type: 'expense',
      ),
      Category(
        id: 'expense-technology',
        name: 'Tecnologia',
        icon: Icons.computer,
        colorHex: '#607D8B',
        type: 'expense',
      ),
      Category(
        id: 'expense-travel',
        name: 'Viaggi',
        icon: Icons.flight,
        colorHex: '#00BCD4',
        type: 'expense',
      ),
    ];

    // Inserisci solo le categorie default
    for (final category in categories) {
      await _databaseService.insertCategory(category);
    }
  }

  Future<void> seedTestData() async {
    // Transazioni di esempio
    final now = DateTime.now();
    final transactions = [
      Transaction(
        id: 'trans-1',
        amount: 1200.00,
        date: DateTime(now.year, now.month, 1),
        description: 'Stipendio Gennaio',
        categoryId: 'income-salary',
        paymentType: PaymentType.bankTransfer,
      ),
      Transaction(
        id: 'trans-2',
        amount: -85.50,
        date: DateTime(now.year, now.month, 5),
        description: 'Spesa supermercato',
        categoryId: 'expense-food',
        paymentType: PaymentType.creditCard,
      ),
      Transaction(
        id: 'trans-3',
        amount: -45.00,
        date: DateTime(now.year, now.month, 8),
        description: 'Benzina',
        categoryId: 'expense-fuel',
        paymentType: PaymentType.cash,
      ),
      Transaction(
        id: 'trans-4',
        amount: -120.00,
        date: DateTime(now.year, now.month, 10),
        description: 'Bolletta luce',
        categoryId: 'expense-bills',
        paymentType: PaymentType.bankTransfer,
      ),
      Transaction(
        id: 'trans-5',
        amount: -35.00,
        date: DateTime(now.year, now.month, 12),
        description: 'Cena ristorante',
        categoryId: 'expense-eating-out',
        paymentType: PaymentType.creditCard,
      ),
      Transaction(
        id: 'trans-6',
        amount: 300.00,
        date: DateTime(now.year, now.month, 15),
        description: 'Progetto freelance',
        categoryId: 'income-freelance',
        paymentType: PaymentType.bankTransfer,
      ),
      Transaction(
        id: 'trans-7',
        amount: -25.00,
        date: DateTime(now.year, now.month, 18),
        description: 'Cinema',
        categoryId: 'expense-entertainment',
        paymentType: PaymentType.cash,
      ),
      Transaction(
        id: 'trans-8',
        amount: -150.00,
        date: DateTime(now.year, now.month, 20),
        description: 'Shopping vestiti',
        categoryId: 'expense-clothing',
        paymentType: PaymentType.creditCard,
      ),
    ];

    // Snapshot di esempio
    final snapshots = [
      Snapshot(
        id: 'snap-1',
        label: 'Conto Corrente',
        amount: 5000.00,
        date: DateTime(now.year, now.month, 1),
        note: 'Saldo iniziale',
      ),
      Snapshot(
        id: 'snap-2',
        label: 'Conto Corrente',
        amount: 5200.00,
        date: DateTime(now.year, now.month, 15),
        note: 'Dopo stipendio',
      ),
    ];

    // Regole ricorrenti di esempio
    final recurringRules = [
      RecurringRule(
        id: 'rule-1',
        name: 'Stipendio Mensile',
        amount: 1200.00,
        categoryId: 'income-salary',
        paymentType: 'bankTransfer',
        rrule: 'FREQ=MONTHLY;BYMONTHDAY=1',
        startDate: DateTime(now.year, now.month, 1),
      ),
      RecurringRule(
        id: 'rule-2',
        name: 'Bolletta Luce',
        amount: -120.00,
        categoryId: 'expense-bills',
        paymentType: 'bankTransfer',
        rrule: 'FREQ=MONTHLY;BYMONTHDAY=10',
        startDate: DateTime(now.year, now.month, 10),
      ),
    ];

    // Inserisci dati di test
    for (final transaction in transactions) {
      await _databaseService.insertTransaction(transaction);
    }
    for (final snapshot in snapshots) {
      await _databaseService.insertSnapshot(snapshot);
    }
    for (final rule in recurringRules) {
      await _databaseService.insertRecurringRule(rule);
    }
  }

  Future<void> clearData() async {
    final db = await _databaseService.database;
    await db.transaction((txn) async {
      await txn.delete('transactions');
      await txn.delete('categories');
      await txn.delete('snapshots');
      await txn.delete('recurring_rules');
    });
  }
}
