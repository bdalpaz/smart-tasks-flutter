import 'dart:convert';
import 'dart:io';

import 'package:file_selector/file_selector.dart' show XFile;
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smart_tasks/data/anexo_storage.dart';
import 'package:smart_tasks/models/anexo.dart';
import 'package:smart_tasks/models/tarefa.dart';
import 'package:smart_tasks/providers/tarefa_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory temp;
  late Directory raiz;
  late AnexoStorage storage;

  /// Um arquivo "do usuário", fora da pasta de anexos.
  Future<XFile> arquivo(String nome, [String conteudo = 'conteúdo']) async {
    final f = File(p.join(temp.path, 'origem', nome));
    await f.parent.create(recursive: true);
    await f.writeAsString(conteudo);
    return XFile(f.path);
  }

  /// Nomes das entradas diretas de uma pasta, para conferir o que sobrou.
  Future<Set<String>> conteudo(Directory dir) async => {
        if (await dir.exists())
          await for (final e in dir.list()) p.basename(e.path),
      };

  setUp(() async {
    temp = await Directory.systemTemp.createTemp('anexos_test');
    raiz = Directory(p.join(temp.path, 'anexos'));
    storage = AnexoStorage(raiz: () async => raiz);
  });

  tearDown(() => temp.delete(recursive: true));

  group('Anexo', () {
    test('reconhece imagem pela extensão, sem diferenciar maiúsculas', () {
      expect(Anexo(id: '1', nome: 'foto.JPG', tamanho: 0).ehImagem, isTrue);
      expect(Anexo(id: '1', nome: 'nota.pdf', tamanho: 0).ehImagem, isFalse);
      expect(Anexo(id: '1', nome: 'sem_extensao', tamanho: 0).extensao, '');
    });

    test('formatarTamanho', () {
      expect(formatarTamanho(820), '820 B');
      expect(formatarTamanho(14540), '14,2 KB');
      expect(formatarTamanho(3670016), '3,5 MB');
    });

    test('tarefa gravada antes dos anexos carrega com a lista vazia', () {
      final json = Tarefa(id: '1', titulo: 'X').toJson()..remove('anexos');
      expect(Tarefa.fromJson(json).anexos, isEmpty);
    });

    test('anexos sobrevivem à ida e volta pelo JSON', () {
      final t = Tarefa(id: '1', titulo: 'X', anexos: [
        Anexo(id: 'a', nome: 'foto.png', tamanho: 42),
      ]);
      final lido = Tarefa.fromJson(jsonDecode(jsonEncode(t.toJson())));
      expect(lido.anexos.single.nome, 'foto.png');
      expect(lido.anexos.single.tamanho, 42);
    });
  });

  group('AnexoStorage', () {
    test('guarda uma cópia, independente do arquivo original', () async {
      final origem = await arquivo('relatorio.pdf', 'abc');
      final anexo = await storage.guardar('t1', origem);

      await File(origem.path).delete();
      final copia = File(await storage.caminho('t1', anexo));
      expect(await copia.readAsString(), 'abc');
      expect(anexo.nome, 'relatorio.pdf');
      expect(anexo.tamanho, 3);
    });

    test('dois anexos com o mesmo nome não se sobrescrevem', () async {
      final a = await storage.guardar('t1', await arquivo('x.txt', 'um'));
      final b = await storage.guardar('t1', await arquivo('x.txt', 'dois'));

      expect(a.id, isNot(b.id));
      expect(await File(await storage.caminho('t1', a)).readAsString(), 'um');
      expect(await File(await storage.caminho('t1', b)).readAsString(), 'dois');
    });

    test('apagar remove só aquele anexo', () async {
      final a = await storage.guardar('t1', await arquivo('a.txt'));
      final b = await storage.guardar('t1', await arquivo('b.txt'));
      await storage.apagar('t1', a);

      expect(await File(await storage.caminho('t1', a)).exists(), isFalse);
      expect(await File(await storage.caminho('t1', b)).exists(), isTrue);
    });

    test('limparOrfaos apaga tarefas e anexos que não existem mais', () async {
      final fica = await storage.guardar('t1', await arquivo('a.txt'));
      final sai = await storage.guardar('t1', await arquivo('b.txt'));
      await storage.guardar('t2', await arquivo('c.txt'));

      await storage.limparOrfaos({
        't1': {fica.id},
      });

      expect(await conteudo(raiz), {'t1'});
      expect(await conteudo(Directory(p.join(raiz.path, 't1'))), {fica.id});
      expect(sai.id, isNot(fica.id));
    });

    test('limparOrfaos sem pasta de anexos não falha', () async {
      await storage.limparOrfaos({});
      expect(await raiz.exists(), isFalse);
    });
  });

  group('TarefaProvider e anexos', () {
    Future<TarefaProvider> provedorCom(List<Tarefa> tarefas) async {
      SharedPreferences.setMockInitialValues({
        'tarefas': jsonEncode(tarefas.map((t) => t.toJson()).toList()),
      });
      final provider = TarefaProvider(anexos: storage);
      await provider.carregar();
      return provider;
    }

    test('anexar persiste e sobrevive a recarregar o app', () async {
      final provider = await provedorCom([Tarefa(id: 't1', titulo: 'X')]);
      final falhas = await provider.anexar(
          't1', [await arquivo('a.png'), await arquivo('b.pdf')]);
      expect(falhas, 0);

      final reaberto = TarefaProvider(anexos: storage);
      await reaberto.carregar();
      expect(reaberto.tarefaPor('t1')!.anexos.map((a) => a.nome),
          ['a.png', 'b.pdf']);
    });

    test('arquivo que falha não impede os outros', () async {
      final provider = await provedorCom([Tarefa(id: 't1', titulo: 'X')]);
      final falhas = await provider.anexar('t1', [
        XFile(p.join(temp.path, 'nao_existe.txt')),
        await arquivo('ok.txt'),
      ]);

      expect(falhas, 1);
      expect(provider.tarefaPor('t1')!.anexos.single.nome, 'ok.txt');
    });

    test('remover anexo apaga o arquivo', () async {
      final provider = await provedorCom([Tarefa(id: 't1', titulo: 'X')]);
      await provider.anexar('t1', [await arquivo('a.txt')]);
      final anexo = provider.tarefaPor('t1')!.anexos.single;
      final caminho = await storage.caminho('t1', anexo);

      await provider.removerAnexo('t1', anexo);
      expect(provider.tarefaPor('t1')!.anexos, isEmpty);
      expect(await File(caminho).exists(), isFalse);
    });

    test('excluir mantém os arquivos até o "Desfazer" expirar', () async {
      final provider = await provedorCom([Tarefa(id: 't1', titulo: 'X')]);
      await provider.anexar('t1', [await arquivo('a.txt')]);
      final tarefa = provider.tarefaPor('t1')!;
      final caminho = await storage.caminho('t1', tarefa.anexos.single);

      await provider.excluir('t1');
      expect(await File(caminho).exists(), isTrue,
          reason: 'ainda dá para desfazer');

      await provider.descartarAnexosDeExcluida('t1');
      expect(await File(caminho).exists(), isFalse);
    });

    test('desfazer a exclusão preserva os arquivos', () async {
      final provider = await provedorCom([Tarefa(id: 't1', titulo: 'X')]);
      await provider.anexar('t1', [await arquivo('a.txt')]);
      final tarefa = provider.tarefaPor('t1')!;
      final caminho = await storage.caminho('t1', tarefa.anexos.single);

      await provider.excluir('t1');
      await provider.adicionar(tarefa);
      await provider.descartarAnexosDeExcluida('t1');
      expect(await File(caminho).exists(), isTrue);
    });

    test('ao abrir o app, apaga arquivos de tarefas que sumiram', () async {
      await storage.guardar('fantasma', await arquivo('a.txt'));
      await provedorCom([Tarefa(id: 't1', titulo: 'X')]);
      expect(await conteudo(raiz), isEmpty);
    });

    test('dados ilegíveis não disparam a limpeza dos arquivos', () async {
      await storage.guardar('t1', await arquivo('a.txt'));
      SharedPreferences.setMockInitialValues({'tarefas': 'isso não é json'});
      await TarefaProvider(anexos: storage).carregar();
      expect(await conteudo(raiz), {'t1'},
          reason: 'a lista vazia não reflete o que o usuário tinha');
    });
  });
}
