import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../shared/widgets/boton_grande.dart';
import '../../../actividades/domain/actividad.dart';
import '../../../actividades/domain/ruta_aprendizaje.dart';
import '../../../actividades/presentation/screens/mapa_niveles_screen.dart';
import '../../../actividades/presentation/widgets/tarjeta_elemento.dart';
import '../../../modulos/domain/modulo.dart';
import '../../../modulos/presentation/widgets/icono_area.dart';
import '../../domain/progreso_modulo.dart';
import '../../domain/resumen_modulo.dart';
import '../progreso_scope.dart';

/// Progreso de un módulo, juego por juego (HU09): qué está terminado, qué
/// falta y qué todavía está bloqueado. Todo sale del dispositivo.
class DetalleProgresoScreen extends StatelessWidget {
  final Modulo modulo;
  final PlanActividades? plan;

  const DetalleProgresoScreen({
    super.key,
    required this.modulo,
    required this.plan,
  });

  @override
  Widget build(BuildContext context) {
    final resumen = ResumenModulo(
      modulo: modulo,
      progreso: ProgresoScope.maybeOf(context)?.progresoDe(modulo.id) ??
          ProgresoModulo.vacio(modulo.id),
      plan: plan,
    );
    final ruta = resumen.ruta;

    return Scaffold(
      appBar: AppBar(title: const Text('Mi progreso')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Row(
              children: [
                IconoArea(area: modulo.area),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        modulo.nombre,
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      Text(
                        '${modulo.area} · Grado ${modulo.grado}',
                        style: const TextStyle(
                          fontSize: 17,
                          color: AppTheme.textoSecundario,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            TarjetaResumen(resumen: resumen),
            const SizedBox(height: 24),
            if (ruta == null)
              const _SinJuegosDescargados()
            else ...[
              const _Leyenda(),
              const SizedBox(height: 16),
              for (final nivel in ruta.niveles) ...[
                _SeccionNivel(nivel: nivel, progreso: resumen.progreso),
                const SizedBox(height: 18),
              ],
              if (ruta.siguiente != null)
                BotonGrande(
                  texto: 'Seguir jugando',
                  icono: Icons.play_arrow_rounded,
                  color: AppTheme.verde,
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => MapaNivelesScreen(modulo: modulo),
                    ),
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Resumen de juegos, estrellas y lectura de un módulo.
class TarjetaResumen extends StatelessWidget {
  final ResumenModulo resumen;

  const TarjetaResumen({super.key, required this.resumen});

  @override
  Widget build(BuildContext context) {
    final total = resumen.juegosTotales;
    final avance = resumen.avanceJuegos;
    final lectura = resumen.lectura;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: resumen.estaTerminado ? AppTheme.verdeSuave : AppTheme.azulSuave,
        borderRadius: BorderRadius.circular(AppTheme.radio),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (resumen.estaTerminado)
            const Padding(
              padding: EdgeInsets.only(bottom: 8),
              child: Text(
                '🏆 ¡Terminaste todos los juegos!',
                style: TextStyle(
                  fontSize: 19,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.verde,
                ),
              ),
            ),
          Text(
            total == null
                ? '🎮 Juegos terminados: ${resumen.juegosTerminados}'
                : '🎮 Juegos: ${resumen.juegosTerminados} de $total',
            style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w800),
          ),
          if (avance != null) ...[
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                minHeight: 14,
                value: avance,
                color: AppTheme.verdeVivo,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '${(avance * 100).round()} % · '
              '${resumen.juegosPendientes} por terminar',
              style: const TextStyle(
                fontSize: 16,
                color: AppTheme.textoSecundario,
              ),
            ),
          ],
          const SizedBox(height: 10),
          Text(
            '⭐ ${resumen.estrellas} estrellas',
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 6),
          Text(
            lectura == null
                ? '📖 Todavía no has leído la cartilla'
                : '📖 Lectura: página ${lectura.ultimaPagina} de '
                    '${lectura.totalPaginas} '
                    '(${(lectura.avance * 100).round()} %)',
            style: const TextStyle(fontSize: 18),
          ),
        ],
      ),
    );
  }
}

class _Leyenda extends StatelessWidget {
  const _Leyenda();

  @override
  Widget build(BuildContext context) {
    return const Wrap(
      spacing: 10,
      runSpacing: 8,
      children: [
        _ChipLeyenda(estado: EstadoActividad.completada),
        _ChipLeyenda(estado: EstadoActividad.disponible),
        _ChipLeyenda(estado: EstadoActividad.bloqueada),
      ],
    );
  }
}

/// Apariencia de cada estado: color, símbolo y texto. Se usan símbolo y
/// texto además del color para que se distingan sin depender solo del
/// color.
({String simbolo, String texto, Color color, Color fondo}) aparienciaDe(
  EstadoActividad estado,
) {
  return switch (estado) {
    EstadoActividad.completada => (
        simbolo: '✅',
        texto: 'Terminado',
        color: AppTheme.verde,
        fondo: AppTheme.verdeSuave,
      ),
    EstadoActividad.disponible => (
        simbolo: '⏳',
        texto: 'Pendiente',
        color: AppTheme.azul,
        fondo: AppTheme.superficie,
      ),
    EstadoActividad.bloqueada => (
        simbolo: '🔒',
        texto: 'Bloqueado',
        color: AppTheme.textoSecundario,
        fondo: AppTheme.grisSuave,
      ),
  };
}

class _ChipLeyenda extends StatelessWidget {
  final EstadoActividad estado;

  const _ChipLeyenda({required this.estado});

  @override
  Widget build(BuildContext context) {
    final apariencia = aparienciaDe(estado);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: apariencia.fondo,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: apariencia.color, width: 2),
      ),
      child: Text(
        '${apariencia.simbolo} ${apariencia.texto}',
        style: TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w800,
          color: apariencia.color,
        ),
      ),
    );
  }
}

