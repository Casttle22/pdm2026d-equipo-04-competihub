import 'package:flutter/material.dart';

// Renglón de las tarjetas: ícono pequeño y un texto que puede ocupar varias
// líneas.
class FilaInfo extends StatelessWidget {
  const FilaInfo({super.key, required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          size: 18,
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
        const SizedBox(width: 9),
        Expanded(child: Text(text)),
      ],
    );
  }
}
