import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import '../models/fashion_models.dart';

/// Gestor de base de datos local SQLite para soporte Offline (RN-03, RN-04, RNF05).
/// Funciona en Android, iOS, macOS, Windows y Linux.
class LocalDatabase {
  static final LocalDatabase instance = LocalDatabase._internal();
  LocalDatabase._internal();

  Database? _db;

  Future<Database> get database async {
    if (_db != null) return _db!;
    _db = await _initDatabase();
    return _db!;
  }

  Future<Database> _initDatabase() async {
    if (!kIsWeb && (Platform.isLinux || Platform.isWindows || Platform.isMacOS)) {
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
    }

    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'fashionstore_offline.db');

    return await openDatabase(
      path,
      version: 2,
      onCreate: (db, version) async {
        // Cola de transacciones offline (ventas y reservas pendientes de sync)
        await db.execute('''
          CREATE TABLE offline_queue (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            uuid TEXT UNIQUE NOT NULL,
            type TEXT NOT NULL,
            payload TEXT NOT NULL,
            created_at TEXT NOT NULL,
            status TEXT NOT NULL,
            server_message TEXT
          )
        ''');

        // Caché local de productos para catálogo offline
        await db.execute('''
          CREATE TABLE cached_products (
            id INTEGER PRIMARY KEY,
            name TEXT NOT NULL,
            brand TEXT,
            category TEXT,
            price REAL,
            image TEXT,
            data_json TEXT
          )
        ''');

        // Caché local de inventario por sucursal
        await db.execute('''
          CREATE TABLE cached_stock (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            stock_id INTEGER NOT NULL,
            variant_id INTEGER NOT NULL,
            branch_id INTEGER NOT NULL,
            available_stock INTEGER NOT NULL
          )
        ''');

        await _createCatalogRelationTables(db);
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        // v2: variantes (talla/precio) y sucursales para resolver el stock_id
        // real de las operaciones offline (CU-12 / CU-15).
        if (oldVersion < 2) {
          await _createCatalogRelationTables(db);
        }
      },
    );
  }

  Future<void> _createCatalogRelationTables(Database db) async {
    // Variante del backend (variant_id) con su talla y precio: permite pasar de
    // la prenda demo (nombre + talla) a la fila real de inventario sin red.
    await db.execute('''
      CREATE TABLE IF NOT EXISTS cached_variants (
        variant_id INTEGER PRIMARY KEY,
        product_id INTEGER NOT NULL,
        product_name TEXT NOT NULL,
        size_id INTEGER,
        size_name TEXT,
        price REAL
      )
    ''');

    // Sucursales del backend para mapear el nombre demo → branch_id real.
    await db.execute('''
      CREATE TABLE IF NOT EXISTS cached_branches (
        id INTEGER PRIMARY KEY,
        name TEXT NOT NULL,
        address TEXT
      )
    ''');
  }

  // ── MÉTODOS DE LA COLA OFFLINE (SYNC QUEUE) ──

  Future<int> addToQueue({
    required String uuid,
    required String type,
    required Map<String, dynamic> payload,
  }) async {
    final db = await database;
    return await db.insert(
      'offline_queue',
      {
        'uuid': uuid,
        'type': type,
        'payload': jsonEncode(payload),
        'created_at': DateTime.now().toIso8601String(),
        'status': 'LOCAL',
        'server_message': null,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<Map<String, dynamic>>> getPendingQueue() async {
    final db = await database;
    final rows = await db.query(
      'offline_queue',
      where: 'status = ?',
      whereArgs: ['LOCAL'],
      orderBy: 'id ASC',
    );
    return rows.map(_queueRow).toList();
  }

  /// Toda la cola (incluye confirmadas y conflictos) para la pantalla de sync.
  Future<List<Map<String, dynamic>>> getQueue() async {
    final db = await database;
    final rows = await db.query('offline_queue', orderBy: 'id DESC');
    return rows.map(_queueRow).toList();
  }

  Map<String, dynamic> _queueRow(Map<String, dynamic> row) {
    final map = Map<String, dynamic>.from(row);
    try {
      map['payload_data'] = jsonDecode(row['payload'] as String);
    } catch (_) {
      map['payload_data'] = {};
    }
    return map;
  }

  Future<int> countPending() async {
    final db = await database;
    final res = await db.rawQuery(
      'SELECT COUNT(*) as cnt FROM offline_queue WHERE status = ?',
      ['LOCAL'],
    );
    return Sqflite.firstIntValue(res) ?? 0;
  }

  Future<void> updateQueueStatus(
    String uuid,
    String status, {
    String? serverMessage,
  }) async {
    final db = await database;
    await db.update(
      'offline_queue',
      {
        'status': status,
        if (serverMessage != null) 'server_message': serverMessage,
      },
      where: 'uuid = ?',
      whereArgs: [uuid],
    );
  }

  Future<void> deleteQueueItem(String uuid) async {
    final db = await database;
    await db.delete('offline_queue', where: 'uuid = ?', whereArgs: [uuid]);
  }

  Future<void> removeConfirmedQueueItems() async {
    final db = await database;
    await db.delete(
      'offline_queue',
      where: 'status IN (?, ?)',
      whereArgs: ['CONFIRMADO', 'DUPLICADO_IDEMPOTENTE'],
    );
  }

  Future<void> clearProcessedQueue() => removeConfirmedQueueItems();

  // ── MÉTODOS DE CACHÉ DE PRODUCTOS E INVENTARIO ──

  Future<void> cacheProducts(List<Product> products) async {
    final db = await database;
    final batch = db.batch();
    for (final p in products) {
      batch.insert(
        'cached_products',
        {
          'id': p.id,
          'name': p.name,
          'brand': p.brand,
          'category': p.category,
          'price': p.price,
          'image': p.image,
          'data_json': jsonEncode({
            'oldPrice': p.oldPrice,
            'discount': p.discount,
            'images': p.images,
            'sizes': p.sizes,
            'description': p.description,
            'rating': p.rating,
            'reviews': p.reviews,
            'isNew': p.isNew,
            'isFeatured': p.isFeatured,
            'model3dUrl': p.model3dUrl,
            'model3dFormat': p.model3dFormat,
          }),
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
    await batch.commit(noResult: true);
  }

  Future<List<Product>> getCachedProducts() async {
    final db = await database;
    final rows = await db.query('cached_products');
    return rows.map((r) {
      Map<String, dynamic> extra = {};
      try {
        if (r['data_json'] != null) {
          extra = jsonDecode(r['data_json'] as String);
        }
      } catch (_) {}

      return Product(
        id: r['id'] as int,
        name: r['name'] as String,
        brand: (r['brand'] as String?) ?? 'FashionStore',
        category: (r['category'] as String?) ?? 'Prendas',
        price: (r['price'] as num?)?.toDouble() ?? 0.0,
        oldPrice: (extra['oldPrice'] as num?)?.toDouble() ?? 0.0,
        discount: (extra['discount'] as num?)?.toInt() ?? 0,
        image: (r['image'] as String?) ?? '',
        images: (extra['images'] as List?)?.cast<String>() ?? const <String>[],
        sizes: (extra['sizes'] as List?)?.cast<String>() ?? const <String>[],
        description: (extra['description'] as String?) ?? '',
        rating: (extra['rating'] as num?)?.toDouble() ?? 0.0,
        reviews: (extra['reviews'] as num?)?.toInt() ?? 0,
        isNew: extra['isNew'] == true,
        isFeatured: extra['isFeatured'] == true,
        model3dUrl: extra['model3dUrl'] as String?,
        model3dFormat: extra['model3dFormat'] as String?,
      );
    }).toList();
  }

  Future<void> cacheStock(List<Map<String, dynamic>> stocks) async {
    final db = await database;
    final batch = db.batch();
    batch.delete('cached_stock');
    for (final s in stocks) {
      batch.insert('cached_stock', {
        'stock_id': s['id'] ?? s['stock_id'] ?? 0,
        'variant_id': s['variant_id'] ?? 0,
        'branch_id': s['branch_id'] ?? 0,
        'available_stock': s['available_stock'] ?? 0,
      });
    }
    await batch.commit(noResult: true);
  }

  Future<void> decrementStock(int variantId, int branchId, int qty) async {
    final db = await database;
    await db.rawUpdate('''
      UPDATE cached_stock
      SET available_stock = MAX(0, available_stock - ?)
      WHERE variant_id = ? AND branch_id = ?
    ''', [qty, variantId, branchId]);
  }

  Future<void> decrementStockByStockId(int stockId, int qty) async {
    final db = await database;
    await db.rawUpdate('''
      UPDATE cached_stock
      SET available_stock = MAX(0, available_stock - ?)
      WHERE stock_id = ?
    ''', [qty, stockId]);
  }

  Future<List<Map<String, dynamic>>> getCachedStock() async {
    final db = await database;
    return db.query('cached_stock');
  }

  Future<void> cacheVariants(List<Map<String, dynamic>> variants) async {
    final db = await database;
    final batch = db.batch();
    batch.delete('cached_variants');
    for (final v in variants) {
      batch.insert(
        'cached_variants',
        {
          'variant_id': v['variant_id'],
          'product_id': v['product_id'],
          'product_name': v['product_name'] ?? '',
          'size_id': v['size_id'],
          'size_name': v['size_name'],
          'price': v['price'],
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
    await batch.commit(noResult: true);
  }

  Future<List<Map<String, dynamic>>> getCachedVariants() async {
    final db = await database;
    return db.query('cached_variants');
  }

  Future<void> cacheBranches(List<Map<String, dynamic>> branches) async {
    final db = await database;
    final batch = db.batch();
    batch.delete('cached_branches');
    for (final b in branches) {
      batch.insert(
        'cached_branches',
        {
          'id': b['id'],
          'name': b['name'] ?? '',
          'address': b['address'],
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
    await batch.commit(noResult: true);
  }

  Future<List<Map<String, dynamic>>> getCachedBranches() async {
    final db = await database;
    return db.query('cached_branches');
  }
}
