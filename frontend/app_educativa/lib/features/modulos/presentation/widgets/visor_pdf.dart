import 'package:flutter/material.dart';
import 'package:pdfx/pdfx.dart';

import '../../../../core/theme/app_theme.dart';

typedef AlCambiarPagina = void Function(int pagina, int totalPaginas);

class VisorPdf extends StatefulWidget {
  final String ruta;

  /// Página con la que se abre el documento (empieza en 1).
  final int paginaInicial;

  /// Se llama al abrir el documento y cada vez que cambia la página, para
  /// guardar el progreso de lectura (HU06).
  final AlCambiarPagina? onPaginaCambiada;

  const VisorPdf({
    super.key,
    required this.ruta,
    this.paginaInicial = 1,
    this.onPaginaCambiada,
  });

  @override
  State<VisorPdf> createState() => _VisorPdfState();
}

class _VisorPdfState extends State<VisorPdf> {
  static const _duracionAnimacion = Duration(milliseconds: 250);
  static const _curvaAnimacion = Curves.easeOut;

  late final PdfController _controller = PdfController(
    document: PdfDocument.openFile(widget.ruta),
    initialPage: widget.paginaInicial < 1 ? 1 : widget.paginaInicial,
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
        Expanded(child: _construirDocumento()),
        if (_totalPaginas > 0)
          ValueListenableBuilder<int>(
            valueListenable: _controller.pageListenable,
            builder: (context, pagina, _) => _construirBarra(pagina),
          ),
      ],
    );
  }

  Widget _construirDocumento() {
    return PdfView(
      controller: _controller,
      onDocumentLoaded: _alCargarDocumento,
      onPageChanged: _alCambiarPagina,
      backgroundDecoration: const BoxDecoration(color: AppTheme.grisSuave),
      builders: PdfViewBuilders<DefaultBuilderOptions>(
        options: const DefaultBuilderOptions(),
        documentLoaderBuilder: (_) => const _Cargando(),
        pageLoaderBuilder: (_) => const _Cargando(),
        errorBuilder: (_, __) => const _ErrorDocumento(),
      ),
    );
  }

  void _alCargarDocumento(PdfDocument documento) {
    final total = documento.pagesCount;
    var pagina = widget.paginaInicial < 1 ? 1 : widget.paginaInicial;

    // Si el documento cambió y ahora tiene menos páginas, va a la última.
    if (pagina > total) {
      pagina = total;
      _controller.jumpToPage(total);
    }

    setState(() => _totalPaginas = total);
    widget.onPaginaCambiada?.call(pagina, total);
  }

  void _alCambiarPagina(int pagina) {
    if (_totalPaginas > 0) {
      widget.onPaginaCambiada?.call(pagina, _totalPaginas);
    }
  }

  Widget _construirBarra(int pagina) {
    final esPrimera = pagina <= 1;
    final esUltima = pagina >= _totalPaginas;

    return _BarraPaginas(
      pagina: pagina,
      total: _totalPaginas,
      onAnterior: esPrimera ? null : _irAPaginaAnterior,
      onSiguiente: esUltima ? null : _irAPaginaSiguiente,
    );
  }

  void _irAPaginaAnterior() {
    _controller.previousPage(
      duration: _duracionAnimacion,
      curve: _curvaAnimacion,
    );
  }

  void _irAPaginaSiguiente() {
    _controller.nextPage(
      duration: _duracionAnimacion,
      curve: _curvaAnimacion,
    );
  }
}

class _Cargando extends StatelessWidget {
  const _Cargando();

  @override
  Widget build(BuildContext context) {
    return const Center(child: CircularProgressIndicator());
  }
}

class _ErrorDocumento extends StatelessWidget {
  const _ErrorDocumento();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(24),
        child: Text(
          'No se pudo abrir el documento. '
          'Elimina el módulo y descárgalo de nuevo.',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 20),
        ),
      ),
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
            _BotonPagina(
              tooltip: 'Página anterior',
              icono: Icons.arrow_back_rounded,
              onPressed: onAnterior,
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
            _BotonPagina(
              tooltip: 'Página siguiente',
              icono: Icons.arrow_forward_rounded,
              onPressed: onSiguiente,
            ),
          ],
        ),
      ),
    );
  }
}

class _BotonPagina extends StatelessWidget {
  final String tooltip;
  final IconData icono;
  final VoidCallback? onPressed;

  const _BotonPagina({
    required this.tooltip,
    required this.icono,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return IconButton.filled(
      tooltip: tooltip,
      iconSize: 36,
      onPressed: onPressed,
      icon: Icon(icono),
    );
  }
}
