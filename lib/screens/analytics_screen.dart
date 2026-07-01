import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import '../providers/app_provider.dart';
import '../services/groq_service.dart';
import '../models/inference_record.dart';
import '../theme/app_theme.dart';

class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> {
  String  _aiSummary   = '';
  bool    _loadingAI   = false;
  String  _timeFilter  = '24h'; // '24h' | '7d' | 'all'

  Future<void> _fetchAI(AppProvider prov) async {
    if (prov.settings.groqApiKey.isEmpty) {
      setState(() => _aiSummary =
          'Add your Groq API key in Settings → AI Analytics to enable this feature.\n\nGet a free key at console.groq.com');
      return;
    }
    setState(() { _loadingAI = true; _aiSummary = ''; });

    final groq    = GroqService(prov.settings.groqApiKey);
    final summary = await groq.analyzeHistory(prov.history);
    setState(() { _aiSummary = summary; _loadingAI = false; });
  }

  List<InferenceRecord> _filtered(List<InferenceRecord> all) {
    final now = DateTime.now();
    return switch (_timeFilter) {
      '24h' => all.where((r) =>
          now.difference(r.timestamp).inHours < 24).toList(),
      '7d'  => all.where((r) =>
          now.difference(r.timestamp).inDays < 7).toList(),
      _     => all,
    };
  }

  @override
  Widget build(BuildContext context) {
    final prov     = context.watch<AppProvider>();
    final records  = _filtered(prov.history);
    final filling  = records.where((r) => r.isFilling).length;
    final filled   = records.where((r) => !r.isFilling).length;

    return Scaffold(
      body: SafeArea(
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            // Header
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                child: Row(
                  children: [
                    const Text('Analytics',
                        style: TextStyle(
                            fontSize: 22, fontWeight: FontWeight.w800)),
                    const Spacer(),
                    // Time filter chips
                    for (final t in ['24h', '7d', 'all'])
                      Padding(
                        padding: const EdgeInsets.only(left: 6),
                        child: ChoiceChip(
                          label: Text(t,
                              style: const TextStyle(fontSize: 11)),
                          selected: _timeFilter == t,
                          onSelected: (_) =>
                              setState(() => _timeFilter = t),
                          selectedColor: AppColors.cyan.withOpacity(0.2),
                          backgroundColor:
                              Theme.of(context).cardColor,
                          side: BorderSide(
                            color: _timeFilter == t
                                ? AppColors.cyan
                                : Theme.of(context).dividerColor,
                          ),
                          labelStyle: TextStyle(
                            color: _timeFilter == t
                                ? AppColors.cyan
                                : Colors.white.withOpacity(0.5),
                          ),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8),
                        ),
                      ),
                  ],
                ),
              ),
            ),

