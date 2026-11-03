import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:pdfx/pdfx.dart';

import '../../../../core/theme/app_theme.dart';

/// Muestra todas las páginas de la cartilla en miniatura para saltar a una
/// (por ejemplo, cuando la docente dice "vayan a la página 9"). Devuelve la
/// página elegida, o null si se cierra.
Future<int?> mostrarMiniaturas(
  BuildContext context, {
  required String ruta,
  required int totalPaginas,
  required int paginaActual,
}) {
  return showModalBottomSheet<int>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    backgroundColor: AppTheme.fondo,
    builder: (context) => _HojaMiniaturas(
      ruta: ruta,
      totalPaginas: totalPaginas,
      paginaActual: paginaActual,
    ),
  );
}

class _HojaMiniaturas extends StatefulWidget {
  final String ruta;
  final int totalPaginas;
  final int paginaActual;

  const _HojaMiniaturas({
    required this.ruta,
    required this.totalPaginas,
    required this.paginaActual,
  });

  @override
  State<_HojaMiniaturas> createState() => _HojaMiniaturasState();
}

class _HojaMiniaturasState extends State<_HojaMiniaturas> {
  late final _RenderizadorMiniaturas _renderizador =
      _RenderizadorMiniaturas(widget.ruta);

  @override
  void dispose() {
    _renderizador.cerrar();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final alto = MediaQuery.sizeOf(context).height * 0.75;

    return SizedBox(
      height: alto,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(20, 0, 20, 12),
            child: Text(
              'Toca la página que quieres ver',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
            ),
          ),
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
              gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                maxCrossAxisExtent: 170,
                mainAxisSpacing: 14,
                crossAxisSpacing: 14,
                childAspectRatio: 1.05,
              ),
              itemCount: widget.totalPaginas,
              itemBuilder: (context, indice) {
                final pagina = indice + 1;

                return _Miniatura(
                  key: ValueKey('miniatura-$pagina'),
                  pagina: pagina,
                  esActual: pagina == widget.paginaActual,
                  imagen: _renderizador.miniatura(pagina),
                  onTap: () => Navigator.of(context).pop(pagina),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _Miniatura extends StatelessWidget {
  final int pagina;
  final bool esActual;
  final Future<Uint8List?> imagen;
  final VoidCallback onTap;

  const _Miniatura({
    super.key,
    required this.pagina,
    required this.esActual,
    required this.imagen,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = esActual ? AppTheme.naranja : AppTheme.borde;
    final radio = BorderRadius.circular(18);

    return Semantics(
      button: true,
      selected: esActual,
      label: 'Página $pagina',
      excludeSemantics: true,
      child: Material(
        color: AppTheme.superficie,
        shape: RoundedRectangleBorder(
          borderRadius: radio,
          side: BorderSide(color: color, width: esActual ? 4 : 2),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Column(
            children: [
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(6),
                  child: FutureBuilder<Uint8List?>(
                    future: imagen,
                    builder: (context, snapshot) {
                      final bytes = snapshot.data;

                      if (bytes == null) {
                        return const Center(
                          child: Icon(
                            Icons.description_rounded,
                            size: 40,
                            color: AppTheme.borde,
                          ),
                        );
                      }
                      return Image.memory(bytes, fit: BoxFit.contain);
                    },
                  ),
                ),
              ),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 4),
                color: esActual ? AppTheme.naranja : AppTheme.grisSuave,
                child: Text(
                  '$pagina',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    color: esActual ? Colors.white : AppTheme.texto,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Dibuja las miniaturas de una en una (Android no deja abrir dos páginas a
/// la vez) con su propia copia del documento, para no estorbar al visor.
class _RenderizadorMiniaturas {
  static const double _ancho = 260;

  final Future<PdfDocument> _documento;
  final Map<int, Future<Uint8List?>> _hechas = {};
  Future<void> _cola = Future.value();
  bool _cerrado = false;

  _RenderizadorMiniaturas(String ruta)
      : _documento = PdfDocument.openFile(ruta);

  Future<Uint8List?> miniatura(int pagina) {
    return _hechas[pagina] ??= _encolar(() => _dibujar(pagina));
  }

  Future<Uint8List?> _encolar(Future<Uint8List?> Function() tarea) {
    final resultado = _cola.then((_) => tarea());
    // Si una falla, las demás siguen.
    _cola = resultado.then((_) {}, onError: (_) {});
    return resultado;
  }

  Future<Uint8List?> _dibujar(int pagina) async {
    if (_cerrado) {
      return null;
    }

    try {
      final documento = await _documento;
      final hoja = await documento.getPage(pagina);

      try {
        final imagen = await hoja.render(
          width: _ancho,
          height: _ancho * hoja.height / hoja.width,
          format: PdfPageImageFormat.jpeg,
          backgroundColor: '#FFFFFF',
          quality: 70,
        );
        return imagen?.bytes;
      } finally {
        await hoja.close();
      }
    } catch (error) {
      debugPrint('No se pudo dibujar la miniatura $pagina: $error');
      return null;
    }
  }

  void cerrar() {
    _cerrado = true;
    _cola.then((_) async {
      try {
        await (await _documento).close();
      } catch (_) {
        // Si el documento no se pudo abrir, no hay nada que cerrar.
      }
    });
  }
}
