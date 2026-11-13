import 'package:file_selector/file_selector.dart' show XFile;
import 'package:flutter/foundation.dart';
import '../data/anexo_storage.dart';
import '../data/categoria_repository.dart';
import '../data/tarefa_repository.dart';
import '../models/anexo.dart';
import '../models/categoria.dart';
import '../models/tarefa.dart';

enum ResultadoExclusaoCategoria { excluida, emUso, ultimaRestante }

class TarefaProvider extends ChangeNotifier {
  TarefaProvider({AnexoStorage? anexos})
      : armazenamentoAnexos = anexos ?? AnexoStorage();

  final _repo = TarefaRepository();
  final _repoCategorias = CategoriaRepository();

  final AnexoStorage armazenamentoAnexos;

  static bool get anexosDisponiveis => !kIsWeb;

  List<Tarefa> _tarefas = [];
  List<Categoria> _categorias = [];
  bool _carregando = true;

  String busca = '';
  String? filtroCategoriaId;
  Prioridade? filtroPrioridade;
  bool? filtroConcluida;

  bool get carregando => _carregando;

  List<Categoria> get categorias => List.unmodifiable(_categorias);

  int get pendentes => _tarefas.where((t) => !t.concluida).length;

  int get total => _tarefas.length;

  bool get filtrando =>
      busca.isNotEmpty ||
      filtroCategoriaId != null ||
      filtroPrioridade != null ||
      filtroConcluida != null;

  Categoria? categoriaPor(String id) {
    for (final c in _categorias) {
      if (c.id == id) return c;
    }
    return null;
  }

  String nomeCategoria(String id) =>
      categoriaPor(id)?.nome ?? Categoria.nomeDesconhecida;

  int corCategoria(String id) => categoriaPor(id)?.cor ?? Categoria.corPadrao;

  Tarefa? tarefaPor(String id) {
    for (final t in _tarefas) {
      if (t.id == id) return t;
    }
    return null;
  }

  List<Tarefa> get tarefas {
    final termo = busca.toLowerCase();
    final lista = _tarefas.where((t) {
      if (termo.isNotEmpty &&
          !t.titulo.toLowerCase().contains(termo) &&
          !t.descricao.toLowerCase().contains(termo)) {
        return false;
      }
      if (filtroCategoriaId != null && t.categoriaId != filtroCategoriaId) {
        return false;
      }
      if (filtroPrioridade != null && t.prioridade != filtroPrioridade) {
        return false;
      }
      if (filtroConcluida != null && t.concluida != filtroConcluida) {
        return false;
      }
      return true;
    }).toList();

    lista.sort((a, b) {
      if (a.concluida != b.concluida) return a.concluida ? 1 : -1;
      if (a.atrasada != b.atrasada) return a.atrasada ? -1 : 1;
      final p = a.prioridade.index.compareTo(b.prioridade.index);
      if (p != 0) return p;
      if (a.prazo == null && b.prazo == null) return 0;
      if (a.prazo == null) return 1;
      if (b.prazo == null) return -1;
      return a.prazo!.compareTo(b.prazo!);
    });
    return lista;
  }

  Future<void> carregar() async {
    _categorias = await _repoCategorias.carregar();
    _tarefas = await _repo.carregar();
    _carregando = false;
    notifyListeners();
    if (anexosDisponiveis && !_repo.leituraFalhou) await _limparAnexosOrfaos();
  }

  Future<void> _limparAnexosOrfaos() async {
    try {
      await armazenamentoAnexos.limparOrfaos({
        for (final t in _tarefas) t.id: {for (final a in t.anexos) a.id},
      });
    } catch (e) {
      debugPrint('Falha ao limpar anexos órfãos: $e');
    }
  }

  Future<void> _persistir() async {
    notifyListeners();
    await _repo.salvar(_tarefas);
  }

  Future<void> _persistirCategorias() async {
    notifyListeners();
    await _repoCategorias.salvar(_categorias);
  }

  Future<void> adicionar(Tarefa t) async {
    _tarefas.add(t);
    await _persistir();
  }

  Future<void> atualizar(Tarefa t) async {
    final i = _tarefas.indexWhere((x) => x.id == t.id);
    if (i != -1) _tarefas[i] = t;
    await _persistir();
  }

