import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/tarefa.dart';

class TarefaRepository {
  static const _chave = 'tarefas';

  /// Nunca lança: dados ilegíveis resultam em lista vazia. Abrir o app sem as
  /// tarefas antigas é ruim, mas não abrir é pior.
  Future<List<Tarefa>> carregar() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final json = prefs.getString(_chave);
      if (json == null) return [];
      final lista = jsonDecode(json) as List;
      return lista
          .map((e) => Tarefa.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      // JSON corrompido ou gravado por uma versão anterior do modelo — por
      // exemplo uma categoria que não existe mais faz `byName` lançar.
      debugPrint('Falha ao carregar tarefas: $e');
      return [];
    }
  }

  Future<void> salvar(List<Tarefa> tarefas) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
        _chave, jsonEncode(tarefas.map((t) => t.toJson()).toList()));
  }
}