impor 'paket:flutter/material.dart';
impor 'layar/layar_rumah';

void main() {
WidgetsFlutterBinding.ensureInitialized();
jalankanApp(const App());
}

kelas App memperluas StatelessWidget {
const App({super.key});

@mengesampingkan
Widget build(BuildContext context) {
kembalikan MaterialApp(
debugShowCheckedModeBanner: salah,
judul: 'SAWIT PRO v2',
tema: ThemeData(
skema warna: Skema Warna.dariSeed(
Warna benih: konstanta Warna(0xFF087443),
),
useMaterial3: true,
),
beranda: const HomeScreen(),
);
}
}
