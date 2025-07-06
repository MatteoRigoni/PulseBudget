import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../model/transaction.dart' as model;
import '../model/category.dart';
import '../model/snapshot.dart';
import '../model/recurring_rule.dart';

class DatabaseService {
  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'bilanciome.db');

    return await openDatabase(
      path,
      version: 3,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    // Tabella categorie
    await db.execute('''
      CREATE TABLE categories (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        iconCodePoint INTEGER NOT NULL,
        colorHex TEXT NOT NULL,
        type TEXT NOT NULL
      )
    ''');

    // Tabella transazioni
    await db.execute('''
      CREATE TABLE transactions (
        id TEXT PRIMARY KEY,
        amount REAL NOT NULL,
        date TEXT NOT NULL,
        description TEXT NOT NULL,
        descriptionLowercase TEXT NOT NULL,
        categoryId TEXT NOT NULL,
        paymentType TEXT NOT NULL,
        isRecurring INTEGER NOT NULL DEFAULT 0,
        recurringRuleName TEXT,
        FOREIGN KEY (categoryId) REFERENCES categories (id)
      )
    ''');

    // Tabella snapshot (patrimonio)
    await db.execute('''
      CREATE TABLE snapshots (
        id TEXT PRIMARY KEY,
        label TEXT NOT NULL,
        amount REAL NOT NULL,
        date TEXT NOT NULL,
        note TEXT
      )
    ''');

    // Tabella regole ricorrenti
    await db.execute('''
      CREATE TABLE recurring_rules (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        amount REAL NOT NULL,
        categoryId TEXT NOT NULL,
        paymentType TEXT NOT NULL,
        rrule TEXT NOT NULL,
        startDate TEXT NOT NULL,
        FOREIGN KEY (categoryId) REFERENCES categories (id)
      )
    ''');

    // Tabella account/entità
    await db.execute('''
      CREATE TABLE entities (
        id TEXT PRIMARY KEY,
        type TEXT NOT NULL,
        name TEXT NOT NULL
      )
    ''');

    // Indici per performance
    await db.execute(
      'CREATE INDEX idx_transactions_date ON transactions(date)',
    );
    await db.execute(
      'CREATE INDEX idx_transactions_category ON transactions(categoryId)',
    );
    await db.execute(
      'CREATE INDEX idx_transactions_description ON transactions(descriptionLowercase)',
    );
    await db.execute('CREATE INDEX idx_snapshots_date ON snapshots(date)');
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      // Migrazione da versione 1 a 2: ricrea le tabelle con la nuova struttura
      try {
        // Backup dei dati esistenti
        final oldSnapshots = await db.query('snapshots');
        final oldRecurringRules = await db.query('recurring_rules');

        // Elimina le tabelle vecchie
        await db.execute('DROP TABLE snapshots');
        await db.execute('DROP TABLE recurring_rules');

        // Ricrea snapshots con la nuova struttura
        await db.execute('''
          CREATE TABLE snapshots (
            id TEXT PRIMARY KEY,
            label TEXT NOT NULL,
            amount REAL NOT NULL,
            date TEXT NOT NULL,
            note TEXT
          )
        ''');

        // Ricrea recurring_rules con la nuova struttura
        await db.execute('''
          CREATE TABLE recurring_rules (
            id TEXT PRIMARY KEY,
            name TEXT NOT NULL,
            amount REAL NOT NULL,
            categoryId TEXT NOT NULL,
            paymentType TEXT NOT NULL,
            rrule TEXT NOT NULL,
            startDate TEXT NOT NULL,
            FOREIGN KEY (categoryId) REFERENCES categories (id)
          )
        ''');

        // Ripristina i dati esistenti di snapshots (se ce ne sono)
        for (final snapshot in oldSnapshots) {
          await db.insert('snapshots', {
            'id': snapshot['id'],
            'label': snapshot['label'] ?? snapshot['entityName'] ?? 'Unknown',
            'amount': snapshot['amount'],
            'date': snapshot['date'],
            'note': snapshot['note'],
          });
        }

        // Ripristina i dati esistenti di recurring_rules (se ce ne sono)
        for (final rule in oldRecurringRules) {
          await db.insert('recurring_rules', {
            'id': rule['id'],
            'name': rule['name'],
            'amount': rule['amount'],
            'categoryId': rule['categoryId'],
            'paymentType':
                rule['paymentType'] ?? 'cash', // default se non esiste
            'rrule': rule['rrule'],
            'startDate': rule['startDate'] ??
                DateTime.now().toIso8601String(), // default se non esiste
          });
        }

        // Ricrea gli indici
        await db.execute('CREATE INDEX idx_snapshots_date ON snapshots(date)');
      } catch (e) {
        print('Migration error: $e');
      }
    }

    if (oldVersion < 3) {
      // Migrazione da versione 2 a 3: aggiungi tabella entities
      try {
        await db.execute('''
          CREATE TABLE entities (
            id TEXT PRIMARY KEY,
            type TEXT NOT NULL,
            name TEXT NOT NULL
          )
        ''');

        // Inserisci account di default se non esistono entità
        final entities = await db.query('entities');
        if (entities.isEmpty) {
          await db.insert('entities', {
            'id': 'default-account',
            'type': 'Conto',
            'name': 'Conto Corrente',
          });
        }
      } catch (e) {
        print('Migration error: $e');
      }
    }
  }

  // Metodi per le transazioni
  Future<List<model.Transaction>> getTransactions() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'transactions',
      orderBy: 'date DESC',
    );
    return List.generate(
      maps.length,
      (i) => model.Transaction.fromJson(maps[i]),
    );
  }

  Future<void> insertTransaction(model.Transaction transaction) async {
    final db = await database;
    await db.insert('transactions', transaction.toJson());
  }

  Future<void> updateTransaction(model.Transaction transaction) async {
    final db = await database;
    await db.update(
      'transactions',
      transaction.toJson(),
      where: 'id = ?',
      whereArgs: [transaction.id],
    );
  }

  Future<void> deleteTransaction(String id) async {
    final db = await database;
    await db.delete('transactions', where: 'id = ?', whereArgs: [id]);
  }

  // Metodi per le categorie
  Future<List<Category>> getCategories() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'categories',
      orderBy: 'name',
    );
    return List.generate(maps.length, (i) => Category.fromJson(maps[i]));
  }

  Future<void> insertCategory(Category category) async {
    final db = await database;
    await db.insert('categories', category.toJson());
  }

  Future<void> updateCategory(Category category) async {
    final db = await database;
    await db.update(
      'categories',
      category.toJson(),
      where: 'id = ?',
      whereArgs: [category.id],
    );
  }

  Future<void> deleteCategory(String id) async {
    final db = await database;
    await db.delete('categories', where: 'id = ?', whereArgs: [id]);
  }

  // Metodi per gli snapshot
  Future<List<Snapshot>> getSnapshots() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'snapshots',
      orderBy: 'date DESC',
    );
    return List.generate(maps.length, (i) => Snapshot.fromJson(maps[i]));
  }

  Future<void> insertSnapshot(Snapshot snapshot) async {
    final db = await database;
    await db.insert('snapshots', snapshot.toJson());
  }

  Future<void> updateSnapshot(Snapshot snapshot) async {
    final db = await database;
    await db.update(
      'snapshots',
      snapshot.toJson(),
      where: 'id = ?',
      whereArgs: [snapshot.id],
    );
  }

  Future<void> deleteSnapshot(String id) async {
    final db = await database;
    await db.delete('snapshots', where: 'id = ?', whereArgs: [id]);
  }

  // Metodi per le regole ricorrenti
  Future<List<RecurringRule>> getRecurringRules() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'recurring_rules',
      orderBy: 'name',
    );
    return List.generate(maps.length, (i) => RecurringRule.fromJson(maps[i]));
  }

  Future<void> insertRecurringRule(RecurringRule rule) async {
    final db = await database;
    await db.insert('recurring_rules', rule.toJson());
  }

  Future<void> updateRecurringRule(RecurringRule rule) async {
    final db = await database;
    await db.update(
      'recurring_rules',
      rule.toJson(),
      where: 'id = ?',
      whereArgs: [rule.id],
    );
  }

  Future<void> deleteRecurringRule(String id) async {
    final db = await database;
    await db.delete('recurring_rules', where: 'id = ?', whereArgs: [id]);
  }

  // Metodi per le entità/account
  Future<List<Map<String, dynamic>>> getEntities() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'entities',
      orderBy: 'name',
    );
    return maps;
  }

  Future<void> insertEntity(String id, String type, String name) async {
    final db = await database;
    await db.insert('entities', {
      'id': id,
      'type': type,
      'name': name,
    });
  }

  Future<void> updateEntity(String id, String type, String name) async {
    final db = await database;
    await db.update(
      'entities',
      {
        'type': type,
        'name': name,
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> deleteEntity(String id) async {
    final db = await database;
    await db.delete('entities', where: 'id = ?', whereArgs: [id]);
  }

  // Metodo per triggerare l'aggiornamento dei provider
  Future<void> triggerProviderUpdate() async {
    final db = await database;
    // Fai un'operazione fittizia che triggera l'aggiornamento
    // Aggiorna un record esistente con gli stessi valori
    final categories = await db.query('categories', limit: 1);
    if (categories.isNotEmpty) {
      final category = categories.first;
      await db.update(
        'categories',
        category,
        where: 'id = ?',
        whereArgs: [category['id']],
      );
    }
  }

  // Backup e restore
  Future<Map<String, dynamic>> exportData() async {
    final db = await database;
    final transactions = await db.query('transactions');
    final categories = await db.query('categories');
    final snapshots = await db.query('snapshots');
    final recurringRules = await db.query('recurring_rules');
    final entities = await db.query('entities');

    return {
      'transactions': transactions,
      'categories': categories,
      'snapshots': snapshots,
      'recurring_rules': recurringRules,
      'entities': entities,
      'export_date': DateTime.now().toIso8601String(),
      'version': '1.0.0',
    };
  }

  Future<void> importData(Map<String, dynamic> data) async {
    final db = await database;
    await db.transaction((txn) async {
      // Pulisci database esistente
      await txn.delete('transactions');
      await txn.delete('categories');
      await txn.delete('snapshots');
      await txn.delete('recurring_rules');
      await txn.delete('entities');

      // Importa nuovi dati
      for (final category in data['categories']) {
        await txn.insert('categories', category);
      }
      for (final transaction in data['transactions']) {
        await txn.insert('transactions', transaction);
      }
      for (final snapshot in data['snapshots']) {
        await txn.insert('snapshots', snapshot);
      }
      for (final rule in data['recurring_rules']) {
        await txn.insert('recurring_rules', rule);
      }
      if (data['entities'] != null) {
        for (final entity in data['entities']) {
          await txn.insert('entities', entity);
        }
      }
    });
  }
}
