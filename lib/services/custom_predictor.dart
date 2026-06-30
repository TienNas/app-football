import 'dart:math';

import '../config/model_weights.dart';
import '../models/fixture_model.dart';
import '../models/prediction_model.dart';
import '../models/team_form_stats.dart';

class CustomPredictor {
  static PredictionModel predict({
    required FixtureModel fixture,
    required List<FixtureModel> homeRecentFixtures,
    required List<FixtureModel> awayRecentFixtures,
    required List<FixtureModel> h2hFixtures,
    required Map<int, double> opponentRatingMap,
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
        modelName: 'Opponent-Adjusted Elo Model',
        confidence: 'Low',
      );
    }

    final homeOverallStats = _buildTeamStats(
      teamId: homeTeamId,
      fixtures: homeRecentFixtures,
      excludeFixtureId: fixture.fixtureId,
      opponentRatingMap: opponentRatingMap,
    );

    final homeVenueStats = _buildTeamStats(
      teamId: homeTeamId,
      fixtures: homeRecentFixtures,
      excludeFixtureId: fixture.fixtureId,
      venueFilter: _VenueFilter.homeOnly,
      opponentRatingMap: opponentRatingMap,
    );

    final awayOverallStats = _buildTeamStats(
      teamId: awayTeamId,
      fixtures: awayRecentFixtures,
      excludeFixtureId: fixture.fixtureId,
      opponentRatingMap: opponentRatingMap,
    );

    final awayVenueStats = _buildTeamStats(
      teamId: awayTeamId,
      fixtures: awayRecentFixtures,
      excludeFixtureId: fixture.fixtureId,
      venueFilter: _VenueFilter.awayOnly,
      opponentRatingMap: opponentRatingMap,
    );

    final homeH2hStats = _buildTeamStats(
      teamId: homeTeamId,
      fixtures: h2hFixtures,
      excludeFixtureId: fixture.fixtureId,
      opponentRatingMap: opponentRatingMap,
    );

    final awayH2hStats = _buildTeamStats(
      teamId: awayTeamId,
      fixtures: h2hFixtures,
      excludeFixtureId: fixture.fixtureId,
      opponentRatingMap: opponentRatingMap,
    );

    final h2hEdge =
        ((homeH2hStats.pointsPerGame - awayH2hStats.pointsPerGame) *
                ModelWeights.h2hPpgMultiplier)
            .clamp(ModelWeights.h2hEdgeMin, ModelWeights.h2hEdgeMax)
            .toDouble();

    final eloEdge =
        ((homeOverallStats.eloLikeRating - awayOverallStats.eloLikeRating) /
                ModelWeights.eloEdgeDivisor)
            .clamp(ModelWeights.eloEdgeMin, ModelWeights.eloEdgeMax)
            .toDouble();

    final momentumEdge =
        ((homeOverallStats.formMomentum - awayOverallStats.formMomentum) *
                ModelWeights.momentumEdgeMultiplier)
            .clamp(ModelWeights.momentumEdgeMin, ModelWeights.momentumEdgeMax)
            .toDouble();

    final dynamicHomeAdvantage = _calculateDynamicHomeAdvantage(
      homeOverallStats: homeOverallStats,
      homeVenueStats: homeVenueStats,
    );

    final homeBaseStrength = _combineOverallAndVenueStrength(
      overallStats: homeOverallStats,
      venueStats: homeVenueStats,
    );

    final awayBaseStrength = _combineOverallAndVenueStrength(
      overallStats: awayOverallStats,
      venueStats: awayVenueStats,
    );

    final homeStrength =
        homeBaseStrength +
        dynamicHomeAdvantage +
        h2hEdge +
        eloEdge +
        momentumEdge;

    final awayStrength = awayBaseStrength - h2hEdge - eloEdge - momentumEdge;

    final diff = homeStrength - awayStrength;

    final result = _convertStrengthToPercent(diff);

    final homePercent = result[0];
    final drawPercent = result[1];
    final awayPercent = result[2];

    final advice = _buildAdvice(
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
      homeOverallStats: homeOverallStats,
      awayOverallStats: awayOverallStats,
      homeVenueStats: homeVenueStats,
      awayVenueStats: awayVenueStats,
    );

