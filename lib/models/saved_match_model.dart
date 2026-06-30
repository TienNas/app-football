import 'fixture_model.dart';

class SavedMatchModel {
  final int fixtureId;
  final String date;
  final String statusShort;

  final int? leagueId;
  final int? season;
  final String leagueName;
  final String country;

  final int? homeTeamId;
  final int? awayTeamId;
  final String homeName;
  final String awayName;
  final String? homeLogo;
  final String? awayLogo;

  final int? homeGoals;
  final int? awayGoals;

  final String savedAt;

  const SavedMatchModel({
    required this.fixtureId,
    required this.date,
    required this.statusShort,
    required this.leagueId,
    required this.season,
    required this.leagueName,
    required this.country,
    required this.homeTeamId,
    required this.awayTeamId,
    required this.homeName,
    required this.awayName,
    required this.homeLogo,
    required this.awayLogo,
    required this.homeGoals,
    required this.awayGoals,
    required this.savedAt,
  });

  factory SavedMatchModel.fromFixture(FixtureModel fixture) {
    return SavedMatchModel(
      fixtureId: fixture.fixtureId,
      date: fixture.date,
      statusShort: fixture.statusShort,
      leagueId: fixture.leagueId,
      season: fixture.season,
      leagueName: fixture.leagueName,
      country: fixture.country,
      homeTeamId: fixture.homeTeamId,
      awayTeamId: fixture.awayTeamId,
      homeName: fixture.homeName,
      awayName: fixture.awayName,
      homeLogo: fixture.homeLogo,
      awayLogo: fixture.awayLogo,
      homeGoals: fixture.homeGoals,
      awayGoals: fixture.awayGoals,
      savedAt: DateTime.now().toIso8601String(),
    );
  }

  factory SavedMatchModel.fromJson(Map<String, dynamic> json) {
    return SavedMatchModel(
      fixtureId: _toInt(json['fixtureId']) ?? 0,
      date: json['date']?.toString() ?? '',
      statusShort: json['statusShort']?.toString() ?? '',
      leagueId: _toInt(json['leagueId']),
      season: _toInt(json['season']),
      leagueName: json['leagueName']?.toString() ?? 'Unknown League',
      country: json['country']?.toString() ?? '',
      homeTeamId: _toInt(json['homeTeamId']),
      awayTeamId: _toInt(json['awayTeamId']),
      homeName: json['homeName']?.toString() ?? 'Home',
      awayName: json['awayName']?.toString() ?? 'Away',
      homeLogo: json['homeLogo']?.toString(),
      awayLogo: json['awayLogo']?.toString(),
      homeGoals: _toInt(json['homeGoals']),
      awayGoals: _toInt(json['awayGoals']),
      savedAt: json['savedAt']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'fixtureId': fixtureId,
      'date': date,
      'statusShort': statusShort,
      'leagueId': leagueId,
      'season': season,
      'leagueName': leagueName,
      'country': country,
      'homeTeamId': homeTeamId,
      'awayTeamId': awayTeamId,
      'homeName': homeName,
      'awayName': awayName,
      'homeLogo': homeLogo,
      'awayLogo': awayLogo,
      'homeGoals': homeGoals,
      'awayGoals': awayGoals,
      'savedAt': savedAt,
    };
  }

  FixtureModel toFixture() {
    return FixtureModel(
      fixtureId: fixtureId,
      date: date,
      statusShort: statusShort,
      leagueId: leagueId,
      season: season,
      leagueName: leagueName,
      country: country,
      homeTeamId: homeTeamId,
      awayTeamId: awayTeamId,
      homeName: homeName,
      awayName: awayName,
      homeLogo: homeLogo,
      awayLogo: awayLogo,
      homeGoals: homeGoals,
      awayGoals: awayGoals,
    );
  }

  static int? _toInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    return int.tryParse(value.toString());
  }
}
