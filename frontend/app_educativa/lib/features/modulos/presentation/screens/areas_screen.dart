import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../domain/area_resumen.dart';
import '../controllers/modulos_scope.dart';
import '../widgets/icono_area.dart';
import 'modulos_screen.dart';

/// Lista las áreas educativas con módulos habilitados. Al tocar una se abre
/// la lista de módulos de esa área.
class AreasScreen extends StatefulWidget {
  const AreasScreen({super.key});

  @override
  State<AreasScreen> createState() => _AreasScreenState();
}

class _AreasScreenState extends State<AreasScreen> {
  bool _cargaIniciada = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    if (!_cargaIniciada) {
      _cargaIniciada = true;
      final controller = ModulosScope.of(context);
      WidgetsBinding.instance.addPostFrameCallback(
        (_) => controller.cargarCatalogo(),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final controller = ModulosScope.of(context);
    final areas = AreaResumen.agrupar(controller.catalogo);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Áreas educativas'),
      ),
      body: SafeArea(
        child: controller.cargando && areas.isEmpty
            ? const Center(child: CircularProgressIndicator())
            : RefreshIndicator(
                onRefresh: controller.cargarCatalogo,
                child: ListView(
                  padding: const EdgeInsets.all(20),
                  children: [
                    if (areas.isEmpty)
                      const Padding(
                        padding: EdgeInsets.only(top: 48),
                        child: Text(
                          'No hay áreas disponibles. '
                          'Conéctate a internet y desliza hacia abajo.',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 19),
                        ),
                      ),
                    for (final area in areas) TarjetaArea(area: area),
                  ],
                ),
              ),
      ),
    );
  }
}

/// Tarjeta de un área: ícono, nombre y "Grado 1 • 1 módulo disponible".
class TarjetaArea extends StatelessWidget {
  final AreaResumen area;
  final bool compacta;

  const TarjetaArea({
    super.key,
    required this.area,
    this.compacta = false,
  });

  void _abrir(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ModulosScreen(area: area.area),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final descripcion = Text(
      area.descripcion,
      style: const TextStyle(
        fontSize: 15,
        color: AppTheme.textoSecundario,
      ),
    );

    final nombre = Text(
      area.area,
      style: const TextStyle(
        fontSize: 19,
        fontWeight: FontWeight.w800,
      ),
    );

    return Padding(
      padding: EdgeInsets.only(bottom: compacta ? 0 : 14),
      child: Card(
        child: InkWell(
          onTap: () => _abrir(context),
          borderRadius: BorderRadius.circular(AppTheme.radio),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: compacta
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      IconoArea(area: area.area, tamano: 44),
                      const SizedBox(height: 12),
                      nombre,
                      const SizedBox(height: 2),
                      descripcion,
                    ],
                  )
                : Row(
                    children: [
                      IconoArea(area: area.area),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            nombre,
                            const SizedBox(height: 2),
                            descripcion,
                          ],
                        ),
                      ),
                      const Icon(Icons.chevron_right_rounded, size: 32),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}
