import 'package:flutter/material.dart';

import '../../domain/area_resumen.dart';
import '../controllers/carga_al_mostrar.dart';
import '../controllers/modulos_controller.dart';
import '../controllers/modulos_scope.dart';
import '../widgets/tarjeta_area.dart';

class AreasScreen extends StatefulWidget {
  const AreasScreen({super.key});

  @override
  State<AreasScreen> createState() => _AreasScreenState();
}

class _AreasScreenState extends State<AreasScreen>
    with CargaAlMostrar<AreasScreen> {
  @override
  Future<void> cargarAlMostrar(ModulosController controller) {
    return controller.cargarCatalogo();
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
        child: controller.estaCargando && areas.isEmpty
            ? const Center(child: CircularProgressIndicator())
            : RefreshIndicator(
                onRefresh: controller.cargarCatalogo,
                child: _ListaAreas(areas: areas),
              ),
      ),
    );
  }
}

class _ListaAreas extends StatelessWidget {
  final List<AreaResumen> areas;

  const _ListaAreas({required this.areas});

  @override
  Widget build(BuildContext context) {
    return ListView(
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
    );
  }
}