            // Summary cards row
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    _StatCard(
                        label: 'Total Events',
                        value: '${records.length}',
                        color: AppColors.cyan),
                    const SizedBox(width: 8),
                    _StatCard(
                        label: 'Filling',
                        value: '$filling',
                        color: AppColors.filling),
                    const SizedBox(width: 8),
                    _StatCard(
                        label: 'Filled',
                        value: '$filled',
                        color: AppColors.filled),
                  ],
                ),
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 16)),

            // Pie chart
            if (records.isNotEmpty)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Container(
                    height: 200,
                    decoration: BoxDecoration(
                      color: Theme.of(context).cardColor,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                          color: Theme.of(context).dividerColor),
                    ),
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Expanded(
                          child: PieChart(
                            PieChartData(
                              sections: [
                                PieChartSectionData(
                                  value:     filling.toDouble(),
                                  color:     AppColors.filling,
                                  title:     '${filling > 0 ? (filling / records.length * 100).toStringAsFixed(0) : 0}%',
                                  radius:    60,
                                  titleStyle: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white),
                                ),
                                PieChartSectionData(
                                  value:     filled.toDouble(),
                                  color:     AppColors.filled,
                                  title:     '${filled > 0 ? (filled / records.length * 100).toStringAsFixed(0) : 0}%',
                                  radius:    60,
                                  titleStyle: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white),
                                ),
                              ],
                              sectionsSpace: 3,
                              centerSpaceRadius: 30,
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _Legend(
                                color: AppColors.filling,
                                label: 'Filling ($filling)'),
                            const SizedBox(height: 8),
                            _Legend(
                                color: AppColors.filled,
                                label: 'Filled ($filled)'),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),

            const SliverToBoxAdapter(child: SizedBox(height: 16)),

            // Confidence trend bar chart
            if (records.length > 1)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Container(
                    height: 160,
                    decoration: BoxDecoration(
                      color: Theme.of(context).cardColor,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                          color: Theme.of(context).dividerColor),
                    ),
                    padding: const EdgeInsets.fromLTRB(12, 14, 12, 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Confidence Trend',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: Colors.white.withOpacity(0.4),
                              letterSpacing: 0.5,
                            )),
                        const SizedBox(height: 8),
                        Expanded(
                          child: BarChart(
                            BarChartData(
                              gridData: FlGridData(
                                show: true,
                                drawVerticalLine: false,
                                horizontalInterval: 0.25,
                                getDrawingHorizontalLine: (_) => FlLine(
                                  color: Colors.white.withOpacity(0.05),
                                  strokeWidth: 1,
                                ),
                              ),
                              titlesData:
                                  const FlTitlesData(show: false),
                              borderData: FlBorderData(show: false),
                              barGroups: records
                                  .reversed
                                  .take(20)
                                  .toList()
                                  .asMap()
                                  .entries
                                  .map((e) => BarChartGroupData(
                                        x: e.key,
                                        barRods: [
                                          BarChartRodData(
                                            toY: e.value.confidence,
                                            color: e.value.isFilling
                                                ? AppColors.filling
                                                : AppColors.filled,
                                            width: 8,
                                            borderRadius:
                                                BorderRadius.circular(3),
                                          ),
                                        ],
                                      ))
                                  .toList(),
                              maxY: 1.0,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

            const SliverToBoxAdapter(child: SizedBox(height: 16)),

            // AI Analytics
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Container(
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardColor,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                        color: Theme.of(context).dividerColor),
                  ),
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.auto_awesome,
                              size: 16, color: AppColors.amber),
                          const SizedBox(width: 6),
                          const Text(
                            'AI Analytics',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 5, vertical: 1),
                            decoration: BoxDecoration(
                              color: AppColors.amber.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Text('Groq LLaMA 3.3',
                                style: TextStyle(
                                    fontSize: 8,
                                    color: AppColors.amber,
                                    fontWeight: FontWeight.w600)),
                          ),
                          const Spacer(),
                          TextButton.icon(
                            onPressed: _loadingAI
                                ? null
                                : () => _fetchAI(prov),
                            icon: _loadingAI
                                ? const SizedBox(
                                    width: 12,
                                    height: 12,
                                    child: CircularProgressIndicator(
                                        strokeWidth: 1.5,
                                        color: AppColors.amber),
                                  )
                                : const Icon(Icons.refresh,
                                    size: 14, color: AppColors.amber),
                            label: Text(
                              _loadingAI ? 'Thinking...' : 'Analyze',
                              style: const TextStyle(
                                  fontSize: 11, color: AppColors.amber),
                            ),
                            style: TextButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 4),
                              minimumSize: Size.zero,
                              tapTargetSize:
                                  MaterialTapTargetSize.shrinkWrap,
                            ),
                          ),
                        ],
                      ),
                      if (_aiSummary.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppColors.amber.withOpacity(0.05),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                                color:
                                    AppColors.amber.withOpacity(0.15)),
                          ),
                          child: Text(
                            _aiSummary,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.white.withOpacity(0.8),
                              height: 1.6,
                            ),
                          ),
                        ),
                      ] else if (!_loadingAI) ...[
                        const SizedBox(height: 12),
                        Text(
                          'Tap Analyze to get AI-powered insights about your tank usage patterns.',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.white.withOpacity(0.3),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 100)),
          ],
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label, value;
  final Color color;
  const _StatCard(
      {required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) => Expanded(
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
          decoration: BoxDecoration(
            color: color.withOpacity(0.08),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: color.withOpacity(0.2)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(value,
                  style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: color)),
              Text(label,
                  style: TextStyle(
                      fontSize: 10,
                      color: Colors.white.withOpacity(0.4))),
            ],
          ),
        ),
      );
}

class _Legend extends StatelessWidget {
  final Color color;
  final String label;
  const _Legend({required this.color, required this.label});

  @override
  Widget build(BuildContext context) => Row(
        children: [
          Container(
              width: 10,
              height: 10,
              decoration:
                  BoxDecoration(color: color, shape: BoxShape.circle)),
          const SizedBox(width: 6),
          Text(label,
              style: TextStyle(
                  fontSize: 11, color: Colors.white.withOpacity(0.6))),
        ],
      );
}
