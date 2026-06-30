import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/fixture_model.dart';
import '../models/prediction_model.dart';
import '../models/prediction_record_model.dart';

class PredictionHistoryService {
  static const String _recordsKey = 'prediction_records';
  static const int _maxRecords = 300;

  final SharedPreferencesAsync _prefs = SharedPreferencesAsync();

  Future<List<PredictionRecordModel>> getRecords() async {
    final rawList = await _prefs.getStringList(_recordsKey) ?? [];

    final records = <PredictionRecordModel>[];

    for (final raw in rawList) {
      try {
        final decoded = jsonDecode(raw) as Map<String, dynamic>;
        records.add(PredictionRecordModel.fromJson(decoded));
      } catch (_) {
        continue;
      }
    }

    records.sort((a, b) {
      final dateA = DateTime.tryParse(a.createdAt);
      final dateB = DateTime.tryParse(b.createdAt);

      if (dateA == null && dateB == null) return 0;
      if (dateA == null) return 1;
      if (dateB == null) return -1;

      return dateB.compareTo(dateA);
    });

    return records;
  }

  Future<void> savePrediction({
    required FixtureModel fixture,
    required PredictionModel prediction,
  }) async {
    final records = await getRecords();

    records.removeWhere((record) => record.fixtureId == fixture.fixtureId);

    final actualResult = _buildActualResult(fixture);
    final predictedLabel = prediction.advice ?? prediction.winnerName ?? 'N/A';

    final isCorrect = actualResult == null
        ? null
        : _normalizeResult(predictedLabel) == _normalizeResult(actualResult);

    final record = PredictionRecordModel(
      fixtureId: fixture.fixtureId,
      date: fixture.date,
      leagueName: fixture.leagueName,
      homeName: fixture.homeName,
      awayName: fixture.awayName,
      homeLogo: fixture.homeLogo,
      awayLogo: fixture.awayLogo,
      predictedLabel: predictedLabel,
      homePercent: prediction.percentHome ?? 'N/A',
      drawPercent: prediction.percentDraw ?? 'N/A',
      awayPercent: prediction.percentAway ?? 'N/A',
      modelName: prediction.modelName,
      confidence: prediction.confidence,
      actualResult: actualResult,
      homeGoals: fixture.homeGoals,
      awayGoals: fixture.awayGoals,
      isCorrect: isCorrect,
      createdAt: DateTime.now().toIso8601String(),
    );

    records.insert(0, record);

    final limited = records.take(_maxRecords).toList();

    await _writeRecords(limited);
  }

  Future<void> clearRecords() async {
    await _prefs.remove(_recordsKey);
  }

  Future<void> _writeRecords(List<PredictionRecordModel> records) async {
    final rawList = records.map((record) {
      return jsonEncode(record.toJson());
    }).toList();

    await _prefs.setStringList(_recordsKey, rawList);
  }

  String? _buildActualResult(FixtureModel fixture) {
    if (!_isFinished(fixture.statusShort)) return null;
    if (fixture.homeGoals == null || fixture.awayGoals == null) return null;

    if (fixture.homeGoals! > fixture.awayGoals!) {
      return 'Home Win';
    }

    if (fixture.awayGoals! > fixture.homeGoals!) {
      return 'Away Win';
    }

    return 'Draw';
  }

  bool _isFinished(String statusShort) {
    return statusShort == 'FT' || statusShort == 'AET' || statusShort == 'PEN';
  }

  String _normalizeResult(String value) {
    final text = value.toLowerCase().trim();

    if (text.contains('home')) return 'home_win';
    if (text.contains('away')) return 'away_win';
    if (text.contains('draw')) return 'draw';

    return text;
  }
}
