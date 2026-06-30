import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config/api_config.dart';
import '../config/model_weights.dart';
import '../models/backtest_result_model.dart';
import '../models/fixture_model.dart';
import 'custom_predictor.dart';

class BacktestService {
  Map<String, String> get _headers {
    return {'x-apisports-key': ApiConfig.apiKey};
  }

  Future<BacktestResultModel> runBacktest({
    required int leagueId,
    required int season,
    required int maxMatches,
  }) async {
    _validateApiKey();

    final allFixtures = await _getFixturesByLeagueSeason(
      leagueId: leagueId,
      season: season,
    );

    final finishedFixtures = allFixtures.where((fixture) {
      return _isFinished(fixture.statusShort) &&
          fixture.homeGoals != null &&
          fixture.awayGoals != null &&
          fixture.homeTeamId != null &&
          fixture.awayTeamId != null;
    }).toList();

    finishedFixtures.sort(_compareFixtureDateAsc);

    if (finishedFixtures.isEmpty) {
      return const BacktestResultModel(
        total: 0,
        correct: 0,
        wrong: 0,
        accuracy: 0,
        brierScore: 0,
        buckets: [],
        records: [],
      );
    }

    final candidateFixtures = finishedFixtures.reversed
        .take(maxMatches)
        .toList()
        .reversed
        .toList();

    final records = <BacktestMatchRecordModel>[];

    for (final fixture in candidateFixtures) {
      final fixtureDate = DateTime.tryParse(fixture.date);

      if (fixtureDate == null) continue;

      final previousFixtures = finishedFixtures.where((item) {
        final itemDate = DateTime.tryParse(item.date);
        if (itemDate == null) return false;

        return itemDate.isBefore(fixtureDate);
      }).toList();

      final homeRecentFixtures = _teamRecentFixtures(
        previousFixtures: previousFixtures,
        teamId: fixture.homeTeamId!,
        limit: 10,
      );

      final awayRecentFixtures = _teamRecentFixtures(
        previousFixtures: previousFixtures,
        teamId: fixture.awayTeamId!,
        limit: 10,
      );

      if (homeRecentFixtures.length < 3 || awayRecentFixtures.length < 3) {
        continue;
      }

      final h2hFixtures = _h2hFixtures(
        previousFixtures: previousFixtures,
        homeTeamId: fixture.homeTeamId!,
        awayTeamId: fixture.awayTeamId!,
        limit: 5,
      );

      final opponentRatingMap = _buildOpponentRatingMap(previousFixtures);

      final prediction = CustomPredictor.predict(
        fixture: fixture,
        homeRecentFixtures: homeRecentFixtures,
        awayRecentFixtures: awayRecentFixtures,
        h2hFixtures: h2hFixtures,
        opponentRatingMap: opponentRatingMap,
      );

      final predictedLabel =
          prediction.advice ?? prediction.winnerName ?? 'N/A';
      final actualLabel = _actualResult(fixture);

      final isCorrect =
          _normalizeResult(predictedLabel) == _normalizeResult(actualLabel);

      final homeProbability = _parsePercent(prediction.percentHome);
      final drawProbability = _parsePercent(prediction.percentDraw);
      final awayProbability = _parsePercent(prediction.percentAway);

      final maxProbability = [
        homeProbability,
        drawProbability,
        awayProbability,
      ].reduce((a, b) => a > b ? a : b);

      records.add(
        BacktestMatchRecordModel(
          fixtureId: fixture.fixtureId,
          date: fixture.date,
          leagueName: fixture.leagueName,
          homeName: fixture.homeName,
          awayName: fixture.awayName,
          homeLogo: fixture.homeLogo,
          awayLogo: fixture.awayLogo,
          predictedLabel: predictedLabel,
          actualLabel: actualLabel,
          homePercent: prediction.percentHome ?? 'N/A',
          drawPercent: prediction.percentDraw ?? 'N/A',
          awayPercent: prediction.percentAway ?? 'N/A',
          homeProbability: homeProbability,
          drawProbability: drawProbability,
          awayProbability: awayProbability,
          maxProbability: maxProbability,
          modelName: prediction.modelName,
          confidence: prediction.confidence,
          homeGoals: fixture.homeGoals!,
          awayGoals: fixture.awayGoals!,
          isCorrect: isCorrect,
        ),
      );
    }

    return _buildResult(records);
  }