class _SeccionNivel extends StatelessWidget {
  final NivelEnRuta nivel;
  final ProgresoModulo progreso;

  const _SeccionNivel({required this.nivel, required this.progreso});

  @override
  Widget build(BuildContext context) {
    final terminados = nivel.pasos
        .where((paso) => paso.estado == EstadoActividad.completada)
        .length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Semantics(
          header: true,
          child: Row(
            children: [
              Text(nivel.nivel.emoji, style: const TextStyle(fontSize: 28)),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Nivel ${nivel.nivel.numero}: ${nivel.nivel.titulo}',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              Text(
                '$terminados de ${nivel.pasos.length}',
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.textoSecundario,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        for (final paso in nivel.pasos) ...[
          _FilaActividad(
            paso: paso,
            enLaNube: progreso.actividadDe(paso.actividad.id)?.sincronizado ??
                false,
          ),
          const SizedBox(height: 8),
        ],
      ],
    );
  }
}

class _FilaActividad extends StatelessWidget {
  final PasoRuta paso;

  /// HU11: el servidor ya confirmó que recibió este resultado.
  final bool enLaNube;

  const _FilaActividad({required this.paso, this.enLaNube = false});

  @override
  Widget build(BuildContext context) {
    final apariencia = aparienciaDe(paso.estado);
    final terminada = paso.estado == EstadoActividad.completada;

    return Semantics(
      label: '${paso.actividad.titulo}: ${apariencia.texto}'
          '${terminada ? (enLaNube ? ', guardado en la nube' : ', falta enviar') : ''}',
      excludeSemantics: true,
      child: Container(
        key: ValueKey('progreso-${paso.actividad.id}'),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: apariencia.fondo,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: terminada ? AppTheme.verde : AppTheme.borde,
            width: terminada ? 3 : 2,
          ),
        ),
        child: Opacity(
          opacity: paso.estado == EstadoActividad.bloqueada ? 0.6 : 1,
          child: Row(
            children: [
              Text(apariencia.simbolo, style: const TextStyle(fontSize: 26)),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      paso.actividad.titulo,
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    if (terminada) ...[
                      FilaEstrellas(estrellas: paso.estrellas, tamano: 18),
                      _EstadoEnvio(enLaNube: enLaNube),
                    ],
                  ],
                ),
              ),
              Text(
                apariencia.texto,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: apariencia.color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// HU11: si el resultado ya quedó registrado en el servidor o todavía está
/// solo en el teléfono.
class _EstadoEnvio extends StatelessWidget {
  final bool enLaNube;

  const _EstadoEnvio({required this.enLaNube});

  @override
  Widget build(BuildContext context) {
    return Text(
      enLaNube ? '☁️ Guardado en la nube' : '📱 Falta enviar',
      key: ValueKey(enLaNube ? 'en-la-nube' : 'falta-enviar'),
      style: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w700,
        color: enLaNube ? AppTheme.verde : AppTheme.ambar,
      ),
    );
  }
}

class _SinJuegosDescargados extends StatelessWidget {
  const _SinJuegosDescargados();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.grisSuave,
        borderRadius: BorderRadius.circular(AppTheme.radio),
      ),
      child: const Text(
        'Para ver todos los juegos de este módulo, descárgalo de nuevo cuando '
        'tengas internet. Tu progreso no se ha perdido.',
        style: TextStyle(fontSize: 17),
      ),
    );
  }
}
