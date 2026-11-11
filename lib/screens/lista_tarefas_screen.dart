import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/tarefa.dart';
import '../providers/tarefa_provider.dart';
import 'form_tarefa_screen.dart';

class ListaTarefasScreen extends StatelessWidget {
  const ListaTarefasScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<TarefaProvider>();
    final tarefas = provider.tarefas;

    return Scaffold(
      appBar: AppBar(
        title: Text('Minhas Tarefas (${provider.pendentes} pendentes)'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: TextField(
              onChanged: provider.setBusca,
              decoration: const InputDecoration(
                hintText: 'Buscar tarefas...',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
                isDense: true,
              ),
            ),
          ),
        ),
      ),
      body: Column(
        children: [
          const _BarraFiltros(),
          Expanded(
            child: tarefas.isEmpty
                ? const Center(child: Text('Nenhuma tarefa encontrada'))
                : ListView.builder(
                    itemCount: tarefas.length,
                    itemBuilder: (context, i) => _ItemTarefa(tarefa: tarefas[i]),
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const FormTarefaScreen()),
        ),
        icon: const Icon(Icons.add),
        label: const Text('Nova tarefa'),
      ),
    );
  }
}

class _BarraFiltros extends StatelessWidget {
  const _BarraFiltros();

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<TarefaProvider>();

    return SizedBox(
      height: 48,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        children: [
          for (final c in Categoria.values)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: FilterChip(
                label: Text(c.label),
                selected: provider.filtroCategoria == c,
                onSelected: (sel) =>
                    provider.setFiltroCategoria(sel ? c : null),
              ),
            ),
          const _SeparadorFiltros(),
          for (final p in Prioridade.values)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: FilterChip(
                label: Text(p.label),
                selected: provider.filtroPrioridade == p,
                onSelected: (sel) =>
                    provider.setFiltroPrioridade(sel ? p : null),
              ),
            ),
          const _SeparadorFiltros(),
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              label: const Text('Pendentes'),
              selected: provider.filtroConcluida == false,
              onSelected: (sel) =>
                  provider.setFiltroConcluida(sel ? false : null),
            ),
          ),
          FilterChip(
            label: const Text('Concluídas'),
            selected: provider.filtroConcluida == true,
            onSelected: (sel) => provider.setFiltroConcluida(sel ? true : null),
          ),
        ],
      ),
    );
  }
}

class _SeparadorFiltros extends StatelessWidget {
  const _SeparadorFiltros();

  @override
  Widget build(BuildContext context) => const Padding(
        padding: EdgeInsets.symmetric(horizontal: 4, vertical: 10),
        child: VerticalDivider(width: 1),
      );
}

class _ItemTarefa extends StatelessWidget {
  final Tarefa tarefa;
  const _ItemTarefa({required this.tarefa});

  // Alta → vermelho, média → laranja, baixa → verde.
  Color _corPrioridade(BuildContext context) => switch (tarefa.prioridade) {
        Prioridade.alta => Colors.red.shade400,
        Prioridade.media => Colors.orange.shade400,
        Prioridade.baixa => Colors.green.shade400,
      };

  @override
  Widget build(BuildContext context) {
    final provider = context.read<TarefaProvider>();
    final messenger = ScaffoldMessenger.of(context);

    final partes = <String>[
      tarefa.categoria.label,
      tarefa.prioridade.label,
      if (tarefa.prazo != null) formatarData(tarefa.prazo!),
    ];

    return Dismissible(
      key: ValueKey(tarefa.id),
      direction: DismissDirection.endToStart,
      background: Container(
        color: Theme.of(context).colorScheme.errorContainer,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        child: const Icon(Icons.delete_outline),
      ),
      onDismissed: (_) {
        provider.excluir(tarefa.id);
        messenger.showSnackBar(
          SnackBar(content: Text('"${tarefa.titulo}" excluída')),
        );
      },
      child: ListTile(
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => FormTarefaScreen(tarefa: tarefa),
          ),
        ),
        leading: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 6,
              height: 36,
              decoration: BoxDecoration(
                color: _corPrioridade(context),
                borderRadius: BorderRadius.circular(3),
              ),
            ),
            Checkbox(
              value: tarefa.concluida,
              onChanged: (_) => provider.alternarConcluida(tarefa),
            ),
          ],
        ),
        title: Text(
          tarefa.titulo,
          style: TextStyle(
            decoration: tarefa.concluida ? TextDecoration.lineThrough : null,
          ),
        ),
        subtitle: Row(
          children: [
            if (tarefa.atrasada) ...[
              Icon(
                Icons.warning_amber_rounded,
                size: 16,
                color: Theme.of(context).colorScheme.error,
              ),
              const SizedBox(width: 4),
            ],
            Expanded(
              child: Text(
                partes.join(' • '),
                overflow: TextOverflow.ellipsis,
                style: tarefa.atrasada
                    ? TextStyle(color: Theme.of(context).colorScheme.error)
                    : null,
              ),
            ),
          ],
        ),
      ),
    );
  }
}