import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../shared/widgets/boton_escuchar.dart';
import '../../../../shared/widgets/dibujo.dart';
import '../../../actividades/domain/ruta_aprendizaje.dart';
import '../../../progreso/domain/progreso_modulo.dart';

/// "Tu avance" como marcador de juego (HU08): una ficha con los juegos
/// terminados y sus estrellas, y otra con un anillo que se llena según la
/// página leída. Cada ficha se toca para seguir jugando o leyendo.
class MarcadorAvance extends StatelessWidget {
  final ProgresoModulo progreso;

  /// El documento leído por última vez, o null si no ha leído.
  final ProgresoLectura? ultimaLectura;
  final VoidCallback onJugar;
  final VoidCallback onLeer;

  const MarcadorAvance({
    super.key,
    required this.progreso,
    required this.ultimaLectura,
    required this.onJugar,
    required this.onLeer,
  });

  int get _estrellas => progreso.actividades
      .where((actividad) => actividad.completada)
      .fold(0, (total, a) => total + estrellasPorPuntaje(a.puntaje));

  String get _resumen {
    final juegos = progreso.actividadesCompletadas;
    final lectura = ultimaLectura;
    final partes = [
      juegos == 1 ? 'Terminaste 1 juego' : 'Terminaste $juegos juegos',
      if (lectura != null)
        'vas en la página ${lectura.ultimaPagina} de ${lectura.totalPaginas}',
    ];

    return '¡Mira cuánto has avanzado! ${partes.join(' y ')}.';
  }

  @override
  Widget build(BuildContext context) {
    final juegos = progreso.actividadesCompletadas;
    final lectura = ultimaLectura;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            const Expanded(
              child: Text(
                'Tu avance',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
              ),
            ),
            BotonEscuchar(texto: _resumen),
          ],
        ),
        const SizedBox(height: 12),
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: _Ficha(
                  key: const ValueKey('avance-juegos'),
                  color: AppTheme.naranja,
                  etiqueta: '$juegos ${juegos == 1 ? 'juego terminado' : 'juegos '
                      'terminados'}, $_estrellas estrellas. Toca para jugar.',
                  onTap: onJugar,
                  child:
                      _ContenidoJuegos(juegos: juegos, estrellas: _estrellas),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _Ficha(
                  key: const ValueKey('avance-lectura'),
                  color: AppTheme.verde,
                  etiqueta: lectura == null
                      ? 'Todavía no has leído. Toca para leer.'
                      : 'Vas en la página ${lectura.ultimaPagina} de '
                          '${lectura.totalPaginas}. Toca para seguir leyendo.',
                  onTap: onLeer,
                  child: _ContenidoLectura(lectura: lectura),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Ficha grande de color que rebota al tocarla.
class _Ficha extends StatefulWidget {
  static const double _relieve = 6;

  final Color color;
  final String etiqueta;
  final VoidCallback onTap;
  final Widget child;

  const _Ficha({
    super.key,
    required this.color,
    required this.etiqueta,
    required this.onTap,
    required this.child,
  });

  @override
  State<_Ficha> createState() => _FichaState();
}

class _FichaState extends State<_Ficha> {
  bool _presionada = false;

  @override
  Widget build(BuildContext context) {
    final radio = BorderRadius.circular(24);

    return Semantics(
      button: true,
      label: widget.etiqueta,
      excludeSemantics: true,
      child: AnimatedScale(
        scale: _presionada ? 0.94 : 1,
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeOutBack,
        child: Container(
          margin: const EdgeInsets.only(bottom: _Ficha._relieve),
          decoration: BoxDecoration(
            color: widget.color,
            borderRadius: radio,
            boxShadow: [
              BoxShadow(
                color: Color.lerp(widget.color, Colors.black, 0.35)!,
                offset: const Offset(0, _Ficha._relieve),
              ),
            ],
          ),
          child: Material(
            type: MaterialType.transparency,
            child: InkWell(
              borderRadius: radio,
              onTap: widget.onTap,
              onHighlightChanged: (valor) =>
                  setState(() => _presionada = valor),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(10, 14, 10, 12),
                child: widget.child,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ContenidoJuegos extends StatelessWidget {
  final int juegos;
  final int estrellas;

  const _ContenidoJuegos({required this.juegos, required this.estrellas});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 76,
          height: 76,
          alignment: Alignment.center,
          decoration: const BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
          ),
          child: const Dibujo('🏆', tamano: 50),
        ),
        const SizedBox(height: 6),
        // El número cuenta desde 0 al aparecer, como en un marcador.
        _NumeroQueSube(valor: juegos),
        Text(
          juegos == 1 ? 'juego terminado' : 'juegos terminados',
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w800,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
          decoration: BoxDecoration(
            color: AppTheme.amarillo,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.star_rounded, size: 22, color: Colors.white),
              const SizedBox(width: 2),
              Text(
                '$estrellas',
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF5C3A00),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ContenidoLectura extends StatelessWidget {
  static const double _tamanoAnillo = 76;

  final ProgresoLectura? lectura;

  const _ContenidoLectura({required this.lectura});

  @override
  Widget build(BuildContext context) {
    final datos = lectura;
    final avance = datos == null || datos.totalPaginas == 0
        ? 0.0
        : datos.ultimaPagina / datos.totalPaginas;
    final sinAnimar = MediaQuery.maybeDisableAnimationsOf(context) ?? false;

    return Column(
      children: [
        SizedBox.square(
          dimension: _tamanoAnillo,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Container(
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
              ),
              // El anillo se llena al aparecer.
              TweenAnimationBuilder<double>(
                tween: Tween(begin: sinAnimar ? avance : 0, end: avance),
                duration: const Duration(milliseconds: 900),
                curve: Curves.easeOutCubic,
                builder: (context, valor, _) => SizedBox.square(
                  dimension: _tamanoAnillo - 6,
                  child: CircularProgressIndicator(
                    value: valor,
                    strokeWidth: 8,
                    strokeCap: StrokeCap.round,
                    color: AppTheme.amarillo,
                    backgroundColor: AppTheme.verdeSuave,
                  ),
                ),
              ),
              const Dibujo('📖', tamano: 36),
            ],
          ),
        ),
        const SizedBox(height: 6),
        Text(
          datos == null ? '¡A leer!' : 'Página ${datos.ultimaPagina}',
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 24,
            height: 1.1,
            fontWeight: FontWeight.w800,
            color: Colors.white,
          ),
        ),
        Text(
          datos == null ? 'la cartilla' : 'de ${datos.totalPaginas}',
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w800,
            color: Colors.white,
          ),
        ),
      ],
    );
  }
}

/// Número grande que cuenta desde 0 hasta [valor] al aparecer.
class _NumeroQueSube extends StatelessWidget {
  final int valor;

  const _NumeroQueSube({required this.valor});

  @override
  Widget build(BuildContext context) {
    final sinAnimar = MediaQuery.maybeDisableAnimationsOf(context) ?? false;

    return TweenAnimationBuilder<double>(
      tween:
          Tween(begin: sinAnimar ? valor.toDouble() : 0, end: valor.toDouble()),
      duration: const Duration(milliseconds: 900),
      curve: Curves.easeOutCubic,
      builder: (context, actual, _) => Text(
        '${actual.round()}',
        style: const TextStyle(
          fontSize: 34,
          height: 1.1,
          fontWeight: FontWeight.w800,
          color: Colors.white,
        ),
      ),
    );
  }
}
