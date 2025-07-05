import '../model/category.dart';

/// Interfaccia astratta per il repository delle categorie
abstract class CategoryRepository {
  /// Ottiene tutte le categorie
  Stream<List<Category>> watchAll();

  /// Ottiene una categoria specifica per ID
  Future<Category?> getById(String id);

  /// Aggiunge una nuova categoria
  Future<void> add(Category category);

  /// Aggiorna una categoria esistente
  Future<void> update(Category category);

  /// Elimina una categoria
  Future<void> delete(String id);

  /// Aggiunge multiple categorie in batch
  Future<void> addBatch(List<Category> categories);
}
