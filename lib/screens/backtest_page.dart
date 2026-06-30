import 'package:flutter/material.dart';

import '../models/backtest_result_model.dart';
import '../services/backtest_service.dart';
import '../widgets/backtest_match_card.dart';

class BacktestPage extends StatefulWidget {
  const BacktestPage({super.key});

  @override
  State<BacktestPage> createState() => _BacktestPageState();
}

class _BacktestPageState extends State<BacktestPage> {
  final BacktestService backtestService = BacktestService();

  final TextEditingController leagueController = TextEditingController(
    text: '39',
  );
  final TextEditingController seasonController = TextEditingController(
    text: '2024',
  );
  final TextEditingController limitController = TextEditingController(
    text: '80',
  );

  Future<BacktestResultModel>? resultFuture;

  @override
  void dispose() {
    leagueController.dispose();
    seasonController.dispose();
    limitController.dispose();
    super.dispose();
  }

  void runBacktest() {
    final leagueId = int.tryParse(leagueController.text.trim());
    final season = int.tryParse(seasonController.text.trim());
    final maxMatches = int.tryParse(limitController.text.trim());

    if (leagueId == null || season == null || maxMatches == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('League ID, season và limit phải là số.'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.black,
        ),
      );
      return;
    }

    FocusScope.of(context).unfocus();

    setState(() {
      resultFuture = backtestService.runBacktest(
        leagueId: leagueId,
        season: season,
        maxMatches: maxMatches,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final future = resultFuture;

    return Scaffold(
      appBar: AppBar(title: const Text('Backtest')),
      body: ListView(
        padding: const EdgeInsets.only(top: 16, bottom: 24),
        children: [
          _InputCard(
            leagueController: leagueController,
            seasonController: seasonController,
            limitController: limitController,
            onRun: runBacktest,
          ),
          const SizedBox(height: 12),
          if (future == null)
            const _SimpleState(
              title: 'Run a backtest',
              message:
                  'Nhập league ID, season và số trận muốn kiểm tra. Mặc định: Premier League 2024, 80 trận gần nhất.',
            )
          else
            FutureBuilder<BacktestResultModel>(
              future: future,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Padding(
                    padding: EdgeInsets.only(top: 60),
                    child: Center(
                      child: CircularProgressIndicator(color: Colors.black),
                    ),
                  );
                }

                if (snapshot.hasError) {
                  return _SimpleState(
                    title: 'Backtest failed',
                    message: snapshot.error.toString(),
                  );
                }

                final result = snapshot.data;

                if (result == null || result.total == 0) {
                  return const _SimpleState(
                    title: 'No valid matches',
                    message:
                        'Không đủ trận đã kết thúc hoặc không đủ dữ liệu trước trận để backtest.',
                  );
                }

                return Column(
                  children: [
                    _ResultCard(result: result),
                    const SizedBox(height: 12),
                    _BucketCard(buckets: result.buckets),
                    const SizedBox(height: 12),
                    ...result.records.map(
                      (record) => BacktestMatchCard(record: record),
                    ),
                  ],
                );
              },
            ),
        ],
      ),
    );
  }
}

class _InputCard extends StatelessWidget {
  final TextEditingController leagueController;
  final TextEditingController seasonController;
  final TextEditingController limitController;
  final VoidCallback onRun;

  const _InputCard({
    required this.leagueController,
    required this.seasonController,
    required this.limitController,
    required this.onRun,
  });

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
                'Backtest Settings',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: _NumberField(
                      label: 'League ID',
                      controller: leagueController,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _NumberField(
                      label: 'Season',
                      controller: seasonController,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _NumberField(
                      label: 'Limit',
                      controller: limitController,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              SizedBox(
                height: 46,
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: onRun,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Run backtest'),
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                'Backtest chỉ dùng các trận trước thời điểm trận cần dự đoán. Cách này hạn chế leakage dữ liệu tương lai.',
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.black38,
                  height: 1.35,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NumberField extends StatelessWidget {
  final String label;
  final TextEditingController controller;

  const _NumberField({required this.label, required this.controller});

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: TextInputType.number,
      cursorColor: Colors.black,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.black45, fontSize: 12),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: Colors.grey.shade200),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Colors.black),
        ),
      ),
    );
  }
}

class _ResultCard extends StatelessWidget {
  final BacktestResultModel result;

  const _ResultCard({required this.result});

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
                'Backtest Result',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  _StatBox(label: 'Total', value: result.total.toString()),
                  const SizedBox(width: 10),
                  _StatBox(
                    label: 'Accuracy',
                    value: '${result.accuracy.toStringAsFixed(1)}%',
                  ),
                  const SizedBox(width: 10),
                  _StatBox(
                    label: 'Brier',
                    value: result.brierScore.toStringAsFixed(3),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  _StatBox(label: 'Correct', value: result.correct.toString()),
                  const SizedBox(width: 10),
                  _StatBox(label: 'Wrong', value: result.wrong.toString()),
                  const SizedBox(width: 10),
                  const _StatBox(label: 'Best Brier', value: '0.000'),
                ],
              ),
              const SizedBox(height: 14),
              const Text(
                'Brier Score càng thấp càng tốt. Accuracy đo đúng/sai, còn Brier đo chất lượng xác suất.',
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.black38,
                  height: 1.35,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BucketCard extends StatelessWidget {
  final List<BacktestBucketModel> buckets;

  const _BucketCard({required this.buckets});

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
                'Confidence Buckets',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 14),
              ...buckets.map((bucket) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 9),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 70,
                        child: Text(
                          bucket.label,
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.black54,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      Expanded(
                        child: Text(
                          '${bucket.correct}/${bucket.total}',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.black87,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      SizedBox(
                        width: 70,
                        child: Text(
                          '${bucket.accuracy.toStringAsFixed(1)}%',
                          textAlign: TextAlign.right,
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.black87,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }),
              const SizedBox(height: 6),
              const Text(
                'Nếu bucket 60%+ có accuracy thấp hơn 60%, model đang overconfident.',
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.black38,
                  height: 1.35,
                ),
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
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
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
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                message,
                style: const TextStyle(
                  fontSize: 13,
                  color: Colors.black54,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
