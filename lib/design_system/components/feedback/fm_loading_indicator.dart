import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';

class FMLoadingIndicator extends StatefulWidget {
  final Color? color;
  final double dotSize;
  final double spacing;

  const FMLoadingIndicator({
    super.key,
    this.color,
    this.dotSize = 6.0,
    this.spacing = 4.0,
  });

  @override
  State<FMLoadingIndicator> createState() => _FMLoadingIndicatorState();
}

class _FMLoadingIndicatorState extends State<FMLoadingIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = widget.color ?? AppColors.textPrimary;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(3, (index) {
        return AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            // Stagger the animation for each dot
            final delay = index * 0.2;
            final progress = (_controller.value - delay).clamp(0.0, 1.0);

            // Create a pulsing effect using sine wave
            final scale = 0.5 + 0.5 * _pulse(progress);
            final opacity = 0.4 + 0.6 * _pulse(progress);

            return Container(
              margin: EdgeInsets.symmetric(horizontal: widget.spacing / 2),
              child: Transform.scale(
                scale: scale,
                child: Opacity(
                  opacity: opacity,
                  child: Container(
                    width: widget.dotSize,
                    height: widget.dotSize,
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              ),
            );
          },
        );
      }),
    );
  }

  double _pulse(double progress) {
    // Creates a smooth pulse effect
    // Each dot pulses up and down in a wave pattern
    const cycles = 1.0;
    final value = progress * cycles * 2 * 3.14159;
    return (1 + _sin(value)) / 2;
  }

  double _sin(double x) {
    // Simple sine approximation
    x = x % (2 * 3.14159);
    if (x > 3.14159) x -= 2 * 3.14159;
    return x - (x * x * x) / 6 + (x * x * x * x * x) / 120;
  }
}

class FMLoadingDots extends StatefulWidget {
  final Color? color;
  final double size;

  const FMLoadingDots({
    super.key,
    this.color,
    this.size = 20.0,
  });

  @override
  State<FMLoadingDots> createState() => _FMLoadingDotsState();
}

class _FMLoadingDotsState extends State<FMLoadingDots>
    with TickerProviderStateMixin {
  late List<AnimationController> _controllers;
  late List<Animation<double>> _animations;

  @override
  void initState() {
    super.initState();
    _controllers = List.generate(3, (index) {
      return AnimationController(
        duration: const Duration(milliseconds: 600),
        vsync: this,
      );
    });

    _animations = _controllers.map((controller) {
      return TweenSequence<double>([
        TweenSequenceItem(
          tween: Tween(begin: 1.0, end: 0.4)
              .chain(CurveTween(curve: Curves.easeInOut)),
          weight: 50,
        ),
        TweenSequenceItem(
          tween: Tween(begin: 0.4, end: 1.0)
              .chain(CurveTween(curve: Curves.easeInOut)),
          weight: 50,
        ),
      ]).animate(controller);
    }).toList();

    // Start animations with stagger
    for (int i = 0; i < _controllers.length; i++) {
      Future.delayed(Duration(milliseconds: i * 150), () {
        if (mounted) {
          _controllers[i].repeat();
        }
      });
    }
  }

  @override
  void dispose() {
    for (final controller in _controllers) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = widget.color ?? AppColors.textPrimary;
    final dotSize = widget.size / 4;

    return SizedBox(
      width: widget.size,
      height: dotSize,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: List.generate(3, (index) {
          return AnimatedBuilder(
            animation: _animations[index],
            builder: (context, child) {
              return Opacity(
                opacity: _animations[index].value,
                child: Container(
                  width: dotSize,
                  height: dotSize,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                  ),
                ),
              );
            },
          );
        }),
      ),
    );
  }
}
