import 'package:flutter/material.dart';

import '../models/fixture_model.dart';
import 'team_logo.dart';

class MatchHeader extends StatelessWidget {
  final FixtureModel fixture;

  const MatchHeader({super.key, required this.fixture});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          children: [
            Text(
              fixture.leagueName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodySmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 18),
            Row(
              children: [
                Expanded(
                  child: _TeamBlock(
                    logo: fixture.homeLogo,
                    name: fixture.homeName,
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  child: Text(
                    'vs',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.black45,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Expanded(
                  child: _TeamBlock(
                    logo: fixture.awayLogo,
                    name: fixture.awayName,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _TeamBlock extends StatelessWidget {
  final String? logo;
  final String name;

  const _TeamBlock({required this.logo, required this.name});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TeamLogo(url: logo, size: 58),
        const SizedBox(height: 10),
        Text(
          name,
          textAlign: TextAlign.center,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: Colors.black,
          ),
        ),
      ],
    );
  }
}
