import 'package:flutter_test/flutter_test.dart';
import 'package:smart_tasks/models/tarefa.dart';

/// Meia-noite de hoje, que é a referência usada por [Tarefa.atrasada].
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
      // Exatamente o formato que a versão anterior gravava: a categoria era
      // `Categoria.trabalho.name`, que hoje é o id da categoria padrão.
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
}
