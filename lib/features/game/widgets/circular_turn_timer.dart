import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/app_colors.dart';

class CircularTurnTimer extends StatefulWidget {
  const CircularTurnTimer({
    super.key,
    required this.duration,
    required this.currentTurn,
    required this.onTimeout,
    required this.isActive,
  });

  final int duration;
  final int currentTurn;
  final VoidCallback onTimeout;
  final bool isActive;

  @override
  State<CircularTurnTimer> createState() => _CircularTurnTimerState();
}

class _CircularTurnTimerState extends State<CircularTurnTimer>
    with SingleTickerProviderStateMixin {
  late int _timeLeft;
  Timer? _timer;
  late final AnimationController _pulseCtrl;

  @override
  void initState() {
    super.initState();
    _timeLeft = widget.duration;
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    if (widget.isActive) {
      _startTimer();
    }
  }

  @override
  void didUpdateWidget(covariant CircularTurnTimer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.currentTurn != widget.currentTurn) {
      // Reset timer on turn change
      _timer?.cancel();
      setState(() {
        _timeLeft = widget.duration;
      });
      _pulseCtrl.stop();
      if (widget.isActive) {
        _startTimer();
      }
    } else if (oldWidget.isActive != widget.isActive) {
      if (widget.isActive) {
        _startTimer();
      } else {
        _timer?.cancel();
        _pulseCtrl.stop();
      }
    }
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) return;
      if (_timeLeft <= 1) {
        t.cancel();
        _pulseCtrl.stop();
        widget.onTimeout();
      } else {
        setState(() {
          _timeLeft--;
        });
        if (_timeLeft <= 10) {
          _pulseCtrl.repeat(reverse: true);
        }
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pulseCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ratio = _timeLeft / widget.duration;
    final isLowTime = _timeLeft <= 10;
    final color = isLowTime ? AppColors.danger : AppColors.secondary;

    return AnimatedBuilder(
      animation: _pulseCtrl,
      builder: (context, child) {
        final pulseScale = 1.0 + (_pulseCtrl.value * 0.08 * (isLowTime ? 1.0 : 0.0));
        return Transform.scale(
          scale: pulseScale,
          child: Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: 44,
                height: 44,
                child: CircularProgressIndicator(
                  value: ratio,
                  strokeWidth: 3.5,
                  backgroundColor: AppColors.divider.withOpacity(0.2),
                  valueColor: AlwaysStoppedAnimation<Color>(color),
                ),
              ),
              Text(
                '$_timeLeft',
                style: GoogleFonts.luckiestGuy(
                  fontSize: 14,
                  color: color,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
