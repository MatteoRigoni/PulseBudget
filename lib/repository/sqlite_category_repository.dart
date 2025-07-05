import 'dart:async';
import 'category_repository.dart';
import '../model/category.dart';
import '../services/database_service.dart';

class SqliteCategoryRepository implements CategoryRepository {
  final DatabaseService _databaseService;
  final StreamController<List<Category>> _categoriesController =
      StreamController<List<Category>>.broadcast();

  SqliteCategoryRepository(this._databaseService) {
    _loadCategories();
  }

  Future<void> _loadCategories() async {
    try {
      final categories = await _databaseService.getCategories();
      _categoriesController.add(categories);
    } catch (e) {
      _categoriesController.addError(e);
    }
  }

  @override
  Stream<List<Category>> watchAll() {
    return _categoriesController.stream;
  }

  @override
  Future<Category?> getById(String id) async {
    final categories = await _databaseService.getCategories();
    try {
      return categories.firstWhere((category) => category.id == id);
    } catch (e) {
      return null;
    }
  }

  @override
  Future<void> add(Category category) async {
    await _databaseService.insertCategory(category);
    await _loadCategories();
  }

  @override
  Future<void> update(Category category) async {
    await _databaseService.updateCategory(category);
    await _loadCategories();
  }

  @override
  Future<void> delete(String id) async {
    await _databaseService.deleteCategory(id);
    await _loadCategories();
  }

  @override
  Future<void> addBatch(List<Category> categories) async {
    for (final category in categories) {
      await _databaseService.insertCategory(category);
    }
    await _loadCategories();
  }

  void dispose() {
    _categoriesController.close();
  }
}
