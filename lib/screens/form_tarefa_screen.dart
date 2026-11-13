import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/categoria.dart';
import '../models/tarefa.dart';
import '../providers/tarefa_provider.dart';
import '../theme.dart';
import 'dialogo_categoria.dart';

class FormTarefaScreen extends StatefulWidget {
  final Tarefa? tarefa;
  const FormTarefaScreen({super.key, this.tarefa});

  @override
  State<FormTarefaScreen> createState() => _FormTarefaScreenState();
}

class _FormTarefaScreenState extends State<FormTarefaScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titulo;
  late final TextEditingController _descricao;
  late String _categoriaId;
  late Prioridade _prioridade;
  DateTime? _prazo;

  bool get _editando => widget.tarefa != null;

  @override
  void initState() {
    super.initState();
    final t = widget.tarefa;
    _titulo = TextEditingController(text: t?.titulo ?? '');
    _descricao = TextEditingController(text: t?.descricao ?? '');
    _categoriaId = t?.categoriaId ??
        context.read<TarefaProvider>().categorias.first.id;
    _prioridade = t?.prioridade ?? Prioridade.media;
    _prazo = t?.prazo;
  }

  @override
  void dispose() {
    _titulo.dispose();
    _descricao.dispose();
    super.dispose();
  }

  Future<void> _escolherPrazo() async {
    final hoje = DateTime.now();
    final data = await showDatePicker(
      context: context,
      initialDate: _prazo ?? hoje,
      firstDate: DateTime(hoje.year - 1),
      lastDate: DateTime(hoje.year + 5),
    );
    if (data != null) setState(() => _prazo = data);
  }

  Future<void> _criarCategoria() async {
    final provider = context.read<TarefaProvider>();
    final messenger = ScaffoldMessenger.of(context);

    final dados = await pedirDadosDeCategoria(
      context,
      titulo: 'Nova categoria',
      rotuloBotao: 'Criar',
      corInicial: Categoria.paleta.first,
    );

    if (dados == null) return;

    final criada =
        await provider.adicionarCategoria(dados.nome, cor: dados.cor);
    if (!mounted) return;
    if (criada == null) {
      messenger.showSnackBar(
        SnackBar(
          content: Text('Já existe uma categoria chamada "${dados.nome}"'),
        ),
      );
      return;
    }
    setState(() => _categoriaId = criada.id);
  }

  Future<void> _salvar() async {
    if (!_formKey.currentState!.validate()) return;
    final provider = context.read<TarefaProvider>();
    final t = widget.tarefa;
    final tarefa = Tarefa(
      id: t?.id ?? DateTime.now().microsecondsSinceEpoch.toString(),
      titulo: _titulo.text.trim(),
      descricao: _descricao.text.trim(),
      categoriaId: _categoriaId,
      prioridade: _prioridade,
      concluida: t?.concluida ?? false,
      criadaEm: t?.criadaEm,
      prazo: _prazo,
      anexos: t?.anexos,
    );
    if (_editando) {
      await provider.atualizar(tarefa);
    } else {
      await provider.adicionar(tarefa);
    }
    if (!mounted) return;
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_editando ? 'Editar tarefa' : 'Nova tarefa'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _titulo,
              decoration: const InputDecoration(
                labelText: 'Título',
                border: OutlineInputBorder(),
              ),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Informe um título' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _descricao,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Descrição (opcional)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 24),
            const Text('Categoria'),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final c in context.watch<TarefaProvider>().categorias)
                  Builder(builder: (context) {
                    final cor = corLegivel(context, Color(c.cor));
                    final marcado = _categoriaId == c.id;
                    return ChoiceChip(
                      label: Text(c.nome),
                      avatar: marcado
                          ? null
                          : CircleAvatar(backgroundColor: cor, radius: 6),
                      selected: marcado,
                      selectedColor: cor.withValues(alpha: 0.22),
                      side: marcado ? BorderSide(color: cor) : null,
                      onSelected: (_) => setState(() => _categoriaId = c.id),
                    );
                  }),
                ActionChip(
                  avatar: const Icon(Icons.add, size: 18),
                  label: const Text('Nova'),
                  onPressed: _criarCategoria,
                ),
              ],
            ),
            const SizedBox(height: 24),
            const Text('Prioridade'),
            const SizedBox(height: 8),
            SegmentedButton<Prioridade>(
              segments: Prioridade.values
                  .map((p) => ButtonSegment(value: p, label: Text(p.label)))
                  .toList(),
              selected: {_prioridade},
              onSelectionChanged: (s) => setState(() => _prioridade = s.first),
            ),
            const SizedBox(height: 16),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.event),
              title: Text(_prazo == null
                  ? 'Sem prazo (toque para definir)'
                  : 'Prazo: ${formatarData(_prazo!)}'),
              trailing: _prazo == null
                  ? null
                  : IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () => setState(() => _prazo = null),
                    ),
              onTap: _escolherPrazo,
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: _salvar,
              icon: const Icon(Icons.save),
              label: const Text('Salvar'),
            ),
          ],
        ),
      ),
    );
  }
}