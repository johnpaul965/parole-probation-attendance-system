import 'package:flutter/material.dart';

class GradientHeader extends StatelessWidget {
  const GradientHeader({
    super.key,
    required this.color,
    required this.child,
    this.padding = const EdgeInsets.fromLTRB(18, 14, 18, 16),
  });

  final Color color;
  final Widget child;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [color, Color.lerp(color, Colors.black, 0.15)!],
        ),
      ),
      padding: padding,
      child: child,
    );
  }
}
