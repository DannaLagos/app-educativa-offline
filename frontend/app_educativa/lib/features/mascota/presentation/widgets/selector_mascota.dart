import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../domain/mascota.dart';
import '../apariencia_mascota.dart';
import 'mascota_animada.dart';

/// Las cinco mascotas para elegir. Solo la elegida se mueve.
class SelectorMascota extends StatelessWidget {
  static const int _porFila = 3;
  static const double _espacio = 10;

  final EspecieMascota? seleccionada;
  final ValueChanged<EspecieMascota> onSeleccionar;

  const SelectorMascota({
    super.key,
    required this.seleccionada,
    required this.onSeleccionar,
  });

  @override
  Widget build(BuildContext context) {
    final elegida = seleccionada;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        LayoutBuilder(
          builder: (context, limites) {
            final ancho =
                (limites.maxWidth - _espacio * (_porFila - 1)) / _porFila;

            return Wrap(
              spacing: _espacio,
              runSpacing: _espacio,
              alignment: WrapAlignment.center,
              children: [
                for (final especie in EspecieMascota.values)
                  SizedBox(
                    width: ancho,
                    child: _OpcionMascota(
                      especie: especie,
                      estaSeleccionada: especie == elegida,
                      onTap: () => onSeleccionar(especie),
                    ),
                  ),
              ],
            );
          },
        ),
        if (elegida != null) ...[
          const SizedBox(height: 12),
          Text(
            elegida.descripcion,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: AparienciaMascota.de(elegida).oscuro,
            ),
          ),
        ],
      ],
    );
  }
}

class _OpcionMascota extends StatelessWidget {
  final EspecieMascota especie;
  final bool estaSeleccionada;
  final VoidCallback onTap;

  const _OpcionMascota({
    required this.especie,
    required this.estaSeleccionada,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final apariencia = AparienciaMascota.de(especie);

    return Semantics(
      button: true,
      selected: estaSeleccionada,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: estaSeleccionada ? apariencia.fondo : AppTheme.superficie,
          borderRadius: BorderRadius.circular(AppTheme.radio),
          border: Border.all(
            color: estaSeleccionada ? apariencia.principal : AppTheme.borde,
            width: estaSeleccionada ? 3 : 1,
          ),
        ),
        child: InkWell(
          key: ValueKey('mascota-${especie.name}'),
          borderRadius: BorderRadius.circular(AppTheme.radio),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Column(
              children: [
                MascotaAnimada(
                  especie: especie,
                  etapa: EtapaMascota.bebe,
                  tamano: 72,
                  animada: estaSeleccionada,
                  saltaAlTocar: false,
                ),
                Text(
                  especie.nombre,
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    color:
                        estaSeleccionada ? apariencia.oscuro : AppTheme.texto,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Hoja para elegir mascota desde el inicio (perfiles creados antes de que
/// existieran las mascotas). Devuelve la elegida, o null si se cierra.
Future<EspecieMascota?> elegirMascota(BuildContext context) {
  return showModalBottomSheet<EspecieMascota>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (context) {
      EspecieMascota? elegida;

      return StatefulBuilder(
        builder: (context, setState) => SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'Elige tu mascota',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 6),
                const Text(
                  '¡Crecerá contigo mientras aprendes!',
                  style:
                      TextStyle(fontSize: 17, color: AppTheme.textoSecundario),
                ),
                const SizedBox(height: 16),
                SelectorMascota(
                  seleccionada: elegida,
                  onSeleccionar: (especie) => setState(() => elegida = especie),
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: elegida == null
                      ? null
                      : () => Navigator.of(context).pop(elegida),
                  child: const Text('¡Esta es mi mascota!'),
                ),
              ],
            ),
          ),
        ),
      );
    },
  );
}
