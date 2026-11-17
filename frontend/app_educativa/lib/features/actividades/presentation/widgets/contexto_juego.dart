import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../shared/widgets/boton_escuchar.dart';
import '../../../../shared/widgets/boton_grande.dart';
import '../../domain/actividad.dart';
import 'boton_pista.dart';

/// Explicación corta de cómo se juega cada tipo de actividad.
String comoSeJuega(TipoActividad tipo) => switch (tipo) {
      TipoActividad.elige =>
        'Lee o escucha cada pregunta y toca la respuesta correcta.',
      TipoActividad.parejas =>
        'Une cada elemento de la izquierda con su pareja de la derecha.',
      TipoActividad.clasifica =>
        'Pon cada tarjeta en el grupo al que pertenece.',
      TipoActividad.ordena => 'Toca los pasos en el orden correcto.',
      TipoActividad.memoria =>
        'Voltea las cartas de dos en dos hasta encontrar cada pareja.',
      TipoActividad.arrastra =>
        'Lleva con el dedo cada tarjeta a su canasta.',
      TipoActividad.atrapa =>
        'Los dibujos suben como globos: revienta solo los que te piden.',
      TipoActividad.completa =>
        'Completa cada oración con la palabra que falta.',
      TipoActividad.arma =>
        'Toca las palabras en orden para armar la oración.',
      TipoActividad.sopa =>
        'Busca las palabras escondidas en la sopa de letras.',
      TipoActividad.bienOMal =>
        'Mira cada situación y toca la carita feliz si está bien o la '
            'carita triste si está mal.',
      TipoActividad.escucha =>
        'Escucha con atención lo que dice la voz y toca el dibujo.',
    };

/// Un consejo para mejorar en cada tipo de actividad.
String consejoParaMejorar(TipoActividad tipo) => switch (tipo) {
      TipoActividad.elige =>
        'Lee toda la pregunta y todas las opciones antes de tocar.',
      TipoActividad.parejas =>
        'Mira bien los dos lados antes de unir cada pareja.',
      TipoActividad.clasifica =>
        'Piensa qué tienen en común las tarjetas de cada grupo.',
      TipoActividad.ordena =>
        'Piensa qué pasa primero, qué pasa después y qué pasa al final.',
      TipoActividad.memoria =>
        'Trata de recordar dónde estaba cada carta que ya volteaste.',
      TipoActividad.arrastra =>
        'Antes de soltar, piensa en qué canasta va cada tarjeta.',
      TipoActividad.atrapa =>
        'Escucha bien qué debes atrapar y revienta solo esos globos.',
      TipoActividad.completa =>
        'Lee la oración completa con cada palabra y elige la que tenga sentido.',
      TipoActividad.arma =>
        'Busca primero la palabra con la que empieza la oración.',
      TipoActividad.sopa =>
        'Busca las palabras de izquierda a derecha y de arriba abajo.',
      TipoActividad.bienOMal =>
        'Piensa si lo que pasa en el dibujo ayuda o hace daño.',
      TipoActividad.escucha =>
        'Toca el botón de escuchar para oír otra vez antes de responder.',
    };

/// El nivel al que pertenece [actividad], o null si no está en el plan.
Nivel? nivelDeActividad(PlanActividades plan, Actividad actividad) {
  for (final nivel in plan.niveles) {
    if (nivel.actividades.any((a) => a.id == actividad.id)) {
      return nivel;
    }
  }

  return null;
}

/// Lo que la voz lee en la presentación del juego.
String textoContexto(Nivel? nivel, Actividad actividad) {
  final partes = [
    if (nivel != null) ...[
      'Nivel ${nivel.numero}: ${nivel.titulo}.',
      'Vas a aprender: ${nivel.objetivo}',
    ],
    'Juego: ${actividad.titulo}.',
    comoSeJuega(actividad.tipo),
    'Toca Empezar cuando estés listo.',
  ];

  return partes.join(' ');
}

/// Breve contexto antes de empezar un juego: de qué trata el nivel, qué se
/// aprende y cómo se juega.
class ContextoJuego extends StatelessWidget {
  final Nivel? nivel;
  final Actividad actividad;
  final VoidCallback onEmpezar;

  const ContextoJuego({
    super.key,
    required this.nivel,
    required this.actividad,
    required this.onEmpezar,
  });

