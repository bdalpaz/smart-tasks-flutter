import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/tarefa_provider.dart';
import 'screens/lista_tarefas_screen.dart';
import 'theme.dart';

void main() {
  runApp(
    ChangeNotifierProvider(
      create: (_) => TarefaProvider()..carregar(),
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Smart Tasks',
      debugShowCheckedModeBanner: false,
      theme: temaClaro(),
      darkTheme: temaEscuro(),
      themeMode: ThemeMode.system,
      home: const ListaTarefasScreen(),
    );
  }
}