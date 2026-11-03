import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../shared/widgets/boton_grande.dart';
import '../../../../shared/widgets/dibujo.dart';
import '../../../../shared/widgets/fondo_divertido.dart';
import '../../../../shared/widgets/latido.dart';
import '../../../../shared/widgets/mensaje_con_accion.dart';
import '../../../modulos/domain/modulo.dart';
import '../../../modulos/presentation/controllers/modulos_scope.dart';
import '../../../progreso/domain/progreso_modulo.dart';
import '../../../progreso/presentation/progreso_scope.dart';
import '../../data/actividades_local_datasource.dart';
import '../../domain/actividad.dart';
import '../../domain/ruta_aprendizaje.dart';
import '../widgets/efectos.dart';
import '../widgets/tarjeta_elemento.dart';
import 'juego_screen.dart';

typedef CargadorPlan = Future<PlanActividades?> Function(BuildContext context);

/// Camino de niveles de un módulo. Los niveles y juegos se abren en orden:
/// el niño avanza de lo fácil a lo difícil y de lo más cercano a lo más
/// lejano.
class MapaNivelesScreen extends StatefulWidget {
  final Modulo modulo;

  /// Reemplazable en pruebas. Por defecto lee `actividades.json` del módulo
  /// descargado.
  final CargadorPlan? cargarPlan;

  const MapaNivelesScreen({
    super.key,
    required this.modulo,
    this.cargarPlan,
  });

  @override
  State<MapaNivelesScreen> createState() => _MapaNivelesScreenState();
}

class _MapaNivelesScreenState extends State<MapaNivelesScreen> {
  Future<PlanActividades?>? _plan;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    if (_plan == null) {
      _plan = (widget.cargarPlan ?? _cargarDesdeModulo)(context);
      ProgresoScope.leer(context)?.cargarProgreso(widget.modulo.id);
    }
  }

  Future<PlanActividades?> _cargarDesdeModulo(BuildContext context) async {
    final recursos =
        await ModulosScope.of(context).obtenerRecursos(widget.modulo);

    return const ActividadesLocalDataSource().leer(recursos);
  }

  Future<void> _jugar(PlanActividades plan, PasoRuta paso) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => JuegoScreen(
          moduloId: widget.modulo.id,
          plan: plan,
          actividad: paso.actividad,
          lecturaAsistida: widget.modulo.necesitaLecturaAsistida,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Juegos: ${widget.modulo.nombre}'),
        backgroundColor: Colors.transparent,
      ),
      extendBodyBehindAppBar: true,
      body: FondoDivertido(
        child: SafeArea(
        child: FutureBuilder<PlanActividades?>(
          future: _plan,
          builder: (context, snapshot) {
            if (snapshot.connectionState != ConnectionState.done) {
              return const Center(child: CircularProgressIndicator());
            }

            final plan = snapshot.data;

            if (snapshot.hasError || plan == null || plan.niveles.isEmpty) {
              return _SinJuegos(hayError: snapshot.hasError);
            }

            final progreso =
                ProgresoScope.maybeOf(context)?.progresoDe(widget.modulo.id) ??
                    ProgresoModulo.vacio(widget.modulo.id);

            return _Camino(
              ruta: RutaAprendizaje.calcular(plan, progreso),
              onJugar: (paso) => _jugar(plan, paso),
            );
          },
        ),
        ),
      ),
    );
  }
}

class _SinJuegos extends StatelessWidget {
  final bool hayError;

  const _SinJuegos({required this.hayError});

  @override
  Widget build(BuildContext context) {
    return MensajeConAccion(
      icono: const Icon(Icons.extension_off_rounded),
      mensaje: hayError
          ? 'No pudimos abrir los juegos. Elimina el módulo y descárgalo '
              'de nuevo cuando tengas internet.'
          : 'Este módulo todavía no tiene juegos. Si hay una versión nueva, '
              'actualízalo cuando tengas internet.',
      accion: BotonGrande(
        texto: 'Volver',
        icono: Icons.arrow_back_rounded,
        onPressed: () => Navigator.of(context).pop(),
      ),
    );
  }
}

class _Camino extends StatelessWidget {
  final RutaAprendizaje ruta;
  final ValueChanged<PasoRuta> onJugar;

  const _Camino({required this.ruta, required this.onJugar});

  @override
  Widget build(BuildContext context) {
    final siguiente = ruta.siguiente;

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        _Resumen(ruta: ruta, onContinuar: onJugar),
        const SizedBox(height: 24),
        for (final nivel in ruta.niveles) ...[
          _SeccionNivel(
            nivel: nivel,
            siguienteId: siguiente?.actividad.id,
            onJugar: onJugar,
          ),
          const SizedBox(height: 28),
        ],
      ],
    );
  }
}

