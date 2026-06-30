import 'dart:math';

import '../models/fixture_model.dart';
import '../models/prediction_model.dart';
import '../models/team_form_stats.dart';

class CustomPredictor {
  static PredictionModel predict({
    required FixtureModel fixture,
    required List<FixtureModel> homeRecentFixtures,
    required List<FixtureModel> awayRecentFixtures,
    required List<FixtureModel> h2hFixtures,
  }) {
    final homeTeamId = fixture.homeTeamId;
    final awayTeamId = fixture.awayTeamId;

    if (homeTeamId == null || awayTeamId == null) {
      return PredictionModel(
        winnerName: null,
        winnerComment: 'Missing team id. Cannot calculate custom prediction.',
        advice: 'Prediction unavailable',
        percentHome: 'N/A',
        percentDraw: 'N/A',
        percentAway: 'N/A',
        modelName: 'Elo Momentum Model',
        confidence: 'Low',
      );
    }

    final homeStats = _buildTeamStats(
      teamId: homeTeamId,
      fixtures: homeRecentFixtures,
      excludeFixtureId: fixture.fixtureId,
    );

    final awayStats = _buildTeamStats(
      teamId: awayTeamId,
      fixtures: awayRecentFixtures,
      excludeFixtureId: fixture.fixtureId,
    );

    final homeH2hStats = _buildTeamStats(
      teamId: homeTeamId,
      fixtures: h2hFixtures,
      excludeFixtureId: fixture.fixtureId,
    );

    final awayH2hStats = _buildTeamStats(
      teamId: awayTeamId,
      fixtures: h2hFixtures,
      excludeFixtureId: fixture.fixtureId,
    );

    final h2hEdge =
        ((homeH2hStats.pointsPerGame - awayH2hStats.pointsPerGame) * 3.8)
            .clamp(-7.0, 7.0)
            .toDouble();

    final eloEdge = ((homeStats.eloLikeRating - awayStats.eloLikeRating) / 22.0)
        .clamp(-8.0, 8.0)
        .toDouble();

    final momentumEdge =
        ((homeStats.formMomentum - awayStats.formMomentum) * 2.8)
            .clamp(-6.0, 6.0)
            .toDouble();

    final homeStrength =
        _teamStrength(homeStats) + 5.5 + h2hEdge + eloEdge + momentumEdge;
    final awayStrength =
        _teamStrength(awayStats) - h2hEdge - eloEdge - momentumEdge;

    final diff = homeStrength - awayStrength;

    final result = _convertStrengthToPercent(diff);

    final homePercent = result[0];
    final drawPercent = result[1];
    final awayPercent = result[2];

    final advice = _buildAdvice(
      fixture: fixture,
      homePercent: homePercent,
      drawPercent: drawPercent,
      awayPercent: awayPercent,
    );

    final winnerName = _buildWinnerName(
      fixture: fixture,
      homePercent: homePercent,
      drawPercent: drawPercent,
      awayPercent: awayPercent,
    );

    final confidence = _buildConfidence(
      homePercent: homePercent,
      drawPercent: drawPercent,
      awayPercent: awayPercent,
      homeStats: homeStats,
      awayStats: awayStats,
    );

    return PredictionModel(
      winnerName: winnerName,
      winnerComment: 'Elo momentum model • Confidence: $confidence',
      advice: advice,
      percentHome: '$homePercent%',
      percentDraw: '$drawPercent%',
      percentAway: '$awayPercent%',
      modelName: 'Elo Momentum Model',
      confidence: confidence,
      homeFormSummary: _buildFormSummary(fixture.homeName, homeStats),
      awayFormSummary: _buildFormSummary(fixture.awayName, awayStats),
      h2hSummary: _buildH2hSummary(
        fixture: fixture,
        homeH2hStats: homeH2hStats,
        awayH2hStats: awayH2hStats,
      ),
      modelExplanation:
          'The model combines recent form, weighted points per game, goal difference, attack/defense output, home advantage, head-to-head, Elo-style rating, and form momentum.',
      homeStrength: homeStrength,
      awayStrength: awayStrength,
      homeElo: homeStats.eloLikeRating,
      awayElo: awayStats.eloLikeRating,
      homeMomentum: homeStats.formMomentum,
      awayMomentum: awayStats.formMomentum,
    );
  }

