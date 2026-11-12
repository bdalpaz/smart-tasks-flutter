/// Categoria de uma tarefa.
///
/// Era um `enum` fixo. Virou dado persistido para que o usuário possa criar as
/// próprias categorias. O `id` é o que fica gravado dentro da tarefa e nunca
/// muda; `nome` e `cor` são apresentação e podem ser editados sem afetar as
/// tarefas.
class Categoria {
  final String id;
  String nome;

  /// ARGB. Guardado como `int` porque `Color` não é serializável em JSON.
  int cor;

  Categoria({required this.id, required this.nome, required this.cor});

  /// Cores oferecidas ao usuário. Escolhidas com saturação parecida para que
  /// nenhuma domine a lista, e claras o bastante para o tema escuro — onde
  /// ainda recebem um ajuste de luminosidade (ver `corLegivel` em theme.dart).
  static const paleta = <int>[
    0xFF1E88E5, // azul
    0xFF8E24AA, // roxo
    0xFF43A047, // verde
    0xFFF4511E, // laranja
    0xFF00897B, // verde-azulado
    0xFFD81B60, // rosa
    0xFF3949AB, // índigo
    0xFF6D4C41, // marrom
  ];

  /// Ids das categorias originais. São mantidos iguais aos nomes do antigo
  /// `enum` para que tarefas gravadas antes desta mudança continuem válidas.
  static List<Categoria> padroes() => [
        Categoria(id: 'trabalho', nome: 'Trabalho', cor: paleta[0]),
        Categoria(id: 'estudo', nome: 'Estudo', cor: paleta[1]),
        Categoria(id: 'pessoal', nome: 'Pessoal', cor: paleta[2]),
        Categoria(id: 'outros', nome: 'Outros', cor: paleta[3]),
      ];

  /// Usado quando uma tarefa aponta para uma categoria que não existe mais.
  static const nomeDesconhecida = 'Sem categoria';
  static const corPadrao = 0xFF78909C;

  Map<String, dynamic> toJson() => {'id': id, 'nome': nome, 'cor': cor};

  factory Categoria.fromJson(Map<String, dynamic> j) => Categoria(
        id: j['id'] as String,
        nome: j['nome'] as String,
        // Categorias gravadas antes de existir cor não têm a chave.
        cor: j['cor'] as int? ?? corPadrao,
      );
}
