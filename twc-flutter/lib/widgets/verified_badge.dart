import 'package:flutter/material.dart';

/// Badge "vérifié" affiché juste après le nom d'un utilisateur Premium.
class VerifiedBadge extends StatelessWidget {
  final double size;

  const VerifiedBadge({super.key, this.size = 16});

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      'assets/images/verified_badge.png',
      width: size,
      height: size,
    );
  }
}
