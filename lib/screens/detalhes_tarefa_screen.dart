import 'dart:io';

import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:open_filex/open_filex.dart';
import 'package:provider/provider.dart';
import '../data/anexo_storage.dart';
import '../models/anexo.dart';
import '../models/tarefa.dart';
import '../providers/tarefa_provider.dart';
import '../theme.dart';
import '../widgets/pilula.dart';
import 'form_tarefa_screen.dart';

/// Mostra uma tarefa por inteiro, com o acompanhamento do prazo.
///
/// Ao excluir, a tela fecha devolvendo o id da tarefa e quem a abriu faz a
/// exclusão. Excluir aqui dentro faria o cartão de destino da transição de
/// volta sumir no meio dela, e a lista já tem o aviso com "Desfazer" pronto.
/// O id, e não um simples "excluir": a lista reaproveita os cartões por
/// posição, e editar a tarefa pode tê-la movido para outro lugar.
class DetalhesTarefaScreen extends StatelessWidget {
  /// O id, e não a tarefa: salvar a edição troca o objeto no provider, e a
  /// tela precisa mostrar a versão nova ao voltar do formulário.
  final String tarefaId;

  const DetalhesTarefaScreen({super.key, required this.tarefaId});

  static const _larguraMaxima = 720.0;

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<TarefaProvider>();
    final tarefa = provider.tarefaPor(tarefaId);

    // Só acontece se a tarefa sumir por outro caminho com a tela aberta.
    if (tarefa == null) {
      return Scaffold(
        appBar: AppBar(),
        body: const Center(child: Text('Esta tarefa não existe mais.')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Detalhes da tarefa'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            tooltip: 'Editar',
            onPressed: () => _editar(context, tarefa),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline),
            tooltip: 'Excluir',
            onPressed: () => Navigator.pop(context, tarefa.id),
          ),
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: _larguraMaxima),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 24),
            children: [
              _Cabecalho(tarefa: tarefa),
              const SizedBox(height: 20),
              _CartaoPrazo(tarefa: tarefa),
              const SizedBox(height: 12),
              _CartaoDescricao(tarefa: tarefa),
              if (TarefaProvider.anexosDisponiveis) ...[
                const SizedBox(height: 12),
                _CartaoAnexos(tarefa: tarefa),
              ],
              const SizedBox(height: 24),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                alignment: WrapAlignment.end,
                children: [
                  FilledButton.tonalIcon(
                    onPressed: () => provider.alternarConcluida(tarefa),
                    icon: Icon(tarefa.concluida
                        ? Icons.replay
                        : Icons.check_circle_outline),
                    label: Text(tarefa.concluida
                        ? 'Reabrir tarefa'
                        : 'Marcar como concluída'),
                  ),
                  FilledButton.icon(
                    onPressed: () => _editar(context, tarefa),
                    icon: const Icon(Icons.edit_outlined),
                    label: const Text('Editar'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _editar(BuildContext context, Tarefa tarefa) => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => FormTarefaScreen(tarefa: tarefa)),
      );
}

class _Cabecalho extends StatelessWidget {
  final Tarefa tarefa;
  const _Cabecalho({required this.tarefa});

  @override
  Widget build(BuildContext context) {
    final provider = context.read<TarefaProvider>();
    final cores = Theme.of(context).colorScheme;
    final textos = Theme.of(context).textTheme;
    final corPrioridade = corDaPrioridade(context, tarefa.prioridade.index);

    final (situacao, corSituacao) = switch (tarefa) {
      Tarefa(concluida: true) => ('Concluída', cores.outline),
      Tarefa(atrasada: true) => ('Atrasada', cores.error),
      _ => ('Pendente', cores.primary),
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SelectableText(
          tarefa.titulo,
          style: textos.headlineSmall?.copyWith(
            fontWeight: FontWeight.w600,
            decoration: tarefa.concluida ? TextDecoration.lineThrough : null,
            color: tarefa.concluida ? cores.outline : null,
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 10,
          runSpacing: 6,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Pilula(
              texto: provider.nomeCategoria(tarefa.categoriaId),
              cor: corLegivel(
                  context, Color(provider.corCategoria(tarefa.categoriaId))),
            ),
            Pilula(texto: situacao, cor: corSituacao),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.flag, size: 16, color: corPrioridade),
                const SizedBox(width: 4),
                Text(
                  'Prioridade ${tarefa.prioridade.label.toLowerCase()}',
                  style: textos.labelLarge?.copyWith(
                    color: corPrioridade,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }
}

class _Secao extends StatelessWidget {
  final IconData icone;
  final String titulo;
  final Widget child;
  final Widget? acao;

  const _Secao({
    required this.icone,
    required this.titulo,
    required this.child,
    this.acao,
  });

  @override
  Widget build(BuildContext context) {
    final cores = Theme.of(context).colorScheme;
    return Card(
      elevation: 0,
      margin: EdgeInsets.zero,
      color: cores.surfaceContainerHighest.withValues(alpha: 0.45),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icone, size: 18, color: cores.onSurfaceVariant),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    titulo,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          color: cores.onSurfaceVariant,
                        ),
                  ),
                ),
                ?acao,
              ],
            ),
            SizedBox(height: acao == null ? 12 : 4),
            child,
          ],
        ),
      ),
    );
  }
}

