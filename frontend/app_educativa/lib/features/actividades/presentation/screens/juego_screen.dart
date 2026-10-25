import 'dart:math';

import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/voz/lector_voz.dart';
import '../../../../shared/widgets/boton_grande.dart';
import '../../../progreso/domain/resultado_actividad.dart';
import '../../../progreso/presentation/progreso_scope.dart';
import '../../domain/actividad.dart';
import '../../domain/ruta_aprendizaje.dart';
import '../juegos/juego_arma.dart';
import '../juegos/juego_arrastra.dart';
import '../juegos/juego_atrapa.dart';
import '../juegos/juego_clasifica.dart';
import '../juegos/juego_completa.dart';
import '../juegos/juego_elige.dart';
import '../juegos/juego_memoria.dart';
import '../juegos/juego_ordena.dart';
import '../juegos/juego_parejas.dart';
import '../juegos/juego_sopa.dart';
import '../widgets/boton_pista.dart';
import '../widgets/confeti.dart';
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

  const JuegoScreen({
    super.key,
    required this.moduloId,
    required this.plan,
    required this.actividad,
    this.random,
    this.pausa = pausaPorDefecto,
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
  bool? _ultimaFueAcierto;
  String _mensaje = '';
  int? _puntaje;

  Actividad get _actividad => widget.actividad;

  LectorVoz get _voz => VozScope.de(context);

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    // En "Elige" el propio juego lee cada pregunta.
    if (_puntaje == null && _ultimaFueAcierto == null &&
        _actividad is! ActividadElige) {
      _voz.hablar(_actividad.instruccion);
    }
  }

  void _alResponder(bool esAcierto) {
    final opciones = esAcierto ? _mensajesAcierto : _mensajesError;
    final mensaje = opciones[_random.nextInt(opciones.length)];

    setState(() {
      if (!esAcierto) {
        _errores++;
      }
      _ultimaFueAcierto = esAcierto;
      _mensaje = mensaje;
    });
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

    // HU07, criterio 3: registra el resultado y actualiza el progreso.
    await ProgresoScope.leer(context)?.registrarResultado(
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

    setState(() => _puntaje = puntaje);
    _voz.hablar(_mensajeFinal(estrellasPorPuntaje(puntaje)));
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
    };
  }

  @override
  Widget build(BuildContext context) {
    final puntaje = _puntaje;

    return Scaffold(
      appBar: AppBar(title: Text(_actividad.titulo)),
      body: SafeArea(
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
                    ),
                  ),
                  const Positioned.fill(child: Confeti()),
                ],
              ),
      ),
    );
  }

  Widget _construirPartida() {
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
                  onEscuchar: () => _voz.hablar(_actividad.instruccion),
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

class _Instruccion extends StatelessWidget {
  final String texto;
  final VoidCallback onEscuchar;

  const _Instruccion({required this.texto, required this.onEscuchar});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.azulSuave,
        borderRadius: BorderRadius.circular(AppTheme.radio),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              texto,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppTheme.azul,
              ),
            ),
          ),
          const SizedBox(width: 8),
          IconButton.filled(
            tooltip: 'Escuchar la instrucción',
            iconSize: 30,
            onPressed: onEscuchar,
            icon: const Icon(Icons.volume_up_rounded),
          ),
        ],
      ),
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

  const _VistaResultado({
    required this.moduloId,
    required this.plan,
    required this.actividad,
    required this.estrellas,
    required this.mensaje,
    required this.random,
    required this.pausa,
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
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final siguiente = _siguiente();
    final nivelNuevo = siguiente?.$2;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            switch (estrellas) { 3 => '🏆', 2 => '🎉', _ => '👏' },
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 80),
          ),
          const SizedBox(height: 8),
          Center(child: FilaEstrellas(estrellas: estrellas, tamano: 60)),
          const SizedBox(height: 16),
          Text(
            mensaje,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800),
          ),
          if (nivelNuevo != null) ...[
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.verdeSuave,
                borderRadius: BorderRadius.circular(AppTheme.radio),
                border: Border.all(color: AppTheme.verde, width: 2),
              ),
              child: Text(
                '🔓 ¡Abriste el nivel ${nivelNuevo.numero}: '
                '${nivelNuevo.titulo}!',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.verde,
                ),
              ),
            ),
          ],
          if (siguiente == null && actividad.id == plan.actividades.last.id) ...[
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
