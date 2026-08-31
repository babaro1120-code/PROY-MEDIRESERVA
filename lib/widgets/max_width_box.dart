import 'package:flutter/material.dart';

/// Centra el contenido y limita su ancho maximo.
/// Util en web/desktop para que botones, listas y formularios
/// no ocupen todo el ancho de la pantalla.
class MaxWidthBox extends StatelessWidget {
  const MaxWidthBox({super.key, required this.child, this.maxWidth = 900});

  final Widget child;
  final double maxWidth;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: child,
      ),
    );
  }
}
