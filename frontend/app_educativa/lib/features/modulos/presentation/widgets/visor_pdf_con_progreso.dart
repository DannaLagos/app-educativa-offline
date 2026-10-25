import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;

import '../../../progreso/presentation/progreso_controller.dart';
import '../../../progreso/presentation/progreso_scope.dart';
import '../../domain/recurso_local.dart';
import 'visor_pdf.dart';

/// Abre un PDF del módulo en la página donde el estudiante lo dejó y guarda
/// cada cambio de página en el dispositivo (HU06). Si no hay ProgresoScope
/// (por ejemplo, en pruebas), funciona como un visor normal.
class VisorPdfConProgreso extends StatefulWidget {
  final String moduloId;
  final RecursoLocal recurso;

  const VisorPdfConProgreso({
    super.key,
    required this.moduloId,
    required this.recurso,
  });

  @override
  State<VisorPdfConProgreso> createState() => _VisorPdfConProgresoState();
}

class _VisorPdfConProgresoState extends State<VisorPdfConProgreso> {
  ProgresoController? _progreso;
  Future<int?>? _paginaInicial;

  /// Nombre del archivo: identifica el documento dentro del módulo.
  String get _recurso => p.basename(widget.recurso.ruta);

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    if (_paginaInicial == null) {
      _progreso = ProgresoScope.leer(context);
      _paginaInicial =
          _progreso?.paginaParaContinuar(widget.moduloId, _recurso) ??
              Future.value(null);
    }
  }

  void _guardarPagina(int pagina, int totalPaginas) {
    _progreso?.guardarPagina(
      moduloId: widget.moduloId,
      recurso: _recurso,
      pagina: pagina,
      totalPaginas: totalPaginas,
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<int?>(
      future: _paginaInicial,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Center(child: CircularProgressIndicator());
        }

        return VisorPdf(
          ruta: widget.recurso.ruta,
          paginaInicial: snapshot.data ?? 1,
          onPaginaCambiada: _guardarPagina,
        );
      },
    );
  }
}
