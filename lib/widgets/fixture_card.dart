import 'package:flutter/material.dart';

import '../models/fixture_model.dart';
import 'team_line.dart';

class FixtureCard extends StatelessWidget {
  final FixtureModel fixture;
  final VoidCallback onTap;

  const FixtureCard({super.key, required this.fixture, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final scoreText = fixture.homeGoals == null || fixture.awayGoals == null
        ? 'vs'
        : '${fixture.homeGoals} - ${fixture.awayGoals}';

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
                Text(
                  fixture.leagueName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: TeamLine(
                        logo: fixture.homeLogo,
                        name: fixture.homeName,
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Text(
                        scoreText,
                        style: const TextStyle(
                          fontSize: 13,
                          color: Colors.black45,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    Expanded(
                      child: TeamLine(
                        logo: fixture.awayLogo,
                        name: fixture.awayName,
                        alignRight: true,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
