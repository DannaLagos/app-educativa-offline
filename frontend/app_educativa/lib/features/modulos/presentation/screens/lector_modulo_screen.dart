import 'package:flutter/material.dart';

import '../../../../shared/widgets/app_button.dart';
import '../../domain/modulo.dart';
import '../../domain/recurso_local.dart';
import '../controllers/modulos_scope.dart';
import '../widgets/visor_pdf.dart';

/// Abre un módulo descargado. Todo se lee del dispositivo, así que funciona
/// igual con o sin internet, y perder la conexión no lo interrumpe.
class LectorModuloScreen extends StatefulWidget {
  final Modulo modulo;

  /// Permite reemplazar el visor en las pruebas (pdfx usa código nativo).
  final Widget Function(RecursoLocal recurso) construirVisor;

  const LectorModuloScreen({
    super.key,
    required this.modulo,
    this.construirVisor = _visorPdf,
  });

  static Widget _visorPdf(RecursoLocal recurso) => VisorPdf(ruta: recurso.ruta);

  @override
  State<LectorModuloScreen> createState() => _LectorModuloScreenState();
}

class _LectorModuloScreenState extends State<LectorModuloScreen> {
  Future<List<RecursoLocal>>? _recursos;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _recursos ??= ModulosScope.of(context).recursosDe(widget.modulo);
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
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          final recursos = snapshot.data;

          if (snapshot.hasError || recursos == null || recursos.isEmpty) {
            return _MensajeError(
              onVolver: () => Navigator.of(context).pop(),
            );
          }

          // Con un solo documento se abre directamente.
          if (recursos.length == 1) {
            return widget.construirVisor(recursos.single);
          }

          return ListView(
            padding: const EdgeInsets.all(24),
            children: [
              const Text(
                'Elige qué quieres ver:',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
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
        },
      ),
    );
  }
}

class _MensajeError extends StatelessWidget {
  final VoidCallback onVolver;

  const _MensajeError({required this.onVolver});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.report_problem_rounded,
              size: 72,
            ),
            const SizedBox(height: 16),
            const Text(
              'Faltan archivos de este módulo. Descárgalo de nuevo.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 20),
            ),
            const SizedBox(height: 24),
            BotonGrande(
              texto: 'Volver',
              icono: Icons.arrow_back_rounded,
              onPressed: onVolver,
            ),
          ],
        ),
      ),
    );
  }
}
