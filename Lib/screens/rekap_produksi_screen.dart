import 'package:flutter/material.dart';
import '../services/rekap_produksi_service.dart';

class RekapProduksiScreen extends StatefulWidget {
  const RekapProduksiScreen({super.key});
  @override State<RekapProduksiScreen> createState()=>_RekapProduksiState();
}

class _RekapProduksiState extends State<RekapProduksiScreen> {
  final service=RekapProduksiService();
  int tab=0;
  DateTime? tanggal;
  bool loading=true;
  Map<String,dynamic> total={};
  List<Map<String,dynamic>> blok=[];
  List<Map<String,dynamic>> grup=[];
  List<Map<String,dynamic>> pemanen=[];

  String get iso {
    if(tanggal==null)return '';
    return '${tanggal!.year}-${tanggal!.month.toString().padLeft(2,'0')}-${tanggal!.day.toString().padLeft(2,'0')}';
  }

  String get labelTanggal {
    if(tanggal==null)return 'Semua tanggal';
    return '${tanggal!.day.toString().padLeft(2,'0')}/${tanggal!.month.toString().padLeft(2,'0')}/${tanggal!.year}';
  }

  @override void initState(){super.initState();load();}

  Future<void> load() async {
    setState(()=>loading=true);
    final r=await Future.wait([
      service.total(tanggal:iso),
      service.perBlok(tanggal:iso),
      service.perGrup(tanggal:iso),
      service.perPemanen(tanggal:iso),
    ]);
    if(!mounted)return;
    setState((){
      total=r[0] as Map<String,dynamic>;
      blok=r[1] as List<Map<String,dynamic>>;
      grup=r[2] as List<Map<String,dynamic>>;
      pemanen=r[3] as List<Map<String,dynamic>>;
      loading=false;
    });
  }

  Future<void> pilihTanggal() async {
    final d=await showDatePicker(
      context:context,
      firstDate:DateTime(2020),
      lastDate:DateTime(2100),
      initialDate:tanggal??DateTime.now(),
    );
    if(d==null)return;
    setState(()=>tanggal=d);
    await load();
  }

  String kg(dynamic v)=>'${((v as num?)?.toDouble()??0).toStringAsFixed(0)} kg';
  String jjg(dynamic v)=>'${(v as num?)?.toInt()??0} jjg';

  @override Widget build(BuildContext context){
    final data=tab==0?blok:tab==1?grup:pemanen;
    return Scaffold(
      appBar:AppBar(
        title:const Text('Rekap Produksi'),
        actions:[
          IconButton(onPressed:pilihTanggal,icon:const Icon(Icons.calendar_month)),
          if(tanggal!=null)IconButton(
            onPressed:()async{setState(()=>tanggal=null);await load();},
            icon:const Icon(Icons.clear),
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
                title:Text(labelTanggal),
                subtitle:Text('${kg(total['kg'])} • ${jjg(total['jjg'])} • ${total['tiket']??0} tiket'),
              )),
              const SizedBox(height:8),
              SegmentedButton<int>(
                segments:const[
                  ButtonSegment(value:0,label:Text('Blok')),
                  ButtonSegment(value:1,label:Text('Grup')),
                  ButtonSegment(value:2,label:Text('Pemanen')),
                ],
                selected:{tab},
                onSelectionChanged:(v)=>setState(()=>tab=v.first),
              ),
              const SizedBox(height:8),
              if(data.isEmpty)
                const Card(child:Padding(
                  padding:EdgeInsets.all(24),
                  child:Center(child:Text('Belum ada produksi teralokasi.')),
                ))
              else
                ...data.map((r){
                  String title;
                  String sub;
                  if(tab==0){
                    title='${r['blok_kode']??'-'} • ${r['blok_nama']??''}';
                    sub='${kg(r['kg'])} • ${jjg(r['jjg'])} • ${r['tiket']??0} tiket';
                  }else if(tab==1){
                    title='${r['grup_kode']??'-'} • ${r['grup_nama']??''}';
                    sub='${kg(r['kg'])} • ${jjg(r['jjg'])} • ${r['tiket']??0} tiket';
                  }else{
                    title='${r['pemanen_kode']??'-'} • ${r['pemanen_nama']??''}';
                    sub='Grup: ${r['grup_nama']??'-'} • ${kg(r['kg'])} • ${jjg(r['jjg'])}';
                  }
                  return Card(child:ListTile(
                    leading:Icon(tab==0?Icons.grid_view:tab==1?Icons.groups:Icons.person),
                    title:Text(title),
                    subtitle:Text(sub),
                  ));
                }),
            ],
          ),
        ),
    );
  }
}
