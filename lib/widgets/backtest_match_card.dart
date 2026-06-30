import 'package:flutter/material.dart';

import '../models/backtest_result_model.dart';
import 'team_logo.dart';

class BacktestMatchCard extends StatelessWidget {
  final BacktestMatchRecordModel record;

  const BacktestMatchCard({super.key, required this.record});

  @override
  Widget build(BuildContext context) {
    final dateText = _formatDate(record.date);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                record.leagueName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  TeamLogo(url: record.homeLogo, size: 30),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      record.homeName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: Colors.black,
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    child: Text(
                      '${record.homeGoals}-${record.awayGoals}',
                      style: const TextStyle(
                        fontSize: 13,
                        color: Colors.black45,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      record.awayName,
                      textAlign: TextAlign.right,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: Colors.black,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  TeamLogo(url: record.awayLogo, size: 30),
                ],
              ),
              const SizedBox(height: 14),
              _InfoLine(label: 'Predicted', value: record.predictedLabel),
              _InfoLine(label: 'Actual', value: record.actualLabel),
              _InfoLine(
                label: 'Probability',
                value:
                    'H ${record.homePercent} • D ${record.drawPercent} • A ${record.awayPercent}',
              ),
              _InfoLine(label: 'Confidence', value: record.confidence ?? 'N/A'),
              const SizedBox(height: 10),
              Row(
                children: [
                  _StatusPill(isCorrect: record.isCorrect),
                  const Spacer(),
                  Text(
                    dateText,
                    style: const TextStyle(fontSize: 11, color: Colors.black38),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(String rawDate) {
    final date = DateTime.tryParse(rawDate);

    if (date == null) return rawDate;

    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    final year = date.year.toString();

    return '$day/$month/$year';
  }
}

class _InfoLine extends StatelessWidget {
  final String label;
  final String value;

  const _InfoLine({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 7),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 82,
            child: Text(
              label,
              style: const TextStyle(fontSize: 12, color: Colors.black45),
            ),
          ),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: const TextStyle(
                fontSize: 12,
                color: Colors.black87,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  final bool isCorrect;

  const _StatusPill({required this.isCorrect});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: isCorrect ? Colors.black : Colors.black.withAlpha(18),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        isCorrect ? 'Correct' : 'Wrong',
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: isCorrect ? Colors.white : Colors.black,
        ),
      ),
    );
  }
}
