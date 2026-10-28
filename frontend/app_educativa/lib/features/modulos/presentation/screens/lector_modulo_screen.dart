import 'package:flutter/material.dart';

import '../../../../shared/widgets/boton_grande.dart';
import '../../../../shared/widgets/mensaje_con_accion.dart';
import '../../domain/modulo.dart';
import '../../domain/recurso_local.dart';
import '../controllers/modulos_scope.dart';
import '../widgets/visor_pdf_con_progreso.dart';

typedef ConstructorVisor = Widget Function(RecursoLocal recurso);

const String tipoRecursoDocumento = 'pdf';

class LectorModuloScreen extends StatefulWidget {
  final Modulo modulo;

  // Reemplazable en pruebas porque pdfx usa código nativo. Si es null se usa
  // el visor de PDF que guarda la página leída (HU06).
  final ConstructorVisor? construirVisor;

  const LectorModuloScreen({
    super.key,
    required this.modulo,
    this.construirVisor,
  });

  @override
  State<LectorModuloScreen> createState() => _LectorModuloScreenState();
}

class _LectorModuloScreenState extends State<LectorModuloScreen> {
  Future<List<RecursoLocal>>? _recursos;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _recursos ??= ModulosScope.of(context).obtenerRecursos(widget.modulo);
  }

  Widget _construirVisor(RecursoLocal recurso) {
    return widget.construirVisor?.call(recurso) ??
        VisorPdfConProgreso(moduloId: widget.modulo.id, recurso: recurso);
  }

  void _abrirRecurso(RecursoLocal recurso) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => Scaffold(
          appBar: AppBar(title: Text(recurso.titulo)),
          body: _construirVisor(recurso),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.modulo.nombre),
      ),
      body: FutureBuilder<List<RecursoLocal>>(
        future: _recursos,
        builder: _construirSegunEstado,
      ),
    );
  }

  Widget _construirSegunEstado(
    BuildContext context,
    AsyncSnapshot<List<RecursoLocal>> snapshot,
  ) {
    if (snapshot.connectionState != ConnectionState.done) {
      return const Center(child: CircularProgressIndicator());
    }

    // El lector solo muestra documentos; los juegos se abren desde el mapa
    // de niveles (HU07).
    final recursos = snapshot.data
        ?.where((recurso) => recurso.tipo == tipoRecursoDocumento)
        .toList();

    if (snapshot.hasError || recursos == null || recursos.isEmpty) {
      return _construirError();
    }

    if (recursos.length == 1) {
      return _construirVisor(recursos.single);
    }

    return _construirSelectorDeRecursos(recursos);
  }

  Widget _construirError() {
    return MensajeConAccion(
      icono: const Icon(Icons.report_problem_rounded),
      mensaje: 'Faltan archivos de este módulo. Descárgalo de nuevo.',
      accion: BotonGrande(
        texto: 'Volver',
        icono: Icons.arrow_back_rounded,
        onPressed: () => Navigator.of(context).pop(),
      ),
    );
  }

  Widget _construirSelectorDeRecursos(List<RecursoLocal> recursos) {
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        const Text(
          'Elige qué quieres ver:',
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        for (final recurso in recursos) ...[
          BotonGrande(
            texto: recurso.titulo,
            icono: Icons.picture_as_pdf_rounded,
            onPressed: () => _abrirRecurso(recurso),
          ),
          const SizedBox(height: 12),
        ],
      ],
    );
  }
}