class _Resumen extends StatelessWidget {
  final RutaAprendizaje ruta;
  final ValueChanged<PasoRuta> onContinuar;

  const _Resumen({required this.ruta, required this.onContinuar});

  @override
  Widget build(BuildContext context) {
    final estrellas = ruta.niveles.fold(0, (total, n) => total + n.estrellas);
    final siguiente = ruta.siguiente;
    final terminado = siguiente == null;
    final yaEmpezo = ruta.actividadesCompletadas > 0;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppTheme.verde, AppTheme.turquesa],
        ),
        borderRadius: BorderRadius.circular(AppTheme.radio),
        boxShadow: [
          BoxShadow(color: relieve(AppTheme.verde), offset: const Offset(0, 6)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            terminado ? '🌟 ¡Terminaste todos los juegos!' : '🎮 ¡Vamos a jugar!',
            style: const TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w800,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '${ruta.actividadesCompletadas} de ${ruta.totalActividades} '
            'juegos terminados · ⭐ $estrellas',
            style: const TextStyle(
              fontSize: 18,
              color: Colors.white,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              minHeight: 14,
              color: AppTheme.amarillo,
              backgroundColor: const Color(0x55FFFFFF),
              value: ruta.totalActividades == 0
                  ? 0
                  : ruta.actividadesCompletadas / ruta.totalActividades,
            ),
          ),
          if (siguiente != null) ...[
            const SizedBox(height: 16),
            // HU08: abre directamente el juego donde iba.
            BotonGrande(
              texto: yaEmpezo ? 'Continuar donde ibas' : 'Empezar a jugar',
              icono: Icons.play_arrow_rounded,
              color: AppTheme.naranja,
              onPressed: () => onContinuar(siguiente),
            ),
            Text(
              'Nivel ${siguiente.nivel.numero}: ${siguiente.actividad.titulo}',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _SeccionNivel extends StatelessWidget {
  /// Dónde va cada juego, de izquierda (-1) a derecha (1): el camino hace
  /// zigzag como en un juego de mesa.
  static const List<double> _zigzag = [-0.6, 0.6, 0, -0.6, 0.6];

  final NivelEnRuta nivel;
  final String? siguienteId;
  final ValueChanged<PasoRuta> onJugar;

  const _SeccionNivel({
    required this.nivel,
    required this.siguienteId,
    required this.onJugar,
  });

  @override
  Widget build(BuildContext context) {
    final abierto = nivel.estaDesbloqueado;
    final datos = nivel.nivel;
    final color = abierto ? colorJuego(datos.numero - 1) : AppTheme.gris;
    final pasos = nivel.pasos;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Semantics(
          header: true,
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(AppTheme.radio),
              boxShadow: [
                BoxShadow(color: relieve(color), offset: const Offset(0, 5)),
              ],
            ),
            child: Row(
              children: [
                Container(
                  width: 64,
                  height: 64,
                  alignment: Alignment.center,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white,
                  ),
                  child: Dibujo(abierto ? datos.emoji : '🔒', tamano: 42),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Nivel ${datos.numero}',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        datos.titulo,
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
                if (nivel.estaCompletado)
                  const Text('🏆', style: TextStyle(fontSize: 32)),
              ],
            ),
          ),
        ),
        if (!abierto)
          const Padding(
            padding: EdgeInsets.only(top: 10),
            child: Text(
              'Termina el nivel anterior para abrirlo.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: AppTheme.textoSecundario,
              ),
            ),
          ),
        const SizedBox(height: 14),
        for (var i = 0; i < pasos.length; i++) ...[
          if (i > 0)
            _Conector(
              desde: _zigzag[(i - 1) % _zigzag.length],
              hasta: _zigzag[i % _zigzag.length],
              color: pasos[i - 1].estado == EstadoActividad.completada
                  ? color
                  : AppTheme.borde,
            ),
          Align(
            alignment: Alignment(_zigzag[i % _zigzag.length], 0),
            child: _NodoJuego(
              paso: pasos[i],
              color: color,
              esLaSiguiente: pasos[i].actividad.id == siguienteId,
              onTap: pasos[i].sePuedeJugar ? () => onJugar(pasos[i]) : null,
            ),
          ),
        ],
      ],
    );
  }
}

/// Caminito punteado entre dos juegos del zigzag.
class _Conector extends StatelessWidget {
  final double desde;
  final double hasta;
  final Color color;

