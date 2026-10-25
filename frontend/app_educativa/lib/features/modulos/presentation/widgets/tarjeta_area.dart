import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../domain/area_resumen.dart';
import '../screens/modulos_screen.dart';
import 'icono_area.dart';

class TarjetaArea extends StatelessWidget {
  static const double _tamanoIconoCompacto = 44;

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
    return Padding(
      padding: EdgeInsets.only(bottom: esCompacta ? 0 : 14),
      child: Card(
        child: InkWell(
          onTap: () => _abrirModulosDelArea(context),
          borderRadius: BorderRadius.circular(AppTheme.radio),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: esCompacta
                ? _construirDisenoCompacto()
                : _construirDisenoHorizontal(),
          ),
        ),
      ),
    );
  }

  Widget _construirDisenoCompacto() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        IconoArea(area: area.area, tamano: _tamanoIconoCompacto),
        const SizedBox(height: 12),
        _NombreYDescripcion(area: area),
      ],
    );
  }

  Widget _construirDisenoHorizontal() {
    return Row(
      children: [
        IconoArea(area: area.area),
        const SizedBox(width: 16),
        Expanded(child: _NombreYDescripcion(area: area)),
        const Icon(Icons.chevron_right_rounded, size: 32),
      ],
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
          style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 2),
        Text(
          area.descripcion,
          style: const TextStyle(
            fontSize: 15,
            color: AppTheme.textoSecundario,
          ),
        ),
      ],
    );
  }
}
