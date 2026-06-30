class PredictionRecordModel {
  final int fixtureId;
  final String date;
  final String leagueName;

  final String homeName;
  final String awayName;
  final String? homeLogo;
  final String? awayLogo;

  final String predictedLabel;
  final String homePercent;
  final String drawPercent;
  final String awayPercent;

  final String modelName;
  final String? confidence;

  final String? actualResult;
  final int? homeGoals;
  final int? awayGoals;
  final bool? isCorrect;

  final String createdAt;

  const PredictionRecordModel({
    required this.fixtureId,
    required this.date,
    required this.leagueName,
    required this.homeName,
    required this.awayName,
    required this.homeLogo,
    required this.awayLogo,
    required this.predictedLabel,
    required this.homePercent,
    required this.drawPercent,
    required this.awayPercent,
    required this.modelName,
    required this.confidence,
    required this.actualResult,
    required this.homeGoals,
    required this.awayGoals,
    required this.isCorrect,
    required this.createdAt,
  });

  factory PredictionRecordModel.fromJson(Map<String, dynamic> json) {
    return PredictionRecordModel(
      fixtureId: _toInt(json['fixtureId']) ?? 0,
      date: json['date']?.toString() ?? '',
      leagueName: json['leagueName']?.toString() ?? '',
      homeName: json['homeName']?.toString() ?? 'Home',
      awayName: json['awayName']?.toString() ?? 'Away',
      homeLogo: json['homeLogo']?.toString(),
      awayLogo: json['awayLogo']?.toString(),
      predictedLabel: json['predictedLabel']?.toString() ?? 'N/A',
      homePercent: json['homePercent']?.toString() ?? 'N/A',
      drawPercent: json['drawPercent']?.toString() ?? 'N/A',
      awayPercent: json['awayPercent']?.toString() ?? 'N/A',
      modelName: json['modelName']?.toString() ?? 'Unknown Model',
      confidence: json['confidence']?.toString(),
      actualResult: json['actualResult']?.toString(),
      homeGoals: _toInt(json['homeGoals']),
      awayGoals: _toInt(json['awayGoals']),
      isCorrect: _toBool(json['isCorrect']),
      createdAt: json['createdAt']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'fixtureId': fixtureId,
      'date': date,
      'leagueName': leagueName,
      'homeName': homeName,
      'awayName': awayName,
      'homeLogo': homeLogo,
      'awayLogo': awayLogo,
      'predictedLabel': predictedLabel,
      'homePercent': homePercent,
      'drawPercent': drawPercent,
      'awayPercent': awayPercent,
      'modelName': modelName,
      'confidence': confidence,
      'actualResult': actualResult,
      'homeGoals': homeGoals,
      'awayGoals': awayGoals,
      'isCorrect': isCorrect,
      'createdAt': createdAt,
    };
  }

  static int? _toInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    return int.tryParse(value.toString());
  }

  static bool? _toBool(dynamic value) {
    if (value == null) return null;
    if (value is bool) return value;

    final text = value.toString().toLowerCase();

    if (text == 'true') return true;
    if (text == 'false') return false;

    return null;
  }
}
