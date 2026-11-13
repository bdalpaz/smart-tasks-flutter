import 'package:flutter/material.dart';

const Color sementeDaMarca = Color(0xFF00695C);

ThemeData temaClaro() => _construir(Brightness.light);

ThemeData temaEscuro() => _construir(Brightness.dark);

ThemeData _construir(Brightness brilho) {
  final cores = ColorScheme.fromSeed(
    seedColor: sementeDaMarca,
    brightness: brilho,
  );

  return ThemeData(
    useMaterial3: true,
    colorScheme: cores,
    appBarTheme: AppBarTheme(
      backgroundColor: cores.primaryContainer,
      foregroundColor: cores.onPrimaryContainer,
      elevation: 0,
    ),
    inputDecorationTheme: const InputDecorationTheme(
      border: OutlineInputBorder(),
      isDense: true,
    ),
    snackBarTheme: const SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
    ),
  );
}

Color corLegivel(BuildContext context, Color base) {
  if (Theme.of(context).brightness != Brightness.dark) return base;
  final hsl = HSLColor.fromColor(base);
  return hsl.withLightness((hsl.lightness + 0.22).clamp(0.0, 1.0)).toColor();
}

Color corDaPrioridade(BuildContext context, int indicePrioridade) {
  final escuro = Theme.of(context).brightness == Brightness.dark;
  return switch (indicePrioridade) {
    0 => escuro ? Colors.red.shade300 : Colors.red.shade400,
    1 => escuro ? Colors.orange.shade300 : Colors.orange.shade400,
    _ => escuro ? Colors.green.shade300 : Colors.green.shade400,
  };
}
