enum Prioridade { alta, media, baixa }

extension PrioridadeLabel on Prioridade {
  String get label => switch (this) {
        Prioridade.alta => 'Alta',
        Prioridade.media => 'Média',
        Prioridade.baixa => 'Baixa',
      };
}

String formatarData(DateTime d) =>
    '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';

class Tarefa {
  final String id;
  String titulo;
  String descricao;

  /// Id da [Categoria], e não o objeto: renomear uma categoria não exige
  /// reescrever nenhuma tarefa.
  String categoriaId;
  Prioridade prioridade;
  bool concluida;
  final DateTime criadaEm;
  DateTime? prazo;

  Tarefa({
    required this.id,
    required this.titulo,
    this.descricao = '',
    this.categoriaId = 'pessoal',
    this.prioridade = Prioridade.media,
    this.concluida = false,
    DateTime? criadaEm,
    this.prazo,
  }) : criadaEm = criadaEm ?? DateTime.now();

  bool get atrasada {
    if (concluida || prazo == null) return false;
    final agora = DateTime.now();
    final hoje = DateTime(agora.year, agora.month, agora.day);
    return prazo!.isBefore(hoje);
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'titulo': titulo,
        'descricao': descricao,
        // A chave segue sendo 'categoria' para que os dados gravados pela
        // versão com enum continuem sendo lidos sem conversão.
        'categoria': categoriaId,
        'prioridade': prioridade.name,
        'concluida': concluida,
        'criadaEm': criadaEm.toIso8601String(),
        'prazo': prazo?.toIso8601String(),
      };

  factory Tarefa.fromJson(Map<String, dynamic> j) => Tarefa(
        id: j['id'],
        titulo: j['titulo'],
        descricao: j['descricao'] ?? '',
        categoriaId: j['categoria'] ?? 'outros',
        prioridade: Prioridade.values.byName(j['prioridade']),
        concluida: j['concluida'] ?? false,
        criadaEm: DateTime.parse(j['criadaEm']),
        prazo: j['prazo'] != null ? DateTime.parse(j['prazo']) : null,
      );
}
