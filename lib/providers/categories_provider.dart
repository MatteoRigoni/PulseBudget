import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../model/category.dart';

class CategoriesNotifier extends StateNotifier<List<Category>> {
  CategoriesNotifier() : super([]) {
    if (state.isEmpty) {
      state = _defaultCategories;
    }
  }

  static List<Category> getDefaultCategories() {
    return _defaultCategories;
  }

  // --- DEFAULT CATEGORIES ----------------------------------------------------

  static final List<Category> _defaultCategories = [
    // Entrate
    Category(
      id: 'income-salary',
      name: 'Stipendi',
      iconCodePoint: 0xe6f2, // Icons.work
      colorHex: '#4CAF50',
      type: 'income',
    ),
    Category(
      id: 'income-gifts',
      name: 'Regali',
      iconCodePoint: 0xe13e, // Icons.card_giftcard
      colorHex: '#E91E63',
      type: 'income',
    ),
    Category(
      id: 'income-betting',
      name: 'Scommesse',
      iconCodePoint: 0xe67f, // Icons.trending_up
      colorHex: '#FF9800',
      type: 'income',
    ),
    Category(
      id: 'income-deposits',
      name: 'Depositi',
      iconCodePoint: 0xe040, // Icons.account_balance
      colorHex: '#2196F3',
      type: 'income',
    ),
    Category(
      id: 'income-freelance',
      name: 'Freelance',
      iconCodePoint: 0xe185, // Icons.computer
      colorHex: '#9C27B0',
      type: 'income',
    ),
    Category(
      id: 'income-investment',
      name: 'Investimenti',
      iconCodePoint: 0xe67f, // Icons.trending_up
      colorHex: '#FF9800',
      type: 'income',
    ),

    // Uscite
    Category(
      id: 'expense-clothing',
      name: 'Abbigliamento',
      iconCodePoint: 0xe59a, // Icons.shopping_bag
      colorHex: '#795548',
      type: 'expense',
    ),
    Category(
      id: 'expense-food',
      name: 'Alimentari',
      iconCodePoint: 0xe59c, // Icons.shopping_cart
      colorHex: '#4CAF50',
      type: 'expense',
    ),
    Category(
      id: 'expense-pets',
      name: 'Animali',
      iconCodePoint: 0xe4a1, // Icons.pets
      colorHex: '#8BC34A',
      type: 'expense',
    ),
    Category(
      id: 'expense-car',
      name: 'Auto',
      iconCodePoint: 0xe1d7, // Icons.directions_car
      colorHex: '#607D8B',
      type: 'expense',
    ),
    Category(
      id: 'expense-bar',
      name: 'Bar',
      iconCodePoint: 0xe38d, // Icons.local_cafe
      colorHex: '#FF5722',
      type: 'expense',
    ),
    Category(
      id: 'expense-bills',
      name: 'Bollette',
      iconCodePoint: 0xe50c, // Icons.receipt
      colorHex: '#F44336',
      type: 'expense',
    ),
    Category(
      id: 'expense-fuel',
      name: 'Carburante',
      iconCodePoint: 0xe394, // Icons.local_gas_station
      colorHex: '#FF9800',
      type: 'expense',
    ),
    Category(
      id: 'expense-home',
      name: 'Casa',
      iconCodePoint: 0xe318, // Icons.home
      colorHex: '#795548',
      type: 'expense',
    ),
    Category(
      id: 'expense-communication',
      name: 'Comunicazione',
      iconCodePoint: 0xe4a2, // Icons.phone
      colorHex: '#2196F3',
      type: 'expense',
    ),
    Category(
      id: 'expense-family',
      name: 'Famiglia',
      iconCodePoint: 0xe257, // Icons.family_restroom
      colorHex: '#E91E63',
      type: 'expense',
    ),
    Category(
      id: 'expense-hygiene',
      name: 'Igiene',
      iconCodePoint: 0xe167, // Icons.cleaning_services
      colorHex: '#00BCD4',
      type: 'expense',
    ),
    Category(
      id: 'expense-investments',
      name: 'Investimenti',
      iconCodePoint: 0xe67f, // Icons.trending_up
      colorHex: '#FF9800',
      type: 'expense',
    ),
    Category(
      id: 'expense-work',
      name: 'Lavoro',
      iconCodePoint: 0xe6f2, // Icons.work
      colorHex: '#607D8B',
      type: 'expense',
    ),
    Category(
      id: 'expense-eating-out',
      name: 'Mangiare fuori',
      iconCodePoint: 0xe532, // Icons.restaurant
      colorHex: '#FF5722',
      type: 'expense',
    ),
    Category(
      id: 'expense-motorcycle',
      name: 'Motore',
      iconCodePoint: 0xe40a, // Icons.motorcycle
      colorHex: '#607D8B',
      type: 'expense',
    ),
    Category(
      id: 'expense-gifts',
      name: 'Regali',
      iconCodePoint: 0xe13e, // Icons.card_giftcard
      colorHex: '#E91E63',
      type: 'expense',
    ),
    Category(
      id: 'expense-health',
      name: 'Salute',
      iconCodePoint: 0xe396, // Icons.local_hospital
      colorHex: '#F44336',
      type: 'expense',
    ),
    Category(
      id: 'expense-betting',
      name: 'Scommesse',
      iconCodePoint: 0xe67f, // Icons.trending_up
      colorHex: '#FF9800',
      type: 'expense',
    ),
    Category(
      id: 'expense-misc',
      name: 'Spese varie',
      iconCodePoint: 0xe402, // Icons.more_horiz
      colorHex: '#9E9E9E',
      type: 'expense',
    ),
    Category(
      id: 'expense-sport',
      name: 'Sport',
      iconCodePoint: 0xe5f2, // Icons.sports_soccer
      colorHex: '#4CAF50',
      type: 'expense',
    ),
    Category(
      id: 'expense-entertainment',
      name: 'Svago',
      iconCodePoint: 0xe40d, // Icons.movie
      colorHex: '#9C27B0',
      type: 'expense',
    ),
    Category(
      id: 'expense-transport',
      name: 'Trasporti',
      iconCodePoint: 0xe1d5, // Icons.directions_bus
      colorHex: '#2196F3',
      type: 'expense',
    ),
    Category(
      id: 'expense-technology',
      name: 'Tecnologia',
      iconCodePoint: 0xe185, // Icons.computer
      colorHex: '#607D8B',
      type: 'expense',
    ),
    Category(
      id: 'expense-travel',
      name: 'Viaggi',
      iconCodePoint: 0xe297, // Icons.flight
      colorHex: '#00BCD4',
      type: 'expense',
    ),
  ];

  // --- CRUD ------------------------------------------------------------------

  void addCategory(Category category) => state = [...state, category];

  void deleteCategory(String id) =>
      state = state.where((c) => c.id != id).toList();

  void updateCategory(Category updated) => state = [
        for (final c in state)
          if (c.id == updated.id) updated else c
      ];
}

final categoriesProvider =
    StateNotifierProvider<CategoriesNotifier, List<Category>>(
  (ref) => CategoriesNotifier(),
);
