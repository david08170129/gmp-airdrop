import 'package:flutter/material.dart';

class GmpLogo extends StatelessWidget {
  const GmpLogo({this.height = 46, super.key});

  final double height;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'GMP Transfer',
      image: true,
      child: Image.asset(
        'assets/images/gmp_logo.png',
        height: height,
        fit: BoxFit.contain,
      ),
    );
  }
}
