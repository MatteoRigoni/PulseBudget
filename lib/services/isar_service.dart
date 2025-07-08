import '../model/train_sample.dart';
import '../model/category_stat.dart';
import 'database_service.dart';

class IsarService {
  static DatabaseService? _databaseService;

  /// Inizializza il servizio
  static Future<void> initialize() async {
    if (_databaseService == null) {
      _databaseService = DatabaseService();
      await _databaseService!.initialize();
    }
  }

  /// Aggiunge un campione di training
  static Future<void> addTrainSample(
      String description, String categoryId) async {
    await initialize();
    if (categoryId.isEmpty) {
      print('[TRAINING] categoryId vuoto, non salvo il campione.');
      return;
    }
    final categories = await _databaseService!.getCategories();
    final exists = categories.any((cat) => cat.id == categoryId);
    if (!exists) {
      print(
          '[TRAINING] Categoria non trovata per id: "$categoryId", non salvo il campione.');
      return;
    }
    await _databaseService!.insertTrainSample(description, categoryId);
  }

  /// Ottiene tutti i campioni di training
  static Future<List<TrainSample>> getAllTrainSamples() async {
    await initialize();
    return await _databaseService!.getTrainSamples();
  }

  /// Ottiene i campioni di training per una categoria
  static Future<List<TrainSample>> getTrainSamplesByCategory(
      String categoryId) async {
    await initialize();
    final samples = await getAllTrainSamples();
    return samples.where((sample) => sample.categoryId == categoryId).toList();
  }

  /// Salva le statistiche di una categoria
  static Future<void> saveCategoryStat(CategoryStat stat) async {
    await initialize();
    await _databaseService!.saveCategoryStat(stat);
  }

  /// Ottiene le statistiche di una categoria
  static Future<CategoryStat?> getCategoryStat(String categoryId) async {
    await initialize();
    return await _databaseService!.getCategoryStat(categoryId);
  }

  /// Ottiene tutte le statistiche delle categorie
  static Future<List<CategoryStat>> getAllCategoryStats() async {
    await initialize();
    final stats = await _databaseService!.getAllCategoryStats();
    return stats ?? <CategoryStat>[];
  }

  /// Elimina tutti i dati di training
  static Future<void> clearAllTrainingData() async {
    await initialize();
    await _databaseService!.clearTrainingData();
  }
}
