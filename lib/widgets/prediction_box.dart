import 'package:flutter/material.dart';

import '../models/prediction_model.dart';
import 'minimal_percent_row.dart';

class PredictionBox extends StatelessWidget {
  final PredictionModel prediction;

  const PredictionBox({super.key, required this.prediction});

  @override
  Widget build(BuildContext context) {
    final advice = prediction.advice ?? prediction.winnerName ?? 'N/A';

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Prediction', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 18),
            MinimalPercentRow(
              label: 'Home',
              value: prediction.percentHome ?? 'N/A',
            ),
            MinimalPercentRow(
              label: 'Draw',
              value: prediction.percentDraw ?? 'N/A',
            ),
            MinimalPercentRow(
              label: 'Away',
              value: prediction.percentAway ?? 'N/A',
            ),
            const Divider(height: 32),
            Text('Advice', style: Theme.of(context).textTheme.bodySmall),
            const SizedBox(height: 6),
            Text(
              advice,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 18),
            _SectionTitle(title: 'Model'),
            const SizedBox(height: 8),
            _InfoLine(label: 'Type', value: prediction.modelName),
            if (prediction.confidence != null)
              _InfoLine(label: 'Confidence', value: prediction.confidence!),
            if (prediction.homeStrength != null &&
                prediction.awayStrength != null) ...[
              _InfoLine(
                label: 'Home strength',
                value: prediction.homeStrength!.toStringAsFixed(1),
              ),
              _InfoLine(
                label: 'Away strength',
                value: prediction.awayStrength!.toStringAsFixed(1),
              ),
            ],
            if (prediction.dynamicHomeAdvantage != null)
              _InfoLine(
                label: 'Home advantage',
                value: _formatSigned(prediction.dynamicHomeAdvantage!),
              ),
            if (prediction.homeElo != null && prediction.awayElo != null) ...[
              _InfoLine(
                label: 'Home Elo',
                value: prediction.homeElo!.toStringAsFixed(0),
              ),
              _InfoLine(
                label: 'Away Elo',
                value: prediction.awayElo!.toStringAsFixed(0),
              ),
            ],
            if (prediction.homeMomentum != null &&
                prediction.awayMomentum != null) ...[
              _InfoLine(
                label: 'Home momentum',
                value: _formatSigned(prediction.homeMomentum!),
              ),
              _InfoLine(
                label: 'Away momentum',
                value: _formatSigned(prediction.awayMomentum!),
              ),
            ],
            if (prediction.homeFormSummary != null ||
                prediction.awayFormSummary != null) ...[
              const SizedBox(height: 18),
              _SectionTitle(title: 'Overall form'),
              const SizedBox(height: 8),
              if (prediction.homeFormSummary != null)
                _SignalText(text: prediction.homeFormSummary!),
              if (prediction.awayFormSummary != null)
                _SignalText(text: prediction.awayFormSummary!),
            ],
            if (prediction.homeVenueFormSummary != null ||
                prediction.awayVenueFormSummary != null) ...[
              const SizedBox(height: 18),
              _SectionTitle(title: 'Venue form'),
              const SizedBox(height: 8),
              if (prediction.homeVenueFormSummary != null)
                _SignalText(text: prediction.homeVenueFormSummary!),
              if (prediction.awayVenueFormSummary != null)
                _SignalText(text: prediction.awayVenueFormSummary!),
            ],
            if (prediction.homeAdvantageSummary != null) ...[
              const SizedBox(height: 18),
              _SectionTitle(title: 'Home advantage'),
              const SizedBox(height: 8),
              _SignalText(text: prediction.homeAdvantageSummary!),
            ],
            if (prediction.h2hSummary != null) ...[
              const SizedBox(height: 18),
              _SectionTitle(title: 'Head to head'),
              const SizedBox(height: 8),
              _SignalText(text: prediction.h2hSummary!),
            ],
            if (prediction.modelExplanation != null) ...[
              const SizedBox(height: 18),
              _SectionTitle(title: 'Explanation'),
              const SizedBox(height: 8),
              Text(
                prediction.modelExplanation!,
                style: const TextStyle(
                  fontSize: 12,
                  color: Colors.black54,
                  height: 1.4,
                ),
              ),
            ],
            const SizedBox(height: 16),
            const Text(
              'For reference only. Football predictions are not guaranteed.',
              style: TextStyle(fontSize: 11, color: Colors.black38),
            ),
          ],
        ),
      ),
    );
  }

  String _formatSigned(double value) {
    if (value > 0) {
      return '+${value.toStringAsFixed(2)}';
    }

    return value.toStringAsFixed(2);
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;

  const _SectionTitle({required this.title});

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w700,
        color: Colors.black,
      ),
    );
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
        children: [
          SizedBox(
            width: 120,
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

class _SignalText extends StatelessWidget {
  final String text;

  const _SignalText({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.black.withAlpha(8),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 12,
          color: Colors.black87,
          height: 1.35,
        ),
      ),
    );
  }
}
