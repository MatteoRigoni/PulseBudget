import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/material.dart';
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

    // Uscite
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
