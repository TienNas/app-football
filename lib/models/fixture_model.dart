class FixtureModel {
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

  FixtureModel({
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
  });

  factory FixtureModel.fromApi(Map<String, dynamic> json) {
    final fixture = json['fixture'] as Map<String, dynamic>? ?? {};
    final league = json['league'] as Map<String, dynamic>? ?? {};
    final teams = json['teams'] as Map<String, dynamic>? ?? {};
    final home = teams['home'] as Map<String, dynamic>? ?? {};
    final away = teams['away'] as Map<String, dynamic>? ?? {};
    final goals = json['goals'] as Map<String, dynamic>? ?? {};
    final status = fixture['status'] as Map<String, dynamic>? ?? {};

    return FixtureModel(
      fixtureId: _toInt(fixture['id']) ?? 0,
      date: fixture['date']?.toString() ?? '',
      statusShort: status['short']?.toString() ?? '',
      leagueId: _toInt(league['id']),
      season: _toInt(league['season']),
      leagueName: league['name']?.toString() ?? 'Unknown League',
      country: league['country']?.toString() ?? '',
      homeTeamId: _toInt(home['id']),
      awayTeamId: _toInt(away['id']),
      homeName: home['name']?.toString() ?? 'Home',
      awayName: away['name']?.toString() ?? 'Away',
      homeLogo: home['logo']?.toString(),
      awayLogo: away['logo']?.toString(),
      homeGoals: _toInt(goals['home']),
      awayGoals: _toInt(goals['away']),
    );
  }

  static int? _toInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    return int.tryParse(value.toString());
  }
}
