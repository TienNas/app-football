class ModelWeights {
  const ModelWeights._();

  // ===== Base score =====
  static const double baseStrength = 50.0;

  // ===== Recent form =====
  static const double recentFormDecay = 0.82;
  static const double weightedPpgBaseline = 1.20;
  static const double weightedPpgWeight = 13.5;

  // ===== Venue form =====
  static const double venueFormBlend = 0.30;
  static const int minVenueMatchesForFullBlend = 4;

  // ===== Goals =====
  static const double goalDifferenceWeight = 8.5;

  // ===== Win rate =====
  static const double winRateBaseline = 0.35;
  static const double winRateWeight = 7.0;

  // ===== Momentum =====
  static const double momentumWeight = 3.0;
  static const double momentumEdgeMultiplier = 2.8;
  static const double momentumEdgeMin = -6.0;
  static const double momentumEdgeMax = 6.0;

  // ===== Dynamic home advantage =====
  static const int minHomeVenueMatchesForAdvantage = 2;
  static const double homeAdvantagePpgWeight = 4.2;
  static const double homeAdvantageGoalDiffWeight = 2.4;
  static const double homeAdvantageWinRateWeight = 3.2;
  static const double homeAdvantageMin = -4.0;
  static const double homeAdvantageMax = 8.0;

  // ===== H2H =====
  static const double h2hPpgMultiplier = 3.8;
  static const double h2hEdgeMin = -7.0;
  static const double h2hEdgeMax = 7.0;

  // ===== Opponent-adjusted Elo =====
  static const double eloBase = 1500.0;
  static const double eloMin = 1350.0;
  static const double eloMax = 1650.0;

  static const double eloStrengthDivisor = 18.0;
  static const double eloEdgeDivisor = 22.0;
  static const double eloEdgeMin = -8.0;
  static const double eloEdgeMax = 8.0;

  static const double eloKFactor = 28.0;
  static const double eloRecencyDecay = 0.92;
  static const double eloHomeRatingBonus = 45.0;

  // ===== Standings proxy rating =====
  static const double standingsPpgWeight = 90.0;
  static const double standingsGoalDiffWeight = 35.0;
  static const double standingsWinRateWeight = 55.0;
  static const double standingsRankWeight = 4.0;

  // ===== Probability conversion =====
  static const double drawBase = 30.0;
  static const double drawMin = 12.0;
  static const double drawMax = 30.0;
  static const double drawDiffPenalty = 0.50;
  static const double drawMaxPenalty = 18.0;

  static const double sigmoidScale = 20.0;

  // ===== Confidence =====
  static const int minMatchesForMediumConfidence = 3;
  static const int minMatchesForHighConfidence = 6;
  static const int minVenueMatchesForHighConfidence = 2;
  static const int highConfidencePercent = 60;
  static const int mediumConfidencePercent = 46;
}
