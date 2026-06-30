import 'package:flutter/material.dart';

import '../models/prediction_record_model.dart';
import '../services/prediction_history_service.dart';
import '../widgets/prediction_record_card.dart';

class PredictionHistoryPage extends StatefulWidget {
  const PredictionHistoryPage({super.key});

  @override
  State<PredictionHistoryPage> createState() => _PredictionHistoryPageState();
}

class _PredictionHistoryPageState extends State<PredictionHistoryPage> {
  final PredictionHistoryService historyService = PredictionHistoryService();

  late Future<List<PredictionRecordModel>> recordsFuture;

  @override
  void initState() {
    super.initState();
    recordsFuture = historyService.getRecords();
  }

  Future<void> reload() async {
    final future = historyService.getRecords();

    setState(() {
      recordsFuture = future;
    });

    await future;
  }

  Future<void> clearHistory() async {
    await historyService.clearRecords();
    await reload();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Prediction History'),
        actions: [
          IconButton(
            onPressed: clearHistory,
            icon: const Icon(Icons.delete_outline, size: 21),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: reload,
        color: Colors.black,
        child: FutureBuilder<List<PredictionRecordModel>>(
          future: recordsFuture,
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
              );
            }

            final records = snapshot.data ?? [];

            if (records.isEmpty) {
              return const _SimpleState(
                title: 'No predictions',
                message: 'Các prediction bạn đã xem sẽ xuất hiện ở đây.',
              );
            }

            final stats = _PredictionStats.fromRecords(records);

            return ListView(
              padding: const EdgeInsets.only(top: 16, bottom: 24),
              children: [
                _StatsCard(stats: stats),
                const SizedBox(height: 8),
                ...records.map(
                  (record) => PredictionRecordCard(record: record),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _StatsCard extends StatelessWidget {
  final _PredictionStats stats;

  const _StatsCard({required this.stats});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Model Performance',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  _StatBox(label: 'Total', value: stats.total.toString()),
                  const SizedBox(width: 10),
                  _StatBox(label: 'Settled', value: stats.settled.toString()),
                  const SizedBox(width: 10),
                  _StatBox(
                    label: 'Accuracy',
                    value: '${stats.accuracy.toStringAsFixed(1)}%',
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  _StatBox(label: 'Correct', value: stats.correct.toString()),
                  const SizedBox(width: 10),
                  _StatBox(label: 'Wrong', value: stats.wrong.toString()),
                  const SizedBox(width: 10),
                  _StatBox(label: 'Pending', value: stats.pending.toString()),
                ],
              ),
              const SizedBox(height: 14),
              const Text(
                'Accuracy chỉ tính các trận đã có kết quả FT/AET/PEN.',
                style: TextStyle(fontSize: 11, color: Colors.black38),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatBox extends StatelessWidget {
  final String label;
  final String value;

  const _StatBox({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        height: 72,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.black.withAlpha(8),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              value,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: Colors.black,
              ),
            ),
            const Spacer(),
            Text(
              label,
              style: const TextStyle(
                fontSize: 11,
                color: Colors.black45,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SimpleState extends StatelessWidget {
  final String title;
  final String message;

  const _SimpleState({required this.title, required this.message});

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
      ],
    );
  }
}

class _PredictionStats {
  final int total;
  final int settled;
  final int correct;
  final int wrong;
  final int pending;
  final double accuracy;

  const _PredictionStats({
    required this.total,
    required this.settled,
    required this.correct,
    required this.wrong,
    required this.pending,
    required this.accuracy,
  });

  factory _PredictionStats.fromRecords(List<PredictionRecordModel> records) {
    final total = records.length;
    final settled = records.where((record) => record.isCorrect != null).length;
    final correct = records.where((record) => record.isCorrect == true).length;
    final wrong = records.where((record) => record.isCorrect == false).length;
    final pending = total - settled;

    final accuracy = settled == 0 ? 0.0 : (correct / settled) * 100;

    return _PredictionStats(
      total: total,
      settled: settled,
      correct: correct,
      wrong: wrong,
      pending: pending,
      accuracy: accuracy,
    );
  }
}
