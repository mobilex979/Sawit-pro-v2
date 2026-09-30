import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

class OcrResult {
  final String rawText;
  final String? ticket;
  final String? vehicle;
  final String? relation;
  final String? product;
  final String? date;
  final String? entryTime;
  final String? exitTime;
  final double? sortasi;
  final double? bruto;
  final double? tara;
  final double? netto;
  final double? potongan;
  final double? berat;
  final int? jjg;
  final double? harga;

  const OcrResult({
    required this.rawText,
    this.ticket,
    this.vehicle,
    this.relation,
    this.product,
    this.date,
    this.entryTime,
    this.exitTime,
    this.sortasi,
    this.bruto,
    this.tara,
    this.netto,
    this.potongan,
    this.berat,
    this.jjg,
    this.harga,
  });
}

class NotaOcrService {
  final _recognizer =
      TextRecognizer(script: TextRecognitionScript.latin);

  Future<OcrResult> read(String imagePath) async {
    final input = InputImage.fromFilePath(imagePath);
    final result = await _recognizer.processImage(input);
    final text = result.text;

    return OcrResult(
      rawText: text,
      ticket: _labelText(text, [
        r'no\s*tiket',
        r'nomor\s*tiket',
        r'ticket',
      ]) ?? _firstMatch(text, [r'\b\d{8,12}\b']),
      vehicle: _labelText(text, [r'plat\s*no', r'plat', r'nopol']),
      relation: _labelText(text, [r'relasi', r'supplier', r'relasi']),
      product: _labelText(text, [r'produk']),
      date: _date(text),
      entryTime: _timeAfter(text, r'jam\s*masuk'),
      exitTime: _timeAfter(text, r'jam\s*keluar'),
      sortasi: _numberAfter(text, [r'sortasi']),
      bruto: _numberAfter(text, [r'bruto', r'gross']),
      tara: _numberAfter(text, [r'tarra', r'tara', r'tare']),
      netto: _numberAfter(text, [r'netto']),
      potongan: _numberAfter(text, [r'potongan', r'pot']),
      berat: _numberAfter(text, [r'berat', r'netto\s*bersih']),
      jjg: _intAfter(text, [r'jjg', r'janjang', r'tandan']),
      harga: _numberAfter(text, [r'harga', r'price']),
    );
  }

  String? _labelText(String text, List<String> labels) {
    for (final label in labels) {
      final p = RegExp(
        '$label\\s*[:=-]?\\s*([^\\n\\r]+)',
        caseSensitive: false,
      );
      final m = p.firstMatch(text);
      if (m != null) {
        var value = m.group(1)!.trim();
        value = value.replaceAll(RegExp(r'\s{2,}'), ' ');
        if (value.isNotEmpty) return value;
      }
    }
    return null;
  }

  String? _firstMatch(String text, List<String> patterns) {
    for (final pattern in patterns) {
      final m = RegExp(pattern, caseSensitive: false).firstMatch(text);
      if (m != null) return m.group(0);
    }
    return null;
  }

  String? _timeAfter(String text, String label) {
    final p = RegExp(
      '$label\\s*[:=-]?\\s*([0-9]{1,2}[.:][0-9]{2}[.:][0-9]{2})',
      caseSensitive: false,
    );
    final m = p.firstMatch(text);
    return m?.group(1)?.replaceAll('.', ':');
  }

  String? _date(String text) {
    final p = RegExp(
      r'(\d{1,2})[/-](\d{1,2})[/-](\d{4})',
      caseSensitive: false,
    );
    final m = p.firstMatch(text);
    if (m == null) return null;
    return '${m.group(3)}-${m.group(2)!.padLeft(2, '0')}-${m.group(1)!.padLeft(2, '0')}';
  }

  double? _numberAfter(String text, List<String> labels) {
    for (final label in labels) {
      final p = RegExp(
        '$label\\s*[:=-]?\\s*([0-9][0-9.,]*)',
        caseSensitive: false,
      );
      final m = p.firstMatch(text);
      if (m != null) return _parse(m.group(1)!);
    }
    return null;
  }

  int? _intAfter(String text, List<String> labels) {
    final x = _numberAfter(text, labels);
    return x?.round();
  }

  double? _parse(String s) {
    var x = s.replaceAll(' ', '');
    if (x.contains('.') && x.contains(',')) {
      x = x.replaceAll('.', '').replaceAll(',', '.');
    } else if (x.contains('.')) {
      // Indonesian ticket weights commonly use dot as thousands separator.
      final parts = x.split('.');
      if (parts.length == 2 && parts[1].length == 3) {
        x = parts.join();
      }
    } else if (x.contains(',')) {
      final parts = x.split(',');
      if (parts.length == 2 && parts[1].length == 3) {
        x = parts.join();
      } else {
        x = x.replaceAll(',', '.');
      }
    }
    return double.tryParse(x);
  }

  Future<void> dispose() => _recognizer.close();
}
