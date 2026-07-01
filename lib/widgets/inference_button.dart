import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../providers/app_provider.dart';

class InferenceButton extends StatefulWidget {
  final AppState appState;
  final VoidCallback onTap;

  const InferenceButton({
    super.key,
    required this.appState,
    required this.onTap,
  });

  @override
  State<InferenceButton> createState() => _InferenceButtonState();
}

class _InferenceButtonState extends State<InferenceButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _ringCtrl;
  late Animation<double>   _ring;

  @override
  void initState() {
    super.initState();
    _ringCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    _ring = CurvedAnimation(parent: _ringCtrl, curve: Curves.easeOut);
  }

  @override
  void didUpdateWidget(InferenceButton old) {
    super.didUpdateWidget(old);
    final active = widget.appState != AppState.idle;
    if (active) {
      _ringCtrl.repeat();
    } else {
      _ringCtrl.stop();
      _ringCtrl.reset();
    }
  }

  @override
  void dispose() {
    _ringCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isActive  = widget.appState != AppState.idle;
    final isAlert   = widget.appState == AppState.alerting;
    final ringColor = isAlert ? AppColors.red : AppColors.cyan;

    return GestureDetector(
      onTap: widget.onTap,
      child: AnimatedBuilder(
        animation: _ring,
        builder: (_, child) {
          return Stack(
            alignment: Alignment.center,
            children: [
              // Animated expanding ring
              if (isActive)
                Container(
                  width:  90 + _ring.value * 30,
                  height: 90 + _ring.value * 30,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: ringColor.withOpacity(1 - _ring.value),
                      width: 2,
                    ),
                  ),
                ),
              // Main button
              Container(
                width:  76,
                height: 76,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isActive
                      ? (isAlert
                          ? AppColors.red.withOpacity(0.15)
                          : AppColors.cyan.withOpacity(0.1))
                      : Colors.white.withOpacity(0.05),
                  border: Border.all(
                    color: isActive ? ringColor : Colors.white.withOpacity(0.2),
                    width: 2,
                  ),
                  boxShadow: isActive
                      ? [
                          BoxShadow(
                            color:       ringColor.withOpacity(0.3),
                            blurRadius:  20,
                            spreadRadius: 2,
                          )
                        ]
                      : null,
                ),
                child: Icon(
                  isAlert
                      ? Icons.notifications_active
                      : (isActive ? Icons.mic : Icons.mic_none),
                  color: isActive ? ringColor : Colors.white.withOpacity(0.4),
                  size: 30,
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
