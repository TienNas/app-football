import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';

import '../config/api_config.dart';
import '../config/model_weights.dart';
import '../models/fixture_model.dart';
import '../models/prediction_model.dart';
import 'custom_predictor.dart';

class FootballApiService {
  static final Map<String, List<FixtureModel>> _fixturesByDateCache = {};
  static final Map<String, List<FixtureModel>> _recentFixturesCache = {};
  static final Map<String, List<FixtureModel>> _h2hCache = {};
  static final Map<String, Map<int, double>> _standingsRatingCache = {};
  static final Map<int, PredictionModel> _predictionCache = {};

  Map<String, String> get _headers {
    return {'x-apisports-key': ApiConfig.apiKey};
  }

  Future<List<FixtureModel>> getFixturesByDate(
    DateTime date, {
    bool forceRefresh = false,
  }) async {
    _validateApiKey();

    final dateText = DateFormat('yyyy-MM-dd').format(date);

    if (!forceRefresh && _fixturesByDateCache.containsKey(dateText)) {
      return _fixturesByDateCache[dateText]!;
    }

    final data = await _get(
      endpoint: '/fixtures',
      queryParameters: {'date': dateText},
    );

    final fixtures = _parseFixtureList(data);

    _fixturesByDateCache[dateText] = fixtures;

    return fixtures;
  }

  Future<PredictionModel> getPrediction(
    FixtureModel fixture, {
    bool forceRefresh = false,
  }) async {
    _validateApiKey();

    if (!forceRefresh && _predictionCache.containsKey(fixture.fixtureId)) {
      return _predictionCache[fixture.fixtureId]!;
    }

    if (fixture.homeTeamId == null || fixture.awayTeamId == null) {
      throw Exception('Thiếu homeTeamId hoặc awayTeamId để tự dự đoán.');
    }

    final results = await Future.wait([
      getRecentFixturesByTeam(
        fixture.homeTeamId!,
        limit: 10,
        forceRefresh: forceRefresh,
      ),
      getRecentFixturesByTeam(
        fixture.awayTeamId!,
        limit: 10,
        forceRefresh: forceRefresh,
      ),
      getHeadToHeadFixtures(
        homeTeamId: fixture.homeTeamId!,
        awayTeamId: fixture.awayTeamId!,
        limit: 5,
        forceRefresh: forceRefresh,
      ),
    ]);

    Map<int, double> standingsRatingMap = {};

    if (fixture.leagueId != null && fixture.season != null) {
      try {
        standingsRatingMap = await getStandingsRatingMap(
          leagueId: fixture.leagueId!,
          season: fixture.season!,
          forceRefresh: forceRefresh,
        );
      } catch (_) {
        standingsRatingMap = {};
      }
    }

    final homeRecentFixtures = results[0];
    final awayRecentFixtures = results[1];
    final h2hFixtures = results[2];

    final prediction = CustomPredictor.predict(
      fixture: fixture,
      homeRecentFixtures: homeRecentFixtures,
      awayRecentFixtures: awayRecentFixtures,
      h2hFixtures: h2hFixtures,
      opponentRatingMap: standingsRatingMap,
    );

    _predictionCache[fixture.fixtureId] = prediction;

    return prediction;
  }

  Future<List<FixtureModel>> getRecentFixturesByTeam(
    int teamId, {
    int limit = 10,
    bool forceRefresh = false,
  }) async {
    final cacheKey = '$teamId-$limit';

    if (!forceRefresh && _recentFixturesCache.containsKey(cacheKey)) {
      return _recentFixturesCache[cacheKey]!;
    }

    final data = await _get(
      endpoint: '/fixtures',
      queryParameters: {'team': teamId.toString(), 'last': limit.toString()},
    );

    final fixtures = _parseFixtureList(data);

    _recentFixturesCache[cacheKey] = fixtures;

    return fixtures;
  }