  @override
  Widget build(BuildContext context) {
    final nivel = this.nivel;

    return SingleChildScrollView(
      key: const ValueKey('contexto-juego'),
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(
              width: 110,
              height: 110,
              alignment: Alignment.center,
              decoration: const BoxDecoration(
                color: AppTheme.moradoSuave,
                shape: BoxShape.circle,
              ),
              child: Text(
                nivel?.emoji ?? '🎮',
                style: const TextStyle(fontSize: 58),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: AppTheme.superficie,
              borderRadius: BorderRadius.circular(AppTheme.radio),
              border: Border.all(color: AppTheme.morado, width: 3),
              boxShadow: const [
                BoxShadow(color: Color(0x336741D9), offset: Offset(0, 5)),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        nivel == null
                            ? actividad.titulo
                            : 'Nivel ${nivel.numero}: ${nivel.titulo}',
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          color: AppTheme.morado,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    BotonEscuchar(texto: textoContexto(nivel, actividad)),
                  ],
                ),
                if (nivel != null) ...[
                  const SizedBox(height: 14),
                  const _Subtitulo('🎯 Vas a aprender'),
                  const SizedBox(height: 4),
                  Text(nivel.objetivo, style: _estiloTexto),
                ],
                const SizedBox(height: 14),
                const _Subtitulo('🎮 ¿Cómo se juega?'),
                const SizedBox(height: 4),
                Text(comoSeJuega(actividad.tipo), style: _estiloTexto),
              ],
            ),
          ),
          const SizedBox(height: 24),
          BotonGrande(
            texto: '¡Empezar!',
            icono: Icons.play_arrow_rounded,
            color: AppTheme.verde,
            onPressed: onEmpezar,
          ),
        ],
      ),
    );
  }
}

const TextStyle _estiloTexto = TextStyle(
  fontSize: 19,
  fontWeight: FontWeight.w600,
  color: AppTheme.texto,
);

class _Subtitulo extends StatelessWidget {
  final String texto;

  const _Subtitulo(this.texto);

  @override
  Widget build(BuildContext context) {
    return Text(
      texto,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w800,
        color: AppTheme.textoSecundario,
      ),
    );
  }
}

/// Retroalimentación al terminar con errores: cuántos hubo, un consejo y,
/// si la actividad tiene pista, el acceso a la cartilla para repasar.
class ConsejoParaMejorar extends StatelessWidget {
  final Actividad actividad;
  final int estrellas;
  final int errores;
  final String moduloId;

  const ConsejoParaMejorar({
    super.key,
    required this.actividad,
    required this.estrellas,
    required this.errores,
    required this.moduloId,
  });

  String get _resumen {
    final cuantos = errores == 1 ? '1 error' : '$errores errores';

    return estrellas <= 1
        ? 'Tuviste $cuantos. No pasa nada: equivocarse también es aprender.'
        : 'Tuviste $cuantos. ¡Ya casi lo haces perfecto!';
  }

  String get _consejo => consejoParaMejorar(actividad.tipo);

  @override
  Widget build(BuildContext context) {
    final pista = actividad.pista;

    return Container(
      key: const ValueKey('consejo-para-mejorar'),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.ambarSuave,
        borderRadius: BorderRadius.circular(AppTheme.radio),
        border: Border.all(color: AppTheme.ambar, width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  '💡 Para mejorar',
                  style: TextStyle(
                    fontSize: 21,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.ambar,
                  ),
                ),
              ),
              BotonEscuchar(
                texto: '$_resumen $_consejo Toca Jugar otra vez para '
                    'intentarlo de nuevo.',
                color: AppTheme.ambar,
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(_resumen, style: _estiloTexto),
          const SizedBox(height: 6),
          Text(_consejo, style: _estiloTexto),
          if (pista != null) ...[
            const SizedBox(height: 10),
            const Text(
              'Repasa en la cartilla antes de volver a jugar:',
              style: TextStyle(fontSize: 17, color: AppTheme.textoSecundario),
            ),
            const SizedBox(height: 6),
            Align(
              alignment: Alignment.centerLeft,
              child: BotonPista(pista: pista, moduloId: moduloId),
            ),
          ],
        ],
      ),
    );
  }
}