  Future<List<FixtureModel>> _getFixturesByLeagueSeason({
    required int leagueId,
    required int season,
  }) async {
    final data = await _get(
      endpoint: '/fixtures',
      queryParameters: {
        'league': leagueId.toString(),
        'season': season.toString(),
      },
    );

    final list = data['response'] as List<dynamic>? ?? [];

    return list
        .map((item) => FixtureModel.fromApi(item as Map<String, dynamic>))
        .toList();
  }

  Future<Map<String, dynamic>> _get({
    required String endpoint,
    required Map<String, String> queryParameters,
  }) async {
    final uri = Uri.parse(
      '${ApiConfig.baseUrl}$endpoint',
    ).replace(queryParameters: queryParameters);

    final response = await http.get(uri, headers: _headers);

    return _decodeResponse(response);
  }

  Map<String, dynamic> _decodeResponse(http.Response response) {
    if (response.statusCode != 200) {
      throw Exception('API lỗi HTTP ${response.statusCode}: ${response.body}');
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;

    final errors = data['errors'];

    if (_hasErrors(errors)) {
      throw Exception('API error: $errors');
    }

    return data;
  }

  bool _hasErrors(dynamic errors) {
    if (errors == null) return false;

    if (errors is Map) {
      return errors.isNotEmpty;
    }

    if (errors is List) {
      return errors.isNotEmpty;
    }

    if (errors is String) {
      return errors.trim().isNotEmpty;
    }

    return false;
  }

  List<FixtureModel> _teamRecentFixtures({
    required List<FixtureModel> previousFixtures,
    required int teamId,
    required int limit,
  }) {
    final fixtures = previousFixtures.where((fixture) {
      return fixture.homeTeamId == teamId || fixture.awayTeamId == teamId;
    }).toList();

    fixtures.sort(_compareFixtureDateDesc);

    return fixtures.take(limit).toList();
  }

  List<FixtureModel> _h2hFixtures({
    required List<FixtureModel> previousFixtures,
    required int homeTeamId,
    required int awayTeamId,
    required int limit,
  }) {
    final fixtures = previousFixtures.where((fixture) {
      final sameDirection =
          fixture.homeTeamId == homeTeamId && fixture.awayTeamId == awayTeamId;

      final oppositeDirection =
          fixture.homeTeamId == awayTeamId && fixture.awayTeamId == homeTeamId;

      return sameDirection || oppositeDirection;
    }).toList();

    fixtures.sort(_compareFixtureDateDesc);

    return fixtures.take(limit).toList();
  }

  Map<int, double> _buildOpponentRatingMap(
    List<FixtureModel> previousFixtures,
  ) {
    final statsMap = <int, _BacktestTeamStats>{};

    for (final fixture in previousFixtures) {
      if (!_isFinished(fixture.statusShort)) continue;
      if (fixture.homeTeamId == null || fixture.awayTeamId == null) continue;
      if (fixture.homeGoals == null || fixture.awayGoals == null) continue;

      final homeStats = statsMap.putIfAbsent(
        fixture.homeTeamId!,
        () => _BacktestTeamStats(),
      );

      final awayStats = statsMap.putIfAbsent(
        fixture.awayTeamId!,
        () => _BacktestTeamStats(),
      );

      homeStats.played++;
      awayStats.played++;

      homeStats.goalsFor += fixture.homeGoals!;
      homeStats.goalsAgainst += fixture.awayGoals!;

      awayStats.goalsFor += fixture.awayGoals!;
      awayStats.goalsAgainst += fixture.homeGoals!;

      if (fixture.homeGoals! > fixture.awayGoals!) {
        homeStats.wins++;
        homeStats.points += 3;
      } else if (fixture.homeGoals! < fixture.awayGoals!) {
        awayStats.wins++;
        awayStats.points += 3;
      } else {
        homeStats.points += 1;
        awayStats.points += 1;
      }
    }

    final ratingMap = <int, double>{};

    for (final entry in statsMap.entries) {
      final stats = entry.value;

      if (stats.played == 0) continue;

      final ppg = stats.points / stats.played;
      final goalDiffPerMatch =
          (stats.goalsFor - stats.goalsAgainst) / stats.played;
      final winRate = stats.wins / stats.played;

      final rating =
          ModelWeights.eloBase +
          ((ppg - ModelWeights.weightedPpgBaseline) *
              ModelWeights.standingsPpgWeight) +
          (goalDiffPerMatch * ModelWeights.standingsGoalDiffWeight) +
          ((winRate - ModelWeights.winRateBaseline) *
              ModelWeights.standingsWinRateWeight);

      ratingMap[entry.key] = rating
          .clamp(ModelWeights.eloMin, ModelWeights.eloMax)
          .toDouble();
    }

    return ratingMap;
  }

  BacktestResultModel _buildResult(List<BacktestMatchRecordModel> records) {
    final total = records.length;
    final correct = records.where((record) => record.isCorrect).length;
    final wrong = total - correct;
    final accuracy = total == 0 ? 0.0 : (correct / total) * 100;
    final brierScore = _calculateBrierScore(records);
    final buckets = _buildBuckets(records);

    return BacktestResultModel(
      total: total,
      correct: correct,
      wrong: wrong,
      accuracy: accuracy,
      brierScore: brierScore,
      buckets: buckets,
      records: records.reversed.toList(),
    );
  }

  double _calculateBrierScore(List<BacktestMatchRecordModel> records) {
    if (records.isEmpty) return 0;

    double total = 0;

    for (final record in records) {
      final actualHome = record.actualLabel == 'Home Win' ? 1.0 : 0.0;
      final actualDraw = record.actualLabel == 'Draw' ? 1.0 : 0.0;
      final actualAway = record.actualLabel == 'Away Win' ? 1.0 : 0.0;

      final homeError = record.homeProbability - actualHome;
      final drawError = record.drawProbability - actualDraw;
      final awayError = record.awayProbability - actualAway;

      total +=
          (homeError * homeError) +
          (drawError * drawError) +
          (awayError * awayError);
    }

    return total / records.length;
  }

  List<BacktestBucketModel> _buildBuckets(
    List<BacktestMatchRecordModel> records,
  ) {
    final configs = [
      _BucketConfig(label: '<40%', min: 0.0, max: 0.3999),
      _BucketConfig(label: '40-49%', min: 0.4, max: 0.4999),
      _BucketConfig(label: '50-59%', min: 0.5, max: 0.5999),
      _BucketConfig(label: '60%+', min: 0.6, max: 1.0),
    ];

    return configs.map((config) {
      final bucketRecords = records.where((record) {
        return record.maxProbability >= config.min &&
            record.maxProbability <= config.max;
      }).toList();

      final total = bucketRecords.length;
      final correct = bucketRecords.where((record) => record.isCorrect).length;
      final accuracy = total == 0 ? 0.0 : (correct / total) * 100;

      return BacktestBucketModel(
        label: config.label,
        total: total,
        correct: correct,
        accuracy: accuracy,
      );
    }).toList();
  }

  int _compareFixtureDateAsc(FixtureModel a, FixtureModel b) {
    final dateA = DateTime.tryParse(a.date);
    final dateB = DateTime.tryParse(b.date);

    if (dateA == null && dateB == null) return 0;
    if (dateA == null) return 1;
    if (dateB == null) return -1;

    return dateA.compareTo(dateB);
  }

  int _compareFixtureDateDesc(FixtureModel a, FixtureModel b) {
    final dateA = DateTime.tryParse(a.date);
    final dateB = DateTime.tryParse(b.date);

    if (dateA == null && dateB == null) return 0;
    if (dateA == null) return 1;
    if (dateB == null) return -1;

    return dateB.compareTo(dateA);
  }

  String _actualResult(FixtureModel fixture) {
    if (fixture.homeGoals! > fixture.awayGoals!) {
      return 'Home Win';
    }

    if (fixture.awayGoals! > fixture.homeGoals!) {
      return 'Away Win';
    }

    return 'Draw';
  }

  String _normalizeResult(String value) {
    final text = value.toLowerCase().trim();

    if (text.contains('home')) return 'home_win';
    if (text.contains('away')) return 'away_win';
    if (text.contains('draw')) return 'draw';

    return text;
  }

  double _parsePercent(String? value) {
    if (value == null) return 0;

    final cleaned = value.replaceAll('%', '').trim();
    final parsed = double.tryParse(cleaned) ?? 0;

    return parsed / 100;
  }

  bool _isFinished(String statusShort) {
    return statusShort == 'FT' || statusShort == 'AET' || statusShort == 'PEN';
  }

  void _validateApiKey() {
    if (ApiConfig.apiKey.isEmpty) {
      throw Exception(
        'Thiếu API key. Hãy chạy app bằng lệnh: flutter run --dart-define=FOOTBALL_API_KEY=API_KEY_CUA_BAN',
      );
    }
  }
}

class _BacktestTeamStats {
  int played = 0;
  int wins = 0;
  int points = 0;
  int goalsFor = 0;
  int goalsAgainst = 0;
}

class _BucketConfig {
  final String label;
  final double min;
  final double max;

  const _BucketConfig({
    required this.label,
    required this.min,
    required this.max,
  });
}