class _CartaoPrazo extends StatelessWidget {
  final Tarefa tarefa;
  const _CartaoPrazo({required this.tarefa});

  @override
  Widget build(BuildContext context) {
    final cores = Theme.of(context).colorScheme;
    final textos = Theme.of(context).textTheme;
    final criada = Text(
      'Criada em ${formatarData(tarefa.criadaEm)}',
      style: textos.bodySmall?.copyWith(color: cores.onSurfaceVariant),
    );

    if (tarefa.prazo == null) {
      return _Secao(
        icone: Icons.event,
        titulo: 'Prazo',
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Sem prazo definido', style: textos.bodyLarge),
            const SizedBox(height: 6),
            criada,
          ],
        ),
      );
    }

    final cor = tarefa.concluida
        ? cores.outline
        : tarefa.atrasada
            ? cores.error
            : cores.primary;

    return _Secao(
      icone: Icons.event,
      titulo: 'Prazo',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                formatarData(tarefa.prazo!),
                style: textos.titleLarge?.copyWith(fontWeight: FontWeight.w600),
              ),
              const SizedBox(width: 12),
              Flexible(
                child: Text(
                  tarefa.descricaoPrazo()!,
                  style: textos.titleSmall?.copyWith(
                    color: cor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: tarefa.concluida ? 1 : tarefa.progressoPrazo(),
              minHeight: 8,
              color: cor,
              backgroundColor: cor.withValues(alpha: 0.18),
              semanticsLabel: 'Tempo decorrido até o prazo',
            ),
          ),
          const SizedBox(height: 8),
          criada,
        ],
      ),
    );
  }
}

class _CartaoDescricao extends StatelessWidget {
  final Tarefa tarefa;
  const _CartaoDescricao({required this.tarefa});

  @override
  Widget build(BuildContext context) {
    final textos = Theme.of(context).textTheme;
    return _Secao(
      icone: Icons.notes,
      titulo: 'Descrição',
      child: tarefa.descricao.isEmpty
          ? Text(
              'Sem descrição',
              style: textos.bodyLarge?.copyWith(
                fontStyle: FontStyle.italic,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            )
          // Selecionável: no desktop e na web é comum querer copiar um
          // trecho, e a descrição é o texto mais longo da tarefa.
          : SelectableText(tarefa.descricao, style: textos.bodyLarge),
    );
  }
}

class _CartaoAnexos extends StatefulWidget {
  final Tarefa tarefa;
  const _CartaoAnexos({required this.tarefa});

  @override
  State<_CartaoAnexos> createState() => _CartaoAnexosState();
}

class _CartaoAnexosState extends State<_CartaoAnexos> {
  /// A pasta é resolvida uma vez só; as miniaturas precisam do caminho pronto.
  late final Future<Directory> _raiz =
      context.read<TarefaProvider>().armazenamentoAnexos.raiz();
  bool _anexando = false;

  Tarefa get _tarefa => widget.tarefa;

  Future<void> _anexar() async {
    final provider = context.read<TarefaProvider>();
    final messenger = ScaffoldMessenger.of(context);
    final arquivos = await openFiles();
    if (arquivos.isEmpty || !mounted) return;

    setState(() => _anexando = true);
    final falhas = await provider.anexar(_tarefa.id, arquivos);
    if (!mounted) return;
    setState(() => _anexando = false);
    if (falhas > 0) {
      messenger.showSnackBar(SnackBar(
        content: Text(falhas == 1
            ? 'Não foi possível anexar 1 arquivo'
            : 'Não foi possível anexar $falhas arquivos'),
      ));
    }
  }

