import 'package:flutter/material.dart';

class MinimalPercentRow extends StatelessWidget {
  final String label;
  final String value;

  const MinimalPercentRow({
    super.key,
    required this.label,
    required this.value,
  });

  double _parsePercent(String value) {
    final cleaned = value.replaceAll('%', '').trim();
    return double.tryParse(cleaned) ?? 0;
  }

  @override
  Widget build(BuildContext context) {
    final percent = _parsePercent(value) / 100;
    final safePercent = percent.clamp(0.0, 1.0).toDouble();

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(fontSize: 14, color: Colors.black87),
                ),
              ),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: Colors.black,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: LinearProgressIndicator(
              value: safePercent,
              minHeight: 5,
              backgroundColor: Colors.black12,
              valueColor: const AlwaysStoppedAnimation<Color>(Colors.black),
            ),
          ),
        ],
      ),
    );
  }
}
