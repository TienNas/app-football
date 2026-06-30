import 'package:flutter/material.dart';

import '../models/saved_match_model.dart';
import 'team_logo.dart';

class SavedMatchCard extends StatelessWidget {
  final SavedMatchModel match;
  final VoidCallback onTap;
  final VoidCallback? onRemove;

  const SavedMatchCard({
    super.key,
    required this.match,
    required this.onTap,
    this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final dateText = _formatDate(match.date);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Card(
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        match.leagueName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ),
                    if (onRemove != null)
                      InkWell(
                        onTap: onRemove,
                        borderRadius: BorderRadius.circular(20),
                        child: const Padding(
                          padding: EdgeInsets.all(4),
                          child: Icon(
                            Icons.close,
                            size: 18,
                            color: Colors.black45,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    TeamLogo(url: match.homeLogo, size: 30),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        match.homeName,
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
                        match.awayName,
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
                    TeamLogo(url: match.awayLogo, size: 30),
                  ],
                ),
                if (dateText.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Text(
                    dateText,
                    style: const TextStyle(fontSize: 12, color: Colors.black38),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
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
