import 'package:flutter/material.dart';

class Pilula extends StatelessWidget {
  final String texto;
  final Color cor;

  const Pilula({super.key, required this.texto, required this.cor});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
      decoration: BoxDecoration(
        color: cor.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        texto,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: cor,
              fontWeight: FontWeight.w700,
            ),
      ),
    );
  }
}
