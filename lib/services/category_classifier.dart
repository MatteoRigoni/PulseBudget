import 'dart:math';
import '../model/category.dart';
import '../model/train_sample.dart';
import '../model/category_stat.dart';
import 'isar_service.dart';
import 'database_service.dart';

class CategoryClassifier {
  static final Map<String, List<String>> _keywordRules = {
    // Entrate
    'income-salary': [
      'stipendio',
      'salario',
      'busta paga',
      'pagamento lavoro',
      'retribuzione',
      'mensilità',
      'emolumento',
      'cedolino'
    ],
    'income-gifts': [
      'regalo',
      'donazione',
      'regali',
      'dono',
      'contributo',
      'elargizione'
    ],
    'income-betting': [
      'vincita',
      'scommessa vinta',
      'gioco',
      'betting',
      'lotteria',
      'gratta e vinci',
      'superenalotto',
      'vincite'
    ],
    'income-deposits': [
      'deposito',
      'versamento',
      'accredito',
      'bonifico in entrata',
      'ricarica',
      'trasferimento in entrata'
    ],
    'income-freelance': [
      'freelance',
      'fattura',
      'prestazione',
      'collaborazione',
      'compenso',
      'progetto',
      'pagamento freelance'
    ],
    'income-investment': [
      'dividendo',
      'interesse',
      'provento',
      'investimento',
      'cedola',
      'guadagno titoli',
      'plusvalenza',
      'rendita'
    ],

    // Uscite
    'expense-clothing': [
      'abbigliamento',
      'vestiti',
      'scarpe',
      'shopping vestiti',
      'maglietta',
      'pantaloni',
      'giacca',
      'negozio abbigliamento'
    ],
    'expense-food': [
      'supermercato',
      'alimentari',
      'coop',
      'esselunga',
      'carrefour',
      'conad',
      'spesa',
      'discount',
      'iper',
      'pam',
      'simply',
      'lidl',
      'md',
      'famila',
      'bennet',
      'craì',
      'grocery'
    ],
    'expense-pets': [
      'animali',
      'veterinario',
      'cibo animali',
      'pet',
      'toelettatura',
      'cuccia',
      'crocchette',
      'accessori animali'
    ],
    'expense-car': [
      'auto',
      'macchina',
      'carburante',
      'benzina',
      'diesel',
      'gpl',
      'manutenzione auto',
      'tagliando',
      'assicurazione auto',
      'bollo auto',
      'riparazione auto',
      'garage',
      'parcheggio',
      'autolavaggio'
    ],
    'expense-bar': [
      'bar',
      'caffè',
      'colazione bar',
      'aperitivo',
      'spritz',
      'happy hour',
      'pasticceria',
      'pub'
    ],
    'expense-bills': [
      'bolletta',
      'enel',
      'luce',
      'gas',
      'acqua',
      'telefono',
      'internet',
      'tim',
      'vodafone',
      'wind',
      'fastweb',
      'energia',
      'utenza',
      'fattura energia',
      'bolletta gas',
      'bolletta luce',
      'bolletta acqua'
    ],
    'expense-fuel': [
      'benzina',
      'diesel',
      'gpl',
      'carburante',
      'rifornimento',
      'distributore',
      'pompa',
      'metano',
      'self service'
    ],
    'expense-home': [
      'casa',
      'affitto',
      'mutuo',
      'condominio',
      'arredamento',
      'mobili',
      'elettrodomestici',
      'spese casa',
      'ristrutturazione',
      'utenze casa',
      'acquisto casa'
    ],
    'expense-communication': [
      'telefono',
      'cellulare',
      'internet',
      'adsl',
      'fibra',
      'mobile',
      'ricarica telefonica',
      'sms',
      'chiamata',
      'abbonamento telefono'
    ],
    'expense-family': [
      'famiglia',
      'figlio',
      'figli',
      'bambino',
      'bambina',
      'asilo',
      'scuola',
      'spese figli',
      'mensa scolastica',
      'baby sitter',
      'genitori',
      'parenti'
    ],
    'expense-hygiene': [
      'igiene',
      'sapone',
      'shampoo',
      'bagnoschiuma',
      'dentifricio',
      'spazzolino',
      'cura persona',
      'parrucchiere',
      'barbiere',
      'estetista',
      'cosmetici',
      'crema',
      'profumo'
    ],
    'expense-investments': [
      'investimento',
      'azioni',
      'obbligazioni',
      'borsa',
      'trading',
      'acquisto titoli',
      'etf',
      'piano accumulo',
      'cripto',
      'bitcoin',
      'finanza'
    ],
    'expense-work': [
      'lavoro',
      'ufficio',
      'materiale ufficio',
      'spese lavoro',
      'colleghi',
      'pranzo lavoro',
      'trasferta',
      'rimborso spese',
      'formazione lavoro'
    ],
    'expense-eating-out': [
      'ristorante',
      'pizzeria',
      'trattoria',
      'osteria',
      'mensa',
      'sushi',
      'fast food',
      'hamburger',
      'paninoteca',
      'cena fuori',
      'pranzo fuori',
      'take away',
      'delivery',
      'just eat',
      'glovo',
      'deliveroo'
    ],
    'expense-motorcycle': [
      'motore',
      'moto',
      'motorino',
      'scooter',
      'assicurazione moto',
      'benzina moto',
      'riparazione moto',
      'garage moto'
    ],
    'expense-gifts': [
      'regalo',
      'regali',
      'dono',
      'compleanno',
      'natale',
      'festa',
      'bomboniera',
      'donazione',
      'pensiero',
      'cadeau'
    ],
    'expense-health': [
      'salute',
      'farmacia',
      'medico',
      'ospedale',
      'dentista',
      'analisi',
      'visita',
      'ticket',
      'medicina',
      'specialista',
      'oculista',
      'fisioterapia',
      'psicologo',
      'esame medico'
    ],
    'expense-betting': [
      'scommessa',
      'gioco',
      'betting',
      'lotteria',
      'gratta e vinci',
      'superenalotto',
      'gioco d azzardo',
      'schedina',
      'vincita scommessa',
      'slot',
      'casino'
    ],
    'expense-misc': [
      'spesa varia',
      'varie',
      'altro',
      'imprevisto',
      'emergenza',
      'acquisto casuale',
      'spese varie',
      'spesa imprevista'
    ],
    'expense-sport': [
      'sport',
      'palestra',
      'abbonamento palestra',
      'corsa',
      'calcio',
      'tennis',
      'nuoto',
      'basket',
      'allenamento',
      'iscrizione sport',
      'personal trainer',
      'fitness',
      'yoga'
    ],
    'expense-entertainment': [
      'svago',
      'cinema',
      'teatro',
      'concerto',
      'museo',
      'disco',
      'spettacolo',
      'evento',
      'biglietto spettacolo',
      'videogioco',
      'gioco',
      'netflix',
      'prime video',
      'spotify',
      'abbonamento streaming'
    ],
    'expense-transport': [
      'trasporto',
      'autobus',
      'metro',
      'tram',
      'treno',
      'taxi',
      'uber',
      'car sharing',
      'ncc',
      'pullman',
      'biglietto trasporto',
      'abbonamento trasporti',
      'viaggio urbano'
    ],
    'expense-technology': [
      'tecnologia',
      'computer',
      'pc',
      'notebook',
      'tablet',
      'smartphone',
      'telefono',
      'stampante',
      'monitor',
      'hardware',
      'software',
      'accessorio tech',
      'gadget',
      'app',
      'acquisto tech'
    ],
    'expense-travel': [
      'viaggio',
      'vacanza',
      'hotel',
      'aereo',
      'volo',
      'treno',
      'traghetto',
      'nave',
      'b&b',
      'ostello',
      'prenotazione viaggio',
      'tour',
      'escursione',
      'gita',
      'weekend',
      'booking',
      'airbnb'
    ],
    // Trasferimenti
    'transfer-withdrawal': [
      'prelievo',
      'atm',
      'bancomat',
      'cash withdrawal',
      'ritiro contanti',
      'withdrawal',
      'sportello',
      'contanti',
      'prelievo contanti'
    ],
  };

