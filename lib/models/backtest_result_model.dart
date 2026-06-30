class BacktestResultModel {
  final int total;
  final int correct;
  final int wrong;
  final double accuracy;
  final double brierScore;
  final List<BacktestBucketModel> buckets;
  final List<BacktestMatchRecordModel> records;

  const BacktestResultModel({
    required this.total,
    required this.correct,
    required this.wrong,
    required this.accuracy,
    required this.brierScore,
    required this.buckets,
    required this.records,
  });
}

class BacktestBucketModel {
  final String label;
  final int total;
  final int correct;
  final double accuracy;

  const BacktestBucketModel({
    required this.label,
    required this.total,
    required this.correct,
    required this.accuracy,
  });
}

class BacktestMatchRecordModel {
  final int fixtureId;
  final String date;
  final String leagueName;

  final String homeName;
  final String awayName;
  final String? homeLogo;
  final String? awayLogo;

  final String predictedLabel;
  final String actualLabel;

  final String homePercent;
  final String drawPercent;
  final String awayPercent;

  final double homeProbability;
  final double drawProbability;
  final double awayProbability;
  final double maxProbability;

  final String modelName;
  final String? confidence;

  final int homeGoals;
  final int awayGoals;
  final bool isCorrect;

  const BacktestMatchRecordModel({
    required this.fixtureId,
    required this.date,
    required this.leagueName,
    required this.homeName,
    required this.awayName,
    required this.homeLogo,
    required this.awayLogo,
    required this.predictedLabel,
    required this.actualLabel,
    required this.homePercent,
    required this.drawPercent,
    required this.awayPercent,
    required this.homeProbability,
    required this.drawProbability,
    required this.awayProbability,
    required this.maxProbability,
    required this.modelName,
    required this.confidence,
    required this.homeGoals,
    required this.awayGoals,
    required this.isCorrect,
  });
}
