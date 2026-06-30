class PredictionModel {
  final String? winnerName;
  final String? winnerComment;
  final String? advice;
  final String? percentHome;
  final String? percentDraw;
  final String? percentAway;

  final String modelName;
  final String? confidence;
  final String? homeFormSummary;
  final String? awayFormSummary;
  final String? homeVenueFormSummary;
  final String? awayVenueFormSummary;
  final String? homeAdvantageSummary;
  final String? h2hSummary;
  final String? modelExplanation;

  final double? homeStrength;
  final double? awayStrength;

  final double? homeElo;
  final double? awayElo;
  final double? homeMomentum;
  final double? awayMomentum;
  final double? dynamicHomeAdvantage;

  PredictionModel({
    required this.winnerName,
    required this.winnerComment,
    required this.advice,
    required this.percentHome,
    required this.percentDraw,
    required this.percentAway,
    this.modelName = 'API Prediction',
    this.confidence,
    this.homeFormSummary,
    this.awayFormSummary,
    this.homeVenueFormSummary,
    this.awayVenueFormSummary,
    this.homeAdvantageSummary,
    this.h2hSummary,
    this.modelExplanation,
    this.homeStrength,
    this.awayStrength,
    this.homeElo,
    this.awayElo,
    this.homeMomentum,
    this.awayMomentum,
    this.dynamicHomeAdvantage,
  });

  factory PredictionModel.fromApi(Map<String, dynamic> json) {
    final predictions = json['predictions'] as Map<String, dynamic>? ?? {};
    final winner = predictions['winner'] as Map<String, dynamic>? ?? {};
    final percent = predictions['percent'] as Map<String, dynamic>? ?? {};

    return PredictionModel(
      winnerName: winner['name']?.toString(),
      winnerComment: winner['comment']?.toString(),
      advice: predictions['advice']?.toString(),
      percentHome: percent['home']?.toString(),
      percentDraw: percent['draw']?.toString(),
      percentAway: percent['away']?.toString(),
      modelName: 'API-Football Prediction',
      confidence: null,
      modelExplanation: 'Prediction returned directly from API-Football.',
    );
  }
}
