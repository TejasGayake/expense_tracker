import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'dart:async';

class DatabaseService {
  static final DatabaseService _instance = DatabaseService._internal();
  factory DatabaseService() => _instance;
  DatabaseService._internal();

  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    Directory documentsDirectory = await getApplicationDocumentsDirectory();
    String path = join(documentsDirectory.path, 'expense_tracker.db');
    
    return await openDatabase(
      path,
      version: 6,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future _onCreate(Database db, int version) async {
    // Create transactions table
    await db.execute('''
      CREATE TABLE transactions(
        id TEXT PRIMARY KEY,
        amount REAL,
        date INTEGER,
        description TEXT,
        category TEXT,
        categoryId TEXT,
        paymentMode TEXT,
        location TEXT,
        notes TEXT,
        type TEXT DEFAULT 'expense',
        createdAt INTEGER,
        updatedAt INTEGER
      )
    ''');

    // Create people table
    await db.execute('''
      CREATE TABLE people(
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        phone TEXT,
        email TEXT,
        createdAt INTEGER
      )
    ''');
    
    // ✅ CREATE CATEGORIES TABLE
    await db.execute('''
      CREATE TABLE categories(
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        icon TEXT NOT NULL,
        color INTEGER NOT NULL,
        isDefault INTEGER DEFAULT 0,
        usageCount INTEGER DEFAULT 0,
        createdAt INTEGER
      )
    ''');
    
    // Insert default categories
    final now = DateTime.now().millisecondsSinceEpoch;
    final defaultCategories = [
      ['Food', '🍕', 0xFFFF6B6B, 1],
      ['Transport', '🚗', 0xFF4ECDC4, 1],
      ['Shopping', '🛍️', 0xFF45B7D1, 1],
      ['Bills', '💡', 0xFF96CEB4, 1],
      ['Healthcare', '🏥', 0xFFFFEEAD, 1],
      ['Education', '📚', 0xFFD4A5A5, 1],
      ['Entertainment', '🎬', 0xFF9B59B6, 1],
      ['Other', '📦', 0xFF95A5A6, 1],
    ];
    
    for (var cat in defaultCategories) {
      final id = '${now}_${cat[0]}';
      await db.insert('categories', {
        'id': id,
        'name': cat[0],
        'icon': cat[1],
        'color': cat[2],
        'isDefault': cat[3],
        'usageCount': 0,
        'createdAt': now,
      });
    }
    if (kDebugMode) {
      print('✅ Default categories inserted during creation');
    }

    // Create transaction_people table
    await db.execute('''
      CREATE TABLE transaction_people(
        id TEXT PRIMARY KEY,
        transactionId TEXT,
        personId TEXT,
        amount REAL,
        direction TEXT,
        status TEXT,
        settledAmount REAL DEFAULT 0,
        dueDate INTEGER,
        FOREIGN KEY (transactionId) REFERENCES transactions(id) ON DELETE CASCADE,
        FOREIGN KEY (personId) REFERENCES people(id) ON DELETE CASCADE
      )
    ''');

    // Create attachments table
    await db.execute('''
      CREATE TABLE attachments(
        id TEXT PRIMARY KEY,
        transactionId TEXT,
        filePath TEXT,
        type TEXT,
        caption TEXT,
        createdAt INTEGER,
        FOREIGN KEY (transactionId) REFERENCES transactions(id) ON DELETE CASCADE
      )
    ''');
      // ✅ ADD THESE INDEX LINES at the end of _onCreate
    await db.execute('CREATE INDEX IF NOT EXISTS idx_transactions_date ON transactions(date)');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_transactions_category ON transactions(category)');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_transaction_people_person ON transaction_people(personId)');
    
    if (kDebugMode) {
      print('✅ Database indexes created');
    }
  }

  Future _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (kDebugMode) {
      print('Upgrading database from $oldVersion to $newVersion');
    }
    
