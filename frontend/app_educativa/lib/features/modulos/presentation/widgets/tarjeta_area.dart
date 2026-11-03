import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../shared/widgets/dibujo.dart';
import '../../domain/area_resumen.dart';
import '../screens/modulos_screen.dart';
import 'icono_area.dart';

/// Tarjeta de color entero para cada área, con relieve como un botón.
class TarjetaArea extends StatelessWidget {
  static const double _tamanoIconoCompacto = 52;
  static const double _relieve = 5;

  final AreaResumen area;
  final bool esCompacta;

  const TarjetaArea({
    super.key,
    required this.area,
    this.esCompacta = false,
  });

  void _abrirModulosDelArea(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ModulosScreen(area: area.area),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final apariencia = AparienciaArea.de(area.area);
    final radio = BorderRadius.circular(AppTheme.radio);

    return Padding(
      padding: EdgeInsets.only(bottom: esCompacta ? _relieve : 14 + _relieve),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: radio,
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              apariencia.color,
              // Más oscuro, no más claro: el texto blanco sigue legible.
              Color.lerp(apariencia.color, Colors.black, 0.12)!,
            ],
          ),
          boxShadow: [
            BoxShadow(
              color: Color.lerp(apariencia.color, Colors.black, 0.35)!,
              offset: const Offset(0, _relieve),
            ),
          ],
        ),
        child: Material(
          type: MaterialType.transparency,
          child: InkWell(
            onTap: () => _abrirModulosDelArea(context),
            borderRadius: radio,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: esCompacta
                  ? _construirDisenoCompacto(apariencia)
                  : _construirDisenoHorizontal(apariencia),
            ),
          ),
        ),
      ),
    );
  }

  Widget _construirDisenoCompacto(AparienciaArea apariencia) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _IconoBlanco(apariencia: apariencia, tamano: _tamanoIconoCompacto),
        const SizedBox(height: 12),
        _NombreYDescripcion(area: area),
      ],
    );
  }

  Widget _construirDisenoHorizontal(AparienciaArea apariencia) {
    return Row(
      children: [
        _IconoBlanco(
            apariencia: apariencia, tamano: IconoArea.tamanoNormal + 8),
        const SizedBox(width: 16),
        Expanded(child: _NombreYDescripcion(area: area)),
        Container(
          decoration: const BoxDecoration(
            color: Color(0x33FFFFFF),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.chevron_right_rounded,
            size: 36,
            color: Colors.white,
          ),
        ),
      ],
    );
  }
}

class _IconoBlanco extends StatelessWidget {
  final AparienciaArea apariencia;
  final double tamano;

  const _IconoBlanco({required this.apariencia, required this.tamano});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: tamano,
      height: tamano,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(tamano * 0.3),
      ),
      alignment: Alignment.center,
      child: Dibujo(apariencia.emoji, tamano: tamano * 0.72),
    );
  }
}

class _NombreYDescripcion extends StatelessWidget {
  final AreaResumen area;

  const _NombreYDescripcion({required this.area});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          area.area,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          area.descripcion,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
      ],
    );
  }
}
