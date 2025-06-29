import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../model/category.dart';

class CategoriesNotifier extends StateNotifier<List<Category>> {
  CategoriesNotifier() : super(_getDefaultCategories());

  static List<Category> _getDefaultCategories() {
    return [
      // Categorie per entrate
      Category(
        id: 'income-salary',
        name: 'Stipendio',
        iconCodePoint: 0xe0b8, // Icons.work
        colorHex: '#4CAF50',
        type: 'income',
      ),
      Category(
        id: 'income-freelance',
        name: 'Freelance',
        iconCodePoint: 0xe3c9, // Icons.computer
        colorHex: '#2196F3',
        type: 'income',
      ),
      Category(
        id: 'income-investment',
        name: 'Investimenti',
        iconCodePoint: 0xe6e1, // Icons.trending_up
        colorHex: '#FF9800',
        type: 'income',
      ),
      Category(
        id: 'income-gift',
        name: 'Regali',
        iconCodePoint: 0xe155, // Icons.card_giftcard
        colorHex: '#E91E63',
        type: 'income',
      ),

      // Categorie per uscite
      Category(
        id: 'expense-food',
        name: 'Cibo',
        iconCodePoint: 0xe533, // Icons.restaurant
        colorHex: '#FF5722',
        type: 'expense',
      ),
      Category(
        id: 'expense-transport',
        name: 'Trasporti',
        iconCodePoint: 0xe531, // Icons.directions_car
        colorHex: '#607D8B',
        type: 'expense',
      ),
      Category(
        id: 'expense-shopping',
        name: 'Shopping',
        iconCodePoint: 0xe59c, // Icons.shopping_bag
        colorHex: '#9C27B0',
        type: 'expense',
      ),
      Category(
        id: 'expense-bills',
        name: 'Bollette',
        iconCodePoint: 0xe1b7, // Icons.receipt
        colorHex: '#F44336',
        type: 'expense',
      ),
      Category(
        id: 'expense-entertainment',
        name: 'Intrattenimento',
        iconCodePoint: 0xe3d3, // Icons.movie
        colorHex: '#673AB7',
        type: 'expense',
      ),
      Category(
        id: 'expense-health',
        name: 'Salute',
        iconCodePoint: 0xe3f3, // Icons.local_hospital
        colorHex: '#00BCD4',
        type: 'expense',
      ),
      Category(
        id: 'expense-education',
        name: 'Educazione',
        iconCodePoint: 0xe80c, // Icons.school
        colorHex: '#795548',
        type: 'expense',
      ),
      Category(
        id: 'expense-home',
        name: 'Casa',
        iconCodePoint: 0xe88a, // Icons.home
        colorHex: '#8BC34A',
        type: 'expense',
      ),
    ];
  }

  void addCategory(Category category) {
    state = [...state, category];
  }

  void updateCategory(Category category) {
    state = state.map((c) => c.id == category.id ? category : c).toList();
  }

  void deleteCategory(String id) {
    state = state.where((c) => c.id != id).toList();
  }

  List<Category> getCategoriesByType(String type) {
    return state.where((c) => c.type == type).toList();
  }
}

final categoriesProvider =
    StateNotifierProvider<CategoriesNotifier, List<Category>>(
  (ref) => CategoriesNotifier(),
);
