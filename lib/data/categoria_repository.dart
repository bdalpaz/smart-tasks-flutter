import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/categoria.dart';

class CategoriaRepository {
  static const _chave = 'categorias';

  Future<List<Categoria>> carregar() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final json = prefs.getString(_chave);
      if (json == null) return Categoria.padroes();
      final lista = jsonDecode(json) as List;
      if (lista.isEmpty) return Categoria.padroes();

      var migrou = false;
      final categorias = <Categoria>[];
      for (var i = 0; i < lista.length; i++) {
        final mapa = lista[i] as Map<String, dynamic>;
        final categoria = Categoria.fromJson(mapa);
        if (mapa['cor'] == null) {
          categoria.cor = Categoria.paleta[i % Categoria.paleta.length];
          migrou = true;
        }
        categorias.add(categoria);
      }

      if (migrou) await salvar(categorias);
      return categorias;
    } catch (e) {
      debugPrint('Falha ao carregar categorias: $e');
      return Categoria.padroes();
    }
  }

  Future<void> salvar(List<Categoria> categorias) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
        _chave, jsonEncode(categorias.map((c) => c.toJson()).toList()));
  }
}
