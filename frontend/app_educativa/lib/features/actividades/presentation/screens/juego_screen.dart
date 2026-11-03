import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/voz/lector_voz.dart';
import '../../../../shared/widgets/boton_escuchar.dart';
import '../../../../shared/widgets/boton_grande.dart';
import '../../../../shared/widgets/fondo_divertido.dart';
import '../../../mascota/domain/mascota.dart';
import '../../../mascota/presentation/mascota_scope.dart';
import '../../../mascota/presentation/widgets/ceremonia_evolucion.dart';
import '../../../mascota/presentation/widgets/mascota_animada.dart';
import '../../../progreso/domain/resultado_actividad.dart';
import '../../../progreso/presentation/progreso_scope.dart';
import '../../domain/actividad.dart';
import '../../domain/ruta_aprendizaje.dart';
import '../juegos/juego_arma.dart';
import '../juegos/juego_arrastra.dart';
import '../juegos/juego_atrapa.dart';
import '../juegos/juego_bien_o_mal.dart';
import '../juegos/juego_clasifica.dart';
import '../juegos/juego_completa.dart';
import '../juegos/juego_elige.dart';
import '../juegos/juego_escucha.dart';
import '../juegos/juego_memoria.dart';
import '../juegos/juego_ordena.dart';
import '../juegos/juego_parejas.dart';
import '../juegos/juego_sopa.dart';
import '../widgets/boton_pista.dart';
import '../widgets/confeti.dart';
import '../widgets/efectos.dart';
import '../widgets/tarjeta_elemento.dart';

/// Pantalla donde el niño juega una actividad (HU07). Muestra la
/// instrucción (con voz), el juego, la retroalimentación de cada respuesta
/// y, al final, las estrellas ganadas.
class JuegoScreen extends StatefulWidget {
  static const Duration pausaPorDefecto = Duration(milliseconds: 900);

  final String moduloId;
  final PlanActividades plan;
  final Actividad actividad;
  final Random? random;
  final Duration pausa;

  /// Para primero y segundo: la voz lee las opciones y los dibujos van en
  /// grande (ver [JuegoBase.lecturaAsistida]).
  final bool lecturaAsistida;

  const JuegoScreen({
    super.key,
    required this.moduloId,
    required this.plan,
    required this.actividad,
    this.random,
    this.pausa = pausaPorDefecto,
    this.lecturaAsistida = false,
  });

  @override
  State<JuegoScreen> createState() => _JuegoScreenState();
}

class _JuegoScreenState extends State<JuegoScreen> {
  static const List<String> _mensajesAcierto = [
    '¡Muy bien! 🎉',
    '¡Excelente! ⭐',
    '¡Lo lograste! 👏',
    '¡Súper! 🙌',
  ];
  static const List<String> _mensajesError = [
    '¡Casi! Intenta otra vez 💪',
    'Piénsalo otra vez 🤔',
    '¡Tú puedes! Prueba otra 💪',
  ];

  static final RegExp _soloEmojis = RegExp(r'[^\p{L}\p{P}\s]', unicode: true);

  late final Random _random = widget.random ?? Random();
  int _errores = 0;

  /// Cada acierto hace saltar a la mascota y lanza un estallido de estrellas.
  int _aciertos = 0;
  bool? _ultimaFueAcierto;
  String _mensaje = '';
  int? _puntaje;

  /// Si al terminar la mascota cambió de etapa, se celebra con la ceremonia
  /// antes de ver las estrellas.
  ({
    MascotaElegida mascota,
    EtapaMascota anterior,
    EtapaMascota nueva
  })? _evolucion;

  Actividad get _actividad => widget.actividad;