  Future<void> _abrir(Anexo anexo) async {
    final messenger = ScaffoldMessenger.of(context);
    final caminho = await context
        .read<TarefaProvider>()
        .armazenamentoAnexos
        .caminho(_tarefa.id, anexo);
    final resultado = await OpenFilex.open(caminho);
    if (resultado.type == ResultType.done) return;
    messenger.showSnackBar(SnackBar(
      content: Text(resultado.type == ResultType.noAppToOpen
          ? 'Nenhum app instalado abre este tipo de arquivo'
          : 'Não foi possível abrir "${anexo.nome}"'),
    ));
  }

  Future<void> _remover(Anexo anexo) async {
    final provider = context.read<TarefaProvider>();
    final confirmado = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remover anexo?'),
        content: Text('"${anexo.nome}" será apagado do app.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Remover'),
          ),
        ],
      ),
    );
    if (confirmado == true) await provider.removerAnexo(_tarefa.id, anexo);
  }

  @override
  Widget build(BuildContext context) {
    final anexos = _tarefa.anexos;
    final cores = Theme.of(context).colorScheme;

    return _Secao(
      icone: Icons.attach_file,
      titulo: anexos.isEmpty ? 'Anexos' : 'Anexos (${anexos.length})',
      acao: _anexando
          ? const Padding(
              padding: EdgeInsets.all(12),
              child: SizedBox.square(
                dimension: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            )
          : TextButton.icon(
              onPressed: _anexar,
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Anexar'),
            ),
      child: anexos.isEmpty
          ? Text(
              'Nenhum arquivo anexado',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    fontStyle: FontStyle.italic,
                    color: cores.onSurfaceVariant,
                  ),
            )
          : FutureBuilder<Directory>(
              future: _raiz,
              builder: (context, raiz) => Column(
                children: [
                  for (final anexo in anexos)
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: _Miniatura(
                        anexo: anexo,
                        caminho: raiz.data == null
                            ? null
                            : AnexoStorage.caminhoEm(
                                raiz.data!, _tarefa.id, anexo),
                      ),
                      title: Text(
                        anexo.nome,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      subtitle: Text(formatarTamanho(anexo.tamanho)),
                      trailing: IconButton(
                        icon: const Icon(Icons.close),
                        tooltip: 'Remover anexo',
                        onPressed: () => _remover(anexo),
                      ),
                      onTap: () => _abrir(anexo),
                    ),
                ],
              ),
            ),
    );
  }
}

class _Miniatura extends StatelessWidget {
  final Anexo anexo;

  /// `null` enquanto a pasta dos anexos não foi resolvida.
  final String? caminho;

  const _Miniatura({required this.anexo, required this.caminho});

  static const _lado = 44.0;

  IconData get _icone => switch (anexo.extensao) {
        'pdf' => Icons.picture_as_pdf_outlined,
        'doc' || 'docx' || 'odt' || 'txt' || 'md' => Icons.description_outlined,
        'xls' || 'xlsx' || 'ods' || 'csv' => Icons.table_chart_outlined,
        'zip' || 'rar' || '7z' => Icons.folder_zip_outlined,
        'mp3' || 'wav' || 'ogg' || 'm4a' => Icons.audio_file_outlined,
        'mp4' || 'mov' || 'mkv' || 'webm' => Icons.video_file_outlined,
        _ when anexo.ehImagem => Icons.image_outlined,
        _ => Icons.insert_drive_file_outlined,
      };

  @override
  Widget build(BuildContext context) {
    final cores = Theme.of(context).colorScheme;
    final icone = Container(
      width: _lado,
      height: _lado,
      decoration: BoxDecoration(
        color: cores.primaryContainer,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(_icone, color: cores.onPrimaryContainer),
    );
    if (!anexo.ehImagem || caminho == null) return icone;

    final escala = MediaQuery.devicePixelRatioOf(context);
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: Image.file(
        File(caminho!),
        width: _lado,
        height: _lado,
        fit: BoxFit.cover,
        // Decodifica perto do tamanho da miniatura, não no da foto original.
        // Com folga: no recorte "cover" o lado menor de uma foto em paisagem
        // é ampliado, e decodificar no tamanho exato a deixaria borrada.
        cacheWidth: (_lado * escala * 2).round(),
        errorBuilder: (_, _, _) => icone,
      ),
    );
  }
}
