enum Categoria { trabalho, estudo, pessoal, outros }
enum Prioridade { alta, media, baixa }

class Tarefa {
  final String id;
  String titulo;
  String descricao;
  Categoria categoria;
  Prioridade prioridade;
  bool concluida;
  final DateTime criadaEm;
  DateTime? prazo;

  Tarefa({
    required this.id,
    required this.titulo,
    this.descricao = '',
    this.categoria = Categoria.pessoal,
    this.prioridade = Prioridade.media,
    this.concluida = false,
    DateTime? criadaEm,
    this.prazo,
  }) : criadaEm = criadaEm ?? DateTime.now();

  Map<String, dynamic> toJson() => {
        'id': id,
        'titulo': titulo,
        'descricao': descricao,
        'categoria': categoria.name,
        'prioridade': prioridade.name,
        'concluida': concluida,
        'criadaEm': criadaEm.toIso8601String(),
        'prazo': prazo?.toIso8601String(),
      };

  factory Tarefa.fromJson(Map<String, dynamic> j) => Tarefa(
        id: j['id'],
        titulo: j['titulo'],
        descricao: j['descricao'] ?? '',
        categoria: Categoria.values.byName(j['categoria']),
        prioridade: Prioridade.values.byName(j['prioridade']),
        concluida: j['concluida'] ?? false,
        criadaEm: DateTime.parse(j['criadaEm']),
        prazo: j['prazo'] != null ? DateTime.parse(j['prazo']) : null,
      );
}