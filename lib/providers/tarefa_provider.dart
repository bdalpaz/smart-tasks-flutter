import 'package:flutter/foundation.dart';
import '../data/tarefa_repository.dart';
import '../models/tarefa.dart';

class TarefaProvider extends ChangeNotifier {
  final _repo = TarefaRepository();
  List<Tarefa> _tarefas = [];

  String busca = '';
  Categoria? filtroCategoria;
  Prioridade? filtroPrioridade;
  bool? filtroConcluida;

<<<<<<< HEAD
  int get pendentes => _tarefas.where((t) => !t.concluida).length;

=======
>>>>>>> d9183b8f2d1c0f1b09677e7003593f461ae60433
  List<Tarefa> get tarefas {
    final termo = busca.toLowerCase();
    final lista = _tarefas.where((t) {
      if (termo.isNotEmpty &&
          !t.titulo.toLowerCase().contains(termo) &&
          !t.descricao.toLowerCase().contains(termo)) return false;
      if (filtroCategoria != null && t.categoria != filtroCategoria) return false;
      if (filtroPrioridade != null && t.prioridade != filtroPrioridade) return false;
      if (filtroConcluida != null && t.concluida != filtroConcluida) return false;
      return true;
    }).toList();

<<<<<<< HEAD
    // Ordenação inteligente: pendentes > atrasadas > prioridade > prazo mais próximo
    lista.sort((a, b) {
      if (a.concluida != b.concluida) return a.concluida ? 1 : -1;
      if (a.atrasada != b.atrasada) return a.atrasada ? -1 : 1;
      final p = a.prioridade.index.compareTo(b.prioridade.index);
      if (p != 0) return p;
      if (a.prazo == null && b.prazo == null) return 0;
      if (a.prazo == null) return 1;
      if (b.prazo == null) return -1;
      return a.prazo!.compareTo(b.prazo!);
=======
    // Pendentes primeiro, depois por prioridade (alta → baixa)
    lista.sort((a, b) {
      if (a.concluida != b.concluida) return a.concluida ? 1 : -1;
      return a.prioridade.index.compareTo(b.prioridade.index);
>>>>>>> d9183b8f2d1c0f1b09677e7003593f461ae60433
    });
    return lista;
  }

  Future<void> carregar() async {
    _tarefas = await _repo.carregar();
    notifyListeners();
  }

  Future<void> _persistir() async {
    notifyListeners();
    await _repo.salvar(_tarefas);
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

  void setBusca(String valor) {
    busca = valor;
    notifyListeners();
  }
<<<<<<< HEAD

  void setFiltroCategoria(Categoria? c) {
    filtroCategoria = c;
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
=======
>>>>>>> d9183b8f2d1c0f1b09677e7003593f461ae60433
}