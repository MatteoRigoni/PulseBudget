import 'package:flutter/material.dart';

class AppTitleWidget extends StatelessWidget {
  final String title;
  final double iconSize;
  final double spacing;

  const AppTitleWidget({
    super.key,
    required this.title,
    this.iconSize = 24,
    this.spacing = 8,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          Icons.account_balance_wallet,
          size: iconSize,
          color: Theme.of(context).colorScheme.primary,
        ),
        SizedBox(width: spacing),
        Text(title),
      ],
    );
  }
}
