import 'dart:async';
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class CountdownTimer extends StatefulWidget {
  final DateTime targetDate;

  const CountdownTimer({super.key, required this.targetDate});

  @override
  State<CountdownTimer> createState() => _CountdownTimerState();
}

class _CountdownTimerState extends State<CountdownTimer> {
  late Timer _timer;
  Duration _duration = Duration.zero;

  @override
  void initState() {
    super.initState();
    _calculateDuration();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _calculateDuration();
    });
  }

  void _calculateDuration() {
    final now = DateTime.now();
    final difference = widget.targetDate.difference(now);
    if (mounted) {
      setState(() {
        _duration = difference.isNegative ? Duration.zero : difference;
      });
    }
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final days = _duration.inDays;
    final hours = _duration.inHours % 24;
    final minutes = _duration.inMinutes % 60;
    final seconds = _duration.inSeconds % 60;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      decoration: BoxDecoration(
        color: AppTheme.purpleCard.withOpacity(0.88),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: AppTheme.goldPrimary.withOpacity(0.55),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.8),
            blurRadius: 40,
            offset: const Offset(0, 20),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _TimeSlot(value: days.toString().padLeft(2, '0'), label: 'DAYS'),
          _Divider(),
          _TimeSlot(value: hours.toString().padLeft(2, '0'), label: 'HOURS'),
          _Divider(),
          _TimeSlot(value: minutes.toString().padLeft(2, '0'), label: 'MINS'),
          _Divider(),
          _TimeSlot(value: seconds.toString().padLeft(2, '0'), label: 'SECS'),
        ],
      ),
    );
  }
}

class _TimeSlot extends StatelessWidget {
  final String value;
  final String label;

  const _TimeSlot({required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w700,
            color: AppTheme.goldPrimary,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: AppTheme.textMuted,
            letterSpacing: 1.5,
          ),
        ),
      ],
    );
  }
}

class _Divider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 40,
      width: 1,
      color: AppTheme.goldPrimary.withOpacity(0.3),
    );
  }
}
