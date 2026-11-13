import 'package:animations/animations.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../layout_responsivo.dart';
import '../models/tarefa.dart';
import '../providers/tarefa_provider.dart';
import '../theme.dart';
import 'categorias_screen.dart';
import '../widgets/pilula.dart';
import 'detalhes_tarefa_screen.dart';
import 'form_tarefa_screen.dart';

const _duracaoTransicao = Duration(milliseconds: 420);
const _raioCartao = 14.0;

class _Limitado extends StatelessWidget {
  final double largura;
  final Widget child;
  const _Limitado({required this.largura, required this.child});

  @override
  Widget build(BuildContext context) => Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: largura),
          child: child,
        ),
      );
}

class _Contador extends StatelessWidget {
  final int quantidade;
  const _Contador({required this.quantidade});

  @override
  Widget build(BuildContext context) {
    final cores = Theme.of(context).colorScheme;
    return Tooltip(
      message:
          '$quantidade tarefa${quantidade == 1 ? '' : 's'} pendente${quantidade == 1 ? '' : 's'}',
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
        decoration: BoxDecoration(
          color: cores.onPrimaryContainer.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          '$quantidade',
          overflow: TextOverflow.ellipsis,
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
                color: cores.onPrimaryContainer,
                fontWeight: FontWeight.w700,
              ),
        ),
      ),
    );
  }
}

class ListaTarefasScreen extends StatelessWidget {
  const ListaTarefasScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<TarefaProvider>();
    final cores = Theme.of(context).colorScheme;
    final tarefas = provider.tarefas;

