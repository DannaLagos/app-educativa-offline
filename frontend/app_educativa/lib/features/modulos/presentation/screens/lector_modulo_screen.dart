import 'package:flutter/material.dart';

import '../../../../shared/widgets/boton_grande.dart';
import '../../../../shared/widgets/mensaje_con_accion.dart';
import '../../domain/modulo.dart';
import '../../domain/recurso_local.dart';
import '../controllers/modulos_scope.dart';
import '../widgets/visor_pdf.dart';

typedef ConstructorVisor = Widget Function(RecursoLocal recurso);

class LectorModuloScreen extends StatefulWidget {
  final Modulo modulo;

  // Reemplazable en pruebas porque pdfx usa código nativo.
  final ConstructorVisor construirVisor;

  const LectorModuloScreen({
    super.key,
    required this.modulo,
    this.construirVisor = _construirVisorPdf,
  });

  static Widget _construirVisorPdf(RecursoLocal recurso) {
    return VisorPdf(ruta: recurso.ruta);
  }

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

  void _abrirRecurso(RecursoLocal recurso) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => Scaffold(
          appBar: AppBar(title: Text(recurso.titulo)),
          body: widget.construirVisor(recurso),
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

    final recursos = snapshot.data;

    if (snapshot.hasError || recursos == null || recursos.isEmpty) {
      return _construirError();
    }

    if (recursos.length == 1) {
      return widget.construirVisor(recursos.single);
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
