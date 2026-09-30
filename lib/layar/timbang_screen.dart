import 'package:flutter/material.dart';
import '../services/database_service.dart';
import 'alokasi_tbs_screen.dart';
import 'package:image_picker/image_picker.dart';
import '../services/nota_ocr_service.dart';

class TimbangScreen extends StatefulWidget {
  const TimbangScreen({super.key});
  @override State<TimbangScreen> createState() => _TimbangScreenState();
}

class _TimbangScreenState extends State<TimbangScreen> {
  final db = DB.i;
  List<Map<String,dynamic>> rows = [];

  @override void initState() { super.initState(); load(); }

  Future<void> load() async {
    final r = await db.all('tiket_timbang');
    if (mounted) setState(() => rows = r);
  }

  Future<void> add() async {
    final saved = await Navigator.push(
      context, MaterialPageRoute(builder: (_) => const TimbangFormScreen()),
    );
    if (saved == true) load();
  }

  @override Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Nota Timbang TBS')),
    body: RefreshIndicator(
      onRefresh: load,
      child: rows.isEmpty
        ? ListView(children: const [
            SizedBox(height: 150),
            Center(child: Text('Belum ada nota timbang. Tekan + untuk menambah.')),
          ])
        : ListView.separated(
            padding: const EdgeInsets.all(12),
            itemCount: rows.length,
            separatorBuilder: (_,__) => const SizedBox(height: 6),
            itemBuilder: (_, i) {
              final r = rows[i];
              final nilai = (r['total_nilai'] as num?)?.toDouble() ?? 0;
              return Card(child: ListTile(
                leading: const CircleAvatar(child: Icon(Icons.scale)),
                title: Text('${r['nomor_tiket']} • ${r['tanggal']}'),
                subtitle: Text(
                  'Netto ${r['netto_bersih_kg']} kg • ${r['jjg']} janjang\n'
                  'Nilai Rp ${nilai.toStringAsFixed(0)}'
                ),
                isThreeLine: true,
                trailing: IconButton(icon: const Icon(Icons.account_tree), tooltip: 'Alokasi Blok', onPressed: () async { await Navigator.push(context, MaterialPageRoute(builder: (_) => AlokasiTbsScreen(tiket: r))); if (mounted) setState(() {}); }),
              ));
            },
          ),
    ),
    floatingActionButton: FloatingActionButton.extended(
      onPressed: add,
      icon: const Icon(Icons.add),
      label: const Text('Input Nota'),
    ),
  );
}

class TimbangFormScreen extends StatefulWidget {
  const TimbangFormScreen({super.key});
  @override State<TimbangFormScreen> createState() => _TimbangFormState();
}

class _TimbangFormState extends State<TimbangFormScreen> {
  final db = DB.i;
  final nomor = TextEditingController();
  final bruto = TextEditingController();
  final tara = TextEditingController();
  final potongan = TextEditingController();
  final jjg = TextEditingController();
  final harga = TextEditingController();
  final pks = TextEditingController();
  final kendaraan = TextEditingController();
  final sopir = TextEditingController();
  final supplier = TextEditingController();

  double get netto {
    final b = double.tryParse(bruto.text) ?? 0;
    final t = double.tryParse(tara.text) ?? 0;
    return (b - t).clamp(0, double.infinity);
  }

  double get bersih {
    final p = double.tryParse(potongan.text) ?? 0;
    return (netto - p).clamp(0, double.infinity);
  }

  double get total {
    final h = double.tryParse(harga.text) ?? 0;
    return bersih * h;
  }

  @override void initState() {
    super.initState();
    for (final c in [bruto,tara,potongan,jjg,harga]) {
      c.addListener(() => setState(() {}));
    }
  }

  @override void dispose() {
    for (final c in [nomor,bruto,tara,potongan,jjg,harga,pks,kendaraan,sopir,supplier]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> save() async {
    if (nomor.text.trim().isEmpty) {
      _msg('Nomor tiket wajib diisi.');
      return;
    }
    if (bruto.text.trim().isEmpty || tara.text.trim().isEmpty) {
      _msg('Bruto dan tara wajib diisi.');
      return;
    }
    if (bersih <= 0) {
      _msg('Netto bersih harus lebih besar dari 0.');
      return;
    }

    final d = await db.db;
    final duplicate = await d.query(
      'tiket_timbang',
      columns: ['id'],
      where: 'nomor_tiket = ?',
      whereArgs: [nomor.text.trim()],
      limit: 1,
    );
    if (duplicate.isNotEmpty) {
      _msg('Nomor tiket sudah pernah dicatat.');
      return;
    }

    await d.insert('tiket_timbang', {
      'nomor_tiket': nomor.text.trim(),
      'tanggal': _date(),
      'perusahaan_pks': pks.text.trim(),
      'supplier': supplier.text.trim(),
      'nomor_kendaraan': kendaraan.text.trim(),
      'sopir': sopir.text.trim(),
      'bruto_kg': double.tryParse(bruto.text) ?? 0,
      'tara_kg': double.tryParse(tara.text) ?? 0,
      'netto_kg': netto,
      'potongan_kg': double.tryParse(potongan.text) ?? 0,
      'netto_bersih_kg': bersih,
      'jjg': int.tryParse(jjg.text) ?? 0,
      'harga_per_kg': double.tryParse(harga.text) ?? 0,
      'total_nilai': total,
      'sumber_input': 'manual',
      'status': 'aktif',
    });

    if (mounted) Navigator.pop(context, true);
  }

  String _date() {
    final n = DateTime.now();
    return '${n.year}-${n.month.toString().padLeft(2,'0')}-${n.day.toString().padLeft(2,'0')}';
  }

  void _msg(String s) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(s)));

