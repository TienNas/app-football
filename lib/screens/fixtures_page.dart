import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/fixture_model.dart';
import '../services/football_api_service.dart';
import '../widgets/fixture_card.dart';
import 'backtest_page.dart';
import 'prediction_history_page.dart';
import 'prediction_page.dart';
import 'saved_matches_page.dart';

class FixturesPage extends StatefulWidget {
  const FixturesPage({super.key});

  @override
  State<FixturesPage> createState() => _FixturesPageState();
}

class _FixturesPageState extends State<FixturesPage> {
  final FootballApiService api = FootballApiService();
  final TextEditingController searchController = TextEditingController();

  DateTime selectedDate = DateTime.now();
  late Future<List<FixtureModel>> fixturesFuture;

  String searchQuery = '';
  String selectedLeague = 'All';

  @override
  void initState() {
    super.initState();

    fixturesFuture = api.getFixturesByDate(selectedDate);

    searchController.addListener(() {
      setState(() {
        searchQuery = searchController.text.trim();
      });
    });
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  Future<void> reload() async {
    final future = api.getFixturesByDate(selectedDate, forceRefresh: true);

    setState(() {
      fixturesFuture = future;
    });

    try {
      await future;
    } catch (_) {}
  }

  Future<void> pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime(2022),
      lastDate: DateTime(2030),
      builder: (context, child) {
        return Theme(data: Theme.of(context), child: child!);
      },
    );

    if (picked != null) {
      setState(() {
        selectedDate = picked;
        selectedLeague = 'All';
        fixturesFuture = api.getFixturesByDate(selectedDate);
      });
    }
  }

  List<FixtureModel> _filterFixtures(List<FixtureModel> fixtures) {
    final query = searchQuery.toLowerCase();

    return fixtures.where((fixture) {
      final matchesSearch =
          query.isEmpty ||
          fixture.homeName.toLowerCase().contains(query) ||
          fixture.awayName.toLowerCase().contains(query) ||
          fixture.leagueName.toLowerCase().contains(query) ||
          fixture.country.toLowerCase().contains(query);

      final matchesLeague =
          selectedLeague == 'All' || fixture.leagueName == selectedLeague;

      return matchesSearch && matchesLeague;
    }).toList();
  }

  List<String> _buildLeagueOptions(List<FixtureModel> fixtures) {
    final leagues = fixtures
        .map((fixture) => fixture.leagueName)
        .where((league) => league.trim().isNotEmpty)
        .toSet()
        .toList();

    leagues.sort();

    return ['All', ...leagues];
  }

  @override
  Widget build(BuildContext context) {
    final dateText = DateFormat('dd/MM/yyyy').format(selectedDate);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Football AI'),
        actions: [
          IconButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const BacktestPage()),
              );
            },
            icon: const Icon(Icons.analytics_outlined, size: 21),
          ),
          IconButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const PredictionHistoryPage(),
                ),
              );
            },
            icon: const Icon(Icons.insights_outlined, size: 21),
          ),
          IconButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SavedMatchesPage()),
              );
            },
            icon: const Icon(Icons.bookmark_border, size: 21),
          ),
          TextButton(
            onPressed: pickDate,
            child: Text(
              dateText,
              style: const TextStyle(
                color: Colors.black,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: reload,
        color: Colors.black,
        child: FutureBuilder<List<FixtureModel>>(
          future: fixturesFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: CircularProgressIndicator(color: Colors.black),
              );
            }

            if (snapshot.hasError) {
              return _ErrorState(
                message: snapshot.error.toString(),
                onRetry: reload,
              );
            }

            final fixtures = snapshot.data ?? [];
            final leagueOptions = _buildLeagueOptions(fixtures);
            final filteredFixtures = _filterFixtures(fixtures);

            if (fixtures.isEmpty) {
              return _EmptyState(
                title: 'No matches',
                message: 'Không có trận đấu nào vào ngày $dateText.',
                buttonText: 'Choose another date',
                onPressed: pickDate,
              );
            }

            return ListView(
              padding: const EdgeInsets.only(top: 12, bottom: 24),
              children: [
                _SearchBox(
                  controller: searchController,
                  onClear: () {
                    searchController.clear();
                  },
                ),
                const SizedBox(height: 12),
                _LeagueFilter(
                  leagues: leagueOptions,
                  selectedLeague: selectedLeague,
                  onChanged: (league) {
                    setState(() {
                      selectedLeague = league;
                    });
                  },
                ),
                const SizedBox(height: 12),
                _ResultCount(
                  count: filteredFixtures.length,
                  total: fixtures.length,
                ),
                const SizedBox(height: 8),
                if (filteredFixtures.isEmpty)
                  _NoFilteredMatches(
                    onClear: () {
                      setState(() {
                        selectedLeague = 'All';
                        searchController.clear();
                      });
                    },
                  )
                else
                  ...filteredFixtures.map((fixture) {
                    return FixtureCard(
                      fixture: fixture,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => PredictionPage(fixture: fixture),
                          ),
                        );
                      },
                    );
                  }),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _SearchBox extends StatelessWidget {
  final TextEditingController controller;
  final VoidCallback onClear;

  const _SearchBox({required this.controller, required this.onClear});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: TextField(
        controller: controller,
        cursorColor: Colors.black,
        style: const TextStyle(color: Colors.black, fontSize: 14),
        decoration: InputDecoration(
          hintText: 'Search team or league',
          hintStyle: const TextStyle(color: Colors.black38, fontSize: 14),
          prefixIcon: const Icon(Icons.search, color: Colors.black45, size: 20),
          suffixIcon: controller.text.isEmpty
              ? null
              : IconButton(
                  onPressed: onClear,
                  icon: const Icon(
                    Icons.close,
                    color: Colors.black45,
                    size: 18,
                  ),
                ),
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 14,
            vertical: 14,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(18),
            borderSide: BorderSide(color: Colors.grey.shade200, width: 1),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(18),
            borderSide: const BorderSide(color: Colors.black, width: 1),
          ),
        ),
      ),
    );
  }
}