  LectorVoz get _voz => VozScope.de(context);

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    // En "Elige", "¿Bien o mal?" y "Escucha" el propio juego lee cada
    // pregunta.
    if (_puntaje == null &&
        _ultimaFueAcierto == null &&
        _actividad is! ActividadElige &&
        _actividad is! ActividadBienOMal &&
        _actividad is! ActividadEscucha) {
      _voz.hablar(_actividad.instruccion);
    }
  }

  void _alResponder(bool esAcierto) {
    final opciones = esAcierto ? _mensajesAcierto : _mensajesError;
    final mensaje = opciones[_random.nextInt(opciones.length)];

    setState(() {
      if (esAcierto) {
        _aciertos++;
      } else {
        _errores++;
      }
      _ultimaFueAcierto = esAcierto;
      _mensaje = mensaje;
    });
    // Una vibración corta: el niño "siente" que respondió.
    esAcierto ? HapticFeedback.mediumImpact() : HapticFeedback.lightImpact();
    // En "Arma" cada palabra es un acierto: la voz solo avisa los errores
    // para no interrumpir (al final de cada oración se lee la oración).
    if (!esAcierto || _actividad is! ActividadArma) {
      // Se quitan los emojis para que la voz no los lea.
      _voz.hablar(mensaje.replaceAll(_soloEmojis, '').trim());
    }
  }

  Future<void> _alCompletar() async {
    final puntaje = calcularPuntaje(
      aciertos: _actividad.totalAciertos,
      errores: _errores,
    );

    final progreso = ProgresoScope.leer(context);
    final mascota = MascotaScope.leer(context);
    final estrellasAntes = progreso?.estrellasTotales;

    // HU07, criterio 3: registra el resultado y actualiza el progreso.
    await progreso?.registrarResultado(
      ResultadoActividad(
        moduloId: widget.moduloId,
        actividadId: _actividad.id,
        completada: true,
        puntaje: puntaje,
      ),
    );

    if (!mounted) {
      return;
    }

    final evolucion = _buscarEvolucion(
      mascota,
      estrellasAntes,
      progreso?.estrellasTotales,
    );

    setState(() {
      _puntaje = puntaje;
      _evolucion = evolucion;
    });

    if (evolucion != null) {
      HapticFeedback.heavyImpact();
      _voz.hablar(
        '¡Wow! ${CeremoniaEvolucion.anuncio(evolucion.mascota, evolucion.nueva)}',
      );
    } else {
      _voz.hablar(_mensajeFinal(estrellasPorPuntaje(puntaje)));
    }
  }

  static ({MascotaElegida mascota, EtapaMascota anterior, EtapaMascota nueva})?
      _buscarEvolucion(MascotaElegida? mascota, int? antes, int? despues) {
    if (mascota == null || antes == null || despues == null) {
      return null;
    }

    final anterior = EtapaMascota.segunEstrellas(antes);
    final nueva = EtapaMascota.segunEstrellas(despues);

    return nueva.index > anterior.index
        ? (mascota: mascota, anterior: anterior, nueva: nueva)
        : null;
  }

  void _cerrarCeremonia() {
    setState(() => _evolucion = null);
    _voz.hablar(_mensajeFinal(estrellasPorPuntaje(_puntaje ?? 0)));
  }

  static String _mensajeFinal(int estrellas) => switch (estrellas) {
        3 => '¡Excelente! Ganaste tres estrellas.',
        2 => '¡Muy bien! Ganaste dos estrellas.',
        _ => '¡Lo lograste! Juega otra vez para ganar más estrellas.',
      };

  Widget _construirJuego() {
    return switch (_actividad) {
      final ActividadElige a => JuegoElige(
          actividad: a,
          onResponder: _alResponder,
          onCompletado: _alCompletar,
          random: _random,
          pausa: widget.pausa,
          moduloId: widget.moduloId,
          lecturaAsistida: widget.lecturaAsistida,
        ),
      final ActividadParejas a => JuegoParejas(
          actividad: a,
          onResponder: _alResponder,
          onCompletado: _alCompletar,
          random: _random,
          pausa: widget.pausa,
        ),
      final ActividadClasifica a => JuegoClasifica(
          actividad: a,
          onResponder: _alResponder,
          onCompletado: _alCompletar,
          random: _random,
          pausa: widget.pausa,
        ),
      final ActividadOrdena a => JuegoOrdena(
          actividad: a,
          onResponder: _alResponder,
          onCompletado: _alCompletar,
          random: _random,
          pausa: widget.pausa,
          lecturaAsistida: widget.lecturaAsistida,
        ),
      final ActividadMemoria a => JuegoMemoria(
          actividad: a,
          onResponder: _alResponder,
          onCompletado: _alCompletar,
          random: _random,
          pausa: widget.pausa,
        ),
      final ActividadArrastra a => JuegoArrastra(
          actividad: a,
          onResponder: _alResponder,
          onCompletado: _alCompletar,
          random: _random,
          pausa: widget.pausa,
        ),
      final ActividadAtrapa a => JuegoAtrapa(
          actividad: a,
          onResponder: _alResponder,
          onCompletado: _alCompletar,
          random: _random,
          pausa: widget.pausa,
        ),
      final ActividadCompleta a => JuegoCompleta(
          actividad: a,
          onResponder: _alResponder,
          onCompletado: _alCompletar,
          random: _random,
          pausa: widget.pausa,
          moduloId: widget.moduloId,
        ),
      final ActividadArma a => JuegoArma(
          actividad: a,
          onResponder: _alResponder,
          onCompletado: _alCompletar,
          random: _random,
          pausa: widget.pausa,
        ),
      final ActividadSopa a => JuegoSopa(
          actividad: a,
          onResponder: _alResponder,
          onCompletado: _alCompletar,
          random: _random,
          pausa: widget.pausa,
        ),
      final ActividadBienOMal a => JuegoBienOMal(
          actividad: a,
          onResponder: _alResponder,
          onCompletado: _alCompletar,
          random: _random,
          pausa: widget.pausa,
          moduloId: widget.moduloId,
          lecturaAsistida: widget.lecturaAsistida,
        ),
      final ActividadEscucha a => JuegoEscucha(
          actividad: a,
          onResponder: _alResponder,
          onCompletado: _alCompletar,
          random: _random,
          pausa: widget.pausa,
          moduloId: widget.moduloId,
          lecturaAsistida: widget.lecturaAsistida,
        ),
    };
  }

  @override
  Widget build(BuildContext context) {
    final puntaje = _puntaje;

    return Scaffold(
      appBar: AppBar(
        title: Text(_actividad.titulo),
        backgroundColor: Colors.transparent,
      ),
      extendBodyBehindAppBar: true,
      body: FondoDivertido(
        child: SafeArea(
          child: puntaje == null
              ? _construirPartida()
              : Stack(
                  children: [
                    Positioned.fill(
                      child: _VistaResultado(
                        moduloId: widget.moduloId,
                        plan: widget.plan,
                        actividad: _actividad,
                        estrellas: estrellasPorPuntaje(puntaje),
                        mensaje: _mensajeFinal(estrellasPorPuntaje(puntaje)),
                        random: widget.random,
                        pausa: widget.pausa,
                        lecturaAsistida: widget.lecturaAsistida,
                      ),
                    ),
                    const Positioned.fill(child: Confeti()),
                    if (_evolucion case final evolucion?)
                      Positioned.fill(
                        child: CeremoniaEvolucion(
                          mascota: evolucion.mascota,
                          etapaAnterior: evolucion.anterior,
                          etapaNueva: evolucion.nueva,
                          onTerminar: _cerrarCeremonia,
                        ),
                      ),
                  ],
                ),
        ),
      ),
    );
  }

  Widget _construirPartida() {
    return Stack(
      children: [
        Positioned.fill(child: _construirTablero()),
        // Estallido de estrellas con cada acierto, cerca del mensaje.
        if (_aciertos > 0 && _ultimaFueAcierto == true)
          Positioned(
            left: 0,
            right: 0,
            bottom: 20,
            child: Center(
              child: EstallidoEstrellas(key: ValueKey('estallido-$_aciertos')),
            ),
          ),
      ],
    );
  }

  Widget _construirTablero() {
    final ultimaFueAcierto = _ultimaFueAcierto;

    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _Instruccion(
                  texto: _actividad.instruccion,
                  saltosMascota: _aciertos,
                  // Tras un error la mascota pone cara de ánimo hasta el
                  // siguiente acierto.
                  animando: _ultimaFueAcierto == false,
                  onEscuchar: () =>
                      hablarOAvisar(context, _actividad.instruccion),
                ),
                if (_actividad.pista != null) ...[
                  const SizedBox(height: 10),
                  Align(
                    alignment: Alignment.centerRight,
                    child: BotonPista(
                      pista: _actividad.pista!,
                      moduloId: widget.moduloId,
                    ),
                  ),
                ],
                const SizedBox(height: 20),
                _construirJuego(),
              ],
            ),
          ),
        ),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 200),
          child: ultimaFueAcierto == null
              ? const SizedBox.shrink()
              : Padding(
                  key: ValueKey('$_mensaje-$_errores'),
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                  child: TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0.85, end: 1),
                    duration: const Duration(milliseconds: 250),
                    curve: Curves.elasticOut,
                    builder: (context, escala, hijo) =>
                        Transform.scale(scale: escala, child: hijo),
                    child: Retroalimentacion(
                      esAcierto: ultimaFueAcierto,
                      mensaje: _mensaje,
                    ),
                  ),
                ),
        ),
      ],
    );
  }
}

