import 'dart:math';
import 'dart:ui';
import 'package:flutter/material.dart';
import '../utils/app_colors.dart';

class AnimatedBackground extends StatefulWidget {
  final Widget child;
  const AnimatedBackground({super.key, required this.child});

  @override
  State<AnimatedBackground> createState() => _AnimatedBackgroundState();
}

class _AnimatedBackgroundState extends State<AnimatedBackground> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned.fill(child: Container(color: AppColors.background)),
        AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            return Stack(
              children: [
                _buildBlob(
                  color: AppColors.primary.withOpacity(0.2),
                  size: 300,
                  offset: Offset(
                    100 * sin(_controller.value * 2 * pi),
                    150 * cos(_controller.value * 2 * pi),
                  ),
                  top: -50,
                  left: -50,
                ),
                _buildBlob(
                  color: AppColors.secondary.withOpacity(0.15),
                  size: 250,
                  offset: Offset(
                    120 * cos(_controller.value * 2 * pi),
                    80 * sin(_controller.value * 2 * pi),
                  ),
                  bottom: -50,
                  right: -50,
                ),
              ],
            );
          },
        ),
        Positioned.fill(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 25, sigmaY: 25),
            child: Container(
              color: AppColors.background.withOpacity(0.3),
              child: widget.child,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBlob({
    required Color color,
    required double size,
    required Offset offset,
    double? top,
    double? left,
    double? bottom,
    double? right,
  }) {
    return Positioned(
      top: top,
      left: left,
      bottom: bottom,
      right: right,
      child: Transform.translate(
        offset: offset,
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(
              colors: [color, color.withOpacity(0)],
            ),
          ),
        ),
      ),
    );
  }
}
