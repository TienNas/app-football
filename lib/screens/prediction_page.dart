import 'package:flutter/material.dart';

import '../models/fixture_model.dart';
import '../models/prediction_model.dart';
import '../services/football_api_service.dart';
import '../services/local_storage_service.dart';
import '../widgets/match_header.dart';
import '../widgets/prediction_box.dart';

class PredictionPage extends StatefulWidget {
  final FixtureModel fixture;

  const PredictionPage({super.key, required this.fixture});

  @override
  State<PredictionPage> createState() => _PredictionPageState();
}

class _PredictionPageState extends State<PredictionPage> {
  final FootballApiService api = FootballApiService();
  final LocalStorageService storage = LocalStorageService();

  late Future<PredictionModel> predictionFuture;
  late Future<bool> favoriteFuture;

  @override
  void initState() {
    super.initState();

    predictionFuture = api.getPrediction(widget.fixture);
    favoriteFuture = storage.isFavorite(widget.fixture.fixtureId);

    storage.addToHistory(widget.fixture);
  }

  Future<void> reload() async {
    final future = api.getPrediction(widget.fixture, forceRefresh: true);

    setState(() {
      predictionFuture = future;
    });

    try {
      await future;
    } catch (_) {}
  }

  Future<void> toggleFavorite() async {
    await storage.toggleFavorite(widget.fixture);

    final isFavorite = await storage.isFavorite(widget.fixture.fixtureId);

    setState(() {
      favoriteFuture = Future.value(isFavorite);
    });

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          isFavorite ? 'Added to favorites' : 'Removed from favorites',
        ),
        behavior: SnackBarBehavior.floating,
        backgroundColor: Colors.black,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final fixture = widget.fixture;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Prediction'),
        actions: [
          FutureBuilder<bool>(
            future: favoriteFuture,
            builder: (context, snapshot) {
              final isFavorite = snapshot.data ?? false;

              return IconButton(
                onPressed: toggleFavorite,
                icon: Icon(
                  isFavorite ? Icons.bookmark : Icons.bookmark_border,
                  size: 22,
                ),
              );
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: reload,
        color: Colors.black,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            MatchHeader(fixture: fixture),
            const SizedBox(height: 12),
            FutureBuilder<PredictionModel>(
              future: predictionFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Card(
                    child: Padding(
                      padding: EdgeInsets.all(24),
                      child: Center(
                        child: CircularProgressIndicator(color: Colors.black),
                      ),
                    ),
                  );
                }

                if (snapshot.hasError) {
                  return Card(
                    child: Padding(
                      padding: const EdgeInsets.all(18),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Prediction unavailable',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: Colors.black,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            snapshot.error.toString(),
                            style: const TextStyle(
                              fontSize: 13,
                              color: Colors.black54,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                return PredictionBox(prediction: snapshot.data!);
              },
            ),
          ],
        ),
      ),
    );
  }
}
