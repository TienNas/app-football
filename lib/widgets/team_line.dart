import 'package:flutter/material.dart';

import 'team_logo.dart';

class TeamLine extends StatelessWidget {
  final String? logo;
  final String name;
  final bool alignRight;

  const TeamLine({
    super.key,
    required this.logo,
    required this.name,
    this.alignRight = false,
  });

  @override
  Widget build(BuildContext context) {
    final logoWidget = TeamLogo(url: logo, size: 28);

    final nameWidget = Expanded(
      child: Text(
        name,
        textAlign: alignRight ? TextAlign.right : TextAlign.left,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: Colors.black,
        ),
      ),
    );

    if (alignRight) {
      return Row(children: [nameWidget, const SizedBox(width: 8), logoWidget]);
    }

    return Row(children: [logoWidget, const SizedBox(width: 8), nameWidget]);
  }
}
