import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/tarefa.dart';

class TarefaRepository {
  static const _chave = 'tarefas';

  Future<List<Tarefa>> carregar() async {
    final prefs = await SharedPreferences.getInstance();
    final json = prefs.getString(_chave);
    if (json == null) return [];
    final lista = jsonDecode(json) as List;
    return lista.map((e) => Tarefa.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<void> salvar(List<Tarefa> tarefas) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
        _chave, jsonEncode(tarefas.map((t) => t.toJson()).toList()));
  }
}