import 'package:flutter/material.dart';
import 'master_screen.dart';
import 'panen_screen.dart';
import 'timbang_screen.dart';
import 'rekap_produksi_screen.dart';
import 'upah_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override State<HomeScreen> createState()=>_HomeState();
}

class _HomeState extends State<HomeScreen> {
  int tab=0;

  @override Widget build(BuildContext context){
    return Scaffold(
      appBar:AppBar(title:const Text('SAWIT PRO v2')),
      body:tab==0
        ?const Dash()
        :tab==1
          ?const PanenScreen()
          :tab==2
            ?const TimbangScreen()
            :tab==3
              ?const RekapProduksiScreen()
              :tab==4
                ?const UpahScreen()
                :const MasterScreen(),
      bottomNavigationBar:NavigationBar(
        selectedIndex:tab,
        onDestinationSelected:(x)=>setState(()=>tab=x),
        destinations:const[
          NavigationDestination(icon:Icon(Icons.dashboard),label:'Beranda'),
          NavigationDestination(icon:Icon(Icons.agriculture),label:'Panen'),
          NavigationDestination(icon:Icon(Icons.scale),label:'Timbang'),
          NavigationDestination(icon:Icon(Icons.assessment),label:'Rekap'),
          NavigationDestination(icon:Icon(Icons.payments),label:'Upah'),
          NavigationDestination(icon:Icon(Icons.settings),label:'Master'),
        ],
      ),
    );
  }
}

class Dash extends StatelessWidget {
  const Dash({super.key});
  @override Widget build(BuildContext context){
    return ListView(
      padding:const EdgeInsets.all(16),
      children:const[
        Card(child:ListTile(
          leading:Icon(Icons.eco),
          title:Text('Kebun Utama'),
          subtitle:Text('1 kebun • mode offline'),
        )),
        Card(child:ListTile(
          title:Text('Produksi TBS'),
          subtitle:Text('Rekap dan alokasi menjadi dasar perhitungan upah.'),
        )),
        Card(child:ListTile(
          title:Text('Upah & Premi'),
          subtitle:Text('Tarif dasar dan premi per kg mengikuti tarif pada Grup.'),
        )),
      ],
    );
  }
}