  /// Classifica una transazione usando regole keyword + Naive Bayes
  static Future<Map<String, double>> classifyTransaction(
      String description) async {
    try {
      // 1. Regex match
      final regexCategory = _matchCategoryByRegex(description);
      print(
          '[CLASSIFIER] Regex check for "$description": ${regexCategory ?? 'NO MATCH'}');
      if (regexCategory != null) {
        print('[CLASSIFIER] Regex matched: $regexCategory');
        return {regexCategory: 0.9}; // Alta confidenza per keyword match
      }
      print(
          '[CLASSIFIER] Regex did not match for "$description". Fallback to Naive Bayes.');
      // 2. Fallback: Naive Bayes
      final stats = await IsarService.getAllCategoryStats();
      final words = description.toLowerCase().split(RegExp(r'\W+'));
      final scores = <String, double>{};
      for (final stat in stats) {
        double score = 1.0;
        for (final word in words) {
          score *= (stat.wordCounts[word] ?? 1) / stat.total;
        }
        scores[stat.categoryId] = score;
      }
      if (scores.isEmpty) {
        print('[CLASSIFIER] Naive Bayes found no scores for "$description".');
        return {};
      }
      // Normalizza e trova la migliore
      final maxScore = scores.values.reduce((a, b) => a > b ? a : b);
      final normalized = scores.map((k, v) => MapEntry(k, v / maxScore));
      final best =
          normalized.entries.reduce((a, b) => a.value > b.value ? a : b);
      print(
          '[CLASSIFIER] Naive Bayes best: ${best.key} (score: ${best.value}) for "$description"');
      return {best.key: best.value};
    } catch (e, stack) {
      print('[CLASSIFIER][ERROR] Errore nella classificazione: $e\n$stack');
      return {};
    }
  }

