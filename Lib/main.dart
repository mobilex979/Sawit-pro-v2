import 'package:flutter/material.dart';import 'screens/home_screen.dart';
void main(){WidgetsFlutterBinding.ensureInitialized();runApp(const App());}
class App extends StatelessWidget{const App({super.key});@override Widget build(BuildContext c)=>MaterialApp(debugShowCheckedModeBanner:false,title:'SAWIT PRO v2',theme:ThemeData(colorScheme:ColorScheme.fromSeed(seedColor:const Color(0xFF087443)),useMaterial3:true),home:const HomeScreen());}
