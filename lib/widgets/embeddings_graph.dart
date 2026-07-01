import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../theme/app_theme.dart';

class EmbeddingsGraph extends StatelessWidget {
  final List<double> embeddings;
  final int          dimension;
  final bool         isActive;

  const EmbeddingsGraph({
    super.key,
    required this.embeddings,
    required this.dimension,
    required this.isActive,
  });

  @override
  Widget build(BuildContext context) {
    // Find actual min/max for proper scaling — not 0-1
    double minY = 0;
    double maxY = 1;
    if (embeddings.any((e) => e != 0)) {
      minY = embeddings.reduce((a, b) => a < b ? a : b);
      maxY = embeddings.reduce((a, b) => a > b ? a : b);
      // Add 10% padding
      final range = (maxY - minY).abs();
      if (range < 0.01) {
        minY -= 0.1;
        maxY += 0.1;
      } else {
        minY -= range * 0.1;
        maxY += range * 0.1;
      }
    }

    final spots = <FlSpot>[
      for (int i = 0; i < embeddings.length; i++)
        FlSpot(i.toDouble(), embeddings[i]),
    ];

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isActive
              ? AppColors.cyan.withOpacity(0.3)
              : Theme.of(context).dividerColor,
        ),
      ),
      padding: const EdgeInsets.fromLTRB(8, 8, 8, 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: embeddings.every((e) => e == 0)
                ? Center(
                    child: Text(
                      'Waiting for audio...',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.2),
                        fontSize: 10,
                      ),
                    ),
                  )
                : LineChart(
                    LineChartData(
                      gridData: FlGridData(
                        show: true,
                        drawVerticalLine: false,
                        horizontalInterval: (maxY - minY) / 3,
                        getDrawingHorizontalLine: (_) => FlLine(
                          color: Colors.white.withOpacity(0.04),
                          strokeWidth: 1,
                        ),
                      ),
                      titlesData: const FlTitlesData(show: false),
                      borderData: FlBorderData(show: false),
                      minX: 0,
                      maxX: (embeddings.length - 1).toDouble(),
                      minY: minY,
                      maxY: maxY,
                      lineBarsData: [
                        LineChartBarData(
                          spots:            spots,
                          isCurved:         true,
                          curveSmoothness:  0.2,
                          color:            isActive
                              ? AppColors.cyan
                              : Colors.white.withOpacity(0.2),
                          barWidth:         1.5,
                          isStrokeCapRound: true,
                          dotData:          const FlDotData(show: false),
                          belowBarData: BarAreaData(
                            show: true,
                            gradient: LinearGradient(
                              begin:  Alignment.topCenter,
                              end:    Alignment.bottomCenter,
                              colors: [
                                (isActive ? AppColors.cyan : Colors.white)
                                    .withOpacity(0.15),
                                Colors.transparent,
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    duration: const Duration(milliseconds: 200),
                  ),
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Icon(Icons.graphic_eq,
                  size: 10,
                  color: isActive
                      ? AppColors.cyan
                      : Colors.white.withOpacity(0.3)),
              const SizedBox(width: 3),
              Text(
                'Live Embeddings',
                style: TextStyle(
                  fontSize: 9,
                  color: Colors.white.withOpacity(0.35),
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 5, vertical: 1),
                decoration: BoxDecoration(
                  color:        AppColors.cyan.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(
                      color: AppColors.cyan.withOpacity(0.2),
                      width: 0.5),
                ),
                child: Text(
                  '$dimension-D',
                  style: const TextStyle(
                    fontSize: 8,
                    color:      AppColors.cyan,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}