  static TeamFormStats _buildTeamStats({
    required int teamId,
    required List<FixtureModel> fixtures,
    required int excludeFixtureId,
  }) {
    final validFixtures = fixtures.where((fixture) {
      if (fixture.fixtureId == excludeFixtureId) return false;
      if (!_isFinished(fixture.statusShort)) return false;
      if (fixture.homeGoals == null || fixture.awayGoals == null) return false;

      final isHome = fixture.homeTeamId == teamId;
      final isAway = fixture.awayTeamId == teamId;

      return isHome || isAway;
    }).toList();

    validFixtures.sort(_compareFixtureDateDesc);

    int matches = 0;
    int wins = 0;
    int draws = 0;
    int losses = 0;
    int goalsFor = 0;
    int goalsAgainst = 0;
    int points = 0;

    double weightedPoints = 0;
    double weightSum = 0;

    for (int i = 0; i < validFixtures.length; i++) {
      final fixture = validFixtures[i];
      final result = _extractTeamMatchResult(fixture, teamId);

      if (result == null) continue;

      final weight = pow(0.82, i).toDouble();

      matches++;
      goalsFor += result.goalsFor;
      goalsAgainst += result.goalsAgainst;
      points += result.points;

      weightedPoints += result.points * weight;
      weightSum += weight;

      if (result.points == 3) {
        wins++;
      } else if (result.points == 1) {
        draws++;
      } else {
        losses++;
      }
    }

    final weightedPointsPerGame = weightSum == 0
        ? 0.0
        : weightedPoints / weightSum;
    final formMomentum = _calculateFormMomentum(validFixtures, teamId);
    final eloLikeRating = _calculateEloLikeRating(validFixtures, teamId);

    return TeamFormStats(
      matches: matches,
      wins: wins,
      draws: draws,
      losses: losses,
      goalsFor: goalsFor,
      goalsAgainst: goalsAgainst,
      points: points,
      weightedPointsPerGame: weightedPointsPerGame,
      formMomentum: formMomentum,
      eloLikeRating: eloLikeRating,
    );
  }

  static int _compareFixtureDateDesc(FixtureModel a, FixtureModel b) {
    final dateA = DateTime.tryParse(a.date);
    final dateB = DateTime.tryParse(b.date);

    if (dateA == null && dateB == null) return 0;
    if (dateA == null) return 1;
    if (dateB == null) return -1;

    return dateB.compareTo(dateA);
  }

  static bool _isFinished(String statusShort) {
    return statusShort == 'FT' || statusShort == 'AET' || statusShort == 'PEN';
  }

  static _TeamMatchResult? _extractTeamMatchResult(
    FixtureModel fixture,
    int teamId,
  ) {
    if (fixture.homeGoals == null || fixture.awayGoals == null) {
      return null;
    }

    final isHome = fixture.homeTeamId == teamId;
    final isAway = fixture.awayTeamId == teamId;

    if (!isHome && !isAway) {
      return null;
    }

    final goalsFor = isHome ? fixture.homeGoals! : fixture.awayGoals!;
    final goalsAgainst = isHome ? fixture.awayGoals! : fixture.homeGoals!;

    int points;
    double resultValue;

    if (goalsFor > goalsAgainst) {
      points = 3;
      resultValue = 1.0;
    } else if (goalsFor == goalsAgainst) {
      points = 1;
      resultValue = 0.0;
    } else {
      points = 0;
      resultValue = -1.0;
    }

    return _TeamMatchResult(
      goalsFor: goalsFor,
      goalsAgainst: goalsAgainst,
      points: points,
      resultValue: resultValue,
      isHome: isHome,
    );
  }

  static double _calculateFormMomentum(
    List<FixtureModel> validFixtures,
    int teamId,
  ) {
    if (validFixtures.length < 4) {
      return 0;
    }

    final recentFixtures = validFixtures.take(3).toList();
    final olderFixtures = validFixtures.skip(3).toList();

    final recentPpg = _calculatePpg(recentFixtures, teamId);
    final olderPpg = _calculatePpg(olderFixtures, teamId);

    return (recentPpg - olderPpg).clamp(-3.0, 3.0).toDouble();
  }

  static double _calculatePpg(List<FixtureModel> fixtures, int teamId) {
    if (fixtures.isEmpty) return 0;

    int totalPoints = 0;
    int totalMatches = 0;

    for (final fixture in fixtures) {
      final result = _extractTeamMatchResult(fixture, teamId);

      if (result == null) continue;

      totalPoints += result.points;
      totalMatches++;
    }

    if (totalMatches == 0) return 0;

    return totalPoints / totalMatches;
  }

  static double _calculateEloLikeRating(
    List<FixtureModel> validFixtures,
    int teamId,
  ) {
    if (validFixtures.isEmpty) {
      return 1500.0;
    }

    double rating = 1500.0;

    for (int i = validFixtures.length - 1; i >= 0; i--) {
      final fixture = validFixtures[i];
      final result = _extractTeamMatchResult(fixture, teamId);

      if (result == null) continue;

      final recencyIndex = i;
      final recencyWeight = pow(0.88, recencyIndex).toDouble();

      final goalDiff = (result.goalsFor - result.goalsAgainst)
          .clamp(-3, 3)
          .toDouble();

      final venueFactor = result.isHome ? 0.95 : 1.05;

      final resultImpact = result.resultValue * 20.0 * venueFactor;
      final goalImpact = goalDiff * 4.0;

      rating += (resultImpact + goalImpact) * recencyWeight;
    }

    return rating.clamp(1350.0, 1650.0).toDouble();
  }

