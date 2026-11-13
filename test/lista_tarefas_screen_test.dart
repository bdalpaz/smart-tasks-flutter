import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smart_tasks/main.dart';
import 'package:smart_tasks/models/anexo.dart';
import 'package:smart_tasks/models/tarefa.dart';
import 'package:smart_tasks/providers/tarefa_provider.dart';

Future<void> _percorrerTransicao(WidgetTester tester) async {
  for (var i = 0; i < 40; i++) {
    await tester.pump(const Duration(milliseconds: 16));
  }
  await tester.pumpAndSettle();
}

void main() {
  for (final tamanho in [const Size(400, 800), const Size(1280, 800)]) {
    testWidgets(
        'abrir "Nova tarefa" e um cartão não gera erro na transição ($tamanho)',
        (tester) async {
      final tarefa = Tarefa(id: '1', titulo: 'Tarefa X');
      SharedPreferences.setMockInitialValues({
        'tarefas': jsonEncode([tarefa.toJson()]),
      });
      tester.view.physicalSize = tamanho;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(ChangeNotifierProvider(
        create: (_) => TarefaProvider()..carregar(),
        child: const MyApp(),
      ));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Nova tarefa'));
      await _percorrerTransicao(tester);
      expect(tester.takeException(), isNull);
      expect(find.byType(TextFormField), findsWidgets);

      await tester.pageBack();
      await tester.pumpAndSettle();

      await tester.tap(find.text('Tarefa X'));
      await _percorrerTransicao(tester);
      expect(tester.takeException(), isNull);
      expect(find.text('Detalhes da tarefa'), findsOneWidget);
    });
  }

  group('Detalhes da tarefa', () {
    Future<TarefaProvider> abrirApp(WidgetTester tester, Tarefa tarefa) async {
      SharedPreferences.setMockInitialValues({
        'tarefas': jsonEncode([tarefa.toJson()]),
      });
      tester.view.physicalSize = const Size(400, 800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      final provider = TarefaProvider()..carregar();
      await tester.pumpWidget(ChangeNotifierProvider.value(
        value: provider,
        child: const MyApp(),
      ));
      await tester.pumpAndSettle();
      return provider;
    }

    Future<void> abrirDetalhes(WidgetTester tester, String titulo) async {
      await tester.tap(find.text(titulo));
      await tester.pumpAndSettle();
      expect(find.text('Detalhes da tarefa'), findsOneWidget);
    }

    testWidgets('mostra descrição e situação do prazo', (tester) async {
      final agora = DateTime.now();
      await abrirApp(
        tester,
        Tarefa(
          id: '1',
          titulo: 'Relatório',
          descricao: 'Revisar os gráficos',
          prazo: DateTime(agora.year, agora.month, agora.day + 3),
        ),
      );
      await abrirDetalhes(tester, 'Relatório');

      expect(find.text('Revisar os gráficos'), findsOneWidget);
      expect(find.text('Faltam 3 dias'), findsOneWidget);
      expect(find.byType(LinearProgressIndicator), findsOneWidget);
    });

    testWidgets('sem prazo e sem descrição mostra os textos vazios',
        (tester) async {
      await abrirApp(tester, Tarefa(id: '1', titulo: 'Simples'));
      await abrirDetalhes(tester, 'Simples');

      expect(find.text('Sem prazo definido'), findsOneWidget);
      expect(find.text('Sem descrição'), findsOneWidget);
      expect(find.byType(LinearProgressIndicator), findsNothing);
    });

    testWidgets('editar volta para os detalhes já atualizados',
        (tester) async {
      await abrirApp(tester, Tarefa(id: '1', titulo: 'Antigo'));
      await abrirDetalhes(tester, 'Antigo');

      await tester.tap(find.widgetWithText(FilledButton, 'Editar'));
      await tester.pumpAndSettle();
      expect(find.text('Editar tarefa'), findsOneWidget);

      await tester.enterText(find.byType(TextFormField).first, 'Novo');
      await tester.tap(find.text('Salvar'));
      await tester.pumpAndSettle();

      expect(find.text('Detalhes da tarefa'), findsOneWidget);
      expect(find.text('Novo'), findsOneWidget);
    });

    testWidgets('mostra os anexos e editar a tarefa não os perde',
        (tester) async {
      final provider = await abrirApp(
        tester,
        Tarefa(id: '1', titulo: 'Com anexo', anexos: [
          Anexo(id: 'a', nome: 'contrato.pdf', tamanho: 2048),
        ]),
      );
      await abrirDetalhes(tester, 'Com anexo');
      expect(find.text('Anexos (1)'), findsOneWidget);
      expect(find.text('contrato.pdf'), findsOneWidget);
      expect(find.text('2,0 KB'), findsOneWidget);

      await tester.tap(find.widgetWithText(FilledButton, 'Editar'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextFormField).first, 'Renomeada');
      await tester.tap(find.text('Salvar'));
      await tester.pumpAndSettle();

      expect(provider.tarefaPor('1')!.anexos.single.nome, 'contrato.pdf');
      expect(find.text('contrato.pdf'), findsOneWidget);
    });

    testWidgets('concluir e reabrir pelos detalhes', (tester) async {
      final provider =
          await abrirApp(tester, Tarefa(id: '1', titulo: 'Tarefa X'));
      await abrirDetalhes(tester, 'Tarefa X');

      await tester.tap(find.text('Marcar como concluída'));
      await tester.pump();
      expect(provider.tarefaPor('1')!.concluida, isTrue);

      await tester.tap(find.text('Reabrir tarefa'));
      await tester.pump();
      expect(provider.tarefaPor('1')!.concluida, isFalse);
    });

    testWidgets('excluir fecha os detalhes e permite desfazer',
        (tester) async {
      final provider =
          await abrirApp(tester, Tarefa(id: '1', titulo: 'Tarefa X'));
      await abrirDetalhes(tester, 'Tarefa X');

      await tester.tap(find.byTooltip('Excluir'));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.text('Detalhes da tarefa'), findsNothing);
      expect(provider.total, 0);
      expect(find.text('"Tarefa X" excluída'), findsOneWidget);

      await tester.tap(find.text('Desfazer'));
      await tester.pumpAndSettle();
      expect(provider.total, 1);
      expect(find.text('Tarefa X'), findsOneWidget);
    });
  });
}
