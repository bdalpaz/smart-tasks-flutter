import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/tarefa.dart';
import '../providers/tarefa_provider.dart';

class ListaTarefasScreen extends StatelessWidget {
  const ListaTarefasScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<TarefaProvider>();
    final tarefas = provider.tarefas;

    return Scaffold(
      appBar: AppBar(title: const Text('Minhas Tarefas')),
      body: tarefas.isEmpty
          ? const Center(child: Text('Nenhuma tarefa ainda'))
          : ListView.builder(
              itemCount: tarefas.length,
              itemBuilder: (context, i) {
                final t = tarefas[i];
                return CheckboxListTile(
                  value: t.concluida,
                  onChanged: (_) => provider.alternarConcluida(t),
                  title: Text(t.titulo),
                  subtitle: Text('${t.categoria.name} • ${t.prioridade.name}'),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => provider.adicionar(Tarefa(
          id: DateTime.now().microsecondsSinceEpoch.toString(),
          titulo: 'Tarefa de teste ${tarefas.length + 1}',
        )),
        child: const Icon(Icons.add),
      ),
    );
  }
}