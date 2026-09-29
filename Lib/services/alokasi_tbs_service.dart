import 'database_service.dart';

class AlokasiTbsService {
  final db = DB.i;

  Future<Map<String,dynamic>?> tiket(int id) async {
    final d=await db.db;
    final r=await d.query('tiket_timbang',where:'id=?',whereArgs:[id],limit:1);
    return r.isEmpty?null:r.first;
  }

  Future<List<Map<String,dynamic>>> list(int id) async {
    final d=await db.db;
    return d.rawQuery('''
      SELECT tb.*, b.kode blok_kode, b.nama blok_nama,
             g.kode grup_kode, g.nama grup_nama,
             p.kode pemanen_kode, p.nama pemanen_nama
      FROM tiket_blok tb
      JOIN blok b ON b.id=tb.blok_id
      LEFT JOIN grup g ON g.id=tb.grup_id
      LEFT JOIN pemanen p ON p.id=tb.pemanen_id
      WHERE tb.tiket_id=?
      ORDER BY tb.id
    ''',[id]);
  }

  Future<double> total(int id) async {
    final d=await db.db;
    final r=await d.rawQuery(
      'SELECT COALESCE(SUM(alokasi_kg),0) total FROM tiket_blok WHERE tiket_id=?',
      [id],
    );
    return (r.first['total'] as num?)?.toDouble()??0;
  }

  Future<void> add({
    required int tiketId,
    required int blokId,
    int? grupId,
    int? pemanenId,
    required double beratKg,
    int jjg=0,
  }) async {
    if(beratKg<=0) throw Exception('Berat alokasi harus lebih dari 0 kg.');
    final t=await tiket(tiketId);
    if(t==null) throw Exception('Tiket tidak ditemukan.');
    final batas=(t['netto_bersih_kg'] as num?)?.toDouble()??0;
    final sudah=await total(tiketId);
    final sisa=(batas-sudah).clamp(0,double.infinity);
    if(beratKg>sisa+0.001) {
      throw Exception('Berat melebihi sisa tiket: ${sisa.toStringAsFixed(0)} kg.');
    }
    final d=await db.db;
    await d.insert('tiket_blok',{
      'tiket_id':tiketId,
      'blok_id':blokId,
      'panen_id':null,
      'grup_id':grupId,
      'pemanen_id':pemanenId,
      'alokasi_kg':beratKg,
      'alokasi_jjg':jjg,
    });
  }

  Future<void> delete(int id) async {
    final d=await db.db;
    await d.delete('tiket_blok',where:'id=?',whereArgs:[id]);
  }
}
