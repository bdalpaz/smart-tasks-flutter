import 'package:flutter/material.dart';
import '../models/categoria.dart';
import '../theme.dart';

typedef DadosCategoria = ({String nome, int cor});

Future<DadosCategoria?> pedirDadosDeCategoria(
  BuildContext context, {
  required String titulo,
  required String rotuloBotao,
  required int corInicial,
  String nomeInicial = '',
}) {
  return showDialog<DadosCategoria>(
    context: context,
    builder: (_) => _DialogoCategoria(
      titulo: titulo,
      rotuloBotao: rotuloBotao,
      nomeInicial: nomeInicial,
      corInicial: corInicial,
    ),
  );
}

class _DialogoCategoria extends StatefulWidget {
  final String titulo;
  final String rotuloBotao;
  final String nomeInicial;
  final int corInicial;

  const _DialogoCategoria({
    required this.titulo,
    required this.rotuloBotao,
    required this.nomeInicial,
    required this.corInicial,
  });

  @override
  State<_DialogoCategoria> createState() => _DialogoCategoriaState();
}

class _DialogoCategoriaState extends State<_DialogoCategoria> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _controller;
  late int _cor;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.nomeInicial);
    _cor = widget.corInicial;
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _confirmar() {
    if (_formKey.currentState!.validate()) {
      Navigator.pop(context, (nome: _controller.text.trim(), cor: _cor));
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.titulo),
      content: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 360),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextFormField(
                controller: _controller,
                autofocus: true,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(labelText: 'Nome'),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Informe um nome' : null,
                onFieldSubmitted: (_) => _confirmar(),
              ),
              const SizedBox(height: 22),
              Text('Cor', style: Theme.of(context).textTheme.labelLarge),
              const SizedBox(height: 10),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  for (final cor in Categoria.paleta)
                    _Amostra(
                      cor: corLegivel(context, Color(cor)),
                      selecionada: _cor == cor,
                      onTap: () => setState(() => _cor = cor),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: _confirmar,
          child: Text(widget.rotuloBotao),
        ),
      ],
    );
  }
}

class _Amostra extends StatelessWidget {
  final Color cor;
  final bool selecionada;
  final VoidCallback onTap;

  const _Amostra({
    required this.cor,
    required this.selecionada,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      customBorder: const CircleBorder(),
      child: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: cor,
          shape: BoxShape.circle,
          border: selecionada
              ? Border.all(
                  color: Theme.of(context).colorScheme.onSurface,
                  width: 3,
                )
              : null,
        ),
        child: selecionada
            ? const Icon(Icons.check, color: Colors.white, size: 20)
            : null,
      ),
    );
  }
}
