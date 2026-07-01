import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class MetricCard extends StatelessWidget {
  final String   label;
  final String   value;
  final String   subtitle;
  final double   progress;
  final Color    color;
  final IconData icon;

  const MetricCard({
    super.key,
    required this.label,
    required this.value,
    required this.subtitle,
    required this.progress,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Label — auto-sizes to fit
          Row(
            children: [
              Icon(icon, size: 10, color: color.withOpacity(0.7)),
              const SizedBox(width: 3),
              Flexible(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    label,
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w600,
                      color: Colors.white.withOpacity(0.4),
                      letterSpacing: 0.4,
                    ),
                  ),
                ),
              ),
            ],
          ),
          // Value
          Expanded(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                value,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: color,
                  height: 1,
                ),
              ),
            ),
          ),
          // Progress bar
          ClipRRect(
            borderRadius: BorderRadius.circular(2),
            child: LinearProgressIndicator(
              value: progress.clamp(0.0, 1.0),
              backgroundColor: color.withOpacity(0.1),
              valueColor: AlwaysStoppedAnimation(color),
              minHeight: 3,
            ),
          ),
        ],
      ),
    );
  }
}