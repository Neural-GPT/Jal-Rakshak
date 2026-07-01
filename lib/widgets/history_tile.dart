import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/inference_record.dart';
import '../theme/app_theme.dart';

class HistoryTile extends StatelessWidget {
  final InferenceRecord record;
  final String          userName;

  const HistoryTile({
    super.key,
    required this.record,
    required this.userName,
  });

  @override
  Widget build(BuildContext context) {
    final isFilling = record.isFilling;
    final color     = isFilling ? AppColors.filling : AppColors.filled;
    final timeStr   = DateFormat('HH:mm:ss').format(record.timestamp.toLocal());
    final confStr   = '${(record.confidence * 100).toStringAsFixed(1)}%';

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: Row(
        children: [
          // Icon badge
          Container(
            width: 36, height: 36,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color.withOpacity(0.12),
            ),
            child: Icon(
              isFilling
                  ? Icons.water_drop
                  : Icons.check_circle_outline,
              color: color,
              size: 18,
            ),
          ),
          const SizedBox(width: 10),
          // Text
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  userName,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
                Text(
                  isFilling
                      ? 'Tank filling detected'
                      : 'Tank filled',
                  style: TextStyle(
                    fontSize: 11,
                    color: color.withOpacity(0.8),
                  ),
                ),
              ],
            ),
          ),
          // Time + confidence stacked
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                timeStr,
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.white.withOpacity(0.4),
                ),
              ),
              Text(
                'CL: $confStr',
                style: TextStyle(
                  fontSize: 9,
                  color: color.withOpacity(0.6),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(width: 8),
          // Label badge
          Container(
            padding: const EdgeInsets.symmetric(
                horizontal: 7, vertical: 3),
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(
                  color: color.withOpacity(0.3), width: 0.5),
            ),
            child: Text(
              record.label.toUpperCase(),
              style: TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.w700,
                color: color,
                letterSpacing: 0.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}