import 'package:flutter/material.dart';

import '../models/saved_match_model.dart';
import '../services/local_storage_service.dart';
import '../widgets/saved_match_card.dart';
import 'prediction_page.dart';

class SavedMatchesPage extends StatefulWidget {
  const SavedMatchesPage({super.key});

  @override
  State<SavedMatchesPage> createState() => _SavedMatchesPageState();
}

class _SavedMatchesPageState extends State<SavedMatchesPage> {
  final LocalStorageService storage = LocalStorageService();

  late Future<_SavedData> savedDataFuture;

  @override
  void initState() {
    super.initState();
    savedDataFuture = _loadData();
  }

  Future<_SavedData> _loadData() async {
    final favorites = await storage.getFavorites();
    final history = await storage.getHistory();

    return _SavedData(favorites: favorites, history: history);
  }

  Future<void> reload() async {
    setState(() {
      savedDataFuture = _loadData();
    });

    await savedDataFuture;
  }

  Future<void> removeFavorite(int fixtureId) async {
    await storage.removeFavorite(fixtureId);
    await reload();
  }

  Future<void> clearHistory() async {
    await storage.clearHistory();
    await reload();
  }

  void openPrediction(SavedMatchModel match) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PredictionPage(fixture: match.toFixture()),
      ),
    ).then((_) {
      reload();
    });
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Saved'),
          bottom: const TabBar(
            indicatorColor: Colors.black,
            labelColor: Colors.black,
            unselectedLabelColor: Colors.black45,
            tabs: [
              Tab(text: 'Favorites'),
              Tab(text: 'History'),
            ],
          ),
        ),
        body: FutureBuilder<_SavedData>(
          future: savedDataFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: CircularProgressIndicator(color: Colors.black),
              );
            }

            if (snapshot.hasError) {
              return _SimpleState(
                title: 'Something went wrong',
                message: snapshot.error.toString(),
                buttonText: 'Try again',
                onPressed: reload,
              );
            }

            final data =
                snapshot.data ?? const _SavedData(favorites: [], history: []);

            return TabBarView(
              children: [
                _SavedList(
                  matches: data.favorites,
                  emptyTitle: 'No favorites',
                  emptyMessage: 'Bạn chưa lưu trận nào.',
                  onTap: openPrediction,
                  onRemove: removeFavorite,
                ),
                _SavedList(
                  matches: data.history,
                  emptyTitle: 'No history',
                  emptyMessage: 'Các trận bạn đã xem sẽ xuất hiện ở đây.',
                  onTap: openPrediction,
                  onRemove: null,
                  footer: data.history.isEmpty
                      ? null
                      : Padding(
                          padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                          child: SizedBox(
                            height: 44,
                            child: OutlinedButton(
                              onPressed: clearHistory,
                              style: OutlinedButton.styleFrom(
                                foregroundColor: Colors.black,
                                side: BorderSide(color: Colors.grey.shade300),
                              ),
                              child: const Text('Clear history'),
                            ),
                          ),
                        ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _SavedList extends StatelessWidget {
  final List<SavedMatchModel> matches;
  final String emptyTitle;
  final String emptyMessage;
  final ValueChanged<SavedMatchModel> onTap;
  final ValueChanged<int>? onRemove;
  final Widget? footer;

  const _SavedList({
    required this.matches,
    required this.emptyTitle,
    required this.emptyMessage,
    required this.onTap,
    required this.onRemove,
    this.footer,
  });

  @override
  Widget build(BuildContext context) {
    if (matches.isEmpty) {
      return _SimpleState(title: emptyTitle, message: emptyMessage);
    }

    return ListView(
      padding: const EdgeInsets.only(top: 16, bottom: 24),
      children: [
        ...matches.map((match) {
          return SavedMatchCard(
            match: match,
            onTap: () => onTap(match),
            onRemove: onRemove == null
                ? null
                : () {
                    onRemove!(match.fixtureId);
                  },
          );
        }),
        ?footer,
      ],
    );
  }
}

class _SimpleState extends StatelessWidget {
  final String title;
  final String message;
  final String? buttonText;
  final VoidCallback? onPressed;

  const _SimpleState({
    required this.title,
    required this.message,
    this.buttonText,
    this.onPressed,
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
        if (buttonText != null && onPressed != null) ...[
          const SizedBox(height: 20),
          SizedBox(
            height: 48,
            child: OutlinedButton(
              onPressed: onPressed,
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.black,
                side: BorderSide(color: Colors.grey.shade300),
              ),
              child: Text(buttonText!),
            ),
          ),
        ],
      ],
    );
  }
}

class _SavedData {
  final List<SavedMatchModel> favorites;
  final List<SavedMatchModel> history;

  const _SavedData({required this.favorites, required this.history});
}
