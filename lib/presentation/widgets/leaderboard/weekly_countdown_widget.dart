import 'package:flutter/material.dart';
import 'dart:async';

/// Widget displaying weekly countdown timer and progress bar
class WeeklyCountdownWidget extends StatefulWidget {
  final DateTime weekStart;
  final DateTime weekEnd;

  const WeeklyCountdownWidget({
    super.key,
    required this.weekStart,
    required this.weekEnd,
  });

  @override
  State<WeeklyCountdownWidget> createState() => _WeeklyCountdownWidgetState();
}

class _WeeklyCountdownWidgetState extends State<WeeklyCountdownWidget> {
  late Timer _timer;
  Duration _timeRemaining = Duration.zero;
  double _progress = 0.0;

  @override
  void initState() {
    super.initState();
    _updateTime();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => _updateTime());
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  void _updateTime() {
    if (!mounted) return;
    
    setState(() {
      final now = DateTime.now();
      _timeRemaining = widget.weekEnd.difference(now);
      
      if (_timeRemaining.isNegative) {
        _timeRemaining = Duration.zero;
        _progress = 1.0;
      } else {
        final totalDuration = widget.weekEnd.difference(widget.weekStart).inMilliseconds;
        final elapsed = now.difference(widget.weekStart).inMilliseconds;
        _progress = totalDuration > 0 ? (elapsed / totalDuration).clamp(0.0, 1.0) : 0.0;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Timer header
          Row(
            children: [
              const Icon(Icons.timer_outlined, size: 20),
              const SizedBox(width: 8),
              Text(
                'Week resets in',
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // Countdown numbers
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildTimeUnit(
                context,
                value: _timeRemaining.inDays,
                label: 'days',
              ),
              const SizedBox(width: 16),
              _buildTimeUnit(
                context,
                value: _timeRemaining.inHours.remainder(24),
                label: 'hours',
              ),
              const SizedBox(width: 16),
              _buildTimeUnit(
                context,
                value: _timeRemaining.inMinutes.remainder(60),
                label: 'mins',
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // Progress bar
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: _progress,
                  minHeight: 8,
                  backgroundColor: Colors.grey[200],
                  valueColor: AlwaysStoppedAnimation<Color>(
                    Theme.of(context).primaryColor,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Week ${(_progress * 100).toInt()}% done',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.grey[600],
                    ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTimeUnit(BuildContext context, {required int value, required String label}) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: Theme.of(context).primaryColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            value.toString().padLeft(2, '0'),
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).primaryColor,
                ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Colors.grey[600],
              ),
        ),
      ],
    );
  }
}