  Future<void> _ocr() async {
    final picker = ImagePicker();
    final image = await picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 90,
    );
    if (image == null || !mounted) return;

    try {
      final ocr = NotaOcrService();
      final result = await ocr.read(image.path);
      await ocr.dispose();
      if (!mounted) return;

      final saved = await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => OcrReviewScreen(
            result: result,
            imagePath: image.path,
          ),
        ),
      );
      if (saved == true && mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) _msg('OCR gagal membaca nota: $e');
    }
  }

  @override Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Input Nota Timbang')),
    body: ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text('Data Nota', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        TextField(controller: nomor, decoration: const InputDecoration(labelText: 'Nomor tiket *')),
        TextField(controller: pks, decoration: const InputDecoration(labelText: 'Nama PKS')),
        TextField(controller: supplier, decoration: const InputDecoration(labelText: 'Supplier / pemilik TBS')),
        TextField(controller: kendaraan, decoration: const InputDecoration(labelText: 'Nomor kendaraan')),
        TextField(controller: sopir, decoration: const InputDecoration(labelText: 'Sopir')),
        const SizedBox(height: 18),
        const Text('Berat', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        TextField(controller: bruto, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Bruto (kg) *')),
        TextField(controller: tara, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Tara (kg) *')),
        TextField(controller: potongan, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Potongan (kg)')),
        Card(child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Netto: ${netto.toStringAsFixed(1)} kg'),
            Text('Netto bersih: ${bersih.toStringAsFixed(1)} kg',
                style: const TextStyle(fontWeight: FontWeight.bold)),
          ]),
        )),
        const SizedBox(height: 12),
        TextField(controller: jjg, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Jumlah janjang')),
        TextField(controller: harga, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Harga TBS / kg')),
        Card(child: Padding(
          padding: const EdgeInsets.all(14),
          child: Text('Total nilai: Rp ${total.toStringAsFixed(0)}',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        )),
        const SizedBox(height: 20),
        FilledButton.icon(
          onPressed: save,
          icon: const Icon(Icons.save),
          label: const Text('Simpan Nota'),
        ),
        const SizedBox(height: 8),
        OutlinedButton.icon(
          onPressed: _ocr,
          icon: const Icon(Icons.camera_alt),
          label: const Text('Foto Nota / OCR'),
        ),
      ],
    ),
  );
}



class OcrReviewScreen extends StatefulWidget {
  final OcrResult result;
  final String imagePath;
  const OcrReviewScreen({
    super.key,
    required this.result,
    required this.imagePath,
  });

  @override
  State<OcrReviewScreen> createState() => _OcrReviewState();
}

class _OcrReviewState extends State<OcrReviewScreen> {
  final db = DB.i;
  late final TextEditingController ticket;
  late final TextEditingController vehicle;
  late final TextEditingController relation;
  late final TextEditingController product;
  late final TextEditingController date;
  late final TextEditingController entryTime;
  late final TextEditingController exitTime;
  late final TextEditingController sortasi;
  late final TextEditingController bruto;
  late final TextEditingController tara;
  late final TextEditingController netto;
  late final TextEditingController potongan;
  late final TextEditingController berat;

  @override
  void initState() {
    super.initState();
    ticket = TextEditingController(text: widget.result.ticket ?? '');
    vehicle = TextEditingController(text: widget.result.vehicle ?? '');
    relation = TextEditingController(text: widget.result.relation ?? '');
    product = TextEditingController(text: widget.result.product ?? 'TBS');
    date = TextEditingController(text: widget.result.date ?? _today());
    entryTime = TextEditingController(text: widget.result.entryTime ?? '');
    exitTime = TextEditingController(text: widget.result.exitTime ?? '');
    sortasi = TextEditingController(text: _fmt(widget.result.sortasi));
    bruto = TextEditingController(text: _fmt(widget.result.bruto));
    tara = TextEditingController(text: _fmt(widget.result.tara));
    netto = TextEditingController(text: _fmt(widget.result.netto));
    potongan = TextEditingController(text: _fmt(widget.result.potongan));
    berat = TextEditingController(
      text: _fmt(widget.result.berat ?? _calcNettoBersih()),
    );
  }

  String _today() {
    final n = DateTime.now();
    return '${n.year}-${n.month.toString().padLeft(2, '0')}-${n.day.toString().padLeft(2, '0')}';
  }

  double? _calcNettoBersih() {
    final n = widget.result.netto;
    final p = widget.result.potongan ?? 0;
    if (n == null) return null;
    return (n - p).clamp(0, double.infinity);
  }

  String _fmt(num? x) => x == null ? '' : x.toString();

  @override
  void dispose() {
    for (final c in [
      ticket, vehicle, relation, product, date, entryTime, exitTime,
      sortasi, bruto, tara, netto, potongan, berat
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  double _d(TextEditingController c) =>
      double.tryParse(c.text.replaceAll(',', '.')) ?? 0;

  Future<void> save() async {
    final no = ticket.text.trim();
    if (no.isEmpty) {
      _msg('Nomor tiket belum terbaca. Isi manual sebelum menyimpan.');
      return;
    }

    final d = await db.db;
    final duplicate = await d.query(
      'tiket_timbang',
      columns: ['id'],
      where: 'nomor_tiket=?',
      whereArgs: [no],
      limit: 1,
    );
    if (duplicate.isNotEmpty) {
      _msg('Nomor tiket $no sudah ada di database.');
      return;
    }

    final b = _d(bruto);
    final ta = _d(tara);
    final n = netto.text.trim().isEmpty ? (b - ta) : _d(netto);
    final p = _d(potongan);
    final bersih = berat.text.trim().isEmpty
        ? (n - p).clamp(0, double.infinity)
        : _d(berat);

    if (b <= 0 || ta < 0 || n <= 0 || bersih <= 0) {
      _msg('Periksa kembali bruto, tara, netto, potongan, dan berat bersih.');
      return;
    }

    final now = DateTime.now().toIso8601String();
    await d.insert('tiket_timbang', {
      'nomor_tiket': no,
      'tanggal': date.text.trim().isEmpty ? _today() : date.text.trim(),
      'perusahaan_pks': 'PMKS Perlang Sawitindo Mas',
      'supplier': relation.text.trim(),
      'nomor_kendaraan': vehicle.text.trim(),
      'produk': product.text.trim(),
      'bruto_kg': b,
      'tara_kg': ta,
      'netto_kg': n,
      'potongan_kg': p,
      'sortasi_persen': _d(sortasi),
      'netto_bersih_kg': bersih,
      'jjg': 0,
      'harga_per_kg': 0,
      'total_nilai': 0,
      'jam_masuk': entryTime.text.trim(),
      'jam_keluar': exitTime.text.trim(),
      'foto_path': widget.imagePath,
      'catatan': widget.result.rawText,
      'sumber_input': 'ocr',
      'status': 'aktif',
      'created_at': now,
      'updated_at': now,
    });

    if (mounted) Navigator.pop(context, true);
  }

  void _msg(String s) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(s)));

  Widget _field(String label, TextEditingController c, {bool number = false}) =>
      TextField(
        controller: c,
        keyboardType: number ? TextInputType.number : TextInputType.text,
        decoration: InputDecoration(labelText: label),
      );

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Review Hasil OCR')),
    body: ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Card(
          child: ListTile(
            leading: Icon(Icons.fact_check),
            title: Text('Periksa sebelum simpan'),
            subtitle: Text(
              'Hasil OCR adalah pembacaan awal. Koreksi angka yang salah sebelum disimpan.',
            ),
          ),
        ),
        const SizedBox(height: 8),
        const Text('Identitas Nota',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        _field('Nomor tiket *', ticket),
        _field('Nomor kendaraan / plat', vehicle),
        _field('Relasi / supplier', relation),
        _field('Produk', product),
        _field('Tanggal', date),
        _field('Jam masuk', entryTime),
        _field('Jam keluar', exitTime),
        _field('Sortasi (%)', sortasi, number: true),
        const SizedBox(height: 16),
        const Text('Data Timbangan',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        _field('Bruto (kg)', bruto, number: true),
        _field('Tara (kg)', tara, number: true),
        _field('Netto (kg)', netto, number: true),
        _field('Potongan (kg)', potongan, number: true),
        _field('Berat bersih / BERAT (kg)', berat, number: true),
        const SizedBox(height: 16),
        const Text('Teks mentah OCR',
            style: TextStyle(fontWeight: FontWeight.bold)),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Text(widget.result.rawText.isEmpty
                ? '(Tidak ada teks terbaca)'
                : widget.result.rawText),
          ),
        ),
        const SizedBox(height: 16),
        FilledButton.icon(
          onPressed: save,
          icon: const Icon(Icons.save),
          label: const Text('Konfirmasi & Simpan'),
        ),
      ],
    ),
  );
}