    // Upgrade from version 1 to 2
    if (oldVersion < 2) {
      try {
        final tableInfo = await db.rawQuery("PRAGMA table_info(people)");
        final hasCreatedAt = tableInfo.any((column) => column['name'] == 'createdAt');
        
        if (!hasCreatedAt) {
          await db.execute('ALTER TABLE people ADD COLUMN createdAt INTEGER');
        }
        
        final tpTableInfo = await db.rawQuery("PRAGMA table_info(transaction_people)");
        final hasSettledAmount = tpTableInfo.any((column) => column['name'] == 'settledAmount');
        final hasDueDate = tpTableInfo.any((column) => column['name'] == 'dueDate');
        
        if (!hasSettledAmount) {
          await db.execute('ALTER TABLE transaction_people ADD COLUMN settledAmount REAL DEFAULT 0');
        }
        if (!hasDueDate) {
          await db.execute('ALTER TABLE transaction_people ADD COLUMN dueDate INTEGER');
        }
      } catch (e) {
        if (kDebugMode) {
          print('Migration error (v1->v2): $e');
        }
      }
    }
    
    // Upgrade from version 2 to 3
    if (oldVersion < 3) {
      try {
        final tableInfo = await db.rawQuery("PRAGMA table_info(attachments)");
        final hasCreatedAt = tableInfo.any((column) => column['name'] == 'createdAt');
        
        if (!hasCreatedAt) {
          await db.execute('ALTER TABLE attachments ADD COLUMN createdAt INTEGER');
          if (kDebugMode) {
            print('✅ Added createdAt column to attachments table');
          }
        }
      } catch (e) {
        if (kDebugMode) {
          print('Migration error (v2->v3): $e');
        }
      }
    }
    
    // 🔥 NEW: Upgrade from version 3 to 4 - Add categories table
    if (oldVersion < 4) {
      try {
        // Check if categories table already exists
        final tables = await db.rawQuery(
          "SELECT name FROM sqlite_master WHERE type='table' AND name='categories'"
        );
        
        if (tables.isEmpty) {
          // Create categories table
          await db.execute('''
            CREATE TABLE categories(
              id TEXT PRIMARY KEY,
              name TEXT NOT NULL,
              icon TEXT NOT NULL,
              color INTEGER NOT NULL,
              isDefault INTEGER DEFAULT 0,
              usageCount INTEGER DEFAULT 0,
              createdAt INTEGER
            )
          ''');
          if (kDebugMode) {
            print('✅ Categories table created during migration');
          }
          
          // Insert default categories
          final now = DateTime.now().millisecondsSinceEpoch;
          final defaultCategories = [
            ['Food', '🍕', 0xFFFF6B6B, 1],
            ['Transport', '🚗', 0xFF4ECDC4, 1],
            ['Shopping', '🛍️', 0xFF45B7D1, 1],
            ['Bills', '💡', 0xFF96CEB4, 1],
            ['Healthcare', '🏥', 0xFFFFEEAD, 1],
            ['Education', '📚', 0xFFD4A5A5, 1],
            ['Entertainment', '🎬', 0xFF9B59B6, 1],
            ['Other', '📦', 0xFF95A5A6, 1],
          ];
          
          for (var cat in defaultCategories) {
            final id = '${now}_${cat[0]}';
            await db.insert('categories', {
              'id': id,
              'name': cat[0],
              'icon': cat[1],
              'color': cat[2],
              'isDefault': cat[3],
              'usageCount': 0,
              'createdAt': now,
            });
          }
          if (kDebugMode) {
            print('✅ Default categories inserted during migration');
          }
        }
      } catch (e) {
        if (kDebugMode) {
          print('Migration error (v3->v4): $e');
        }
      }
    }

    // Upgrade from version 4 to 5 - Add categoryId column
    if (oldVersion < 5) {
      try {
        final tableInfo = await db.rawQuery("PRAGMA table_info(transactions)");
        final hasCategoryId = tableInfo.any((column) => column['name'] == 'categoryId');

        if (!hasCategoryId) {
          await db.execute('ALTER TABLE transactions ADD COLUMN categoryId TEXT');
          if (kDebugMode) {
            print('✅ Added categoryId column to transactions table');
          }
        }
      } catch (e) {
        if (kDebugMode) {
          print('Migration error (v4->v5): $e');
        }
      }
    }