class _LeagueFilter extends StatelessWidget {
  final List<String> leagues;
  final String selectedLeague;
  final ValueChanged<String> onChanged;

  const _LeagueFilter({
    required this.leagues,
    required this.selectedLeague,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 38,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        scrollDirection: Axis.horizontal,
        itemCount: leagues.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final league = leagues[index];
          final isSelected = league == selectedLeague;

          return GestureDetector(
            onTap: () => onChanged(league),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
              decoration: BoxDecoration(
                color: isSelected ? Colors.black : Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isSelected ? Colors.black : Colors.grey.shade200,
                  width: 1,
                ),
              ),
              child: Text(
                league,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: isSelected ? Colors.white : Colors.black87,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _ResultCount extends StatelessWidget {
  final int count;
  final int total;

  const _ResultCount({required this.count, required this.total});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Text(
        '$count of $total matches',
        style: const TextStyle(
          fontSize: 12,
          color: Colors.black45,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}

class _NoFilteredMatches extends StatelessWidget {
  final VoidCallback onClear;

  const _NoFilteredMatches({required this.onClear});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'No results',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Không tìm thấy trận phù hợp với bộ lọc hiện tại.',
                style: TextStyle(fontSize: 13, color: Colors.black54),
              ),
              const SizedBox(height: 16),
              SizedBox(
                height: 44,
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: onClear,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.black,
                    side: BorderSide(color: Colors.grey.shade300),
                  ),
                  child: const Text('Clear filters'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final String title;
  final String message;
  final String buttonText;
  final VoidCallback onPressed;

  const _EmptyState({
    required this.title,
    required this.message,
    required this.buttonText,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        const SizedBox(height: 80),
        Text(
          title,
          style: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w700,
            color: Colors.black,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          message,
          style: const TextStyle(fontSize: 14, color: Colors.black54),
        ),
        const SizedBox(height: 20),
        SizedBox(
          height: 48,
          child: OutlinedButton(
            onPressed: onPressed,
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.black,
              side: BorderSide(color: Colors.grey.shade300),
            ),
            child: Text(buttonText),
          ),
        ),
      ],
    );
  }
}

class _ErrorState extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorState({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        const SizedBox(height: 80),
        const Text(
          'Something went wrong',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w700,
            color: Colors.black,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          message,
          style: const TextStyle(fontSize: 13, color: Colors.black54),
        ),
        const SizedBox(height: 20),
        SizedBox(
          height: 48,
          child: OutlinedButton(
            onPressed: onRetry,
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.black,
              side: BorderSide(color: Colors.grey.shade300),
            ),
            child: const Text('Try again'),
          ),
        ),
      ],
    );
  }
}