    return PredictionModel(
      winnerName: winnerName,
      winnerComment: 'Opponent-adjusted Elo model • Confidence: $confidence',
      advice: advice,
      percentHome: '$homePercent%',
      percentDraw: '$drawPercent%',
      percentAway: '$awayPercent%',
      modelName: 'Opponent-Adjusted Elo Model',
      confidence: confidence,
      homeFormSummary: _buildFormSummary(fixture.homeName, homeOverallStats),
      awayFormSummary: _buildFormSummary(fixture.awayName, awayOverallStats),
      homeVenueFormSummary: _buildVenueSummary(
        teamName: fixture.homeName,
        stats: homeVenueStats,
        venueLabel: 'home form',
      ),
      awayVenueFormSummary: _buildVenueSummary(
        teamName: fixture.awayName,
        stats: awayVenueStats,
        venueLabel: 'away form',
      ),
      homeAdvantageSummary: _buildHomeAdvantageSummary(
        teamName: fixture.homeName,
        homeOverallStats: homeOverallStats,
        homeVenueStats: homeVenueStats,
        dynamicHomeAdvantage: dynamicHomeAdvantage,
      ),
      h2hSummary: _buildH2hSummary(
        fixture: fixture,
        homeH2hStats: homeH2hStats,
        awayH2hStats: awayH2hStats,
      ),
      modelExplanation:
          'This version upgrades Elo. Each match now adjusts rating against an estimated opponent strength from league standings. If standings are unavailable, the model falls back to a neutral opponent rating of 1500.',
      homeStrength: homeStrength,
      awayStrength: awayStrength,
      homeElo: homeOverallStats.eloLikeRating,
      awayElo: awayOverallStats.eloLikeRating,
      homeMomentum: homeOverallStats.formMomentum,
      awayMomentum: awayOverallStats.formMomentum,
      dynamicHomeAdvantage: dynamicHomeAdvantage,
    );
  }

  static TeamFormStats _buildTeamStats({
    required int teamId,
    required List<FixtureModel> fixtures,
    required int excludeFixtureId,
    required Map<int, double> opponentRatingMap,
    _VenueFilter venueFilter = _VenueFilter.all,
  }) {
    final validFixtures = fixtures.where((fixture) {
      if (fixture.fixtureId == excludeFixtureId) return false;
      if (!_isFinished(fixture.statusShort)) return false;
      if (fixture.homeGoals == null || fixture.awayGoals == null) {
        return false;
      }

      final isHome = fixture.homeTeamId == teamId;
      final isAway = fixture.awayTeamId == teamId;

      if (!isHome && !isAway) return false;

      switch (venueFilter) {
        case _VenueFilter.all:
          return true;
        case _VenueFilter.homeOnly:
          return isHome;
        case _VenueFilter.awayOnly:
          return isAway;
      }
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

      final weight = pow(ModelWeights.recentFormDecay, i).toDouble();

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

    final eloLikeRating = _calculateOpponentAdjustedElo(
      validFixtures: validFixtures,
      teamId: teamId,
      opponentRatingMap: opponentRatingMap,
    );

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

  static double _combineOverallAndVenueStrength({
    required TeamFormStats overallStats,
    required TeamFormStats venueStats,
  }) {
    final overallStrength = _teamStrength(overallStats);

    if (venueStats.matches == 0) {
      return overallStrength;
    }

    final venueStrength = _teamStrength(venueStats);

    final venueDataRatio =
        (venueStats.matches / ModelWeights.minVenueMatchesForFullBlend)
            .clamp(0.0, 1.0)
            .toDouble();

    final venueBlend = ModelWeights.venueFormBlend * venueDataRatio;
    final overallBlend = 1.0 - venueBlend;

    return (overallStrength * overallBlend) + (venueStrength * venueBlend);
  }

  static double _calculateDynamicHomeAdvantage({
    required TeamFormStats homeOverallStats,
    required TeamFormStats homeVenueStats,
  }) {
    if (homeOverallStats.matches == 0 ||
        homeVenueStats.matches < ModelWeights.minHomeVenueMatchesForAdvantage) {
      return 0.0;
    }

    final dataRatio =
        (homeVenueStats.matches / ModelWeights.minVenueMatchesForFullBlend)
            .clamp(0.0, 1.0)
            .toDouble();

    final ppgEdge =
        (homeVenueStats.weightedPointsPerGame -
            homeOverallStats.weightedPointsPerGame) *
        ModelWeights.homeAdvantagePpgWeight;

    final goalDiffEdge =
        (homeVenueStats.goalDifferencePerMatch -
            homeOverallStats.goalDifferencePerMatch) *
        ModelWeights.homeAdvantageGoalDiffWeight;

    final winRateEdge =
        (homeVenueStats.winRate - homeOverallStats.winRate) *
        ModelWeights.homeAdvantageWinRateWeight;

    final rawAdvantage = ppgEdge + goalDiffEdge + winRateEdge;

    return (rawAdvantage * dataRatio)
        .clamp(ModelWeights.homeAdvantageMin, ModelWeights.homeAdvantageMax)
        .toDouble();
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

    final opponentTeamId = isHome ? fixture.awayTeamId : fixture.homeTeamId;

    if (opponentTeamId == null) {
      return null;
    }

    final goalsFor = isHome ? fixture.homeGoals! : fixture.awayGoals!;
    final goalsAgainst = isHome ? fixture.awayGoals! : fixture.homeGoals!;

    int points;
    double actualScore;

    if (goalsFor > goalsAgainst) {
      points = 3;
      actualScore = 1.0;
    } else if (goalsFor == goalsAgainst) {
      points = 1;
      actualScore = 0.5;
    } else {
      points = 0;
      actualScore = 0.0;
    }

    return _TeamMatchResult(
      goalsFor: goalsFor,
      goalsAgainst: goalsAgainst,
      points: points,
      actualScore: actualScore,
      isHome: isHome,
      opponentTeamId: opponentTeamId,
    );
  }

  static double _calculateFormMomentum(
    List<FixtureModel> validFixtures,
    int teamId,
  ) {
    if (validFixtures.length < 5) {
      return 0;
    }

    final recentFixtures = validFixtures.take(3).toList();
    final olderFixtures = validFixtures.skip(3).take(5).toList();

    if (olderFixtures.length < 2) {
      return 0;
    }

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

  static double _calculateOpponentAdjustedElo({
    required List<FixtureModel> validFixtures,
    required int teamId,
    required Map<int, double> opponentRatingMap,
  }) {
    if (validFixtures.isEmpty) {
      return ModelWeights.eloBase;
    }

    double rating = ModelWeights.eloBase;

    for (int i = validFixtures.length - 1; i >= 0; i--) {
      final fixture = validFixtures[i];
      final result = _extractTeamMatchResult(fixture, teamId);

      if (result == null) continue;

      final opponentRating =
          opponentRatingMap[result.opponentTeamId] ?? ModelWeights.eloBase;

      final adjustedTeamRating = result.isHome
          ? rating + ModelWeights.eloHomeRatingBonus
          : rating;

      final expectedScore =
          1.0 / (1.0 + pow(10, (opponentRating - adjustedTeamRating) / 400.0));

      final goalDiff = (result.goalsFor - result.goalsAgainst).abs();
      final marginMultiplier = _calculateMarginMultiplier(goalDiff);

      final recencyWeight = pow(ModelWeights.eloRecencyDecay, i).toDouble();

      final ratingChange =
          ModelWeights.eloKFactor *
          marginMultiplier *
          (result.actualScore - expectedScore) *
          recencyWeight;

      rating += ratingChange;
    }

    return rating.clamp(ModelWeights.eloMin, ModelWeights.eloMax).toDouble();
  }

  static double _calculateMarginMultiplier(int goalDiff) {
    if (goalDiff <= 1) return 1.0;

    final cappedGoalDiff = goalDiff.clamp(1, 4);

    return 1.0 + (log(cappedGoalDiff) / log(2)) * 0.35;
  }

  static double _teamStrength(TeamFormStats stats) {
    if (stats.matches == 0) {
      return ModelWeights.baseStrength;
    }

    final formComponent =
        (stats.weightedPointsPerGame - ModelWeights.weightedPpgBaseline) *
        ModelWeights.weightedPpgWeight;

    final goalDifferenceComponent =
        stats.goalDifferencePerMatch * ModelWeights.goalDifferenceWeight;

    final winRateComponent =
        (stats.winRate - ModelWeights.winRateBaseline) *
        ModelWeights.winRateWeight;

    final momentumComponent = stats.formMomentum * ModelWeights.momentumWeight;

    final eloComponent =
        (stats.eloLikeRating - ModelWeights.eloBase) /
        ModelWeights.eloStrengthDivisor;

    return ModelWeights.baseStrength +
        formComponent +
        goalDifferenceComponent +
        winRateComponent +
        momentumComponent +
        eloComponent;
  }

  static List<int> _convertStrengthToPercent(double diff) {
    final absDiff = diff.abs();

    final draw =
        (ModelWeights.drawBase -
                min(
                  absDiff * ModelWeights.drawDiffPenalty,
                  ModelWeights.drawMaxPenalty,
                ))
            .clamp(ModelWeights.drawMin, ModelWeights.drawMax)
            .toDouble();

    final remaining = 100.0 - draw;

    final homeShare = 1.0 / (1.0 + exp(-diff / ModelWeights.sigmoidScale));

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
    required TeamFormStats homeOverallStats,
    required TeamFormStats awayOverallStats,
    required TeamFormStats homeVenueStats,
    required TeamFormStats awayVenueStats,
  }) {
    final maxPercent = max(homePercent, max(drawPercent, awayPercent));
    final minOverallMatches = min(
      homeOverallStats.matches,
      awayOverallStats.matches,
    );
    final minVenueMatches = min(homeVenueStats.matches, awayVenueStats.matches);

    if (minOverallMatches < ModelWeights.minMatchesForMediumConfidence) {
      return 'Low';
    }

    if (maxPercent >= ModelWeights.highConfidencePercent &&
        minOverallMatches >= ModelWeights.minMatchesForHighConfidence &&
        minVenueMatches >= ModelWeights.minVenueMatchesForHighConfidence) {
      return 'High';
    }

    if (maxPercent >= ModelWeights.mediumConfidencePercent) {
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

    return '$teamName overall: ${stats.recordText} • '
        'GF ${stats.goalsFor} • GA ${stats.goalsAgainst} • '
        'W-PPG ${stats.weightedPointsPerGame.toStringAsFixed(2)} • '
        'GD/Match ${stats.goalDifferencePerMatch.toStringAsFixed(2)} • '
        'Opp-Elo ${stats.eloLikeRating.toStringAsFixed(0)} • '
        'Momentum $momentumText';
  }

  static String _buildVenueSummary({
    required String teamName,
    required TeamFormStats stats,
    required String venueLabel,
  }) {
    if (stats.matches == 0) {
      return '$teamName $venueLabel: no recent finished matches found.';
    }

    final momentumText = stats.formMomentum >= 0
        ? '+${stats.formMomentum.toStringAsFixed(2)}'
        : stats.formMomentum.toStringAsFixed(2);

    return '$teamName $venueLabel: ${stats.recordText} • '
        'GF ${stats.goalsFor} • GA ${stats.goalsAgainst} • '
        'W-PPG ${stats.weightedPointsPerGame.toStringAsFixed(2)} • '
        'GD/Match ${stats.goalDifferencePerMatch.toStringAsFixed(2)} • '
        'Opp-Elo ${stats.eloLikeRating.toStringAsFixed(0)} • '
        'Momentum $momentumText';
  }

  static String _buildHomeAdvantageSummary({
    required String teamName,
    required TeamFormStats homeOverallStats,
    required TeamFormStats homeVenueStats,
    required double dynamicHomeAdvantage,
  }) {
    final advantageText = dynamicHomeAdvantage >= 0
        ? '+${dynamicHomeAdvantage.toStringAsFixed(2)}'
        : dynamicHomeAdvantage.toStringAsFixed(2);

    if (homeVenueStats.matches < ModelWeights.minHomeVenueMatchesForAdvantage) {
      return '$teamName dynamic home advantage: $advantageText • '
          'not enough home sample, neutralized.';
    }

    return '$teamName dynamic home advantage: $advantageText • '
        'home W-PPG ${homeVenueStats.weightedPointsPerGame.toStringAsFixed(2)} '
        'vs overall W-PPG ${homeOverallStats.weightedPointsPerGame.toStringAsFixed(2)}';
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

enum _VenueFilter { all, homeOnly, awayOnly }

class _TeamMatchResult {
  final int goalsFor;
  final int goalsAgainst;
  final int points;
  final double actualScore;
  final bool isHome;
  final int opponentTeamId;

  const _TeamMatchResult({
    required this.goalsFor,
    required this.goalsAgainst,
    required this.points,
    required this.actualScore,
    required this.isHome,
    required this.opponentTeamId,
  });
}
