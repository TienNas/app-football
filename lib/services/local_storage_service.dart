import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/fixture_model.dart';
import '../models/saved_match_model.dart';

class LocalStorageService {
  static const String _favoritesKey = 'favorite_matches';
  static const String _historyKey = 'viewed_matches';

  static const int _maxFavorites = 100;
  static const int _maxHistory = 50;

  final SharedPreferencesAsync _prefs = SharedPreferencesAsync();

  Future<List<SavedMatchModel>> getFavorites() async {
    return _readMatchList(_favoritesKey);
  }

  Future<List<SavedMatchModel>> getHistory() async {
    return _readMatchList(_historyKey);
  }

  Future<bool> isFavorite(int fixtureId) async {
    final favorites = await getFavorites();
    return favorites.any((match) => match.fixtureId == fixtureId);
  }

  Future<void> toggleFavorite(FixtureModel fixture) async {
    final favorites = await getFavorites();

    final exists = favorites.any(
      (match) => match.fixtureId == fixture.fixtureId,
    );

    if (exists) {
      favorites.removeWhere((match) => match.fixtureId == fixture.fixtureId);
    } else {
      favorites.insert(0, SavedMatchModel.fromFixture(fixture));
    }

    final limited = favorites.take(_maxFavorites).toList();

    await _writeMatchList(_favoritesKey, limited);
  }

  Future<void> removeFavorite(int fixtureId) async {
    final favorites = await getFavorites();

    favorites.removeWhere((match) => match.fixtureId == fixtureId);

    await _writeMatchList(_favoritesKey, favorites);
  }

  Future<void> addToHistory(FixtureModel fixture) async {
    final history = await getHistory();

    history.removeWhere((match) => match.fixtureId == fixture.fixtureId);
    history.insert(0, SavedMatchModel.fromFixture(fixture));

    final limited = history.take(_maxHistory).toList();

    await _writeMatchList(_historyKey, limited);
  }

  Future<void> clearHistory() async {
    await _prefs.remove(_historyKey);
  }

  Future<List<SavedMatchModel>> _readMatchList(String key) async {
    final rawList = await _prefs.getStringList(key) ?? [];

    final matches = <SavedMatchModel>[];

    for (final raw in rawList) {
      try {
        final decoded = jsonDecode(raw) as Map<String, dynamic>;
        matches.add(SavedMatchModel.fromJson(decoded));
      } catch (_) {
        continue;
      }
    }

    return matches;
  }

  Future<void> _writeMatchList(
    String key,
    List<SavedMatchModel> matches,
  ) async {
    final rawList = matches.map((match) {
      return jsonEncode(match.toJson());
    }).toList();

    await _prefs.setStringList(key, rawList);
  }
}
