import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/tarefa.dart';

class TarefaRepository {
  static const _chave = 'tarefas';

  bool leituraFalhou = false;

  Future<List<Tarefa>> carregar() async {
    leituraFalhou = false;
    try {
      final prefs = await SharedPreferences.getInstance();
      final json = prefs.getString(_chave);
      if (json == null) return [];
      final lista = jsonDecode(json) as List;
      return lista
          .map((e) => Tarefa.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      debugPrint('Falha ao carregar tarefas: $e');
      leituraFalhou = true;
      return [];
    }
  }

  Future<void> salvar(List<Tarefa> tarefas) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
        _chave, jsonEncode(tarefas.map((t) => t.toJson()).toList()));
  }
}