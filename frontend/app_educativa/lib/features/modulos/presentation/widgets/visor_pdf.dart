import 'package:flutter/material.dart';
import 'package:pdfx/pdfx.dart';

import '../../../../core/theme/app_theme.dart';

/// Muestra un PDF guardado en el dispositivo, página por página, con
/// botones grandes para avanzar y retroceder.
class VisorPdf extends StatefulWidget {
  final String ruta;

  const VisorPdf({
    super.key,
    required this.ruta,
  });

  @override
  State<VisorPdf> createState() => _VisorPdfState();
}

class _VisorPdfState extends State<VisorPdf> {
  static const _animacion = Duration(milliseconds: 250);

  late final PdfController _controller = PdfController(
    document: PdfDocument.openFile(widget.ruta),
  );

  int _totalPaginas = 0;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: PdfView(
            controller: _controller,
            onDocumentLoaded: (documento) {
              setState(() => _totalPaginas = documento.pagesCount);
            },
            backgroundDecoration: const BoxDecoration(
              color: AppTheme.grisSuave,
            ),
            builders: PdfViewBuilders<DefaultBuilderOptions>(
              options: const DefaultBuilderOptions(),
              documentLoaderBuilder: (_) => const Center(
                child: CircularProgressIndicator(),
              ),
              pageLoaderBuilder: (_) => const Center(
                child: CircularProgressIndicator(),
              ),
              errorBuilder: (_, __) => const Center(
                child: Padding(
                  padding: EdgeInsets.all(24),
                  child: Text(
                    'No se pudo abrir el documento. '
                    'Elimina el módulo y descárgalo de nuevo.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 20),
                  ),
                ),
              ),
            ),
          ),
        ),
        if (_totalPaginas > 0)
          ValueListenableBuilder<int>(
            valueListenable: _controller.pageListenable,
            builder: (context, pagina, _) => _BarraPaginas(
              pagina: pagina,
              total: _totalPaginas,
              onAnterior: pagina > 1
                  ? () => _controller.previousPage(
                        duration: _animacion,
                        curve: Curves.easeOut,
                      )
                  : null,
              onSiguiente: pagina < _totalPaginas
                  ? () => _controller.nextPage(
                        duration: _animacion,
                        curve: Curves.easeOut,
                      )
                  : null,
            ),
          ),
      ],
    );
  }
}

class _BarraPaginas extends StatelessWidget {
  final int pagina;
  final int total;
  final VoidCallback? onAnterior;
  final VoidCallback? onSiguiente;

  const _BarraPaginas({
    required this.pagina,
    required this.total,
    required this.onAnterior,
    required this.onSiguiente,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            IconButton.filled(
              tooltip: 'Página anterior',
              iconSize: 36,
              onPressed: onAnterior,
              icon: const Icon(Icons.arrow_back_rounded),
            ),
            Expanded(
              child: Text(
                'Página $pagina de $total',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.azul,
                ),
              ),
            ),
            IconButton.filled(
              tooltip: 'Página siguiente',
              iconSize: 36,
              onPressed: onSiguiente,
              icon: const Icon(Icons.arrow_forward_rounded),
            ),
          ],
        ),
      ),
    );
  }
}
