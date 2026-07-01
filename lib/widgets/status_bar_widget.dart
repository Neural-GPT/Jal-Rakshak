import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../providers/app_provider.dart';

class StatusBar extends StatefulWidget {
  final AppState appState;

  const StatusBar({super.key, required this.appState});

  @override
  State<StatusBar> createState() => _StatusBarState();
}

class _StatusBarState extends State<StatusBar>
    with SingleTickerProviderStateMixin {
  late AnimationController _dotCtrl;

  @override
  void initState() {
    super.initState();
    _dotCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _dotCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isActive  = widget.appState != AppState.idle;
    final isAlert   = widget.appState == AppState.alerting;
    final isProcess = widget.appState == AppState.processing;

    final color = isAlert ? AppColors.red : AppColors.cyan;

    final label = switch (widget.appState) {
      AppState.idle       => 'Not Listening',
      AppState.listening  => 'Listening...',
      AppState.processing => 'Analyzing tank sound',
      AppState.alerting   => '⚠ Tank Filled! Dismiss alarm',
    };

    final sublabel = switch (widget.appState) {
      AppState.idle       => 'Tap the mic to start monitoring',
      AppState.listening  => 'Analyzing tank sound',
      AppState.processing => 'Running inference...',
      AppState.alerting   => 'Turn off the motor',
    };

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: isActive
            ? color.withOpacity(0.07)
            : Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(30),
        border: Border.all(
          color: isActive ? color.withOpacity(0.4) : Theme.of(context).dividerColor,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Animated dot
          AnimatedBuilder(
            animation: _dotCtrl,
            builder: (_, __) => Container(
              width:  8,
              height: 8,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isActive
                    ? color.withOpacity(0.5 + _dotCtrl.value * 0.5)
                    : Colors.white.withOpacity(0.2),
                boxShadow: isActive
                    ? [BoxShadow(
                        color: color.withOpacity(0.5),
                        blurRadius: 6,
                      )]
                    : null,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: isActive ? color : Colors.white.withOpacity(0.5),
                ),
              ),
              if (isActive)
                Text(
                  sublabel,
                  style: TextStyle(
                    fontSize: 10,
                    color: color.withOpacity(0.6),
                  ),
                ),
            ],
          ),
          if (isProcess) ...[
            const SizedBox(width: 10),
            SizedBox(
              width: 12, height: 12,
              child: CircularProgressIndicator(
                strokeWidth: 1.5,
                valueColor: AlwaysStoppedAnimation(color),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
