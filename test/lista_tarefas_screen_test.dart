import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smart_tasks/main.dart';
import 'package:smart_tasks/models/tarefa.dart';
import 'package:smart_tasks/providers/tarefa_provider.dart';

/// Avança a transição do OpenContainer quadro a quadro: o erro que este teste
/// protege aparecia em um único frame no meio da animação, e um
/// `pumpAndSettle` direto poderia pulá-lo.
Future<void> _percorrerTransicao(WidgetTester tester) async {
  for (var i = 0; i < 40; i++) {
    await tester.pump(const Duration(milliseconds: 16));
  }
  await tester.pumpAndSettle();
}

void main() {
  // Estreita (uma coluna) e larga (grade): o OpenContainer anima de posições
  // diferentes em cada caso.
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
      expect(find.text('Editar tarefa'), findsOneWidget);
    });
  }
}
