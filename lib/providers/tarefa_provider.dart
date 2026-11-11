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

    // Pendentes primeiro, depois por prioridade (alta → baixa)
    lista.sort((a, b) {
      if (a.concluida != b.concluida) return a.concluida ? 1 : -1;
      return a.prioridade.index.compareTo(b.prioridade.index);
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
}