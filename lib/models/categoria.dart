class Categoria {
  final String id;
  String nome;

  int cor;

  Categoria({required this.id, required this.nome, required this.cor});

  static const paleta = <int>[
    0xFF1E88E5,
    0xFF8E24AA,
    0xFF43A047,
    0xFFF4511E,
    0xFF00897B,
    0xFFD81B60,
    0xFF3949AB,
    0xFF6D4C41,
  ];

  static List<Categoria> padroes() => [
        Categoria(id: 'trabalho', nome: 'Trabalho', cor: paleta[0]),
        Categoria(id: 'estudo', nome: 'Estudo', cor: paleta[1]),
        Categoria(id: 'pessoal', nome: 'Pessoal', cor: paleta[2]),
        Categoria(id: 'outros', nome: 'Outros', cor: paleta[3]),
      ];

  static const nomeDesconhecida = 'Sem categoria';
  static const corPadrao = 0xFF78909C;

  Map<String, dynamic> toJson() => {'id': id, 'nome': nome, 'cor': cor};

  factory Categoria.fromJson(Map<String, dynamic> j) => Categoria(
        id: j['id'] as String,
        nome: j['nome'] as String,
        cor: j['cor'] as int? ?? corPadrao,
      );
}
