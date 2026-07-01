import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/app_provider.dart';
import '../widgets/history_tile.dart';
import '../theme/app_theme.dart';

class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final prov    = context.watch<AppProvider>();
    final history = prov.history;

    // Group by date
    final grouped = <String, List<dynamic>>{};
    for (final r in history) {
      final key = DateFormat('dd MMM yyyy').format(r.timestamp.toLocal());
      grouped.putIfAbsent(key, () => []).add(r);
    }

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 16, 12),
              child: Row(
                children: [
                  const Text('History',
                      style: TextStyle(
                          fontSize: 22, fontWeight: FontWeight.w800)),
                  const Spacer(),
                  if (history.isNotEmpty)
                    TextButton.icon(
                      onPressed: () => _confirmClear(context, prov),
                      icon: const Icon(Icons.delete_outline,
                          size: 14, color: AppColors.red),
                      label: const Text('Clear',
                          style: TextStyle(
                              fontSize: 12, color: AppColors.red)),
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
            ),

            // List
            Expanded(
              child: history.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.history,
                              size: 48,
                              color: Colors.white.withOpacity(0.1)),
                          const SizedBox(height: 12),
                          Text(
                            'No inference history yet',
                            style: TextStyle(
                                color: Colors.white.withOpacity(0.2),
                                fontSize: 14),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Start monitoring to see results here',
                            style: TextStyle(
                                color: Colors.white.withOpacity(0.1),
                                fontSize: 12),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 80),
                      physics: const BouncingScrollPhysics(),
                      itemCount: grouped.length,
                      itemBuilder: (ctx, dateIdx) {
                        final date    = grouped.keys.elementAt(dateIdx);
                        final records = grouped[date]!;
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                  vertical: 10),
                              child: Text(
                                date,
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white.withOpacity(0.3),
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ),
                            ...records.map((r) => HistoryTile(
                                  record:   r,
                                  userName: prov.settings.userName,
                                )),
                          ],
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmClear(
      BuildContext context, AppProvider prov) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF131720),
        title: const Text('Clear History'),
        content: const Text('Delete all inference records?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel')),
          TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Clear',
                  style: TextStyle(color: AppColors.red))),
        ],
      ),
    );
    if (ok == true) await prov.clearHistory();
  }
}