/// La mascota del niño "dice" la instrucción en una burbuja y salta con
/// cada acierto.
class _Instruccion extends StatelessWidget {
  final String texto;
  final int saltosMascota;
  final bool animando;
  final VoidCallback onEscuchar;

  const _Instruccion({
    required this.texto,
    required this.saltosMascota,
    required this.animando,
    required this.onEscuchar,
  });

  @override
  Widget build(BuildContext context) {
    final mascota = MascotaScope.de(context);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        if (mascota != null) ...[
          MascotaAnimada(
            especie: mascota.especie,
            etapa: EtapaMascota.segunEstrellas(
              ProgresoScope.leer(context)?.estrellasTotales ?? 0,
            ),
            tamano: 84,
            saltos: saltosMascota,
            expresion:
                animando ? ExpresionMascota.animo : ExpresionMascota.normal,
          ),
          const SizedBox(width: 4),
        ],
        Expanded(
          child: Container(
            padding: const EdgeInsets.fromLTRB(16, 12, 10, 12),
            decoration: BoxDecoration(
              color: AppTheme.superficie,
              borderRadius: BorderRadius.circular(AppTheme.radio),
              border: Border.all(color: AppTheme.morado, width: 3),
              boxShadow: const [
                BoxShadow(color: Color(0x336741D9), offset: Offset(0, 5)),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    texto,
                    style: const TextStyle(
                      fontSize: 19,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.texto,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton.filled(
                  tooltip: 'Escuchar la instrucción',
                  iconSize: 30,
                  style: IconButton.styleFrom(
                    backgroundColor: AppTheme.morado,
                    minimumSize: const Size.square(56),
                  ),
                  onPressed: onEscuchar,
                  icon: const Icon(Icons.volume_up_rounded),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _VistaResultado extends StatelessWidget {
  final String moduloId;
  final PlanActividades plan;
  final Actividad actividad;
  final int estrellas;
  final String mensaje;
  final Random? random;
  final Duration pausa;
  final bool lecturaAsistida;

  const _VistaResultado({
    required this.moduloId,
    required this.plan,
    required this.actividad,
    required this.estrellas,
    required this.mensaje,
    required this.random,
    required this.pausa,
    required this.lecturaAsistida,
  });

  /// La siguiente actividad del camino y si empieza un nivel nuevo.
  (Actividad, Nivel?)? _siguiente() {
    for (var n = 0; n < plan.niveles.length; n++) {
      final actividades = plan.niveles[n].actividades;

      for (var a = 0; a < actividades.length; a++) {
        if (actividades[a].id != actividad.id) {
          continue;
        }
        if (a + 1 < actividades.length) {
          return (actividades[a + 1], null);
        }
        if (n + 1 < plan.niveles.length &&
            plan.niveles[n + 1].actividades.isNotEmpty) {
          final nivel = plan.niveles[n + 1];
          return (nivel.actividades.first, nivel);
        }
        return null;
      }
    }

    return null;
  }

  void _jugar(BuildContext context, Actividad actividad) {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => JuegoScreen(
          moduloId: moduloId,
          plan: plan,
          actividad: actividad,
          random: random,
          pausa: pausa,
          lecturaAsistida: lecturaAsistida,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final siguiente = _siguiente();
    final mascota = MascotaScope.de(context);
    final nivelNuevo = siguiente?.$2;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (mascota == null)
            Text(
              switch (estrellas) { 3 => '🏆', 2 => '🎉', _ => '👏' },
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 80),
            )
          else
            Center(
              child: MascotaAnimada(
                especie: mascota.especie,
                etapa: EtapaMascota.segunEstrellas(
                  ProgresoScope.leer(context)?.estrellasTotales ?? 0,
                ),
                tamano: 150,
              ),
            ),
          const SizedBox(height: 8),
          Center(child: _EstrellasGanadas(estrellas: estrellas)),
          const SizedBox(height: 16),
          Text(
            mensaje,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w800),
          ),
          if (mascota != null && estrellas > 0) ...[
            const SizedBox(height: 12),
            Center(
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                decoration: BoxDecoration(
                  color: AppTheme.amarilloSuave,
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(color: AppTheme.amarillo, width: 3),
                ),
                child: Text(
                  '+$estrellas ⭐ para ${mascota.nombre}',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.ambar,
                  ),
                ),
              ),
            ),
          ],
          if (nivelNuevo != null) ...[
            const SizedBox(height: 20),
            Aparecer(
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.verde,
                  borderRadius: BorderRadius.circular(AppTheme.radio),
                  boxShadow: [
                    BoxShadow(
                      color: relieve(AppTheme.verde),
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: Text(
                  '🔓 ¡Abriste el nivel ${nivelNuevo.numero}: '
                  '${nivelNuevo.titulo}!',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 21,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
          if (siguiente == null &&
              actividad.id == plan.actividades.last.id) ...[
            const SizedBox(height: 20),
            const Text(
              '🌟 ¡Terminaste todos los niveles de este módulo!',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
            ),
          ],
          const SizedBox(height: 28),
          if (siguiente != null) ...[
            BotonGrande(
              texto: 'Siguiente juego',
              icono: Icons.arrow_forward_rounded,
              color: AppTheme.verde,
              onPressed: () => _jugar(context, siguiente.$1),
            ),
            const SizedBox(height: 12),
          ],
          BotonGrande(
            texto: 'Jugar otra vez',
            icono: Icons.replay_rounded,
            tieneContorno: true,
            onPressed: () => _jugar(context, actividad),
          ),
          const SizedBox(height: 12),
          BotonGrande(
            texto: 'Volver a los niveles',
            icono: Icons.map_rounded,
            tieneContorno: true,
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }
}

/// Las estrellas ganadas aparecen una por una, con un saltito.
class _EstrellasGanadas extends StatelessWidget {
  static const double _tamano = 68;

  final int estrellas;

  const _EstrellasGanadas({required this.estrellas});

  @override
  Widget build(BuildContext context) {
    final sinAnimar = MediaQuery.maybeDisableAnimationsOf(context) ?? false;

    return Semantics(
      label: '$estrellas de 3 estrellas',
      excludeSemantics: true,
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: sinAnimar ? 1 : 0, end: 1),
        duration: const Duration(milliseconds: 1400),
        builder: (context, t, _) => Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (var i = 0; i < 3; i++)
              Transform.scale(
                // Cada estrella empieza un poco después que la anterior.
                scale: Curves.elasticOut.transform(
                  ((t - i * 0.22) / 0.5).clamp(0.0, 1.0),
                ),
                child: Padding(
                  // La del medio, más alta: como un podio.
                  padding: EdgeInsets.only(bottom: i == 1 ? 18 : 0),
                  child: Icon(
                    Icons.star_rounded,
                    size: i == 1 ? _tamano + 14 : _tamano,
                    color: i < estrellas
                        ? const Color(0xFFFFC93C)
                        : AppTheme.borde,
                    shadows: i < estrellas
                        ? const [
                            Shadow(
                                color: Color(0x80C2410C), offset: Offset(0, 4)),
                          ]
                        : null,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
