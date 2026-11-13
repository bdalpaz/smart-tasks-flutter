import 'package:flutter_test/flutter_test.dart';
import 'package:smart_tasks/layout_responsivo.dart';

double larguraPorCartao(double janela) {
  final colunas = colunasPara(janela);
  return larguraDoConteudo(janela, colunas) / colunas;
}

double sobra(double janela) =>
    janela - larguraDoConteudo(janela, colunasPara(janela));

void main() {
  group('número de colunas', () {
    test('celular usa uma coluna', () {
      expect(colunasPara(390), 1);
      expect(colunasPara(430), 1);
    });

    test('janela média usa duas colunas', () {
      expect(colunasPara(770), 2);
      expect(colunasPara(1000), 2);
    });

    test('janela larga usa três colunas', () {
      expect(colunasPara(1200), 3);
      expect(colunasPara(1550), 3);
    });

    test('nunca passa do teto, por mais larga que seja a tela', () {
      expect(colunasPara(4000), maxColunas);
    });

    test('nunca devolve zero coluna, por mais estreita que seja a tela', () {
      expect(colunasPara(240), 1);
      expect(colunasPara(1), 1);
    });
  });

  group('largura do conteúdo', () {
    test('ocupa a janela inteira quando ela cabe no teto', () {
      expect(larguraDoConteudo(390, 1), 390);
      expect(larguraDoConteudo(770, 2), 770);
      expect(larguraDoConteudo(1550, 3), 1550);
    });

    test('para de crescer no máximo por coluna', () {
      expect(larguraDoConteudo(4000, 3), 3 * larguraMaximaDoCartao);
    });
  });

  group('a janela é realmente aproveitada', () {
    test('janela de 770 não deixa sobra', () {
      expect(sobra(770), 0);
    });

    test('nenhuma largura comum desperdiça espaço', () {
      for (final janela in [360.0, 390.0, 500.0, 720.0, 770.0, 900.0, 1199.0, 1280.0, 1550.0]) {
        expect(sobra(janela), 0, reason: 'janela de $janela deixou sobra');
      }
    });

    test('o cartão fica sempre dentro da faixa aceitável', () {
      for (var janela = larguraMinimaDoCartao; janela <= 2000; janela += 10) {
        final largura = larguraPorCartao(janela);
        expect(largura, greaterThanOrEqualTo(larguraMinimaDoCartao),
            reason: 'cartão estreito demais em $janela');
        expect(largura, lessThanOrEqualTo(larguraMaximaDoCartao),
            reason: 'cartão largo demais em $janela');
      }
    });

    test('abaixo do mínimo o cartão encolhe junto, sem estourar a tela', () {
      expect(larguraPorCartao(240), 240);
    });
  });
}
