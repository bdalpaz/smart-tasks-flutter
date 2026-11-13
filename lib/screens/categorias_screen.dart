import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/categoria.dart';
import '../providers/tarefa_provider.dart';
import '../theme.dart';
import 'dialogo_categoria.dart';

class CategoriasScreen extends StatelessWidget {
  const CategoriasScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<TarefaProvider>();
    final categorias = provider.categorias;

    return Scaffold(
      appBar: AppBar(title: const Text('Categorias')),
      body: ListView.builder(
        padding: const EdgeInsets.only(top: 8, bottom: 88),
        itemCount: categorias.length,
        itemBuilder: (context, i) => _ItemCategoria(categoria: categorias[i]),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _abrirDialogo(context),
        icon: const Icon(Icons.add),
        label: const Text('Nova categoria'),
      ),
    );
  }
}

class _ItemCategoria extends StatelessWidget {
  final Categoria categoria;
  const _ItemCategoria({required this.categoria});

  @override
  Widget build(BuildContext context) {
    final provider = context.read<TarefaProvider>();
    final messenger = ScaffoldMessenger.of(context);
    final emUso = provider.quantidadeDeTarefasEm(categoria.id);
    final cor = corLegivel(context, Color(categoria.cor));

    return ListTile(
      leading: CircleAvatar(backgroundColor: cor, radius: 14),
      title: Text(categoria.nome),
      subtitle: Text(switch (emUso) {
        0 => 'Nenhuma tarefa',
        1 => '1 tarefa',
        _ => '$emUso tarefas',
      }),
      onTap: () => _abrirDialogo(context, categoria: categoria),
      trailing: IconButton(
        icon: const Icon(Icons.delete_outline),
        tooltip: 'Excluir',
        onPressed: () async {
          final resultado = await provider.excluirCategoria(categoria.id);
          final aviso = switch (resultado) {
            ResultadoExclusaoCategoria.excluida => '"${categoria.nome}" excluída',
            ResultadoExclusaoCategoria.emUso =>
              'Não dá para excluir: $emUso ${emUso == 1 ? 'tarefa usa' : 'tarefas usam'} esta categoria',
            ResultadoExclusaoCategoria.ultimaRestante =>
              'É preciso manter ao menos uma categoria',
          };
          messenger.hideCurrentSnackBar();
          messenger.showSnackBar(SnackBar(content: Text(aviso)));
        },
      ),
    );
  }
}

Future<void> _abrirDialogo(BuildContext context, {Categoria? categoria}) async {
  final provider = context.read<TarefaProvider>();
  final messenger = ScaffoldMessenger.of(context);
  final editando = categoria != null;

  final dados = await pedirDadosDeCategoria(
    context,
    titulo: editando ? 'Editar categoria' : 'Nova categoria',
    rotuloBotao: editando ? 'Salvar' : 'Criar',
    nomeInicial: categoria?.nome ?? '',
    corInicial: categoria?.cor ?? Categoria.paleta.first,
  );

  if (dados == null) return;

  final ok = editando
      ? await provider.atualizarCategoria(categoria.id,
          nome: dados.nome, cor: dados.cor)
      : await provider.adicionarCategoria(dados.nome, cor: dados.cor) != null;

  if (!ok) {
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(
      SnackBar(content: Text('Já existe uma categoria chamada "${dados.nome}"')),
    );
  }
}
