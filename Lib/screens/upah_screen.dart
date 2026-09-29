import 'package:flutter/material.dart';
import '../services/upah_service.dart';

class UpahScreen extends StatefulWidget {
  const UpahScreen({super.key});
  @override State<UpahScreen> createState()=>_UpahState();
}

class _UpahState extends State<UpahScreen> {
  final service=UpahService();
  DateTime tanggal=DateTime.now();
  bool loading=false;
  List<Map<String,dynamic>> rows=[];
  bool tersimpan=false;

  String get iso =>
      '${tanggal.year}-${tanggal.month.toString().padLeft(2,'0')}-${tanggal.day.toString().padLeft(2,'0')}';

  String money(dynamic v) {
    final n=(v as num?)?.toDouble()??0;
    return 'Rp ${n.toStringAsFixed(0)}';
  }

  String kg(dynamic v) =>
      '${((v as num?)?.toDouble()??0).toStringAsFixed(0)} kg';

  @override void initState(){super.initState();load();}

  Future<void> load() async {
    setState(()=>loading=true);
    final x=await service.hitung(iso);
    if(!mounted)return;
    setState((){rows=x;loading=false;tersimpan=false;});
  }

  Future<void> pilihTanggal() async {
    final x=await showDatePicker(
      context:context,
      firstDate:DateTime(2020),
      lastDate:DateTime(2100),
      initialDate:tanggal,
    );
    if(x==null)return;
    setState(()=>tanggal=x);
    await load();
  }

  Future<void> simpan() async {
    if(rows.isEmpty){
      msg('Belum ada produksi yang terhubung ke pemanen pada tanggal ini.');
      return;
    }
    await service.simpan(iso,rows);
    if(!mounted)return;
    setState(()=>tersimpan=true);
    msg('Perhitungan upah disimpan sebagai DRAFT.');
  }

  void msg(String s)=>ScaffoldMessenger.of(context)
      .showSnackBar(SnackBar(content:Text(s)));

  @override Widget build(BuildContext context){
    final totalKg=rows.fold<double>(
      0,(s,r)=>s+((r['kg'] as num?)?.toDouble()??0));
    final totalPremi=rows.fold<double>(
      0,(s,r)=>s+
        (((r['kg'] as num?)?.toDouble()??0)*
         ((r['tarif_premi_per_kg'] as num?)?.toDouble()??0)));
    final totalUpah=rows.fold<double>(
      0,(s,r)=>s+
        ((r['tarif_dasar'] as num?)?.toDouble()??0)+
        (((r['kg'] as num?)?.toDouble()??0)*
         ((r['tarif_premi_per_kg'] as num?)?.toDouble()??0)));

    return Scaffold(
      appBar:AppBar(
        title:const Text('Upah & Premi'),
        actions:[
          IconButton(
            tooltip:'Pilih tanggal',
            onPressed:pilihTanggal,
            icon:const Icon(Icons.calendar_month),
          ),
        ],
      ),
      body:loading
        ?const Center(child:CircularProgressIndicator())
        :RefreshIndicator(
          onRefresh:load,
          child:ListView(
            padding:const EdgeInsets.all(12),
            children:[
              Card(child:ListTile(
                leading:const Icon(Icons.date_range),
                title:Text('${tanggal.day.toString().padLeft(2,'0')}/'
                  '${tanggal.month.toString().padLeft(2,'0')}/${tanggal.year}'),
                subtitle:Text(
                  'Produksi ${kg(totalKg)} • Premi ${money(totalPremi)}'
                  ' • Total ${money(totalUpah)}',
                ),
              )),
              if(rows.isEmpty)
                const Card(child:Padding(
                  padding:EdgeInsets.all(24),
                  child:Center(child:Text(
                    'Belum ada produksi teralokasi ke pemanen pada tanggal ini.',
                  )),
                ))
              else ...[
                ...rows.map((r){
                  final kgv=(r['kg'] as num?)?.toDouble()??0;
                  final dasar=(r['tarif_dasar'] as num?)?.toDouble()??0;
                  final tarif=(r['tarif_premi_per_kg'] as num?)?.toDouble()??0;
                  final premi=kgv*tarif;
                  return Card(
                    child:ListTile(
                      leading:const Icon(Icons.person),
                      title:Text('${r['pemanen_kode']??'-'} • ${r['pemanen_nama']??''}'),
                      subtitle:Text(
                        'Grup: ${r['grup_nama']??'-'}
'
                        'Produksi: ${kg(kgv)} • Dasar: ${money(dasar)}
'
                        'Premi: ${money(premi)} (${money(tarif)}/kg)',
                      ),
                      isThreeLine:true,
                      trailing:Text(
                        money(dasar+premi),
                        style:const TextStyle(fontWeight:FontWeight.bold),
                      ),
                    ),
                  );
                }),
                const SizedBox(height:8),
                FilledButton.icon(
                  onPressed:simpan,
                  icon:const Icon(Icons.save),
                  label:Text(tersimpan?'Simpan Ulang':'Simpan Draft Upah'),
                ),
              ],
            ],
          ),
        ),
    );
  }
}
