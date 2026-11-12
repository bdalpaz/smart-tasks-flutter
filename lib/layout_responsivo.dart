/// Regras de adaptação da lista de tarefas à largura disponível.
///
/// Ficam fora da tela de propósito: assim dá para testá-las sem montar widget
/// nenhum. A regra já errou de duas formas opostas — esticar o cartão até
/// ocupar a janela inteira, e depois travá-lo tão estreito que sobrava metade
/// da tela vazia —, então ela merece teste próprio.
library;

/// Faixa de larguras aceitável para um cartão de tarefa.
///
/// Abaixo do mínimo o título quebra demais; acima do máximo o checkbox fica a
/// meia tela do texto.
const larguraMinimaDoCartao = 360.0;
const larguraMaximaDoCartao = 560.0;

/// Mais do que três colunas vira varredura de planilha, não lista de tarefas.
const maxColunas = 3;

/// Quantas colunas cabem na largura disponível, respeitando o mínimo por
/// cartão. Nunca devolve menos de uma, mesmo numa tela absurdamente estreita.
int colunasPara(double largura) =>
    (largura / larguraMinimaDoCartao).floor().clamp(1, maxColunas);

/// Largura que o conteúdo deve ocupar.
///
/// Preenche tudo o que houver, a não ser que isso ultrapasse o máximo por
/// coluna — nesse caso sobra margem dos dois lados, de propósito.
double larguraDoConteudo(double largura, int colunas) {
  final teto = colunas * larguraMaximaDoCartao;
  return largura < teto ? largura : teto;
}
