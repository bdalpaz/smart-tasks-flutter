import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/tarefa.dart';
import '../providers/tarefa_provider.dart';

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
  late Categoria _categoria;
  late Prioridade _prioridade;
  DateTime? _prazo;

  bool get _editando => widget.tarefa != null;

  @override
  void initState() {
    super.initState();
    final t = widget.tarefa;
    _titulo = TextEditingController(text: t?.titulo ?? '');
    _descricao = TextEditingController(text: t?.descricao ?? '');
    _categoria = t?.categoria ?? Categoria.pessoal;
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

  Future<void> _salvar() async {
    if (!_formKey.currentState!.validate()) return;
    final provider = context.read<TarefaProvider>();
    final t = widget.tarefa;
    final tarefa = Tarefa(
      id: t?.id ?? DateTime.now().microsecondsSinceEpoch.toString(),
      titulo: _titulo.text.trim(),
      descricao: _descricao.text.trim(),
      categoria: _categoria,
      prioridade: _prioridade,
      concluida: t?.concluida ?? false,
      criadaEm: t?.criadaEm,
      prazo: _prazo,
    );
    if (_editando) {
      await provider.atualizar(tarefa);
    } else {
      await provider.adicionar(tarefa);
    }
    if (!mounted) return;
    Navigator.pop(context);
  }

  Future<void> _excluir() async {
    await context.read<TarefaProvider>().excluir(widget.tarefa!.id);
    if (!mounted) return;
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_editando ? 'Editar tarefa' : 'Nova tarefa'),
        actions: [
          if (_editando)
            IconButton(
              icon: const Icon(Icons.delete_outline),
              tooltip: 'Excluir',
              onPressed: _excluir,
            ),
        ],
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
            SegmentedButton<Categoria>(
              segments: Categoria.values
                  .map((c) => ButtonSegment(value: c, label: Text(c.label)))
                  .toList(),
              selected: {_categoria},
              onSelectionChanged: (s) => setState(() => _categoria = s.first),
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