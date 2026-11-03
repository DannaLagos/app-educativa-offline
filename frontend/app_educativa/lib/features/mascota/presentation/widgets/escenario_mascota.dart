import 'dart:math';

import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../shared/widgets/boton_escuchar.dart';
import '../../domain/mascota.dart';
import 'mascota_animada.dart';

/// La mascota como protagonista del inicio: grande, sobre su plataforma,
/// con una burbuja que saluda, la barra de evolución y, abajo, la acción
/// principal ([accion], por ejemplo el botón "¡A jugar!"). Cuando la
/// mascota evoluciona, lo celebra hasta que el niño toca el aviso.
///
/// Al tocar la mascota dice frases (en voz alta); al tocar la silueta de su
/// próxima forma cuenta cuánto le falta. Si el niño lleva días sin jugar,
/// aparece dormida hasta que la toca.
class EscenarioMascota extends StatefulWidget {
  static const Color _fondo = AppTheme.morado;
  static const Color _fondoClaro = Color(0xFF8C6CF2);

  final MascotaElegida mascota;

  /// null mientras no se han leído las estrellas del dispositivo.
  final int? estrellas;

  /// Lo que "dice" la mascota en la burbuja.
  final String saludo;

  /// Botón 🔊 de la burbuja (opcional).
  final Widget? botonEscuchar;

  final Widget accion;

  /// La mascota duerme porque el niño lleva días sin jugar.
  final bool dormida;

  const EscenarioMascota({
    super.key,
    required this.mascota,
    required this.estrellas,
    required this.saludo,
    required this.accion,
    this.botonEscuchar,
    this.dormida = false,
  });

  @override
  State<EscenarioMascota> createState() => _EscenarioMascotaState();
}

class _EscenarioMascotaState extends State<EscenarioMascota> {
  static const List<String> _frases = [
    '¡Me encanta jugar contigo!',
    '¡Jiji, me haces cosquillas!',
    '¡Eres muy inteligente!',
    'Cada juego me ayuda a crecer.',
    '¡Vamos por más estrellas!',
  ];

  EtapaMascota? _evolucionReciente;

  /// Lo que dice la mascota después de tocarla (null: el saludo).
  String? _frase;
  int _toques = 0;
  bool _desperto = false;

  bool get _durmiendo => widget.dormida && !_desperto;

  void _decir(String frase) {
    setState(() => _frase = frase);
    hablarOAvisar(context, frase);
  }

  void _alTocarMascota() {
    if (_durmiendo) {
      _desperto = true;
      _decir('¡Ya desperté! ¡Te extrañé mucho!');
      return;
    }

    _decir(_frases[_toques % _frases.length]);
    _toques++;
  }

  void _alTocarSiguiente(EvolucionMascota evolucion) {
    final siguiente = evolucion.etapa.siguiente;

    if (siguiente == null) {
      return;
    }

    final faltan = evolucion.estrellasFaltantes;
    final estrellas = faltan == 1 ? 'estrella' : 'estrellas';

    _decir(
      evolucion.etapa == EtapaMascota.huevo
          ? '¡Es una sorpresa! Con $faltan $estrellas más voy a nacer.'
          : '¡Es una sorpresa! Con $faltan $estrellas más seré '
              '${siguiente.nombre}.',
    );
  }

  Widget _construirBurbuja() {
    final frase = _frase;

    if (frase != null) {
      return BurbujaDialogo(
        texto: frase,
        botonEscuchar: BotonEscuchar(texto: frase),
      );
    }

    if (_durmiendo) {
      final texto = 'Zzz… ${widget.mascota.nombre} está durmiendo. '
          '¡Tócalo para despertarlo!';

      return BurbujaDialogo(
        texto: texto,
        botonEscuchar: BotonEscuchar(texto: texto),
      );
    }

    return BurbujaDialogo(
      texto: widget.saludo,
      botonEscuchar: widget.botonEscuchar,
    );
  }

  @override
  void didUpdateWidget(EscenarioMascota anterior) {
    super.didUpdateWidget(anterior);

    final antes = anterior.estrellas;
    final ahora = widget.estrellas;

    // Solo cuenta como evolución si ya se conocían las estrellas: así no se
    // celebra al abrir la app.
    if (antes == null || ahora == null) {
      return;
    }

    final etapaAntes = EtapaMascota.segunEstrellas(antes);
    final etapaAhora = EtapaMascota.segunEstrellas(ahora);

    if (etapaAhora.index > etapaAntes.index) {
      setState(() => _evolucionReciente = etapaAhora);
    }
  }

