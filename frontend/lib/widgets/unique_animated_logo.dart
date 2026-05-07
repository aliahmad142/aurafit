import 'dart:math';
import 'package:flutter/material.dart';
import '../utils/app_colors.dart';

class UniqueAnimatedLogo extends StatefulWidget {
  final IconData icon;
  final Color color;
  const UniqueAnimatedLogo({super.key, required this.icon, required this.color});

  @override
  State<UniqueAnimatedLogo> createState() => _UniqueAnimatedLogoState();
}

class _UniqueAnimatedLogoState extends State<UniqueAnimatedLogo> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(seconds: 4))..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final double rotation = _controller.value * 2 * pi;
        final double yRotation = sin(_controller.value * pi); // 3D flip effect
        
        return Stack(
          alignment: Alignment.center,
          children: [
            // Multi-colored Neon Aura
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: widget.color.withOpacity(0.3),
                    blurRadius: 40 + (10 * sin(rotation)),
                    spreadRadius: 5 + (5 * cos(rotation)),
                  ),
                  BoxShadow(
                    color: AppColors.primary.withOpacity(0.2),
                    blurRadius: 60,
                    offset: Offset(20 * cos(rotation), 20 * sin(rotation)),
                  ),
                ],
              ),
            ),
            
            // Orbital Particles
            ...List.generate(3, (index) {
              final double pRotation = rotation + (index * 2 * pi / 3);
              return Transform.translate(
                offset: Offset(55 * cos(pRotation), 55 * sin(pRotation)),
                child: Container(
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: index % 2 == 0 ? widget.color : AppColors.primary,
                    boxShadow: [
                      BoxShadow(color: widget.color, blurRadius: 10, spreadRadius: 1),
                    ],
                  ),
                ),
              );
            }),

            // 3D Rotating Logo
            Transform(
              transform: Matrix4.identity()
                ..setEntry(3, 2, 0.002) // perspective
                ..rotateY(yRotation * 0.5), // 3D Tilt
              alignment: Alignment.center,
              child: Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [
                      widget.color.withOpacity(0.2),
                      widget.color.withOpacity(0.1),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  border: Border.all(color: widget.color.withOpacity(0.5), width: 2),
                ),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Icon(widget.icon, color: widget.color, size: 40),
                    // Shine Sweep Effect
                    Positioned.fill(
                      child: ClipOval(
                        child: Transform.translate(
                          offset: Offset(-100 + (200 * _controller.value), -100 + (200 * _controller.value)),
                          child: Transform.rotate(
                            angle: pi / 4,
                            child: Container(
                              width: 30,
                              height: 200,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    Colors.white.withOpacity(0),
                                    Colors.white.withOpacity(0.3),
                                    Colors.white.withOpacity(0),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
