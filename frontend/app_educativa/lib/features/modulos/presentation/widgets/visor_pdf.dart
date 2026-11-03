import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pdfx/pdfx.dart';

import '../../../../core/theme/app_theme.dart';
import 'miniaturas_pdf.dart';

typedef AlCambiarPagina = void Function(int pagina, int totalPaginas);

/// Visor de la cartilla pensado para niños: se agranda con dos dedos o con
/// doble toque, se pasa de página tocando los bordes (como un libro), se
/// puede girar la pantalla para ver las páginas horizontales en grande y
/// tiene una tira de miniaturas para saltar a cualquier página.
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
  static const _duracionAnimacion = Duration(milliseconds: 300);
  static const _curvaAnimacion = Curves.easeOut;

  /// Cuánto se agranda con un doble toque.
  static const double _zoomDobleToque = 2.5;

  /// Ancho de cada borde que pasa de página al tocarlo (fracción).
  static const double _anchoBorde = 0.25;

  late final PdfControllerPinch _controller = PdfControllerPinch(
    document: PdfDocument.openFile(widget.ruta),
    initialPage: widget.paginaInicial < 1 ? 1 : widget.paginaInicial,
  );

  int _totalPaginas = 0;
  bool _horizontal = false;
  Offset _puntoDobleToque = Offset.zero;
  Size? _tamanoAnterior;

  @override
  void dispose() {
    // Al salir, la app vuelve a girar como siempre.
    SystemChrome.setPreferredOrientations(const []);
    _controller.dispose();
    super.dispose();
  }

  int get _pagina => _controller.pageListenable.value;

  /// true si el niño agrandó la página: entonces tocar los bordes no pasa de
  /// página (estaría moviéndose por el dibujo).
  bool get _estaAgrandada {
    final ajuste = _controller.calculatePageFitMatrix(pageNumber: _pagina);

    if (ajuste == null) {
      return false;
    }
    return _controller.zoomRatio > ajuste.row0[0] * 1.1;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: LayoutBuilder(
            builder: (context, limites) {
              _ajustarSiCambioTamano(limites.biggest);

              return Stack(
                children: [
                  Positioned.fill(child: _construirDocumento(limites.biggest)),
                  if (_totalPaginas > 0) ...[
                    const _PistaBorde(alineacion: Alignment.centerLeft),
                    const _PistaBorde(alineacion: Alignment.centerRight),
                    Positioned(
                      top: 12,
                      right: 12,
                      child: Column(
                        children: [
                          _BotonFlotante(
                            tooltip: _horizontal
                                ? 'Volver a vertical'
                                : 'Girar pantalla',
                            icono: Icons.screen_rotation_rounded,
                            color: AppTheme.morado,
                            onPressed: _girarPantalla,
                          ),
                          const SizedBox(height: 10),
                          _BotonFlotante(
                            tooltip: 'Ver todas las páginas',
                            icono: Icons.grid_view_rounded,
                            color: AppTheme.naranja,
                            onPressed: _verPaginas,
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              );
            },
          ),
        ),
        if (_totalPaginas > 0)
          ValueListenableBuilder<int>(
            valueListenable: _controller.pageListenable,
            builder: (context, pagina, _) => _construirBarra(pagina),
          ),
      ],
    );
  }

  Widget _construirDocumento(Size tamano) {
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTapUp: (detalles) => _tocarBorde(detalles.localPosition, tamano),
      onDoubleTapDown: (detalles) => _puntoDobleToque = detalles.localPosition,
      onDoubleTap: _alternarZoom,
      child: PdfViewPinch(
        controller: _controller,
        onDocumentLoaded: _alCargarDocumento,
        onPageChanged: _alCambiarPagina,
        // Fondo crema, como una mesa: la página se ve como una hoja.
        backgroundDecoration: const BoxDecoration(color: AppTheme.fondo),
        builders: PdfViewPinchBuilders<DefaultBuilderOptions>(
          options: const DefaultBuilderOptions(),
          documentLoaderBuilder: (_) => const _Cargando(),
          pageLoaderBuilder: (_) => const _Cargando(),
          errorBuilder: (_, __) => const _ErrorDocumento(),
        ),
      ),
    );
  }

  /// Al girar la pantalla cambia el tamaño: se vuelve a encuadrar la página
  /// donde iba.
  void _ajustarSiCambioTamano(Size tamano) {
    final anterior = _tamanoAnterior;
    _tamanoAnterior = tamano;

    if (anterior == null || anterior == tamano || _totalPaginas == 0) {
      return;
    }

    final pagina = _pagina;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _controller.jumpToPage(pagina);
      }
    });
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

  /// Como en un libro: tocar el borde derecho pasa a la siguiente página y
  /// el izquierdo vuelve a la anterior.
  void _tocarBorde(Offset punto, Size tamano) {
    if (_totalPaginas == 0 || _estaAgrandada) {
      return;
    }

    if (punto.dx > tamano.width * (1 - _anchoBorde)) {
      _irAPaginaSiguiente();
    } else if (punto.dx < tamano.width * _anchoBorde) {
      _irAPaginaAnterior();
    }
  }

  /// Doble toque: agranda donde tocó; otro doble toque vuelve a la página
  /// completa.
  void _alternarZoom() {
    if (_totalPaginas == 0) {
      return;
    }

    if (_estaAgrandada) {
      _controller.animateToPage(pageNumber: _pagina);
      return;
    }

    final punto = _puntoDobleToque;
    // Agranda alrededor del punto tocado: llevar el punto al origen,
    // escalar y devolverlo.
    final destino = Matrix4.identity()
      ..translateByDouble(punto.dx, punto.dy, 0, 1)
      ..scaleByDouble(_zoomDobleToque, _zoomDobleToque, 1, 1)
      ..translateByDouble(-punto.dx, -punto.dy, 0, 1)
      ..multiply(_controller.value);

    _controller.goTo(destination: destino, duration: _duracionAnimacion);
  }

  /// Las páginas de la cartilla son horizontales: girar la pantalla las
  /// muestra mucho más grandes.
  void _girarPantalla() {
    final horizontal = !_horizontal;

    SystemChrome.setPreferredOrientations(
      horizontal
          ? const [
              DeviceOrientation.landscapeLeft,
              DeviceOrientation.landscapeRight,
            ]
          : const [DeviceOrientation.portraitUp],
    );
    setState(() => _horizontal = horizontal);
  }

  Future<void> _verPaginas() async {
    final elegida = await mostrarMiniaturas(
      context,
      ruta: widget.ruta,
      totalPaginas: _totalPaginas,
      paginaActual: _pagina,
    );

    if (elegida != null && mounted) {
      _controller.animateToPage(
        pageNumber: elegida,
        duration: _duracionAnimacion,
        curve: _curvaAnimacion,
      );
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

/// Flechita translúcida en el borde: le recuerda al niño que puede tocar
/// ahí para pasar de página. No recibe toques.
class _PistaBorde extends StatelessWidget {
  final Alignment alineacion;

  const _PistaBorde({required this.alineacion});

  @override
  Widget build(BuildContext context) {
    final esDerecha = alineacion == Alignment.centerRight;

    return Positioned.fill(
      child: IgnorePointer(
        child: Align(
          alignment: alineacion,
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 6),
            width: 34,
            height: 64,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.7),
              borderRadius: BorderRadius.circular(17),
            ),
            child: Icon(
              esDerecha
                  ? Icons.chevron_right_rounded
                  : Icons.chevron_left_rounded,
              size: 32,
              color: AppTheme.textoSecundario,
            ),
          ),
        ),
      ),
    );
  }
}

