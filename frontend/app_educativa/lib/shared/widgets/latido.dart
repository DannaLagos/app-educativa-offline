import 'package:flutter/material.dart';

/// Hace "latir" a su hijo (crece y se encoge despacio) para llamar la
/// atención del niño, por ejemplo sobre el siguiente juego. Se queda quieto
/// si el teléfono pide reducir animaciones.
class Latido extends StatefulWidget {
  final Widget child;
  final double escala;

  const Latido({super.key, required this.child, this.escala = 1.07});

  @override
  State<Latido> createState() => _LatidoState();
}

class _LatidoState extends State<Latido> with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    if (MediaQuery.maybeDisableAnimationsOf(context) ?? false) {
      _controller.stop();
    } else if (!_controller.isAnimating) {
      _controller.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: Tween<double>(begin: 1, end: widget.escala).animate(
        CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
      ),
      child: widget.child,
    );
  }
}
