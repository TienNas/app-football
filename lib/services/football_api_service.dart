import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';

import '../config/api_config.dart';
import '../models/fixture_model.dart';
import '../models/prediction_model.dart';
import 'custom_predictor.dart';

class FootballApiService {
  static final Map<String, List<FixtureModel>> _fixturesByDateCache = {};
  static final Map<String, List<FixtureModel>> _recentFixturesCache = {};
  static final Map<String, List<FixtureModel>> _h2hCache = {};
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

    final homeRecentFixtures = results[0];
    final awayRecentFixtures = results[1];
    final h2hFixtures = results[2];

    final prediction = CustomPredictor.predict(
      fixture: fixture,
      homeRecentFixtures: homeRecentFixtures,
      awayRecentFixtures: awayRecentFixtures,
      h2hFixtures: h2hFixtures,
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

  void clearCache() {
    _fixturesByDateCache.clear();
    _recentFixturesCache.clear();
    _h2hCache.clear();
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

  void _validateApiKey() {
    if (ApiConfig.apiKey.isEmpty) {
      throw Exception(
        'Thiếu API key. Hãy chạy app bằng lệnh: flutter run --dart-define=FOOTBALL_API_KEY=API_KEY_CUA_BAN',
      );
    }
  }
}
