import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/neural_network_widget.dart';
import '../widgets/embeddings_graph.dart';
import '../widgets/metric_card.dart';
import '../widgets/inference_button.dart';
import '../widgets/status_bar_widget.dart';
import '../widgets/history_tile.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final prov     = context.watch<AppProvider>();
    final result   = prov.lastResult;
    final isActive = prov.state != AppState.idle;
    final isAlert  = prov.state == AppState.alerting;
    final h        = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [

            // ── Title row: settings right, title centred ─────────────────
            const SizedBox(height: 10),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Row(
                children: [
                  // Left spacer = same width as settings button
                  const SizedBox(width: 48),
                  // Title centred between the two spacers
                  Expanded(
                    child: Column(
                      children: [
                        ShaderMask(
                          shaderCallback: (r) => const LinearGradient(
                            colors: [AppColors.cyan, AppColors.blue],
                          ).createShader(r),
                          child: const Text(
                            'Jal Rakshak',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        Text(
                          'AI Powered Tank Monitor',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.white.withOpacity(0.35),
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Settings icon on right
                  SizedBox(
                    width: 48,
                    child: IconButton(
                      icon: const Icon(Icons.settings_outlined, size: 20),
                      color: Colors.white.withOpacity(0.5),
                      onPressed: () =>
                          Navigator.pushNamed(context, '/settings'),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 10),

            // ── Neural network ────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              child: SizedBox(
                height: h * 0.16,
                child: Container(
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardColor,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: isActive
                          ? AppColors.cyan.withOpacity(0.25)
                          : Theme.of(context).dividerColor,
                    ),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(14),
                    child: NeuralNetworkWidget(
                      isActive: isActive,
                      height: h * 0.16,
                    ),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 10),

            // ── Status bar ────────────────────────────────────────────────
            StatusBar(appState: prov.state),

            const SizedBox(height: 10),

            // ── Embeddings + Metrics row ──────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              child: SizedBox(
                height: h * 0.155,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(
                      flex: 3,
                      child: EmbeddingsGraph(
                        embeddings: prov.embeddingVis,
                        dimension:  1024,
                        isActive:   isActive,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      flex: 2,
                      child: Column(
                        children: [
                          Expanded(
                            child: MetricCard(
                              label:    'CONFIDENCE',
                              value:    result != null
                                  ? '${(result.confidence * 100)
                                      .toStringAsFixed(1)}%'
                                  : '--',
                              subtitle: '',
                              progress: result?.confidence ?? 0,
                              color: isAlert
                                  ? AppColors.red
                                  : AppColors.cyan,
                              icon: Icons.shield_outlined,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Expanded(
                            child: MetricCard(
                              label:    'RMS',
                              value:    result != null
                                  ? result.rms.toStringAsFixed(3)
                                  : '--',
                              subtitle: '',
                              progress: (result?.rms ?? 0)
                                  .clamp(0.0, 1.0),
                              color: AppColors.blue,
                              icon: Icons.graphic_eq,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 14),

            // ── Mic button — truly fixed ──────────────────────────────────
            SizedBox(
              height: 90,
              child: Center(
                child: InferenceButton(
                  appState: prov.state,
                  onTap: isAlert
                      ? prov.dismissAlarm
                      : prov.toggleListening,
                ),
              ),
            ),
            SizedBox(
              height: 20,
              child: Center(
                child: Text(
                  isAlert
                      ? 'Tap to dismiss alarm'
                      : (isActive
                          ? 'Tap to stop listening'
                          : 'Tap to listen'),
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.white.withOpacity(0.35),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 8),

            // ── History header — fixed ────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Icon(Icons.history,
                      size: 14,
                      color: AppColors.cyan.withOpacity(0.7)),
                  const SizedBox(width: 5),
                  const Text('History',
                      style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700)),
                  const Spacer(),
                  TextButton(
                    onPressed: () =>
                        Navigator.pushNamed(context, '/history'),
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.cyan,
                      padding:         EdgeInsets.zero,
                      minimumSize:     Size.zero,
                      tapTargetSize:
                          MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: const Text('See all',
                        style: TextStyle(fontSize: 11)),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 4),

            // ── Only history scrolls ──────────────────────────────────────
            Expanded(
              child: prov.history.isEmpty
                  ? Center(
                      child: Text(
                        'No entries yet',
                        style: TextStyle(
                            color: Colors.white.withOpacity(0.2),
                            fontSize: 13),
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.fromLTRB(
                          14, 2, 14, 8),
                      physics: const BouncingScrollPhysics(),
                      itemCount: prov.history.length,
                      itemBuilder: (ctx, i) => HistoryTile(
                        record:   prov.history[i],
                        userName: prov.settings.userName,
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}