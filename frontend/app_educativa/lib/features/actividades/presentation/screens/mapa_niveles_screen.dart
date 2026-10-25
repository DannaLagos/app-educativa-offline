import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../shared/widgets/boton_grande.dart';
import '../../../../shared/widgets/mensaje_con_accion.dart';
import '../../../modulos/domain/modulo.dart';
import '../../../modulos/presentation/controllers/modulos_scope.dart';
import '../../../progreso/domain/progreso_modulo.dart';
import '../../../progreso/presentation/progreso_scope.dart';
import '../../data/actividades_local_datasource.dart';
import '../../domain/actividad.dart';
import '../../domain/ruta_aprendizaje.dart';
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
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Juegos: ${widget.modulo.nombre}')),
      body: SafeArea(
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
        const SizedBox(height: 20),
        for (final nivel in ruta.niveles) ...[
          _SeccionNivel(
            nivel: nivel,
            siguienteId: siguiente?.actividad.id,
            onJugar: onJugar,
          ),
          const SizedBox(height: 20),
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
        color: AppTheme.azulSuave,
        borderRadius: BorderRadius.circular(AppTheme.radio),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            terminado ? '🌟 ¡Terminaste todos los juegos!' : '🎮 ¡Vamos a jugar!',
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 8),
          Text(
            '${ruta.actividadesCompletadas} de ${ruta.totalActividades} '
            'juegos terminados · ⭐ $estrellas',
            style: const TextStyle(
              fontSize: 18,
              color: AppTheme.azul,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              minHeight: 12,
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
              color: AppTheme.verde,
              onPressed: () => onContinuar(siguiente),
            ),
            const SizedBox(height: 6),
            Text(
              'Nivel ${siguiente.nivel.numero}: ${siguiente.actividad.titulo}',
              style: const TextStyle(fontSize: 16, color: AppTheme.textoSecundario),
            ),
          ],
        ],
      ),
    );
  }
}

class _SeccionNivel extends StatelessWidget {
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

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Semantics(
          header: true,
          child: Row(
            children: [
              Container(
                width: 64,
                height: 64,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: abierto ? AppTheme.azulClaro : AppTheme.grisSuave,
                  border: Border.all(
                    color: nivel.estaCompletado
                        ? AppTheme.verde
                        : abierto
                            ? AppTheme.azul
                            : AppTheme.borde,
                    width: 3,
                  ),
                ),
                child: Text(
                  abierto ? datos.emoji : '🔒',
                  style: const TextStyle(fontSize: 32),
                ),
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
                        fontWeight: FontWeight.w700,
                        color: AppTheme.textoSecundario,
                      ),
                    ),
                    Text(
                      datos.titulo,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    FilaEstrellas(
                      estrellas: nivel.estrellas,
                      maximo: nivel.estrellasPosibles,
                      tamano: 18,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        if (!abierto)
          const Padding(
            padding: EdgeInsets.only(top: 8, left: 78),
            child: Text(
              'Termina el nivel anterior para abrirlo.',
              style: TextStyle(fontSize: 16, color: AppTheme.textoSecundario),
            ),
          ),
        const SizedBox(height: 12),
        for (final paso in nivel.pasos) ...[
          _TarjetaJuego(
            paso: paso,
            esLaSiguiente: paso.actividad.id == siguienteId,
            onTap: paso.sePuedeJugar ? () => onJugar(paso) : null,
          ),
          const SizedBox(height: 10),
        ],
      ],
    );
  }
}

class _TarjetaJuego extends StatelessWidget {
  final PasoRuta paso;
  final bool esLaSiguiente;
  final VoidCallback? onTap;

  const _TarjetaJuego({
    required this.paso,
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
      };

  @override
  Widget build(BuildContext context) {
    final bloqueada = paso.estado == EstadoActividad.bloqueada;

    return Semantics(
      button: !bloqueada,
      label: bloqueada
          ? '${paso.actividad.titulo}. Bloqueado.'
          : '${paso.actividad.titulo}. ${paso.estrellas} estrellas.',
      excludeSemantics: true,
      child: Material(
        color: esLaSiguiente
            ? AppTheme.verdeSuave
            : bloqueada
                ? AppTheme.grisSuave
                : AppTheme.superficie,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.radio),
          side: BorderSide(
            color: esLaSiguiente ? AppTheme.verde : AppTheme.borde,
            width: esLaSiguiente ? 3 : 2,
          ),
        ),
        child: InkWell(
          key: ValueKey('juego-${paso.actividad.id}'),
          borderRadius: BorderRadius.circular(AppTheme.radio),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Opacity(
              opacity: bloqueada ? 0.55 : 1,
              child: Row(
                children: [
                  Text(
                    bloqueada ? '🔒' : _emojiDe(paso.actividad.tipo),
                    style: const TextStyle(fontSize: 34),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          paso.actividad.titulo,
                          style: const TextStyle(
                            fontSize: 19,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 4),
                        if (esLaSiguiente)
                          const Text(
                            '¡Juega ahora!',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: AppTheme.verde,
                            ),
                          )
                        else if (paso.estado == EstadoActividad.completada)
                          FilaEstrellas(estrellas: paso.estrellas, tamano: 20),
                      ],
                    ),
                  ),
                  if (!bloqueada)
                    const Icon(
                      Icons.play_circle_fill_rounded,
                      size: 40,
                      color: AppTheme.azul,
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
