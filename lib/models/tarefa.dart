import 'anexo.dart';

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

  String categoriaId;
  Prioridade prioridade;
  bool concluida;
  final DateTime criadaEm;
  DateTime? prazo;
  final List<Anexo> anexos;

  Tarefa({
    required this.id,
    required this.titulo,
    this.descricao = '',
    this.categoriaId = 'pessoal',
    this.prioridade = Prioridade.media,
    this.concluida = false,
    DateTime? criadaEm,
    this.prazo,
    List<Anexo>? anexos,
  })  : criadaEm = criadaEm ?? DateTime.now(),
        anexos = anexos ?? [];

  bool get atrasada {
    if (concluida || prazo == null) return false;
    final agora = DateTime.now();
    final hoje = DateTime(agora.year, agora.month, agora.day);
    return prazo!.isBefore(hoje);
  }

  int? diasAtePrazo([DateTime? agora]) {
    if (prazo == null) return null;
    final h = agora ?? DateTime.now();
    final p = prazo!;
    return DateTime.utc(p.year, p.month, p.day)
        .difference(DateTime.utc(h.year, h.month, h.day))
        .inDays;
  }

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

  double? progressoPrazo([DateTime? agora]) {
    if (prazo == null) return null;
    final h = agora ?? DateTime.now();
    final p = prazo!;
    final fim = DateTime(p.year, p.month, p.day + 1);
    final total = fim.difference(criadaEm).inMinutes;
    if (total <= 0) return 1;
    return (h.difference(criadaEm).inMinutes / total).clamp(0.0, 1.0);
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'titulo': titulo,
        'descricao': descricao,
        'categoria': categoriaId,
        'prioridade': prioridade.name,
        'concluida': concluida,
        'criadaEm': criadaEm.toIso8601String(),
        'prazo': prazo?.toIso8601String(),
        'anexos': anexos.map((a) => a.toJson()).toList(),
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
        anexos: (j['anexos'] as List? ?? [])
            .map((a) => Anexo.fromJson(a as Map<String, dynamic>))
            .toList(),
      );
}
