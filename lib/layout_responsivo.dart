library;

const larguraMinimaDoCartao = 360.0;
const larguraMaximaDoCartao = 560.0;

const maxColunas = 3;

int colunasPara(double largura) =>
    (largura / larguraMinimaDoCartao).floor().clamp(1, maxColunas);

double larguraDoConteudo(double largura, int colunas) {
  final teto = colunas * larguraMaximaDoCartao;
  return largura < teto ? largura : teto;
}