    // Upgrade from version 5 to 6 - Add type column for income tracking
    if (oldVersion < 6) {
      try {
        final tableInfo = await db.rawQuery("PRAGMA table_info(transactions)");
        final hasType = tableInfo.any((column) => column['name'] == 'type');

        if (!hasType) {
          await db.execute("ALTER TABLE transactions ADD COLUMN type TEXT DEFAULT 'expense'");
          if (kDebugMode) {
            print('✅ Added type column to transactions table');
          }
        }
      } catch (e) {
        if (kDebugMode) {
          print('Migration error (v5->v6): $e');
        }
      }
    }
  }

  // Helper method to generate ID
  String generateId() {
    return DateTime.now().millisecondsSinceEpoch.toString();
  }

  // ===== ATTACHMENT METHODS =====
  
  Future<void> insertAttachment(Map<String, dynamic> attachment) async {
    Database db = await database;
    
    final Map<String, dynamic> attachmentData = {
      'id': generateId(),
      'transactionId': attachment['transactionId'] as String,
      'filePath': attachment['filePath'] as String,
      'type': attachment['type'] as String,
      'caption': attachment['caption'] as String?,
      'createdAt': DateTime.now().millisecondsSinceEpoch,
    };
    
    attachmentData.removeWhere((key, value) => value == null);
    
    try {
      await db.insert('attachments', attachmentData);
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error inserting attachment: $e');
      }
      rethrow;
    }
  }
  
  Future<List<Map<String, dynamic>>> getAttachmentsForTransaction(String transactionId) async {
    Database db = await database;
    return await db.query(
      'attachments',
      where: 'transactionId = ?',
      whereArgs: [transactionId],
      orderBy: 'createdAt DESC',
    );
  }
  
  Future<void> deleteAttachment(String id) async {
    Database db = await database;
    await db.delete(
      'attachments',
      where: 'id = ?',
      whereArgs: [id],
    );
  }
  
  Future<Map<String, dynamic>?> getAttachmentById(String id) async {
    Database db = await database;
    final results = await db.query(
      'attachments',
      where: 'id = ?',
      whereArgs: [id],
    );
    return results.isNotEmpty ? results.first : null;
  }
  
  Future<List<Map<String, dynamic>>> getAllAttachments() async {
    Database db = await database;
    return await db.query(
      'attachments',
      orderBy: 'createdAt DESC',
    );
  }

  // ===== CATEGORY METHODS =====

  Future<void> createCategoriesTable() async {
    Database db = await database;
    await db.execute('''
      CREATE TABLE IF NOT EXISTS categories(
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        icon TEXT NOT NULL,
        color INTEGER NOT NULL,
        isDefault INTEGER DEFAULT 0,
        usageCount INTEGER DEFAULT 0,
        createdAt INTEGER
      )
    ''');
  }

  Future<void> insertCategory(Map<String, dynamic> category) async {
    Database db = await database;

    final Map<String, dynamic> categoryData = {
      'id': generateId(),
      'name': category['name'] as String,
      'icon': category['icon'] as String,
      'color': category['color'] as int,
      'isDefault': category['isDefault'] ?? 0,
      'usageCount': 0,
      'createdAt': DateTime.now().millisecondsSinceEpoch,
    };

    await db.insert('categories', categoryData);
  }

  Future<List<Map<String, dynamic>>> getCategories() async {
    Database db = await database;
    if (kDebugMode) {
      print('🔍 Fetching categories from database...');
    }
    
    try {
      final results = await db.query(
        'categories',
        orderBy: 'usageCount DESC, name ASC',
      );
      
      if (kDebugMode) {
        print('📊 Found ${results.length} categories');
      }
      return results;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error fetching categories: $e');
      }
      return [];
    }
  }

  Future<void> updateCategory(Map<String, dynamic> category) async {
    Database db = await database;

    final Map<String, dynamic> categoryData = {
      'name': category['name'] as String,
      'icon': category['icon'] as String,
      'color': category['color'] as int,
    };

    await db.update(
      'categories',
      categoryData,
      where: 'id = ?',
      whereArgs: [category['id']],
    );
  }

  Future<void> deleteCategory(String id) async {
    Database db = await database;

    final transactions = await db.query(
      'transactions',
      where: 'categoryId = ?',
      whereArgs: [id],
    );

    if (transactions.isNotEmpty) {
      throw Exception('Cannot delete category that is in use');
    }

    await db.delete(
      'categories',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> incrementCategoryUsage(String categoryId) async {
    Database db = await database;

    await db.rawUpdate('''
      UPDATE categories 
      SET usageCount = usageCount + 1 
      WHERE id = ?
    ''', [categoryId]);
  }

  Future<void> initializeDefaultCategories() async {
    try {
      final existing = await getCategories();
      if (existing.isNotEmpty) {
        if (kDebugMode) {
          print('✅ Categories already exist, skipping initialization');
        }
        return;
      }

      if (kDebugMode) {
        print('📦 Initializing default categories...');
      }
      
      final defaultCategories = [
        {'name': 'Food', 'icon': '🍕', 'color': 0xFFFF6B6B, 'isDefault': 1},
        {'name': 'Transport', 'icon': '🚗', 'color': 0xFF4ECDC4, 'isDefault': 1},
        {'name': 'Shopping', 'icon': '🛍️', 'color': 0xFF45B7D1, 'isDefault': 1},
        {'name': 'Bills', 'icon': '💡', 'color': 0xFF96CEB4, 'isDefault': 1},
        {'name': 'Healthcare', 'icon': '🏥', 'color': 0xFFFFEEAD, 'isDefault': 1},
        {'name': 'Education', 'icon': '📚', 'color': 0xFFD4A5A5, 'isDefault': 1},
        {'name': 'Entertainment', 'icon': '🎬', 'color': 0xFF9B59B6, 'isDefault': 1},
        {'name': 'Other', 'icon': '📦', 'color': 0xFF95A5A6, 'isDefault': 1},
      ];

      for (var cat in defaultCategories) {
        await insertCategory(cat);
        if (kDebugMode) {
          print('✅ Added category: ${cat['name']}');
        }
      }

      if (kDebugMode) {
        print('🎉 Default categories initialized successfully!');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error in initializeDefaultCategories: $e');
      }
    }
  }


  // ===== TRANSACTION settled =====
  // Add to your DatabaseService class
  
  /// Mark a transaction as settled
  Future<void> markTransactionAsSettled(String transactionPersonId) async {
    Database db = await database;
    
    try {
      // First get the current transaction to know the amount
      final current = await db.query(
        'transaction_people',
        where: 'id = ?',
        whereArgs: [transactionPersonId],
      );
      
      if (current.isNotEmpty) {
        final amount = current.first['amount'] as double;
        
        // Update the transaction to settled with full amount
        await db.update(
          'transaction_people',
          {
            'status': 'settled',
            'settledAmount': amount, // Set to full amount
          },
          where: 'id = ?',
          whereArgs: [transactionPersonId],
        );
        
        if (kDebugMode) {
          print('✅ Transaction marked as settled');
        }
      } else {
        if (kDebugMode) {
          print('❌ Transaction not found');
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error in markTransactionAsSettled: $e');
      }
      rethrow;
    }
  }  
  /// Mark a transaction as partially settled
  Future<void> markTransactionAsPartiallySettled(String transactionPersonId, double amount) async {
    Database db = await database;

    try {
      final current = await db.query(
        'transaction_people',
        where: 'id = ?',
        whereArgs: [transactionPersonId],
      );

      if (current.isNotEmpty) {
        final totalAmount = current.first['amount'] as double;
        final currentSettled = current.first['settledAmount'] as double? ?? 0;
        final newSettled = currentSettled + amount;

        String newStatus = newSettled >= totalAmount ? 'settled' : 'partial';

        await db.update(
          'transaction_people',
          {
            'settledAmount': newSettled,
            'status': newStatus,
          },
          where: 'id = ?',
          whereArgs: [transactionPersonId],
        );

        if (kDebugMode) {
          print('✅ Partial settlement recorded: $amount');
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error in markTransactionAsPartiallySettled: $e');
      }
      rethrow;
    }
  }

  // ===== TRANSACTION METHODS =====
  
  Future<String> insertTransaction(Map<String, dynamic> transaction) async {
    Database db = await database;
    final id = generateId();
    transaction['id'] = id;
    transaction['createdAt'] = DateTime.now().millisecondsSinceEpoch;
    transaction['updatedAt'] = DateTime.now().millisecondsSinceEpoch;

    await db.insert('transactions', transaction);
    return id;
  }

  Future<List<Map<String, dynamic>>> getTransactions() async {
    Database db = await database;
    return await db.rawQuery('''
      SELECT t.*, c.name as categoryName, c.icon as categoryIcon, c.color as categoryColor
      FROM transactions t
      LEFT JOIN categories c ON t.categoryId = c.id
      ORDER BY t.date DESC
    ''');
  }

  Future<Map<String, dynamic>?> getTransactionById(String id) async {
    Database db = await database;
    final results = await db.rawQuery('''
      SELECT t.*, c.name as categoryName, c.icon as categoryIcon, c.color as categoryColor
      FROM transactions t
      LEFT JOIN categories c ON t.categoryId = c.id
      WHERE t.id = ?
    ''', [id]);
    return results.isNotEmpty ? results.first : null;
  }

  Future<void> updateTransaction(Map<String, dynamic> transaction) async {
    Database db = await database;
    transaction['updatedAt'] = DateTime.now().millisecondsSinceEpoch;
    
    await db.update(
      'transactions',
      transaction,
      where: 'id = ?',
      whereArgs: [transaction['id']],
    );
  }

  Future<void> deleteTransaction(String id) async {
    Database db = await database;
    await db.delete(
      'transactions',
      where: 'id = ?',
      whereArgs: [id],
    );
  }
  // =======================================
  // ===== PEOPLE SCREEN QUERIES =====
  
  /// Get all people with transaction summaries
  Future<List<Map<String, dynamic>>> getAllPeopleWithSummary() async {
    Database db = await database;
    
    try {
      final results = await db.rawQuery('''
        SELECT 
          p.*,
          COALESCE((
            SELECT SUM(CASE 
              WHEN tp.direction = 'owes' AND tp.status != 'settled' 
              THEN tp.amount - COALESCE(tp.settledAmount, 0)
              ELSE 0 
            END)
            FROM transaction_people tp
            WHERE tp.personId = p.id
          ), 0) as owedToMe,
          COALESCE((
            SELECT SUM(CASE 
              WHEN tp.direction = 'lent' AND tp.status != 'settled' 
              THEN tp.amount - COALESCE(tp.settledAmount, 0)
              ELSE 0 
            END)
            FROM transaction_people tp
            WHERE tp.personId = p.id
          ), 0) as iOwe,
          COALESCE((
            SELECT COUNT(*) 
            FROM transaction_people tp 
            WHERE tp.personId = p.id AND tp.status != 'settled'
          ), 0) as pendingCount,
          (
            SELECT MAX(t.date) 
            FROM transactions t
            JOIN transaction_people tp ON t.id = tp.transactionId
            WHERE tp.personId = p.id
          ) as lastTransactionDate,
          (
            SELECT t.description 
            FROM transactions t
            JOIN transaction_people tp ON t.id = tp.transactionId
            WHERE tp.personId = p.id
            ORDER BY t.date DESC
            LIMIT 1
          ) as lastTransactionDescription
        FROM people p
        ORDER BY 
          CASE 
            WHEN owedToMe > 0 THEN 1
            WHEN iOwe > 0 THEN 2
            ELSE 3
          END,
          owedToMe DESC,
          iOwe DESC,
          p.name ASC
      ''');
      
      return results;
    } catch (e) {
      if (kDebugMode) {
        print('Error in getAllPeopleWithSummary: $e');
      }
      return [];
    }
  }
  
  /// Get people who owe me (owedToMe > 0)
  Future<List<Map<String, dynamic>>> getPeopleWhoOweMe() async {
    final allPeople = await getAllPeopleWithSummary();
    return allPeople.where((p) => ((p['owedToMe'] as num?)?.toDouble() ?? 0) > 0).toList();
  }
  
  /// Get people I owe (iOwe > 0)
  Future<List<Map<String, dynamic>>> getPeopleIOwe() async {
    final allPeople = await getAllPeopleWithSummary();
    return allPeople.where((p) => ((p['iOwe'] as num?)?.toDouble() ?? 0) > 0).toList();
  }
  
  /// Get settled people (no pending amounts)
  Future<List<Map<String, dynamic>>> getSettledPeople() async {
    final allPeople = await getAllPeopleWithSummary();
    return allPeople.where((p) {
      final owed = (p['owedToMe'] as num?)?.toDouble() ?? 0;
      final iOwe = (p['iOwe'] as num?)?.toDouble() ?? 0;
      return owed == 0 && iOwe == 0;
    }).toList();
  }
  
  /// Get detailed transaction history for a specific person
  Future<List<Map<String, dynamic>>> getPersonTransactions(String personId) async {
    Database db = await database;
    
    try {
      final results = await db.rawQuery('''
        SELECT 
          t.*,
          tp.amount as shareAmount,
          tp.direction,
          tp.status,
          tp.settledAmount
        FROM transactions t
        JOIN transaction_people tp ON t.id = tp.transactionId
        WHERE tp.personId = ?
        ORDER BY t.date DESC
      ''', [personId]);
      
      return results;
    } catch (e) {
      if (kDebugMode) {
        print('Error in getPersonTransactions: $e');
      }
      return [];
    }
  }
  
  /// Get total pending amount for a person
  Future<Map<String, double>> getPersonPendingAmount(String personId) async {
    Database db = await database;
    
    try {
      final results = await db.rawQuery('''
        SELECT 
          COALESCE(SUM(CASE 
            WHEN direction = 'owes' AND status != 'settled' 
            THEN amount - COALESCE(settledAmount, 0)
            ELSE 0 
          END), 0) as owedToMe,
          COALESCE(SUM(CASE 
            WHEN direction = 'lent' AND status != 'settled' 
            THEN amount - COALESCE(settledAmount, 0)
            ELSE 0 
          END), 0) as iOwe
        FROM transaction_people
        WHERE personId = ?
      ''', [personId]);
      
      if (results.isNotEmpty) {
        return {
          'owedToMe': (results.first['owedToMe'] as num?)?.toDouble() ?? 0,
          'iOwe': (results.first['iOwe'] as num?)?.toDouble() ?? 0,
        };
      }
      return {'owedToMe': 0, 'iOwe': 0};
    } catch (e) {
      if (kDebugMode) {
        print('Error in getPersonPendingAmount: $e');
      }
      return {'owedToMe': 0, 'iOwe': 0};
    }
  }
  // =======================================

  // ===== PEOPLE METHODS =====
  
  Future<void> insertPerson(Map<String, dynamic> person) async {
    Database db = await database;
    
    final Map<String, dynamic> personData = {
      'id': generateId(),
      'name': person['name'] as String,
      'phone': person['phone'] as String?,
      'email': person['email'] as String?,
      'createdAt': DateTime.now().millisecondsSinceEpoch,
    };
    
    personData.removeWhere((key, value) => value == null);
    
    await db.insert('people', personData);
  }

  Future<List<Map<String, dynamic>>> getPeople() async {
    Database db = await database;
    return await db.query('people', orderBy: 'name ASC');
  }

  Future<Map<String, dynamic>?> getPersonById(String id) async {
    Database db = await database;
    final results = await db.query(
      'people',
      where: 'id = ?',
      whereArgs: [id],
    );
    return results.isNotEmpty ? results.first : null;
  }

  Future<void> updatePerson(Map<String, dynamic> person) async {
    Database db = await database;
    
    final Map<String, dynamic> personData = {
      'name': person['name'] as String,
      'phone': person['phone'] as String?,
      'email': person['email'] as String?,
    };
    
    personData.removeWhere((key, value) => value == null);
    
    await db.update(
      'people',
      personData,
      where: 'id = ?',
      whereArgs: [person['id']],
    );
  }

  Future<void> deletePerson(String id) async {
    Database db = await database;
    await db.delete(
      'people',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // ===== SPLIT METHODS =====
  
  Future<void> addTransactionPerson(Map<String, dynamic> data) async {
    Database db = await database;
    
    double amount;
    if (data['amount'] is int) {
      amount = (data['amount'] as int).toDouble();
    } else if (data['amount'] is double) {
      amount = data['amount'] as double;
    } else {
      amount = double.tryParse(data['amount'].toString()) ?? 0.0;
    }
    
    double settledAmount = 0.0;
    if (data.containsKey('settledAmount')) {
      if (data['settledAmount'] is int) {
        settledAmount = (data['settledAmount'] as int).toDouble();
      } else if (data['settledAmount'] is double) {
        settledAmount = data['settledAmount'] as double;
      }
    }
    
    final Map<String, dynamic> tpData = {
      'id': generateId(),
      'transactionId': data['transactionId'] as String,
      'personId': data['personId'] as String,
      'amount': amount,
      'direction': data['direction'] as String,
      'status': data['status'] as String,
      'settledAmount': settledAmount,
    };
    
    if (data.containsKey('dueDate') && data['dueDate'] != null) {
      tpData['dueDate'] = data['dueDate'] as int;
    }
    
    tpData.removeWhere((key, value) => value == null);
    
    try {
      await db.insert('transaction_people', tpData);
    } catch (e) {
      if (kDebugMode) {
        print('Error inserting transaction person: $e');
      }
      rethrow;
    }
  }

  Future<List<Map<String, dynamic>>> getPeopleForTransaction(String transactionId) async {
    Database db = await database;
    return await db.query(
      'transaction_people',
      where: 'transactionId = ?',
      whereArgs: [transactionId],
    );
  }

  Future<void> updateTransactionPerson(Map<String, dynamic> data) async {
    Database db = await database;
    
    final Map<String, dynamic> tpData = {
      'amount': data['amount'] as double,
      'direction': data['direction'] as String,
      'status': data['status'] as String,
      'settledAmount': (data['settledAmount'] as double?) ?? 0.0,
      'dueDate': data['dueDate'] as int?,
    };
    
    tpData.removeWhere((key, value) => value == null);
    
    await db.update(
      'transaction_people',
      tpData,
      where: 'id = ?',
      whereArgs: [data['id']],
    );
  }

  Future<void> deleteTransactionPerson(String id) async {
    Database db = await database;
    await db.delete(
      'transaction_people',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // ===== COMPLEX QUERIES =====
  
  Future<List<Map<String, dynamic>>> getPendingAmounts() async {
    Database db = await database;
    
    try {
      final results = await db.rawQuery('''
        SELECT 
          p.id,
          p.name,
          COALESCE(SUM(CASE 
            WHEN tp.direction = 'owes' AND tp.status != 'settled' 
            THEN tp.amount - COALESCE(tp.settledAmount, 0)
            ELSE 0 
          END), 0) as owedToMe,
          COALESCE(SUM(CASE 
            WHEN tp.direction = 'lent' AND tp.status != 'settled' 
            THEN tp.amount - COALESCE(tp.settledAmount, 0)
            ELSE 0 
          END), 0) as iOwe
        FROM people p
        LEFT JOIN transaction_people tp ON p.id = tp.personId
        GROUP BY p.id
        HAVING owedToMe > 0 OR iOwe > 0
        ORDER BY owedToMe DESC
      ''');
      
      return results.map((row) {
        return {
          'id': row['id'] as String,
          'name': row['name'] as String,
          'owedToMe': (row['owedToMe'] as num?)?.toDouble() ?? 0.0,
          'iOwe': (row['iOwe'] as num?)?.toDouble() ?? 0.0,
        };
      }).toList();
    } catch (e) {
      if (kDebugMode) {
        print('Error in getPendingAmounts: $e');
      }
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> getTransactionsWithPeople() async {
    Database db = await database;
    
    try {
      final results = await db.rawQuery('''
        SELECT
          t.*,
          c.name as categoryName, c.icon as categoryIcon, c.color as categoryColor,
          GROUP_CONCAT(p.name || ':' || COALESCE(tp.amount, 0) || ':' || tp.direction || ':' || tp.status) as peopleInfo
        FROM transactions t
        LEFT JOIN categories c ON t.categoryId = c.id
        LEFT JOIN transaction_people tp ON t.id = tp.transactionId
        LEFT JOIN people p ON tp.personId = p.id
        GROUP BY t.id
        ORDER BY t.date DESC
      ''');
      
      return results;
    } catch (e) {
      if (kDebugMode) {
        print('Error in getTransactionsWithPeople: $e');
      }
      return [];
    }
  }

  // ===== BULK OPERATIONS FOR SPLIT =====
  
  Future<void> saveTransactionWithPeople(
    Map<String, dynamic> transaction,
    List<Map<String, dynamic>> peopleList,
  ) async {
    Database db = await database;
    
    await db.transaction((txn) async {
      final String transactionId = generateId();
      final Map<String, dynamic> transactionData = {
        'id': transactionId,
        'amount': transaction['amount'] as double,
        'date': transaction['date'] as int,
        'description': transaction['description'] as String,
        'category': transaction['category'] as String,
        'categoryId': transaction['categoryId'] as String?,
        'paymentMode': transaction['paymentMode'] as String,
        'location': transaction['location'] as String?,
        'notes': transaction['notes'] as String?,
        'createdAt': DateTime.now().millisecondsSinceEpoch,
        'updatedAt': DateTime.now().millisecondsSinceEpoch,
      };
      
      transactionData.removeWhere((key, value) => value == null);
      await txn.insert('transactions', transactionData);
      
      for (var person in peopleList) {
        final Map<String, dynamic> tpData = {
          'id': generateId(),
          'transactionId': transactionId,
          'personId': person['personId'] as String,
          'amount': person['amount'] as double,
          'direction': person['direction'] as String,
          'status': person['status'] as String,
          'settledAmount': (person['settledAmount'] as double?) ?? 0.0,
          'dueDate': person['dueDate'] as int?,
        };
        
        tpData.removeWhere((key, value) => value == null);
        await txn.insert('transaction_people', tpData);
      }
    });
  }

  Future<void> settleAmount(String transactionPersonId, double amount) async {
    Database db = await database;
    
    final results = await db.query(
      'transaction_people',
      where: 'id = ?',
      whereArgs: [transactionPersonId],
    );
    
    if (results.isNotEmpty) {
      final current = results.first;
      final currentAmount = current['amount'] as double;
      final currentSettled = (current['settledAmount'] as double?) ?? 0.0;
      
      double newSettled = currentSettled + amount;
      String newStatus = newSettled >= currentAmount ? 'settled' : 'partial';
      
      await db.update(
        'transaction_people',
        {
          'settledAmount': newSettled,
          'status': newStatus,
        },
        where: 'id = ?',
        whereArgs: [transactionPersonId],
      );
    }
  }
}