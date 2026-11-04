import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../core/voz/lector_voz.dart';

/// Botón 🔊 que lee [texto] en voz alta, para los niños que todavía no leen
/// bien. Usa la voz del teléfono: no necesita internet.
class BotonEscuchar extends StatelessWidget {
  static const double _tamano = 56;

  final String texto;
  final Color color;

  const BotonEscuchar({
    super.key,
    required this.texto,
    this.color = AppTheme.morado,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: 'Escuchar',
      child: Material(
        color: color,
        shape: const CircleBorder(),
        elevation: 0,
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: () => hablarOAvisar(context, texto),
          child: const SizedBox.square(
            dimension: _tamano,
            child: Icon(
              Icons.volume_up_rounded,
              color: Colors.white,
              size: 30,
              semanticLabel: 'Escuchar',
            ),
          ),
        ),
      ),
    );
  }
}

/// Lee [texto] en voz alta. Si el teléfono no tiene un motor de voz, avisa
/// qué instalar en vez de quedarse callado sin explicación.
Future<void> hablarOAvisar(BuildContext context, String texto) async {
  final voz = VozScope.de(context);
  final mensajero = ScaffoldMessenger.maybeOf(context);

  if (await voz.estaDisponible()) {
    await voz.hablar(texto);
    return;
  }

  mensajero
    ?..hideCurrentSnackBar()
    ..showSnackBar(
      const SnackBar(
        duration: Duration(seconds: 6),
        content: Text(
          'Este teléfono no tiene voz instalada. Pide a un adulto que '
          'instale "Servicios de voz de Google" desde la Play Store.',
        ),
      ),
    );
}
