import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/material.dart';
import '../model/category.dart';
import '../repository/category_repository.dart';
import 'repository_providers.dart';

/// Provider per tutte le categorie (StreamProvider)
final categoriesProvider = StreamProvider<List<Category>>((ref) {
  final repository = ref.watch(categoryRepositoryProvider);
  return repository.watchAll();
});

/// Provider per le categorie di entrata
final incomeCategoriesProvider = Provider<List<Category>>((ref) {
  final categories = ref.watch(categoriesProvider).value ?? [];
  return categories.where((c) => c.type == 'income').toList();
});

/// Provider per le categorie di spesa
final expenseCategoriesProvider = Provider<List<Category>>((ref) {
  final categories = ref.watch(categoriesProvider).value ?? [];
  return categories.where((c) => c.type == 'expense').toList();
});

/// Notifier per le operazioni CRUD delle categorie
class CategoriesNotifier extends StateNotifier<AsyncValue<void>> {
  final CategoryRepository _repository;

  CategoriesNotifier(this._repository) : super(const AsyncValue.data(null));

  Future<void> add(Category category) async {
    state = const AsyncValue.loading();
    try {
      await _repository.add(category);
      state = const AsyncValue.data(null);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Future<void> update(Category category) async {
    state = const AsyncValue.loading();
    try {
      await _repository.update(category);
      state = const AsyncValue.data(null);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Future<void> delete(String id) async {
    state = const AsyncValue.loading();
    try {
      await _repository.delete(id);
      state = const AsyncValue.data(null);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Future<void> addBatch(List<Category> categories) async {
    state = const AsyncValue.loading();
    try {
      await _repository.addBatch(categories);
      state = const AsyncValue.data(null);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Future<void> seedDefaultCategories() async {
    state = const AsyncValue.loading();
    try {
      await _repository.addBatch(_defaultCategories);
      state = const AsyncValue.data(null);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }
}

/// Provider per le operazioni CRUD delle categorie
final categoriesNotifierProvider =
    StateNotifierProvider<CategoriesNotifier, AsyncValue<void>>((ref) {
  final repository = ref.watch(categoryRepositoryProvider);
  return CategoriesNotifier(repository);
});

// --- DEFAULT CATEGORIES ----------------------------------------------------

final List<Category> _defaultCategories = [
  // Entrate
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
    icon: Icons.sports_soccer, // pallone
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

  // Uscite
  Category(
    id: 'expense-clothing',
    name: 'Abbigliamento',
    icon: Icons.checkroom, // t-shirt
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
    icon: Icons.sports_soccer, // pallone
    colorHex: '#FF9800',
    type: 'expense',
  ),
  Category(
    id: 'expense-misc',
    name: 'Spese varie',
    icon: Icons.category,
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
    id: 'expense-education',
    name: 'Istruzione',
    icon: Icons.school,
    colorHex: '#607D8B',
    type: 'expense',
  ),
  Category(
    id: 'expense-shopping',
    name: 'Shopping',
    icon: Icons.shopping_bag,
    colorHex: '#E91E63',
    type: 'expense',
  ),
];
