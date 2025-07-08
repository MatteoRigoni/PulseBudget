import 'dart:math';
import '../model/category.dart';
import '../model/train_sample.dart';
import '../model/category_stat.dart';
import 'isar_service.dart';
import 'database_service.dart';

// Debug log globale per abilitare/disabilitare tutti i log avanzati di classificazione
const bool kDebugLogs = false;

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
      'cedolino',
      'paga mensile',
      'retribuzione netta',
      'emolumenti',
      'accredito stipendio',
      'salario netto',
      'pagamento mensile',
      'bonifico stipendio',
      'trattamento economico',
      'salario lordo',
      'accredito paga',
      'compenso mensile',
      'pagamento lav.',
      'accr. stipendio',
      'salario aziendale'
    ],
    'income-gifts': [
      'regalo',
      'donazione',
      'regali',
      'dono',
      'contributo',
      'elargizione',
      'regalo compleanno',
      'regalo natale',
      'accredito regalo',
      'ricezione regalo',
      'dono ricevuto',
      'contributo amico',
      'eredità',
      'lascito',
      'premio regalo',
      'supporto familiare',
      'liberalità',
      'accredito donazione',
      'credito regalo',
      'trasferimento regalo'
    ],
    'income-betting': [
      'vincita',
      'scommessa vinta',
      'gioco',
      'betting',
      'lotteria',
      'gratta e vinci',
      'superenalotto',
      'vincite',
      'premio scommessa',
      'accredito vincita',
      'payout betting',
      'guadagno scommesse',
      'riscossione vincita',
      'vincita giochi',
      'montepremi',
      'premio lotteria',
      'accredito gratta e vinci',
      'payout superenalotto',
      'riscossione premi',
      'vincita concorso',
      'bonus gioco',
      'pagamento vincita'
    ],
    'income-deposits': [
      'deposito',
      'versamento',
      'accredito',
      'bonifico in entrata',
      'ricarica',
      'trasferimento in entrata',
      'accredito contanti',
      'bonifico ricevuto',
      'trasferimento ricevuto',
      'accredito wallet',
      'incasso',
      'accredito assegno',
      'versamento contanti',
      'ricarica wallet',
      'pagamento ricevuto',
      'deposito automatico',
      'entrata fondi',
      'trasferimento bancario',
      'credito su conto',
      'ricarica contante'
    ],
    'income-freelance': [
      'freelance',
      'fattura',
      'prestazione',
      'collaborazione',
      'compenso',
      'progetto',
      'pagamento freelance',
      'pagamento prestazione',
      'compenso consulenza',
      'saldo fattura',
      'compenso occasionale',
      'rimborso collaborazione',
      'accredito freelance',
      'collaborazione occasionale',
      'emolumenti freelance',
      'pagamento collaborazione',
      'pagamento autonomo',
      'parcella professionale',
      'reddito autonomo',
      'fatturazione freelance',
      'accredito collaborazione'
    ],
    'income-investment': [
      'dividendo',
      'interesse',
      'provento',
      'investimento',
      'cedola',
      'guadagno titoli',
      'plusvalenza',
      'rendita',
      'accredito interessi',
      'dividendi azioni',
      'rendimento obbligazioni',
      'profitti investimento',
      'liquidazione fondi',
      'guadagno fondi',
      'reddito capitale',
      'guadagno cripto',
      'accredito plusvalenze',
      'cedola obbligazione',
      'interessi maturati',
      'profitto borsa',
      'guadagno ETF',
      'rendimento investimenti'
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
      'negozio abbigliamento',
      't-shirt',
      'camicia',
      'felpa',
      'jeans',
      'intimo',
      'calzature',
      'stivali',
      'accessori moda',
      'boutique',
      'shopping online',
      'negozio scarpe',
      'abbigliamento sportivo'
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
      'grocery',
      'ipercoop',
      'eurospin',
      'decò',
      'sigma',
      'alimentari locali',
      'spesa online',
      'mercato ortofrutta',
      'negozio bio',
      'market',
      'minimarket'
    ],
    'expense-pets': [
      'animali',
      'veterinario',
      'cibo animali',
      'pet',
      'toelettatura',
      'cuccia',
      'crocchette',
      'accessori animali',
      'pet shop',
      'clinica veterinaria',
      'snack animali',
      'antiparassitari',
      'giochi animali',
      'negozio animali',
      'cuccia cane',
      'cuccia gatto',
      'pensione animali',
      'cura pet',
      'visita veterinaria',
      'farmacia veterinaria'
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
      'autolavaggio',
      'gomme',
      'pneumatici',
      'officina',
      'accessori auto',
      'cambio olio',
      'noleggio auto',
      'lavaggio auto',
      'revisione auto',
      'ricambi auto',
      'stazione servizio'
    ],
    'expense-bar': [
      'bar',
      'caffè',
      'colazione bar',
      'aperitivo',
      'spritz',
      'happy hour',
      'pasticceria',
      'pub',
      'caffetteria',
      'wine bar',
      'birreria',
      'cocktail bar',
      'snack bar',
      'bar pasticceria',
      'bistrot',
      'breakfast bar',
      'drink bar',
      'lounge bar',
      'spuntino bar'
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
      'bolletta acqua',
      'canone',
      'spese utenze',
      'bolletta condominio',
      'enigas',
      'energia elettrica',
      'gestore luce',
      'gestore gas',
      'fatturazione servizi',
      'spese servizi',
      'spese acqua'
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
      'self service',
      'stazione carburante',
      'impianto gpl',
      'rifornimento self',
      'carburante auto',
      'fuel station',
      'erogazione benzina',
      'gasolio',
      'servizio carburante',
      'pagamento benzina',
      'servizio rifornimento'
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
      'acquisto casa',
      'accessori casa',
      'decorazioni casa',
      'manutenzione casa',
      'materiale edile',
      'attrezzi casa',
      'impianti casa',
      'rata mutuo',
      'spese condominiali',
      'forniture casa',
      'artigiani casa'
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
      'abbonamento telefono',
      'canone internet',
      'gestore mobile',
      'ricarica sim',
      'linea fissa',
      'servizi telefonici',
      'gestore telefonico',
      'credito telefono',
      'pagamento cellulare',
      'utenze telefoniche',
      'spese telefonia'
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
      'parenti',
      'rette scolastiche',
      'spese scolastiche',
      'libri scuola',
      'vestiti figli',
      'giocattoli',
      'spese ludiche',
      'medico bambini',
      'attività extrascolastiche',
      'campi estivi',
      'corso lingue'
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
      'profumo',
      'lozione',
      'balsamo',
      'deodorante',
      'cura corpo',
      'trattamento viso',
      'detergente viso',
      'cosmesi',
      'cura capelli',
      'cura mani',
      'cura piedi',
      'igiene intima'
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
      'finanza',
      'cripto monete',
      'criptovalute',
      'trading online',
      'brokeraggio',
      'fondi comuni',
      'portafoglio investimenti',
      'diversificazione',
      'mercati finanziari',
      'speculazione',
      'wallet cripto',
      'exchange cripto'
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
      'formazione lavoro',
      'attrezzatura lavoro',
      'coworking',
      'cancelleria',
      'software lavoro',
      'formazione professionale',
      'consulenza professionale',
      'quota iscrizione',
      'servizi professionali',
      'aggiornamento professionale',
      'conferenze',
      'spese aziendali'
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
      'deliveroo',
      'food court',
      'steakhouse',
      'cucina etnica',
      'cibo da asporto',
      'dinner out',
      'colazione fuori',
      'brunch'
    ],
    'expense-motorcycle': [
      'motore',
      'moto',
      'motorino',
      'scooter',
      'assicurazione moto',
      'benzina moto',
      'riparazione moto',
      'garage moto',
      'accessori moto',
      'casco',
      'gomme moto',
      'pneumatici scooter',
      'ricambi moto',
      'noleggio scooter',
      'lubrificante moto',
      'tagliando scooter',
      'revisione moto',
      'lavaggio scooter'
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
      'cadeau',
      'sorpresa',
      'omaggio',
      'gift card',
      'cofanetto regalo',
      'box regalo',
      'articolo regalo',
      'spesa regalo',
      'pensierino',
      'regalo aziendale',
      'regalo bambini'
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
      'esame medico',
      'parafarmacia',
      'check up',
      'diagnostica',
      'esami sangue',
      'ricovero',
      'ambulatorio',
      'assistenza sanitaria',
      'clinica',
      'terapia',
      'trattamento medico'
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
      'casino',
      'scommesse sportive',
      'poker online',
      'bingo',
      'sala giochi',
      'betting shop',
      'vlt',
      'gaming online',
      'payout gioco',
      'gioco virtuale',
      'blackjack',
      'roulette'
    ],
    'expense-misc': [
      'spesa varia',
      'varie',
      'altro',
      'imprevisto',
      'emergenza',
      'acquisto casuale',
      'spese varie',
      'spesa imprevista',
      'altre spese',
      'diverse',
      'spese extra',
      'pagamento vario',
      'conto vario',
      'altro pagamento',
      'spesa non classificata',
      'spesa generica',
      'altri costi',
      'spesa occasionale'
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
      'yoga',
      'arti marziali',
      'danza',
      'pilates',
      'bicicletta',
      'sala pesi',
      'club sportivo',
      'attrezzatura sportiva',
      'gara sportiva',
      'torneo',
      'camp sportivo'
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
      'abbonamento streaming',
      'festival',
      'serata',
      'party',
      'evento musicale',
      'pay tv',
      'streaming video',
      'serata cinema',
      'biglietto cinema',
      'intrattenimento'
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
      'viaggio urbano',
      'pass mensile',
      'biglietto metro',
      'biglietto autobus',
      'servizio navetta',
      'bike sharing',
      'monopattino sharing',
      'blablacar',
      'trasferimento urbano',
      'ticket trasporto',
      'mobilità urbana'
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
      'acquisto tech',
      'cuffie',
      'auricolari',
      'router',
      'modem',
      'console',
      'controller',
      'smartwatch',
      'ricarica tech',
      'riparazione tech',
      'negozio elettronica'
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
      'airbnb',
      'agriturismo',
      'resort',
      'pacchetto vacanza',
      'agenzia viaggi',
      'autonoleggio',
      'navetta aeroporto',
      'transfer hotel',
      'prenotazione volo',
      'escursioni guidate'
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
      'prelievo contanti',
      'prelievo sportello',
      'cash point',
      'bancomat estero',
      'ritiro atm',
      'prelievo automatico',
      'operazione bancomat',
      'ritiro sportello automatico',
      'prelievo notturno',
      'cash machine'
    ],
  };

  /// Classifica una transazione usando regole keyword + Naive Bayes
  static Future<Map<String, double>> classifyTransaction(
      String description) async {
    try {
      // 1. Regex match
      final regexCategory = _matchCategoryByRegex(description);
      if (kDebugLogs) {
        print(
            '[CLASSIFIER] Regex check for "$description": ${regexCategory ?? 'NO MATCH'}');
      }
      if (regexCategory != null) {
        if (kDebugLogs) {
          print('[CLASSIFIER] Regex matched: $regexCategory');
        }
        return {regexCategory: 0.9}; // Alta confidenza per keyword match
      }
      if (kDebugLogs) {
        print(
            '[CLASSIFIER] Regex did not match for "$description". Fallback to Naive Bayes.');
      }
      // 2. Fallback: Naive Bayes
      final stats = await IsarService.getAllCategoryStats();
      if (stats == null || stats.isEmpty) {
        if (kDebugLogs) {
          print(
              '[CLASSIFIER][NAIVE BAYES] Nessuna statistica disponibile, classificazione impossibile.');
        }
        return {}; // Nessuna categoria suggerita
      }
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
        if (kDebugLogs) {
          print('[CLASSIFIER] Naive Bayes found no scores for "$description".');
        }
        return {};
      }
      // Normalizza e trova la migliore
      final maxScore = scores.values.reduce((a, b) => a > b ? a : b);
      final normalized = scores.map((k, v) => MapEntry(k, v / maxScore));
      final best =
          normalized.entries.reduce((a, b) => a.value > b.value ? a : b);
      // Trova il numero di campioni per la categoria migliore e stampa dettagli per debug
      final bestStat = stats.firstWhere((s) => s.categoryId == best.key,
          orElse: () =>
              CategoryStat(categoryId: best.key, total: 0, wordCounts: {}));
      if (kDebugLogs) {
        print(
            '[CLASSIFIER][DEBUG] Predizione Naive Bayes: categoria migliore = "${best.key}", score = \\${best.value}, campioni per questa categoria = \\${bestStat.total}');
        print('[CLASSIFIER][DEBUG] Campioni per categoria:');
        for (final s in stats) {
          print('  - \\${s.categoryId}: \\${s.total} campioni');
        }
      }
      if (bestStat.total <= 2) {
        if (kDebugLogs) {
          print(
              '[CLASSIFIER][WARNING] Categoria "${best.key}" ha solo \\${bestStat.total} campioni: confidenza forzata a 0.75 (media/gialla)');
        }
        return {best.key: 0.75};
      }
      if (kDebugLogs) {
        print(
            '[CLASSIFIER] Naive Bayes best: ${best.key} (score: ${best.value}) for "$description"');
      }
      return {best.key: best.value};
    } catch (e, stack) {
      if (kDebugLogs) {
        print('[CLASSIFIER][ERROR] Errore nella classificazione: $e\n$stack');
      }
      return {};
    }
  }

  /// Classificazione Naive Bayes semplificata
  static Future<Map<String, double>> _naiveBayesClassification(
      String description) async {
    try {
      final words = _tokenize(description);
      final stats = await IsarService.getAllCategoryStats();
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
      if (kDebugLogs) {
        print('Errore nella classificazione Naive Bayes: $e');
      }
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

      if (kDebugLogs) {
        print('Classificatore addestrato con ${samples.length} campioni');
        print('[TRAINING][DEBUG] Statistiche per categoria:');
        for (final stat in categoryStats.values) {
          print(
              '  - ${stat.categoryId}: totale=${stat.total}, parole=${stat.wordCounts}');
        }
      }
    } catch (e) {
      if (kDebugLogs) {
        print('Errore nell\'addestramento del classificatore: $e');
      }
    }
  }

  /// Aggiunge un campione di training SOLO se la correzione è manuale
  static Future<void> addTrainingSample(String description, String categoryId,
      {bool manual = false}) async {
    if (!manual) {
      // Non salvare campioni se non è una correzione manuale
      return;
    }
    if (kDebugLogs) {
      print(
          '[TRAINING] addTrainingSample called with description: "$description", categoryId: "$categoryId"');
    }
    if (description.isEmpty || categoryId.isEmpty) {
      if (kDebugLogs) {
        print('[TRAINING][ERROR] description o categoryId vuoti, skip.');
      }
      return;
    }
    // Verifica se la categoria esiste nel database
    final db = DatabaseService();
    await db.initialize();
    final categories = await db.getCategories();
    final exists = categories.any((c) => c.id == categoryId);
    if (!exists) {
      if (kDebugLogs) {
        print(
            '[TRAINING][ERROR] Categoria "$categoryId" non trovata nel database, skip.');
      }
      return;
    }
    if (kDebugLogs) {
      print('[TRAINING] Categoria trovata, salvo campione.');
    }
    await IsarService.addTrainSample(description, categoryId);
    // Logga tutti i campioni di training dopo il salvataggio
    final allSamples = await IsarService.getAllTrainSamples();
    if (kDebugLogs) {
      print('[TRAINING][DEBUG] Campioni di training attuali:');
      for (final s in allSamples) {
        print('  - "${s.description}" => ${s.categoryId}');
      }
    }
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
          if (kDebugLogs) {
            print(
                '[CLASSIFIER][REGEX] Matched "$keyword" for category "$categoryId" in "$description"');
          }
          return categoryId;
        }
      }
    }
    return null;
  }
}
