/// Arquivo anexado a uma tarefa.
///
/// Guarda só os metadados. O arquivo é uma cópia feita na pasta do app (ver
/// `AnexoStorage`), localizada a partir dos ids e do nome; o caminho absoluto
/// não é gravado porque a pasta do app pode mudar entre instalações.
class Anexo {
  final String id;
  final String nome;

  /// Em bytes, medido na cópia.
  final int tamanho;
  final DateTime adicionadoEm;

  Anexo({
    required this.id,
    required this.nome,
    required this.tamanho,
    DateTime? adicionadoEm,
  }) : adicionadoEm = adicionadoEm ?? DateTime.now();

  static const _extensoesDeImagem = {'jpg', 'jpeg', 'png', 'gif', 'webp', 'bmp'};

  String get extensao {
    final ponto = nome.lastIndexOf('.');
    return ponto == -1 ? '' : nome.substring(ponto + 1).toLowerCase();
  }

  bool get ehImagem => _extensoesDeImagem.contains(extensao);

  Map<String, dynamic> toJson() => {
        'id': id,
        'nome': nome,
        'tamanho': tamanho,
        'adicionadoEm': adicionadoEm.toIso8601String(),
      };

  factory Anexo.fromJson(Map<String, dynamic> j) => Anexo(
        id: j['id'] as String,
        nome: j['nome'] as String,
        tamanho: j['tamanho'] as int? ?? 0,
        adicionadoEm: DateTime.tryParse(j['adicionadoEm'] as String? ?? ''),
      );
}

/// "820 B", "14,2 KB", "3,5 MB".
String formatarTamanho(int bytes) {
  if (bytes < 1024) return '$bytes B';
  const unidades = ['KB', 'MB', 'GB'];
  var valor = bytes / 1024;
  var i = 0;
  while (valor >= 1024 && i < unidades.length - 1) {
    valor /= 1024;
    i++;
  }
  return '${valor.toStringAsFixed(1).replaceAll('.', ',')} ${unidades[i]}';
}
