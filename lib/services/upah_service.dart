import 'database_service.dart';

class UpahService {
  final db=DB.i;

  Future<List<Map<String,dynamic>>> hitung(String tanggal) async {
    final d=await db.db;
    return d.rawQuery('''
      SELECT
        p.id pemanen_id,
        p.kode pemanen_kode,
        p.nama pemanen_nama,
        COALESCE(g.id,0) grup_id,
        COALESCE(g.kode,'-') grup_kode,
        COALESCE(g.nama,'Tanpa Grup') grup_nama,
        COALESCE(SUM(tb.alokasi_kg),0) kg,
        COALESCE(SUM(tb.alokasi_jjg),0) jjg,
        COALESCE(g.tarif_upah_per_orang,0) tarif_dasar,
        COALESCE(g.tarif_premi_per_kg,0) tarif_premi_per_kg
      FROM tiket_blok tb
      JOIN tiket_timbang t ON t.id=tb.tiket_id
      JOIN pemanen p ON p.id=tb.pemanen_id
      LEFT JOIN grup g ON g.id=tb.grup_id
      WHERE t.tanggal=? AND tb.pemanen_id IS NOT NULL
      GROUP BY p.id,p.kode,p.nama,g.id,g.kode,g.nama,
               g.tarif_upah_per_orang,g.tarif_premi_per_kg
      ORDER BY p.kode
    ''',[tanggal]);
  }

  Future<void> simpan(String tanggal,List<Map<String,dynamic>> rows) async {
    final d=await db.db;
    final now=DateTime.now().toIso8601String();

    await d.transaction((txn) async {
      final groups=<int,double>{};

      for(final r in rows) {
        final kg=(r['kg'] as num?)?.toDouble()??0;
        final dasar=(r['tarif_dasar'] as num?)?.toDouble()??0;
        final tarif=(r['tarif_premi_per_kg'] as num?)?.toDouble()??0;
        final premi=kg*tarif;
        final total=dasar+premi;
        final gid=(r['grup_id'] as num?)?.toInt()??0;

        await txn.insert(
          'upah_detail',
          {
            'tanggal':tanggal,
            'pemanen_id':r['pemanen_id'],
            'grup_id':gid==0?null:gid,
            'kg':kg,
            'jjg':(r['jjg'] as num?)?.toInt()??0,
            'tarif_dasar':dasar,
            'tarif_premi_per_kg':tarif,
            'total_premi':premi,
            'total_upah':total,
            'status':'draft',
            'created_at':now,
            'updated_at':now,
          },
          conflictAlgorithm: ConflictAlgorithm.replace,
        );

        groups[gid]=(groups[gid]??0)+total;
      }

      for(final e in groups.entries) {
        await txn.insert(
          'upah',
          {
            'tanggal':tanggal,
            'grup_id':e.key==0?null:e.key,
            'total_upah':e.value,
            'status':'draft',
          },
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
    });
  }

  Future<List<Map<String,dynamic>>> tersimpan(String tanggal) async {
    final d=await db.db;
    return d.rawQuery('''
      SELECT u.*,p.kode pemanen_kode,p.nama pemanen_nama,
             g.kode grup_kode,g.nama grup_nama
      FROM upah_detail u
      JOIN pemanen p ON p.id=u.pemanen_id
      LEFT JOIN grup g ON g.id=u.grup_id
      WHERE u.tanggal=?
      ORDER BY p.kode
    ''',[tanggal]);
  }
}