  Future<List<FixtureModel>> getHeadToHeadFixtures({
    required int homeTeamId,
    required int awayTeamId,
    int limit = 5,
    bool forceRefresh = false,
  }) async {
    final cacheKey = '$homeTeamId-$awayTeamId-$limit';

    if (!forceRefresh && _h2hCache.containsKey(cacheKey)) {
      return _h2hCache[cacheKey]!;
    }

    final data = await _get(
      endpoint: '/fixtures/headtohead',
      queryParameters: {
        'h2h': '$homeTeamId-$awayTeamId',
        'last': limit.toString(),
      },
    );

    final fixtures = _parseFixtureList(data);

    _h2hCache[cacheKey] = fixtures;

    return fixtures;
  }

  Future<Map<int, double>> getStandingsRatingMap({
    required int leagueId,
    required int season,
    bool forceRefresh = false,
  }) async {
    final cacheKey = '$leagueId-$season';

    if (!forceRefresh && _standingsRatingCache.containsKey(cacheKey)) {
      return _standingsRatingCache[cacheKey]!;
    }

    final data = await _get(
      endpoint: '/standings',
      queryParameters: {
        'league': leagueId.toString(),
        'season': season.toString(),
      },
    );

    final ratingMap = _parseStandingsRatingMap(data);

    _standingsRatingCache[cacheKey] = ratingMap;

    return ratingMap;
  }

  void clearCache() {
    _fixturesByDateCache.clear();
    _recentFixturesCache.clear();
    _h2hCache.clear();
    _standingsRatingCache.clear();
    _predictionCache.clear();
  }

  void clearPredictionCache(int fixtureId) {
    _predictionCache.remove(fixtureId);
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

  List<FixtureModel> _parseFixtureList(Map<String, dynamic> data) {
    final list = data['response'] as List<dynamic>? ?? [];

    return list
        .map((item) => FixtureModel.fromApi(item as Map<String, dynamic>))
        .toList();
  }

  Map<int, double> _parseStandingsRatingMap(Map<String, dynamic> data) {
    final response = data['response'] as List<dynamic>? ?? [];

    if (response.isEmpty) {
      return {};
    }

    final firstLeague = response.first as Map<String, dynamic>? ?? {};
    final league = firstLeague['league'] as Map<String, dynamic>? ?? {};
    final standingsGroups = league['standings'] as List<dynamic>? ?? [];

    final rows = <Map<String, dynamic>>[];

    for (final group in standingsGroups) {
      if (group is List) {
        for (final row in group) {
          if (row is Map<String, dynamic>) {
            rows.add(row);
          }
        }
      }
    }

    if (rows.isEmpty) {
      return {};
    }

    final teamCount = rows.length;
    final ratingMap = <int, double>{};

    for (final row in rows) {
      final team = row['team'] as Map<String, dynamic>? ?? {};
      final all = row['all'] as Map<String, dynamic>? ?? {};

      final teamId = _toInt(team['id']);
      final rank = _toInt(row['rank']) ?? teamCount;
      final points = _toInt(row['points']) ?? 0;
      final goalsDiff = _toInt(row['goalsDiff']) ?? 0;

      final played = _toInt(all['played']) ?? 0;
      final wins = _toInt(all['win']) ?? 0;

      if (teamId == null || played == 0) {
        continue;
      }

      final ppg = points / played;
      final goalDiffPerMatch = goalsDiff / played;
      final winRate = wins / played;

      final rankComponent =
          ((teamCount + 1) / 2 - rank) * ModelWeights.standingsRankWeight;

      final rating =
          ModelWeights.eloBase +
          ((ppg - ModelWeights.weightedPpgBaseline) *
              ModelWeights.standingsPpgWeight) +
          (goalDiffPerMatch * ModelWeights.standingsGoalDiffWeight) +
          ((winRate - ModelWeights.winRateBaseline) *
              ModelWeights.standingsWinRateWeight) +
          rankComponent;

      ratingMap[teamId] = rating
          .clamp(ModelWeights.eloMin, ModelWeights.eloMax)
          .toDouble();
    }

    return ratingMap;
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

  int? _toInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    return int.tryParse(value.toString());
  }

  void _validateApiKey() {
    if (ApiConfig.apiKey.isEmpty) {
      throw Exception(
        'Thiếu API key. Hãy chạy app bằng lệnh: flutter run --dart-define=FOOTBALL_API_KEY=API_KEY_CUA_BAN',
      );
    }
  }
}
