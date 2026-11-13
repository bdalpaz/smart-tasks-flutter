import 'package:flutter_test/flutter_test.dart';
import 'package:smart_tasks/models/tarefa.dart';

DateTime hoje() {
  final agora = DateTime.now();
  return DateTime(agora.year, agora.month, agora.day);
}

void main() {
  group('Tarefa.atrasada', () {
    test('prazo vencido e tarefa pendente conta como atrasada', () {
      final t = Tarefa(
        id: '1',
        titulo: 'X',
        prazo: hoje().subtract(const Duration(days: 1)),
      );
      expect(t.atrasada, isTrue);
    });

    test('prazo que vence hoje ainda não está atrasado', () {
      final t = Tarefa(id: '1', titulo: 'X', prazo: hoje());
      expect(t.atrasada, isFalse);
    });

    test('tarefa concluída nunca aparece como atrasada', () {
      final t = Tarefa(
        id: '1',
        titulo: 'X',
        concluida: true,
        prazo: hoje().subtract(const Duration(days: 10)),
      );
      expect(t.atrasada, isFalse);
    });

    test('tarefa sem prazo nunca está atrasada', () {
      expect(Tarefa(id: '1', titulo: 'X').atrasada, isFalse);
    });
  });

  group('serialização', () {
    test('ida e volta por JSON preserva todos os campos', () {
      final original = Tarefa(
        id: '42',
        titulo: 'Entregar o TPE',
        descricao: 'slides e código',
        categoriaId: 'estudo',
        prioridade: Prioridade.alta,
        concluida: true,
        criadaEm: DateTime(2026, 11, 1, 9, 30),
        prazo: DateTime(2026, 11, 13),
      );

      final copia = Tarefa.fromJson(original.toJson());

      expect(copia.id, original.id);
      expect(copia.titulo, original.titulo);
      expect(copia.descricao, original.descricao);
      expect(copia.categoriaId, original.categoriaId);
      expect(copia.prioridade, original.prioridade);
      expect(copia.concluida, original.concluida);
      expect(copia.criadaEm, original.criadaEm);
      expect(copia.prazo, original.prazo);
    });

    test('tarefa sem prazo volta sem prazo', () {
      final copia = Tarefa.fromJson(Tarefa(id: '1', titulo: 'X').toJson());
      expect(copia.prazo, isNull);
    });
  });

  group('compatibilidade com dados antigos', () {
    test('tarefa gravada pela versão com enum continua sendo lida', () {
      final antiga = Tarefa.fromJson({
        'id': '1',
        'titulo': 'Tarefa antiga',
        'descricao': '',
        'categoria': 'trabalho',
        'prioridade': 'alta',
        'concluida': false,
        'criadaEm': '2026-11-01T09:00:00.000',
        'prazo': null,
      });

      expect(antiga.categoriaId, 'trabalho');
      expect(antiga.prioridade, Prioridade.alta);
    });

    test('tarefa sem categoria gravada cai em "outros"', () {
      final semCategoria = Tarefa.fromJson({
        'id': '1',
        'titulo': 'X',
        'prioridade': 'media',
        'criadaEm': '2026-11-01T09:00:00.000',
      });

      expect(semCategoria.categoriaId, 'outros');
    });
  });

  group('rótulos e formatação', () {
    test('prioridades têm rótulo em português', () {
      expect(Prioridade.alta.label, 'Alta');
      expect(Prioridade.media.label, 'Média');
      expect(Prioridade.baixa.label, 'Baixa');
    });

    test('formatarData usa dd/mm/aaaa com zero à esquerda', () {
      expect(formatarData(DateTime(2026, 11, 3)), '03/11/2026');
    });
  });

  group('Acompanhamento do prazo', () {
    final agora = DateTime(2026, 3, 10, 15, 30);
    Tarefa comPrazo(DateTime? prazo, {bool concluida = false}) => Tarefa(
          id: '1',
          titulo: 'X',
          prazo: prazo,
          concluida: concluida,
          criadaEm: DateTime(2026, 3, 1, 9),
        );

    test('conta dias de calendário, não horas', () {
      expect(comPrazo(DateTime(2026, 3, 10)).diasAtePrazo(agora), 0);
      expect(comPrazo(DateTime(2026, 3, 11)).diasAtePrazo(agora), 1);
      expect(comPrazo(DateTime(2026, 3, 8)).diasAtePrazo(agora), -2);
    });

    test('atravessar a mudança de horário de verão não perde um dia', () {
      final antes = DateTime(2026, 10, 30, 12);
      expect(comPrazo(DateTime(2026, 11, 5)).diasAtePrazo(antes), 6);
    });

    test('descrição cobre hoje, amanhã, futuro e atraso', () {
      String? d(DateTime prazo) => comPrazo(prazo).descricaoPrazo(agora);
      expect(d(DateTime(2026, 3, 10)), 'Vence hoje');
      expect(d(DateTime(2026, 3, 11)), 'Vence amanhã');
      expect(d(DateTime(2026, 3, 15)), 'Faltam 5 dias');
      expect(d(DateTime(2026, 3, 9)), 'Atrasada há 1 dia');
      expect(d(DateTime(2026, 3, 4)), 'Atrasada há 6 dias');
    });

    test('descrição concorda com atrasada no dia do prazo', () {
      final t = comPrazo(hoje());
      expect(t.atrasada, isFalse);
      expect(t.descricaoPrazo(), 'Vence hoje');
    });

    test('tarefa concluída mostra "Concluída" mesmo com prazo vencido', () {
      final t = comPrazo(DateTime(2026, 3, 1), concluida: true);
      expect(t.descricaoPrazo(agora), 'Concluída');
    });

    test('sem prazo não há descrição nem progresso', () {
      final t = comPrazo(null);
      expect(t.diasAtePrazo(agora), isNull);
      expect(t.descricaoPrazo(agora), isNull);
      expect(t.progressoPrazo(agora), isNull);
    });

    test('progresso vai da criação até o fim do dia do prazo', () {
      final t = comPrazo(DateTime(2026, 3, 10));
      expect(t.progressoPrazo(DateTime(2026, 3, 1, 9)), 0);
      expect(t.progressoPrazo(DateTime(2026, 3, 11)), 1);
      expect(t.progressoPrazo(agora), closeTo(0.963, 0.005));
    });

    test('progresso fica entre 0 e 1 fora do intervalo', () {
      final t = comPrazo(DateTime(2026, 3, 10));
      expect(t.progressoPrazo(DateTime(2026, 2, 1)), 0);
      expect(t.progressoPrazo(DateTime(2026, 4, 1)), 1);
    });

    test('prazo anterior à criação conta como tempo esgotado', () {
      expect(comPrazo(DateTime(2026, 2, 20)).progressoPrazo(agora), 1);
    });
  });
}