  static double _teamStrength(TeamFormStats stats) {
    if (stats.matches == 0) {
      return 50.0;
    }

    final formComponent = (stats.weightedPointsPerGame - 1.2) * 12.0;
    final classicFormComponent = (stats.pointsPerGame - 1.2) * 7.0;
    final goalDifferenceComponent = stats.goalDifferencePerMatch * 7.5;
    final attackComponent = (stats.avgGoalsFor - 1.2) * 4.2;
    final defenseComponent = (1.2 - stats.avgGoalsAgainst) * 4.2;
    final winRateComponent = (stats.winRate - 0.35) * 7.0;
    final momentumComponent = stats.formMomentum * 3.0;
    final eloComponent = (stats.eloLikeRating - 1500.0) / 18.0;

    return 50.0 +
        formComponent +
        classicFormComponent +
        goalDifferenceComponent +
        attackComponent +
        defenseComponent +
        winRateComponent +
        momentumComponent +
        eloComponent;
  }

  static List<int> _convertStrengthToPercent(double diff) {
    final absDiff = diff.abs();

    final draw = (30.0 - min(absDiff * 0.5, 18.0)).clamp(12.0, 30.0).toDouble();

    final remaining = 100.0 - draw;

    final homeShare = 1.0 / (1.0 + exp(-diff / 20.0));

    final home = remaining * homeShare;

    final homeRounded = home.round();
    final drawRounded = draw.round();
    final awayRounded = 100 - homeRounded - drawRounded;

    return [
      homeRounded.clamp(1, 98).toInt(),
      drawRounded.clamp(1, 98).toInt(),
      awayRounded.clamp(1, 98).toInt(),
    ];
  }

  static String _buildAdvice({
    required FixtureModel fixture,
    required int homePercent,
    required int drawPercent,
    required int awayPercent,
  }) {
    if (homePercent >= drawPercent && homePercent >= awayPercent) {
      return 'Home Win';
    }

    if (awayPercent >= homePercent && awayPercent >= drawPercent) {
      return 'Away Win';
    }

    return 'Draw';
  }

  static String _buildWinnerName({
    required FixtureModel fixture,
    required int homePercent,
    required int drawPercent,
    required int awayPercent,
  }) {
    if (homePercent >= drawPercent && homePercent >= awayPercent) {
      return fixture.homeName;
    }

    if (awayPercent >= homePercent && awayPercent >= drawPercent) {
      return fixture.awayName;
    }

    return 'Draw';
  }

  static String _buildConfidence({
    required int homePercent,
    required int drawPercent,
    required int awayPercent,
    required TeamFormStats homeStats,
    required TeamFormStats awayStats,
  }) {
    final maxPercent = max(homePercent, max(drawPercent, awayPercent));
    final minMatches = min(homeStats.matches, awayStats.matches);

    if (minMatches < 3) {
      return 'Low';
    }

    if (maxPercent >= 60 && minMatches >= 6) {
      return 'High';
    }

    if (maxPercent >= 46) {
      return 'Medium';
    }

    return 'Low';
  }

  static String _buildFormSummary(String teamName, TeamFormStats stats) {
    if (stats.matches == 0) {
      return '$teamName: no recent finished matches found.';
    }

    final momentumText = stats.formMomentum >= 0
        ? '+${stats.formMomentum.toStringAsFixed(2)}'
        : stats.formMomentum.toStringAsFixed(2);

    return '$teamName: ${stats.recordText} • '
        'GF ${stats.goalsFor} • GA ${stats.goalsAgainst} • '
        'W-PPG ${stats.weightedPointsPerGame.toStringAsFixed(2)} • '
        'Elo ${stats.eloLikeRating.toStringAsFixed(0)} • '
        'Momentum $momentumText';
  }

  static String _buildH2hSummary({
    required FixtureModel fixture,
    required TeamFormStats homeH2hStats,
    required TeamFormStats awayH2hStats,
  }) {
    final h2hMatches = max(homeH2hStats.matches, awayH2hStats.matches);

    if (h2hMatches == 0) {
      return 'No recent head-to-head data found.';
    }

    return 'Last $h2hMatches H2H: ${fixture.homeName} '
        '${homeH2hStats.recordText} • '
        '${fixture.awayName} ${awayH2hStats.recordText}';
  }
}

class _TeamMatchResult {
  final int goalsFor;
  final int goalsAgainst;
  final int points;
  final double resultValue;
  final bool isHome;

  const _TeamMatchResult({
    required this.goalsFor,
    required this.goalsAgainst,
    required this.points,
    required this.resultValue,
    required this.isHome,
  });
}