  @override
  Widget build(BuildContext context) {
    final evolucion = EvolucionMascota(widget.estrellas ?? 0);
    final reciente = _evolucionReciente;

    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [EscenarioMascota._fondoClaro, EscenarioMascota._fondo],
        ),
        borderRadius: BorderRadius.circular(30),
        boxShadow: const [
          BoxShadow(color: Color(0xFF4A2BB0), offset: Offset(0, 7)),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(30),
        child: CustomPaint(
          painter: const _PintorDestellos(),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (reciente != null) ...[
                  _AvisoEvolucion(
                    nombre: widget.mascota.nombre,
                    etapa: reciente,
                    onCerrar: () => setState(() => _evolucionReciente = null),
                  ),
                  const SizedBox(height: 12),
                ],
                _construirBurbuja(),
                const SizedBox(height: 4),
                _MascotaEnPlataforma(
                  mascota: widget.mascota,
                  evolucion: evolucion,
                  expresion: _durmiendo
                      ? ExpresionMascota.dormida
                      : ExpresionMascota.normal,
                  onTocar: _alTocarMascota,
                  onTocarSiguiente: () => _alTocarSiguiente(evolucion),
                ),
                const SizedBox(height: 10),
                _BarraEvolucion(evolucion: evolucion),
                const SizedBox(height: 16),
                widget.accion,
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Burbuja de diálogo blanca con su "colita" abajo, para lo que dice la
/// mascota.
class BurbujaDialogo extends StatelessWidget {
  final String texto;

  /// Texto más pequeño debajo (opcional).
  final String? detalle;
  final Widget? botonEscuchar;

  const BurbujaDialogo({
    super.key,
    required this.texto,
    this.detalle,
    this.botonEscuchar,
  });

  @override
  Widget build(BuildContext context) {
    final boton = botonEscuchar;
    final masTexto = detalle;

    return Column(
      children: [
        Container(
          padding: EdgeInsets.fromLTRB(18, 12, boton == null ? 18 : 8, 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(22),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  children: [
                    Text(
                      texto,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 21,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.texto,
                      ),
                    ),
                    if (masTexto != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        masTexto,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 17,
                          color: AppTheme.texto,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (boton != null) ...[const SizedBox(width: 8), boton],
            ],
          ),
        ),
        // La "colita" de la burbuja apunta a la mascota.
        const CustomPaint(
          size: Size(26, 12),
          painter: _PintorColita(),
        ),
      ],
    );
  }
}

class _MascotaEnPlataforma extends StatelessWidget {
  final MascotaElegida mascota;
  final EvolucionMascota evolucion;
  final ExpresionMascota expresion;
  final VoidCallback onTocar;
  final VoidCallback onTocarSiguiente;

  const _MascotaEnPlataforma({
    required this.mascota,
    required this.evolucion,
    required this.expresion,
    required this.onTocar,
    required this.onTocarSiguiente,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 170,
      child: Stack(
        alignment: Alignment.bottomCenter,
        children: [
          // Plataforma: una isla de pasto bajo los pies.
          Positioned(
            bottom: 0,
            child: Container(
              width: 190,
              height: 34,
              decoration: BoxDecoration(
                color: const Color(0xFF5BD47A),
                borderRadius: const BorderRadius.all(Radius.elliptical(95, 17)),
                border: Border(
                  bottom: BorderSide(
                    color:
                        Color.lerp(const Color(0xFF5BD47A), Colors.black, 0.3)!,
                    width: 6,
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            bottom: 8,
            child: Semantics(
              button: true,
              label: 'Tocar a ${mascota.nombre}',
              child: MascotaAnimada(
                especie: mascota.especie,
                etapa: evolucion.etapa,
                tamano: 160,
                expresion: expresion,
                onTocar: onTocar,
              ),
            ),
          ),
          if (evolucion.etapa.siguiente case final siguiente?)
            Positioned(
              right: 0,
              top: 0,
              child: _ProximaForma(
                especie: mascota.especie,
                etapa: siguiente,
                onTocar: onTocarSiguiente,
              ),
            ),
        ],
      ),
    );
  }
}

/// Silueta de la siguiente etapa: se ve la forma, no los colores, para que
/// el niño tenga curiosidad por descubrirla.
class _ProximaForma extends StatelessWidget {
  static const double _tamano = 62;

  final EspecieMascota especie;
  final EtapaMascota etapa;
  final VoidCallback onTocar;

  const _ProximaForma({
    required this.especie,
    required this.etapa,
    required this.onTocar,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: '¿En qué se convertirá?',
      child: GestureDetector(
        key: const ValueKey('proxima-forma'),
        behavior: HitTestBehavior.opaque,
        onTap: onTocar,
        child: ExcludeSemantics(
          child: Column(
            children: [
              Container(
                width: _tamano + 14,
                height: _tamano + 14,
                decoration: BoxDecoration(
                  color: const Color(0x26FFFFFF),
                  shape: BoxShape.circle,
                  border: Border.all(color: const Color(0x80FFFFFF), width: 2),
                ),
                alignment: Alignment.center,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    ColorFiltered(
                      colorFilter: const ColorFilter.mode(
                        Color(0xFF3B2290),
                        BlendMode.srcIn,
                      ),
                      child: MascotaAnimada(
                        especie: especie,
                        etapa: etapa,
                        tamano: _tamano,
                        animada: false,
                        saltaAlTocar: false,
                      ),
                    ),
                    const Text(
                      '?',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w900,
                        color: AppTheme.amarillo,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 2),
              const Text(
                '¿Y después?',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BarraEvolucion extends StatelessWidget {
  final EvolucionMascota evolucion;

  const _BarraEvolucion({required this.evolucion});

  String get _mensaje {
    if (evolucion.esUltimaEtapa) {
      return '¡Llegó a su máxima evolución!';
    }

    final faltan = evolucion.estrellasFaltantes;
    final estrellas = faltan == 1 ? 'estrella' : 'estrellas';

    if (evolucion.etapa == EtapaMascota.huevo) {
      return 'Gana $faltan $estrellas en los juegos para que nazca.';
    }
    return 'Faltan $faltan ⭐ para evolucionar.';
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
              decoration: BoxDecoration(
                color: AppTheme.amarillo,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                evolucion.etapa.nombre,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF5C3A00),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(
                  minHeight: 14,
                  value: evolucion.avance,
                  color: AppTheme.amarillo,
                  backgroundColor: const Color(0x40FFFFFF),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Text(
          _mensaje,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w800,
            color: Colors.white,
          ),
        ),
      ],
    );
  }
}

class _AvisoEvolucion extends StatelessWidget {
  final String nombre;
  final EtapaMascota etapa;
  final VoidCallback onCerrar;

  const _AvisoEvolucion({
    required this.nombre,
    required this.etapa,
    required this.onCerrar,
  });

  @override
  Widget build(BuildContext context) {
    final texto = etapa == EtapaMascota.bebe
        ? '✨ ¡$nombre nació! ✨'
        : '✨ ¡$nombre evolucionó a ${etapa.nombre}! ✨';

    return Material(
      color: AppTheme.amarillo,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onCerrar,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  texto,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF5C3A00),
                  ),
                ),
              ),
              const Icon(Icons.close_rounded, color: Color(0xFF5C3A00)),
            ],
          ),
        ),
      ),
    );
  }
}

class _PintorColita extends CustomPainter {
  const _PintorColita();

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawPath(
      Path()
        ..moveTo(0, 0)
        ..lineTo(size.width, 0)
        ..lineTo(size.width / 2, size.height)
        ..close(),
      Paint()..color = Colors.white,
    );
  }

  @override
  bool shouldRepaint(_PintorColita anterior) => false;
}

/// Estrellitas y círculos suaves de fondo, como un cielo de noche mágica.
class _PintorDestellos extends CustomPainter {
  const _PintorDestellos();

  @override
  void paint(Canvas canvas, Size size) {
    final azar = Random(11);
    final circulo = Paint()..color = const Color(0x14FFFFFF);

    canvas.drawCircle(
      Offset(size.width * 0.9, size.height * 0.12),
      70,
      circulo,
    );
    canvas.drawCircle(
      Offset(size.width * 0.05, size.height * 0.55),
      60,
      circulo,
    );

    final punto = Paint()..color = const Color(0x55FFFFFF);
    for (var i = 0; i < 18; i++) {
      canvas.drawCircle(
        Offset(azar.nextDouble() * size.width, azar.nextDouble() * size.height),
        1 + azar.nextDouble() * 2.5,
        punto,
      );
    }
  }

  @override
  bool shouldRepaint(_PintorDestellos anterior) => false;
}