    final larguraDisponivel = MediaQuery.sizeOf(context).width;
    final colunas = colunasPara(larguraDisponivel);
    final larguraDaCaixa = larguraDoConteudo(larguraDisponivel, colunas);

    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Flexible(
              child: Text('Minhas Tarefas', overflow: TextOverflow.ellipsis),
            ),
            if (provider.pendentes > 0) ...[
              const SizedBox(width: 10),
              Flexible(child: _Contador(quantidade: provider.pendentes)),
            ],
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.label_outline),
            tooltip: 'Categorias',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const CategoriasScreen()),
            ),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: Size.fromHeight(
            62 * MediaQuery.textScalerOf(context).scale(1).clamp(1.0, 2.0),
          ),
          child: _Limitado(
            largura: larguraDaCaixa,
            child: const Padding(
              padding: EdgeInsets.fromLTRB(16, 0, 16, 14),
              child: _CampoBusca(),
            ),
          ),
        ),
      ),
      body: _Limitado(
        largura: larguraDaCaixa,
        child: Column(
          children: [
            const _BarraFiltros(),
            Expanded(
              child: switch ((provider.carregando, tarefas.isEmpty)) {
                (true, _) => const Center(child: CircularProgressIndicator()),
                (false, true) => _EstadoVazio(filtrando: provider.filtrando),
                (false, false) =>
                  _Grade(tarefas: tarefas, colunas: colunas),
              },
            ),
          ],
        ),
      ),
      floatingActionButton: OpenContainer(
        transitionType: ContainerTransitionType.fadeThrough,
        transitionDuration: _duracaoTransicao,
        closedElevation: 6,
        closedShape: const StadiumBorder(),
        closedColor: cores.primaryContainer,
        openColor: cores.surface,
        tappable: false,
        openBuilder: (_, _) => const FormTarefaScreen(),
        closedBuilder: (_, abrir) => Material(
          type: MaterialType.transparency,
          child: InkWell(
            onTap: abrir,
            child: Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.add, color: cores.onPrimaryContainer),
                  const SizedBox(width: 8),
                  Text(
                    'Nova tarefa',
                    style: TextStyle(
                      color: cores.onPrimaryContainer,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _CampoBusca extends StatefulWidget {
  const _CampoBusca();

  @override
  State<_CampoBusca> createState() => _CampoBuscaState();
}

class _CampoBuscaState extends State<_CampoBusca> {
  final _controller = TextEditingController();
  late final TarefaProvider _provider;

  @override
  void initState() {
    super.initState();
    _provider = context.read<TarefaProvider>();
    _provider.addListener(_sincronizar);
  }

  void _sincronizar() {
    final busca = _provider.busca;
    if (_controller.text == busca) return;
    _controller.value = TextEditingValue(
      text: busca,
      selection: TextSelection.collapsed(offset: busca.length),
    );
  }

  @override
  void dispose() {
    _provider.removeListener(_sincronizar);
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cores = Theme.of(context).colorScheme;
    final temTexto = context.watch<TarefaProvider>().busca.isNotEmpty;

    return TextField(
      controller: _controller,
      onChanged: _provider.setBusca,
      textInputAction: TextInputAction.search,
      decoration: InputDecoration(
        hintText: 'Buscar tarefas...',
        prefixIcon: const Icon(Icons.search),
        suffixIcon: temTexto
            ? IconButton(
                icon: const Icon(Icons.close),
                tooltip: 'Limpar busca',
                onPressed: () => _provider.setBusca(''),
              )
            : null,
        filled: true,
        fillColor: cores.surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(28),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.symmetric(vertical: 4),
        isDense: true,
      ),
    );
  }
}

class _EstadoVazio extends StatelessWidget {
  final bool filtrando;
  const _EstadoVazio({required this.filtrando});

  @override
  Widget build(BuildContext context) {
    final cores = Theme.of(context).colorScheme;
    final textos = Theme.of(context).textTheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              filtrando ? Icons.search_off_rounded : Icons.task_alt_rounded,
              size: 76,
              color: cores.outlineVariant,
            ),
            const SizedBox(height: 20),
            Text(
              filtrando ? 'Nada encontrado' : 'Tudo em dia por aqui',
              style: textos.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              filtrando
                  ? 'Tente outra busca ou limpe os filtros.'
                  : 'Toque em "Nova tarefa" para criar a primeira.',
              textAlign: TextAlign.center,
              style: textos.bodyMedium?.copyWith(color: cores.onSurfaceVariant),
            ),
            if (filtrando) ...[
              const SizedBox(height: 20),
              TextButton.icon(
                onPressed: context.read<TarefaProvider>().limparFiltros,
                icon: const Icon(Icons.filter_alt_off_outlined),
                label: const Text('Limpar filtros'),
              ),
            ],
          ],
        ),
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
      height: 50,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        children: [
          for (final c in provider.categorias)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: Builder(builder: (context) {
                final cor = corLegivel(context, Color(c.cor));
                final marcado = provider.filtroCategoriaId == c.id;
                return FilterChip(
                  label: Text(c.nome),
                  avatar: marcado
                      ? null
                      : CircleAvatar(backgroundColor: cor, radius: 6),
                  selected: marcado,
                  selectedColor: cor.withValues(alpha: 0.22),
                  checkmarkColor: cor,
                  side: marcado ? BorderSide(color: cor) : null,
                  onSelected: (sel) =>
                      provider.setFiltroCategoria(sel ? c.id : null),
                );
              }),
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
        padding: EdgeInsets.symmetric(horizontal: 4, vertical: 11),
        child: VerticalDivider(width: 1),
      );
}

class _Grade extends StatelessWidget {
  final List<Tarefa> tarefas;
  final int colunas;

  const _Grade({required this.tarefas, required this.colunas});

  static const _recheio = EdgeInsets.only(top: 4, bottom: 88);

  @override
  Widget build(BuildContext context) {
    if (colunas == 1) {
      return ListView.builder(
        padding: _recheio,
        itemCount: tarefas.length,
        itemBuilder: (context, i) => _ItemTarefa(tarefa: tarefas[i]),
      );
    }

    final linhas = (tarefas.length + colunas - 1) ~/ colunas;

    return ListView.builder(
      padding: _recheio,
      itemCount: linhas,
      itemBuilder: (context, linha) {
        final inicio = linha * colunas;
        return IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (var i = 0; i < colunas; i++)
                Expanded(
                  child: inicio + i < tarefas.length
                      ? _ItemTarefa(tarefa: tarefas[inicio + i])
                      : const SizedBox.shrink(),
                ),
            ],
          ),
        );
      },
    );
  }
}

class _ItemTarefa extends StatelessWidget {
  final Tarefa tarefa;
  const _ItemTarefa({required this.tarefa});

