import 'package:flutter/material.dart';

class TeamLogo extends StatelessWidget {
  final String? url;
  final double size;

  const TeamLogo({super.key, required this.url, this.size = 36});

  @override
  Widget build(BuildContext context) {
    if (url == null || url!.isEmpty) {
      return _fallbackLogo();
    }

    return Image.network(
      url!,
      width: size,
      height: size,
      fit: BoxFit.contain,
      errorBuilder: (_, _, _) {
        return _fallbackLogo();
      },
    );
  }

  Widget _fallbackLogo() {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: Colors.black12),
      ),
      child: const Icon(Icons.sports_soccer, size: 16, color: Colors.black45),
    );
  }
}
