import 'package:flutter/material.dart';

/// Row with a bold section title and an optional trailing action.
class SectionHeader extends StatelessWidget {
  const SectionHeader({super.key, required this.title, this.action});

  final String title;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title, style: Theme.of(context).textTheme.titleLarge),
        if (action != null) action!,
      ],
    );
  }
}