  Future<void> excluir(String id) async {
    _tarefas.removeWhere((t) => t.id == id);
    await _persistir();
  }

  Future<void> alternarConcluida(Tarefa t) async {
    t.concluida = !t.concluida;
    await _persistir();
  }

  Future<int> anexar(String tarefaId, List<XFile> arquivos) async {
    final tarefa = tarefaPor(tarefaId);
    if (tarefa == null) return arquivos.length;
    var falhas = 0;
    for (final arquivo in arquivos) {
      try {
        tarefa.anexos.add(await armazenamentoAnexos.guardar(tarefaId, arquivo));
      } catch (e) {
        debugPrint('Falha ao anexar ${arquivo.name}: $e');
        falhas++;
      }
    }
    await _persistir();
    return falhas;
  }

  Future<void> removerAnexo(String tarefaId, Anexo anexo) async {
    tarefaPor(tarefaId)?.anexos.removeWhere((a) => a.id == anexo.id);
    await _persistir();
    try {
      await armazenamentoAnexos.apagar(tarefaId, anexo);
    } catch (e) {
      debugPrint('Falha ao apagar anexo: $e');
    }
  }

  Future<void> descartarAnexosDeExcluida(String tarefaId) async {
    if (!anexosDisponiveis || tarefaPor(tarefaId) != null) return;
    try {
      await armazenamentoAnexos.apagarDaTarefa(tarefaId);
    } catch (e) {
      debugPrint('Falha ao apagar anexos da tarefa: $e');
    }
  }

  bool categoriaEmUso(String id) => _tarefas.any((t) => t.categoriaId == id);

  int quantidadeDeTarefasEm(String id) =>
      _tarefas.where((t) => t.categoriaId == id).length;

  bool _nomeJaExiste(String nome, {String? ignorandoId}) {
    final alvo = nome.trim().toLowerCase();
    return _categorias
        .any((c) => c.id != ignorandoId && c.nome.toLowerCase() == alvo);
  }

  int _proximaCorLivre() {
    final usadas = _categorias.map((c) => c.cor).toSet();
    for (final cor in Categoria.paleta) {
      if (!usadas.contains(cor)) return cor;
    }
    return Categoria.paleta[_categorias.length % Categoria.paleta.length];
  }

  Future<Categoria?> adicionarCategoria(String nome, {int? cor}) async {
    final limpo = nome.trim();
    if (limpo.isEmpty || _nomeJaExiste(limpo)) return null;

    final categoria = Categoria(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      nome: limpo,
      cor: cor ?? _proximaCorLivre(),
    );
    _categorias.add(categoria);
    await _persistirCategorias();
    return categoria;
  }

  Future<bool> atualizarCategoria(String id,
      {required String nome, int? cor}) async {
    final limpo = nome.trim();
    if (limpo.isEmpty || _nomeJaExiste(limpo, ignorandoId: id)) return false;

    final categoria = categoriaPor(id);
    if (categoria == null) return false;

    categoria.nome = limpo;
    if (cor != null) categoria.cor = cor;
    await _persistirCategorias();
    return true;
  }

  Future<ResultadoExclusaoCategoria> excluirCategoria(String id) async {
    if (categoriaEmUso(id)) return ResultadoExclusaoCategoria.emUso;
    if (_categorias.length <= 1) {
      return ResultadoExclusaoCategoria.ultimaRestante;
    }

    _categorias.removeWhere((c) => c.id == id);
    if (filtroCategoriaId == id) filtroCategoriaId = null;
    await _persistirCategorias();
    return ResultadoExclusaoCategoria.excluida;
  }

  void setBusca(String valor) {
    busca = valor;
    notifyListeners();
  }

  void setFiltroCategoria(String? id) {
    filtroCategoriaId = id;
    notifyListeners();
  }

  void setFiltroPrioridade(Prioridade? p) {
    filtroPrioridade = p;
    notifyListeners();
  }

  void setFiltroConcluida(bool? c) {
    filtroConcluida = c;
    notifyListeners();
  }

  void limparFiltros() {
    busca = '';
    filtroCategoriaId = null;
    filtroPrioridade = null;
    filtroConcluida = null;
    notifyListeners();
  }
}
