import 'dart:io';
import 'package:flutter/services.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

class DB {
  static final i = DB._();
  DB._();
  Database? d;

  Future<Database> get db async => d ??= await open();

  Future<Database> open() async {
    final dir = await getApplicationDocumentsDirectory();
    final p = join(dir.path, 'sawit_pro_v2.db');

    if (!await File(p).exists()) {
      final x = await rootBundle.load('assets/db/sawit_pro_v2.db');
      await File(p).writeAsBytes(
        x.buffer.asUint8List(x.offsetInBytes, x.lengthInBytes),
      );
    }

    return openDatabase(
      p,
      version: 5,
      onConfigure: (db) => db.execute('PRAGMA foreign_keys=ON'),
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          final columns = <String, String>{
            'perusahaan_pks': 'TEXT',
            'supplier': 'TEXT',
            'nomor_kendaraan': 'TEXT',
            'sopir': 'TEXT',
            'bruto_kg': 'REAL DEFAULT 0',
            'tara_kg': 'REAL DEFAULT 0',
            'netto_kg': 'REAL DEFAULT 0',
            'potongan_kg': 'REAL DEFAULT 0',
            'sortasi_persen': 'REAL DEFAULT 0',
            'jam_masuk': 'TEXT',
            'jam_keluar': 'TEXT',
            'produk': 'TEXT',
            'catatan': 'TEXT',
            'sumber_input': "TEXT DEFAULT 'manual'",
            'created_at': 'TEXT',
            'updated_at': 'TEXT',
          };
          final info = await db.rawQuery('PRAGMA table_info(tiket_timbang)');
          final existing = info.map((e) => e['name'] as String).toSet();
          for (final e in columns.entries) {
            if (!existing.contains(e.key)) {
              await db.execute(
                'ALTER TABLE tiket_timbang ADD COLUMN ${e.key} ${e.value}',
              );
            }
          }
        }
        if (oldVersion < 3) {
          await db.execute('''
            CREATE TABLE IF NOT EXISTS tiket_blok (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              tiket_id INTEGER NOT NULL,
              blok_id INTEGER NOT NULL,
              panen_id INTEGER,
              grup_id INTEGER,
              alokasi_kg REAL NOT NULL DEFAULT 0,
              alokasi_jjg INTEGER DEFAULT 0,
              FOREIGN KEY(tiket_id) REFERENCES tiket_timbang(id) ON DELETE CASCADE,
              FOREIGN KEY(blok_id) REFERENCES blok(id),
              FOREIGN KEY(panen_id) REFERENCES panen(id),
              FOREIGN KEY(grup_id) REFERENCES grup(id)
            )
          ''');
        }
        if (oldVersion < 4) {
          final info = await db.rawQuery('PRAGMA table_info(tiket_blok)');
          final existing = info.map((e) => e['name'] as String).toSet();
          if (!existing.contains('pemanen_id')) {
            await db.execute(
              'ALTER TABLE tiket_blok ADD COLUMN pemanen_id INTEGER',
            );
          }
        }
        if (oldVersion < 5) {
          await db.execute('''
            CREATE TABLE IF NOT EXISTS upah_detail (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              tanggal TEXT NOT NULL,
              pemanen_id INTEGER NOT NULL,
              grup_id INTEGER,
              kg REAL NOT NULL DEFAULT 0,
              jjg INTEGER NOT NULL DEFAULT 0,
              tarif_dasar REAL NOT NULL DEFAULT 0,
              tarif_premi_per_kg REAL NOT NULL DEFAULT 0,
              total_premi REAL NOT NULL DEFAULT 0,
              total_upah REAL NOT NULL DEFAULT 0,
              status TEXT DEFAULT 'draft',
              created_at TEXT,
              updated_at TEXT,
              UNIQUE(tanggal,pemanen_id),
              FOREIGN KEY(pemanen_id) REFERENCES pemanen(id),
              FOREIGN KEY(grup_id) REFERENCES grup(id)
            )
          ''');
        }
      },
    );
  }

  Future<List<Map<String, dynamic>>> all(String table) async {
    final x = await db;
    return x.query(table, orderBy: 'id DESC');
  }
}