  @override
  Widget build(BuildContext context) {
    final provider = context.read<TarefaProvider>();
    final messenger = ScaffoldMessenger.of(context);
    final cores = Theme.of(context).colorScheme;

    void excluirComDesfazer(Tarefa tarefa) {
      provider.excluir(tarefa.id);
      messenger.hideCurrentSnackBar();
      messenger
          .showSnackBar(
            SnackBar(
              content: Text('"${tarefa.titulo}" excluída'),
              action: SnackBarAction(
                label: 'Desfazer',
                onPressed: () => provider.adicionar(tarefa),
              ),
            ),
          )
          .closed
          .then((_) => provider.descartarAnexosDeExcluida(tarefa.id));
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: Dismissible(
        key: ValueKey(tarefa.id),
        direction: DismissDirection.endToStart,
        background: Container(
          decoration: BoxDecoration(
            color: cores.errorContainer,
            borderRadius: BorderRadius.circular(_raioCartao),
          ),
          alignment: Alignment.centerRight,
          padding: const EdgeInsets.only(right: 22),
          child: Icon(Icons.delete_outline, color: cores.onErrorContainer),
        ),
        onDismissed: (_) => excluirComDesfazer(tarefa),
        child: OpenContainer<String>(
          transitionType: ContainerTransitionType.fadeThrough,
          transitionDuration: _duracaoTransicao,
          closedElevation: 0,
          closedColor: cores.surfaceContainerHighest.withValues(alpha: 0.45),
          openColor: cores.surface,
          tappable: false,
          closedShape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(_raioCartao),
          ),
          openBuilder: (_, _) => DetalhesTarefaScreen(tarefaId: tarefa.id),
          onClosed: (idExcluir) {
            final alvo =
                idExcluir == null ? null : provider.tarefaPor(idExcluir);
            if (alvo != null) excluirComDesfazer(alvo);
          },
          closedBuilder: (_, abrir) => Material(
            type: MaterialType.transparency,
            child: _ConteudoItem(tarefa: tarefa, aoTocar: abrir),
          ),
        ),
      ),
    );
  }
}

class _ConteudoItem extends StatelessWidget {
  final Tarefa tarefa;
  final VoidCallback aoTocar;

  const _ConteudoItem({required this.tarefa, required this.aoTocar});

  @override
  Widget build(BuildContext context) {
    final provider = context.read<TarefaProvider>();
    final cores = Theme.of(context).colorScheme;
    final textos = Theme.of(context).textTheme;

    final corCategoria =
        corLegivel(context, Color(provider.corCategoria(tarefa.categoriaId)));
    final corPrioridade =
        corDaPrioridade(context, tarefa.prioridade.index);

    return InkWell(
      onTap: aoTocar,
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(width: 5, color: corPrioridade),
            Checkbox(
              value: tarefa.concluida,
              onChanged: (_) => provider.alternarConcluida(tarefa),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(2, 12, 14, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      tarefa.titulo,
                      style: textos.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w500,
                        decoration: tarefa.concluida
                            ? TextDecoration.lineThrough
                            : null,
                        color: tarefa.concluida ? cores.outline : null,
                      ),
                    ),
                    const SizedBox(height: 7),
                    Wrap(
                      spacing: 10,
                      runSpacing: 4,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Pilula(
                          texto: provider.nomeCategoria(tarefa.categoriaId),
                          cor: corCategoria,
                        ),
                        Text(
                          tarefa.prioridade.label,
                          style: textos.labelMedium?.copyWith(
                            color: corPrioridade,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        if (tarefa.prazo != null)
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (tarefa.atrasada) ...[
                                Icon(
                                  Icons.warning_amber_rounded,
                                  size: 15,
                                  color: cores.error,
                                ),
                                const SizedBox(width: 3),
                              ],
                              Text(
                                formatarData(tarefa.prazo!),
                                style: textos.labelMedium?.copyWith(
                                  color: tarefa.atrasada
                                      ? cores.error
                                      : cores.onSurfaceVariant,
                                  fontWeight:
                                      tarefa.atrasada ? FontWeight.w600 : null,
                                ),
                              ),
                            ],
                          ),
                        if (tarefa.anexos.isNotEmpty)
                          Tooltip(
                            message: '${tarefa.anexos.length} anexo'
                                '${tarefa.anexos.length == 1 ? '' : 's'}',
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.attach_file,
                                  size: 15,
                                  color: cores.onSurfaceVariant,
                                ),
                                Text(
                                  '${tarefa.anexos.length}',
                                  style: textos.labelMedium?.copyWith(
                                    color: cores.onSurfaceVariant,
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
