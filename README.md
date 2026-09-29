# SAWIT PRO v2 — Upah & Premi v1

Modul ini menghitung draft upah harian dari produksi yang sudah dialokasikan ke pemanen.

Rumus default:
- Upah dasar = `tarif_upah_per_orang` pada Grup
- Premi = `kg produksi x tarif_premi_per_kg` pada Grup
- Total upah = upah dasar + premi

Tarif dapat diubah melalui Data Master > Grup.

Data per pemanen disimpan ke `upah_detail`, sedangkan rekap per grup disimpan ke tabel `upah`.

Status awal: `draft`.

Catatan:
- Pemanen tanpa alokasi pada tanggal tersebut tidak dihitung.
- Jika tarif Grup = 0, komponen tersebut tetap 0; aplikasi tidak mengarang tarif.
