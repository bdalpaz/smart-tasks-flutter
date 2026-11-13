import 'dart:io';

import 'package:file_selector/file_selector.dart' show XFile;
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import '../models/anexo.dart';

class AnexoStorage {
  AnexoStorage({Future<Directory> Function()? raiz})
      : _obterRaiz = raiz ?? _raizPadrao;

  final Future<Directory> Function() _obterRaiz;
  Future<Directory>? _raiz;
  int _sequencia = 0;

  static Future<Directory> _raizPadrao() async => Directory(
      p.join((await getApplicationSupportDirectory()).path, 'anexos'));

  Future<Directory> raiz() => _raiz ??= _obterRaiz();

  static String caminhoEm(Directory raiz, String tarefaId, Anexo anexo) =>
      p.join(raiz.path, tarefaId, anexo.id, anexo.nome);

  Future<String> caminho(String tarefaId, Anexo anexo) async =>
      caminhoEm(await raiz(), tarefaId, anexo);

  Future<Anexo> guardar(String tarefaId, XFile origem) async {
    final id = '${DateTime.now().microsecondsSinceEpoch}${_sequencia++}';
    final nome = _nomeSeguro(origem.name);
    final destino = File(p.join((await raiz()).path, tarefaId, id, nome));
    await destino.parent.create(recursive: true);
    try {
      await origem.saveTo(destino.path);
      return Anexo(id: id, nome: nome, tamanho: await destino.length());
    } catch (_) {
      await _apagarPasta(destino.parent);
      rethrow;
    }
  }

  Future<void> apagar(String tarefaId, Anexo anexo) async =>
      _apagarPasta(Directory(p.join((await raiz()).path, tarefaId, anexo.id)));

  Future<void> apagarDaTarefa(String tarefaId) async =>
      _apagarPasta(Directory(p.join((await raiz()).path, tarefaId)));

  Future<void> limparOrfaos(Map<String, Set<String>> validos) async {
    final dir = await raiz();
    if (!await dir.exists()) return;
    await for (final pastaTarefa in dir.list()) {
      final anexos = validos[p.basename(pastaTarefa.path)];
      if (anexos == null) {
        await pastaTarefa.delete(recursive: true);
        continue;
      }
      if (pastaTarefa is! Directory) continue;
      await for (final pastaAnexo in pastaTarefa.list()) {
        if (!anexos.contains(p.basename(pastaAnexo.path))) {
          await pastaAnexo.delete(recursive: true);
        }
      }
    }
  }

  static Future<void> _apagarPasta(Directory pasta) async {
    if (await pasta.exists()) await pasta.delete(recursive: true);
  }

  static String _nomeSeguro(String nome) {
    final base = p.basename(nome.replaceAll('\\', '/')).trim();
    return (base.isEmpty || base == '.' || base == '..') ? 'anexo' : base;
  }
}