/// Botón redondo que flota sobre la página.
class _BotonFlotante extends StatelessWidget {
  final String tooltip;
  final IconData icono;
  final Color color;
  final VoidCallback onPressed;

  const _BotonFlotante({
    required this.tooltip,
    required this.icono,
    required this.color,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return IconButton.filled(
      tooltip: tooltip,
      iconSize: 28,
      onPressed: onPressed,
      style: IconButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        minimumSize: const Size.square(54),
        elevation: 3,
      ),
      icon: Icon(icono),
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
    // Píldora flotante, como la barra de abajo del inicio.
    return SafeArea(
      top: false,
      child: Container(
        margin: const EdgeInsets.fromLTRB(14, 6, 14, 12),
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: AppTheme.superficie,
          borderRadius: BorderRadius.circular(40),
          border: Border.all(color: AppTheme.borde, width: 2),
          boxShadow: const [
            BoxShadow(color: AppTheme.borde, offset: Offset(0, 5)),
          ],
        ),
        child: Row(
          children: [
            _BotonPagina(
              tooltip: 'Página anterior',
              icono: Icons.arrow_back_rounded,
              color: AppTheme.naranja,
              onPressed: onAnterior,
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Página $pagina de $total',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 19,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.texto,
                      ),
                    ),
                    const SizedBox(height: 6),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: LinearProgressIndicator(
                        minHeight: 8,
                        value: total == 0 ? 0 : pagina / total,
                        color: AppTheme.verde,
                        backgroundColor: AppTheme.grisSuave,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            _BotonPagina(
              tooltip: 'Página siguiente',
              icono: Icons.arrow_forward_rounded,
              color: AppTheme.verde,
              onPressed: onSiguiente,
            ),
          ],
        ),
      ),
    );
  }
}

class _BotonPagina extends StatelessWidget {
  static const double _tamano = 60;

  final String tooltip;
  final IconData icono;
  final Color color;
  final VoidCallback? onPressed;

  const _BotonPagina({
    required this.tooltip,
    required this.icono,
    required this.color,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return IconButton.filled(
      tooltip: tooltip,
      iconSize: 36,
      onPressed: onPressed,
      style: IconButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        disabledBackgroundColor: AppTheme.grisSuave,
        disabledForegroundColor: AppTheme.borde,
        minimumSize: const Size.square(_tamano),
      ),
      icon: Icon(icono),
    );
  }
}
