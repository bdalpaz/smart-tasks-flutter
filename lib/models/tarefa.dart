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

  /// Dias de calendário entre hoje e o prazo: 0 vence hoje, negativo já venceu.
  /// `null` sem prazo. Conta pela data, não pelas horas, para concordar com
  /// [atrasada]; e em UTC, para que o horário de verão não tire um dia.
  int? diasAtePrazo([DateTime? agora]) {
    if (prazo == null) return null;
    final h = agora ?? DateTime.now();
    final p = prazo!;
    return DateTime.utc(p.year, p.month, p.day)
        .difference(DateTime.utc(h.year, h.month, h.day))
        .inDays;
  }

  /// Texto curto da situação do prazo, como "Faltam 3 dias".
  String? descricaoPrazo([DateTime? agora]) {
    final dias = diasAtePrazo(agora);
    if (dias == null) return null;
    if (concluida) return 'Concluída';
    return switch (dias) {
      0 => 'Vence hoje',
      1 => 'Vence amanhã',
      -1 => 'Atrasada há 1 dia',
      < 0 => 'Atrasada há ${-dias} dias',
      _ => 'Faltam $dias dias',
    };
  }

  /// Fração do tempo já consumido, da criação até o fim do dia do prazo
  /// (0 a 1). O dia do prazo conta como disponível, assim como em [atrasada].
  double? progressoPrazo([DateTime? agora]) {
    if (prazo == null) return null;
    final h = agora ?? DateTime.now();
    final p = prazo!;
    final fim = DateTime(p.year, p.month, p.day + 1);
    final total = fim.difference(criadaEm).inMinutes;
    // Prazo anterior à criação (data retroativa): já não há tempo algum.
    if (total <= 0) return 1;
    return (h.difference(criadaEm).inMinutes / total).clamp(0.0, 1.0);
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