  /// Classificazione Naive Bayes semplificata
  static Future<Map<String, double>> _naiveBayesClassification(
      String description) async {
    try {
      final words = _tokenize(description);
      final stats = await IsarService.getAllCategoryStats();

      if (stats.isEmpty) {
        return {'supermercato': 0.5}; // Default
      }

      final scores = <String, double>{};
      final totalSamples = stats.fold<int>(0, (sum, stat) => sum + stat.total);

      for (final stat in stats) {
        double score = 0.0;

        // Prior probability (P(category))
        final prior = stat.total / totalSamples;
        score += log(prior);

        // Likelihood (P(words|category))
        for (final word in words) {
          final wordCount = stat.wordCounts[word] ?? 0;
          final wordProb =
              (wordCount + 1) / (stat.total + stat.wordCounts.length);
          score += log(wordProb);
        }

        scores[stat.categoryId] = score;
      }

      // Normalizza i punteggi
      final maxScore = scores.values.reduce(max);
      final normalizedScores = <String, double>{};

      for (final entry in scores.entries) {
        final normalized = exp(entry.value - maxScore);
        normalizedScores[entry.key] = normalized;
      }

      // Normalizza per somma = 1
      final sum = normalizedScores.values.reduce((a, b) => a + b);
      for (final key in normalizedScores.keys) {
        normalizedScores[key] = normalizedScores[key]! / sum;
      }

      return normalizedScores;
    } catch (e) {
      print('Errore nella classificazione Naive Bayes: $e');
      return {'supermercato': 0.5}; // Default
    }
  }

  /// Tokenizza il testo in parole
  static List<String> _tokenize(String text) {
    return text
        .toLowerCase()
        .replaceAll(RegExp(r'[^\w\s]'), ' ')
        .split(RegExp(r'\s+'))
        .where((word) => word.length > 2)
        .toList();
  }

  /// Addestra il classificatore con nuovi dati
  static Future<void> trainClassifier() async {
    try {
      final samples = await IsarService.getAllTrainSamples();
      final categoryStats = <String, CategoryStat>{};

      // Raggruppa i campioni per categoria
      for (final sample in samples) {
        if (!categoryStats.containsKey(sample.categoryId)) {
          categoryStats[sample.categoryId] = CategoryStat.create(
            categoryId: sample.categoryId,
            total: 0,
            wordCounts: {},
          );
        }

        final stat = categoryStats[sample.categoryId]!;
        stat.total++;

        // Conta le parole
        final words = _tokenize(sample.description);
        for (final word in words) {
          stat.wordCounts[word] = (stat.wordCounts[word] ?? 0) + 1;
        }
      }

      // Salva le statistiche
      for (final stat in categoryStats.values) {
        await IsarService.saveCategoryStat(stat);
      }

      print('Classificatore addestrato con ${samples.length} campioni');
    } catch (e) {
      print('Errore nell\'addestramento del classificatore: $e');
    }
  }

  /// Aggiunge un campione di training
  static Future<void> addTrainingSample(
      String description, String categoryId) async {
    print(
        '[TRAINING] addTrainingSample called with description: "$description", categoryId: "$categoryId"');
    if (description.isEmpty || categoryId.isEmpty) {
      print('[TRAINING][ERROR] description o categoryId vuoti, skip.');
      return;
    }
    // Verifica se la categoria esiste nel database
    final db = DatabaseService();
    await db.initialize();
    final categories = await db.getCategories();
    final exists = categories.any((c) => c.id == categoryId);
    if (!exists) {
      print(
          '[TRAINING][ERROR] Categoria "$categoryId" non trovata nel database, skip.');
      return;
    }
    print('[TRAINING] Categoria trovata, salvo campione.');
    await IsarService.addTrainSample(description, categoryId);
    // Riaddestra il classificatore
    await trainClassifier();
  }

  /// Cerca una categoria tramite keyword regex
  static String? _matchCategoryByRegex(String description) {
    final descriptionLower = description.toLowerCase();
    for (final entry in _keywordRules.entries) {
      final categoryId = entry.key;
      final keywords = entry.value;
      for (final keyword in keywords) {
        if (descriptionLower.contains(keyword)) {
          print(
              '[CLASSIFIER][REGEX] Matched "$keyword" for category "$categoryId" in "$description"');
          return categoryId;
        }
      }
    }
    return null;
  }
}
