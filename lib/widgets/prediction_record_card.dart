import 'package:flutter/material.dart';

import '../models/prediction_record_model.dart';
import 'team_logo.dart';

class PredictionRecordCard extends StatelessWidget {
  final PredictionRecordModel record;

  const PredictionRecordCard({super.key, required this.record});

  @override
  Widget build(BuildContext context) {
    final statusText = _buildStatusText();
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
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 10),
                    child: Text(
                      'vs',
                      style: TextStyle(fontSize: 13, color: Colors.black45),
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
              _InfoLine(
                label: 'Probability',
                value:
                    'H ${record.homePercent} • D ${record.drawPercent} • A ${record.awayPercent}',
              ),
              _InfoLine(label: 'Model', value: record.modelName),
              if (record.confidence != null)
                _InfoLine(label: 'Confidence', value: record.confidence!),
              if (record.actualResult != null)
                _InfoLine(label: 'Actual', value: _buildActualText()),
              const SizedBox(height: 10),
              Row(
                children: [
                  _StatusPill(text: statusText, isCorrect: record.isCorrect),
                  const Spacer(),
                  if (dateText.isNotEmpty)
                    Text(
                      dateText,
                      style: const TextStyle(
                        fontSize: 11,
                        color: Colors.black38,
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _buildActualText() {
    if (record.homeGoals == null || record.awayGoals == null) {
      return record.actualResult ?? 'N/A';
    }

    return '${record.actualResult} • ${record.homeGoals}-${record.awayGoals}';
  }

  String _buildStatusText() {
    if (record.isCorrect == true) return 'Correct';
    if (record.isCorrect == false) return 'Wrong';

    return 'Pending';
  }

  String _formatDate(String rawDate) {
    if (rawDate.trim().isEmpty) return '';

    final date = DateTime.tryParse(rawDate);

    if (date == null) {
      return rawDate;
    }

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
  final String text;
  final bool? isCorrect;

  const _StatusPill({required this.text, required this.isCorrect});

  @override
  Widget build(BuildContext context) {
    Color backgroundColor = Colors.black.withAlpha(8);
    Color textColor = Colors.black54;

    if (isCorrect == true) {
      backgroundColor = Colors.black;
      textColor = Colors.white;
    } else if (isCorrect == false) {
      backgroundColor = Colors.black.withAlpha(22);
      textColor = Colors.black;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: textColor,
        ),
      ),
    );
  }
}