  const _Conector({
    required this.desde,
    required this.hasta,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 30,
      width: double.infinity,
      child: CustomPaint(painter: _PintorConector(desde, hasta, color)),
    );
  }
}

class _PintorConector extends CustomPainter {
  final double desde;
  final double hasta;
  final Color color;

  _PintorConector(this.desde, this.hasta, this.color);

  /// Centro horizontal de un nodo alineado en [x] (de -1 a 1).
  double _centro(double x, double ancho) =>
      (ancho - _NodoJuego.ancho) * (x + 1) / 2 + _NodoJuego.ancho / 2;

  @override
  void paint(Canvas canvas, Size size) {
    final inicio = Offset(_centro(desde, size.width), 0);
    final fin = Offset(_centro(hasta, size.width), size.height);
    final punto = Paint()..color = color;

    // Puntos a lo largo de una curva suave.
    for (var i = 0; i <= 6; i++) {
      final t = i / 6;
      final x = inicio.dx + (fin.dx - inicio.dx) * Curves.easeInOut.transform(t);
      final y = inicio.dy + (fin.dy - inicio.dy) * t;
      canvas.drawCircle(Offset(x, y), 4, punto);
    }
  }

  @override
  bool shouldRepaint(_PintorConector anterior) =>
      anterior.desde != desde ||
      anterior.hasta != hasta ||
      anterior.color != color;
}

/// Un juego del camino: botón redondo grande con su dibujo. El siguiente
/// juego late para que el niño sepa dónde tocar.
class _NodoJuego extends StatelessWidget {
  static const double ancho = 190;
  static const double _tamano = 92;
  static const double _relieve = 6;

  final PasoRuta paso;
  final Color color;
  final bool esLaSiguiente;
  final VoidCallback? onTap;

  const _NodoJuego({
    required this.paso,
    required this.color,
    required this.esLaSiguiente,
    required this.onTap,
  });

  static String _emojiDe(TipoActividad tipo) => switch (tipo) {
        TipoActividad.elige => '👆',
        TipoActividad.parejas => '🔗',
        TipoActividad.clasifica => '🧺',
        TipoActividad.ordena => '🔢',
        TipoActividad.memoria => '🃏',
        TipoActividad.arrastra => '✋',
        TipoActividad.atrapa => '🎈',
        TipoActividad.completa => '✏️',
        TipoActividad.arma => '🧩',
        TipoActividad.sopa => '🔍',
        TipoActividad.bienOMal => '😄',
        TipoActividad.escucha => '👂',
      };

  @override
  Widget build(BuildContext context) {
    final bloqueada = paso.estado == EstadoActividad.bloqueada;
    final completada = paso.estado == EstadoActividad.completada;
    final fondo = bloqueada ? AppTheme.grisSuave : color;

    Widget circulo = Container(
      width: _tamano,
      height: _tamano,
      margin: const EdgeInsets.only(bottom: _relieve),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: fondo,
        shape: BoxShape.circle,
        border: Border.all(
          color: esLaSiguiente ? AppTheme.amarillo : Colors.white,
          width: esLaSiguiente ? 6 : 4,
        ),
        boxShadow: [
          BoxShadow(
            color: bloqueada ? AppTheme.borde : relieve(fondo),
            offset: const Offset(0, _relieve),
          ),
        ],
      ),
      child: Dibujo(
        bloqueada ? '🔒' : _emojiDe(paso.actividad.tipo),
        tamano: 54,
      ),
    );

    if (esLaSiguiente) {
      circulo = Latido(child: circulo);
    }

    return Semantics(
      button: !bloqueada,
      label: bloqueada
          ? '${paso.actividad.titulo}. Bloqueado.'
          : '${paso.actividad.titulo}. ${paso.estrellas} estrellas.',
      excludeSemantics: true,
      child: SizedBox(
        width: ancho,
        child: Material(
          type: MaterialType.transparency,
          child: InkWell(
            key: ValueKey('juego-${paso.actividad.id}'),
            borderRadius: BorderRadius.circular(AppTheme.radio),
            onTap: onTap,
            child: Opacity(
              opacity: bloqueada ? 0.6 : 1,
              child: Column(
                children: [
                  circulo,
                  const SizedBox(height: 4),
                  Text(
                    paso.actividad.titulo,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 4),
                  if (esLaSiguiente)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: AppTheme.naranja,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Text(
                        '¡Juega ahora!',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                    )
                  else if (completada)
                    FilaEstrellas(estrellas: paso.estrellas, tamano: 24),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
