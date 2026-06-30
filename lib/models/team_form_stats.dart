class TeamFormStats {
  final int matches;
  final int wins;
  final int draws;
  final int losses;
  final int goalsFor;
  final int goalsAgainst;
  final int points;

  final double weightedPointsPerGame;
  final double formMomentum;
  final double eloLikeRating;

  const TeamFormStats({
    required this.matches,
    required this.wins,
    required this.draws,
    required this.losses,
    required this.goalsFor,
    required this.goalsAgainst,
    required this.points,
    required this.weightedPointsPerGame,
    required this.formMomentum,
    required this.eloLikeRating,
  });

  double get pointsPerGame {
    if (matches == 0) return 0;
    return points / matches;
  }

  double get avgGoalsFor {
    if (matches == 0) return 0;
    return goalsFor / matches;
  }

  double get avgGoalsAgainst {
    if (matches == 0) return 0;
    return goalsAgainst / matches;
  }

  double get goalDifferencePerMatch {
    if (matches == 0) return 0;
    return (goalsFor - goalsAgainst) / matches;
  }

  double get winRate {
    if (matches == 0) return 0;
    return wins / matches;
  }

  String get recordText {
    return '${wins}W ${draws}D ${losses}L';
  }
}
