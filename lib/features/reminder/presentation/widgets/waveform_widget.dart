import 'dart:math';
import 'package:flutter/material.dart';

class WaveformWidget extends StatefulWidget {
  final bool isRecording;
  const WaveformWidget({super.key, required this.isRecording});

  @override
  State<WaveformWidget> createState() => _WaveformWidgetState();
}

class _WaveformWidgetState extends State<WaveformWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  final Random _random = Random();
  List<double> _bars = List.filled(20, 0.1);

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
    )..addListener(_updateBars);
  }

  void _updateBars() {
    if (widget.isRecording) {
      setState(() {
        _bars = List.generate(20, (_) => 0.1 + _random.nextDouble() * 0.9);
      });
    }
  }

  @override
  void didUpdateWidget(WaveformWidget old) {
    super.didUpdateWidget(old);
    if (widget.isRecording) {
      _controller.repeat();
    } else {
      _controller.stop();
      setState(() => _bars = List.filled(20, 0.1));
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.primary;
    return SizedBox(
      height: 48,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: _bars.map((h) {
          return Container(
            width: 4,
            height: 48 * h,
            margin: const EdgeInsets.symmetric(horizontal: 2),
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(2),
            ),
          );
        }).toList(),
      ),
    );
  }
}
