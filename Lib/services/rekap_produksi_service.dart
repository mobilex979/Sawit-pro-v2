import 'database_service.dart';

class RekapProduksiService {
  final db=DB.i;

  Future<List<Map<String,dynamic>>> perBlok({String? tanggal}) async {
    final d=await db.db;
    final filter=(tanggal==null||tanggal!.isEmpty)?'':'WHERE t.tanggal=?';
    final args=(tanggal==null||tanggal!.isEmpty)?<dynamic>[]:[tanggal];
    return d.rawQuery('''
      SELECT b.id blok_id,b.kode blok_kode,b.nama blok_nama,
             COALESCE(SUM(tb.alokasi_kg),0) kg,
             COALESCE(SUM(tb.alokasi_jjg),0) jjg,
             COUNT(DISTINCT tb.tiket_id) tiket
      FROM tiket_blok tb
      JOIN tiket_timbang t ON t.id=tb.tiket_id
      JOIN blok b ON b.id=tb.blok_id
      $filter
      GROUP BY b.id,b.kode,b.nama
      ORDER BY b.kode
    ''',args);
  }

  Future<List<Map<String,dynamic>>> perGrup({String? tanggal}) async {
    final d=await db.db;
    final filter=(tanggal==null||tanggal!.isEmpty)?'':'WHERE t.tanggal=?';
    final args=(tanggal==null||tanggal!.isEmpty)?<dynamic>[]:[tanggal];
    return d.rawQuery('''
      SELECT COALESCE(g.id,0) grup_id,
             COALESCE(g.kode,'-') grup_kode,
             COALESCE(g.nama,'Tanpa Grup') grup_nama,
             COALESCE(SUM(tb.alokasi_kg),0) kg,
             COALESCE(SUM(tb.alokasi_jjg),0) jjg,
             COUNT(DISTINCT tb.tiket_id) tiket
      FROM tiket_blok tb
      JOIN tiket_timbang t ON t.id=tb.tiket_id
      LEFT JOIN grup g ON g.id=tb.grup_id
      $filter
      GROUP BY g.id,g.kode,g.nama
      ORDER BY g.kode
    ''',args);
  }

  Future<List<Map<String,dynamic>>> perPemanen({String? tanggal}) async {
    final d=await db.db;
    final filter=(tanggal==null||tanggal!.isEmpty)?'':'WHERE t.tanggal=?';
    final args=(tanggal==null||tanggal!.isEmpty)?<dynamic>[]:[tanggal];
    return d.rawQuery('''
      SELECT COALESCE(p.id,0) pemanen_id,
             COALESCE(p.kode,'-') pemanen_kode,
             COALESCE(p.nama,'Tanpa Pemanen') pemanen_nama,
             COALESCE(g.nama,'Tanpa Grup') grup_nama,
             COALESCE(SUM(tb.alokasi_kg),0) kg,
             COALESCE(SUM(tb.alokasi_jjg),0) jjg,
             COUNT(DISTINCT tb.tiket_id) tiket
      FROM tiket_blok tb
      JOIN tiket_timbang t ON t.id=tb.tiket_id
      LEFT JOIN pemanen p ON p.id=tb.pemanen_id
      LEFT JOIN grup g ON g.id=tb.grup_id
      $filter
      GROUP BY p.id,p.kode,p.nama,g.nama
      ORDER BY p.kode
    ''',args);
  }

  Future<Map<String,dynamic>> total({String? tanggal}) async {
    final d=await db.db;
    if(tanggal==null||tanggal!.isEmpty) {
      final r=await d.rawQuery('''
        SELECT COALESCE(SUM(alokasi_kg),0) kg,
               COALESCE(SUM(alokasi_jjg),0) jjg,
               COUNT(DISTINCT tiket_id) tiket
        FROM tiket_blok
      ''');
      return r.first;
    }
    final r=await d.rawQuery('''
      SELECT COALESCE(SUM(tb.alokasi_kg),0) kg,
             COALESCE(SUM(tb.alokasi_jjg),0) jjg,
             COUNT(DISTINCT tb.tiket_id) tiket
      FROM tiket_blok tb
      JOIN tiket_timbang t ON t.id=tb.tiket_id
      WHERE t.tanggal=?
    ''',[tanggal]);
    return r.first;
  }
}
