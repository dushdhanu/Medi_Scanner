import 'dart:convert';
import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';
import '../models/medicine_analysis_result.dart';
import 'history_service.dart';

class DatabaseService {
  static const String _dbName = 'mediscan_vault.db';
  static const int _dbVersion = 2;
  static const String tableMedicines = 'medicines';

  static Database? _database;

  /// Get the active SQLite database instance
  static Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  /// Initialize SQLite database and tables on the phone's internal storage
  static Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = p.join(dbPath, _dbName);

    final db = await openDatabase(
      path,
      version: _dbVersion,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE $tableMedicines (
            id TEXT PRIMARY KEY,
            brand_name_en TEXT,
            brand_name_si TEXT,
            generic_name_en TEXT,
            generic_name_si TEXT,
            dosage_strength TEXT,
            package_type TEXT,
            confidence_rating TEXT,
            image_path TEXT,
            expiry_date TEXT,
            batch_no TEXT,
            remaining_pills INTEGER,
            raw_json TEXT NOT NULL,
            created_at INTEGER NOT NULL,
            is_favorite INTEGER DEFAULT 0,
            personal_notes TEXT
          )
        ''');

        // Create indexes for instant lightning-fast search by brand/generic names
        await db.execute('CREATE INDEX idx_medicines_brand ON $tableMedicines (brand_name_en, brand_name_si)');
        await db.execute('CREATE INDEX idx_medicines_created ON $tableMedicines (created_at DESC)');
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          try {
            await db.execute('ALTER TABLE $tableMedicines ADD COLUMN expiry_date TEXT');
            await db.execute('ALTER TABLE $tableMedicines ADD COLUMN batch_no TEXT');
            await db.execute('ALTER TABLE $tableMedicines ADD COLUMN remaining_pills INTEGER');
          } catch (_) {}
        }
      },
    );

    // Auto-migrate any previously stored scans from SharedPreferences into SQLite
    await _migrateFromPreferences(db);

    return db;
  }

  /// Import existing SharedPreferences records into SQLite so user history is preserved
  static Future<void> _migrateFromPreferences(Database db) async {
    try {
      final oldItems = await HistoryService.getHistory();
      if (oldItems.isEmpty) return;

      final batch = db.batch();
      for (final item in oldItems) {
        batch.insert(
          tableMedicines,
          {
            'id': item.id,
            'brand_name_en': item.english.brandName,
            'brand_name_si': item.sinhala.brandName,
            'generic_name_en': item.english.genericName,
            'generic_name_si': item.sinhala.genericName,
            'dosage_strength': item.english.dosageStrength,
            'package_type': item.packageType,
            'confidence_rating': item.confidenceRating,
            'image_path': item.imagePath,
            'raw_json': item.toJsonString(),
            'created_at': item.timestamp.millisecondsSinceEpoch,
            'is_favorite': 0,
            'personal_notes': null,
          },
          conflictAlgorithm: ConflictAlgorithm.ignore,
        );
      }
      await batch.commit(noResult: true);
    } catch (_) {}
  }

  /// Insert or update a medicine scan record into the local SQLite database
  static Future<void> insertMedicine(
    MedicineAnalysisResult result, {
    String? notes,
    int? remainingPills,
  }) async {
    final db = await database;
    await db.insert(
      tableMedicines,
      {
        'id': result.id,
        'brand_name_en': result.english.brandName,
        'brand_name_si': result.sinhala.brandName,
        'generic_name_en': result.english.genericName,
        'generic_name_si': result.sinhala.genericName,
        'dosage_strength': result.english.dosageStrength,
        'package_type': result.packageType,
        'confidence_rating': result.confidenceRating,
        'image_path': result.imagePath,
        'expiry_date': result.expiryDate,
        'batch_no': result.batchNumber,
        'remaining_pills': remainingPills ?? result.remainingPills,
        'raw_json': result.toJsonString(),
        'created_at': result.timestamp.millisecondsSinceEpoch,
        'is_favorite': 0,
        'personal_notes': notes,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );

    // Also sync with HistoryService for fallback
    await HistoryService.saveResult(result);
  }

  /// Update remaining pill count for inventory tracking
  static Future<void> updateRemainingPills(String id, int count) async {
    final db = await database;
    final rows = await db.query(tableMedicines, where: 'id = ?', whereArgs: [id]);
    String? updatedRawJson;
    if (rows.isNotEmpty) {
      try {
        final decoded = jsonDecode(rows.first['raw_json'] as String) as Map<String, dynamic>;
        decoded['remainingPills'] = count;
        updatedRawJson = jsonEncode(decoded);
      } catch (_) {}
    }

    final updateData = <String, dynamic>{'remaining_pills': count};
    if (updatedRawJson != null) {
      updateData['raw_json'] = updatedRawJson;
    }

    await db.update(
      tableMedicines,
      updateData,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// Retrieve all saved medicines with optional search and favorite filter
  static Future<List<MedicineAnalysisResult>> getAllMedicines({
    String? searchQuery,
    bool onlyFavorites = false,
  }) async {
    final db = await database;
    String? where;
    List<dynamic>? whereArgs;

    final conditions = <String>[];
    final args = <dynamic>[];

    if (onlyFavorites) {
      conditions.add('is_favorite = 1');
    }

    if (searchQuery != null && searchQuery.trim().isNotEmpty) {
      final query = '%${searchQuery.trim().toLowerCase()}%';
      conditions.add(
        '(LOWER(brand_name_en) LIKE ? OR LOWER(brand_name_si) LIKE ? OR LOWER(generic_name_en) LIKE ? OR LOWER(generic_name_si) LIKE ?)',
      );
      args.addAll([query, query, query, query]);
    }

    if (conditions.isNotEmpty) {
      where = conditions.join(' AND ');
      whereArgs = args;
    }

    final List<Map<String, dynamic>> maps = await db.query(
      tableMedicines,
      where: where,
      whereArgs: whereArgs,
      orderBy: 'created_at DESC',
    );

    final results = <MedicineAnalysisResult>[];
    for (final row in maps) {
      try {
        final rawJson = row['raw_json'] as String;
        final decoded = jsonDecode(rawJson) as Map<String, dynamic>;
        if (row['remaining_pills'] != null) {
          decoded['remainingPills'] = row['remaining_pills'];
        }
        if (row['expiry_date'] != null && (decoded['expiryDate'] == null || decoded['expiryDate'].toString().isEmpty)) {
          decoded['expiryDate'] = row['expiry_date'];
        }
        if (row['batch_no'] != null && (decoded['batchNumber'] == null || decoded['batchNumber'].toString().isEmpty)) {
          decoded['batchNumber'] = row['batch_no'];
        }
        results.add(MedicineAnalysisResult.fromJson(decoded));
      } catch (_) {}
    }

    return results;
  }

  /// Toggle favorite status of a medicine record
  static Future<void> toggleFavorite(String id, bool isFavorite) async {
    final db = await database;
    await db.update(
      tableMedicines,
      {'is_favorite': isFavorite ? 1 : 0},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// Check if a medicine is marked as favorite
  static Future<bool> isFavorite(String id) async {
    final db = await database;
    final res = await db.query(
      tableMedicines,
      columns: ['is_favorite'],
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (res.isNotEmpty) {
      return (res.first['is_favorite'] as int?) == 1;
    }
    return false;
  }

  /// Update personal patient notes for a medicine
  static Future<void> updateNotes(String id, String notes) async {
    final db = await database;
    await db.update(
      tableMedicines,
      {'personal_notes': notes},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// Delete a single medicine record from the phone's database
  static Future<void> deleteMedicine(String id) async {
    final db = await database;
    await db.delete(
      tableMedicines,
      where: 'id = ?',
      whereArgs: [id],
    );
    await HistoryService.deleteResult(id);
  }

  /// Get total count of saved medicines in local storage
  static Future<int> getMedicineCount() async {
    final db = await database;
    final res = await db.rawQuery('SELECT COUNT(*) as count FROM $tableMedicines');
    return Sqflite.firstIntValue(res) ?? 0;
  }

  /// Clear all saved medicines from local phone database
  static Future<void> clearAll() async {
    final db = await database;
    await db.delete(tableMedicines);
    await HistoryService.clearHistory();
  }
}
