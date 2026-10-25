import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../domain/actividad.dart';
import '../widgets/boton_pista.dart';
import '../widgets/tarjeta_elemento.dart';
import 'juego_base.dart';

/// Completa la oración: el niño toca (o arrastra) la palabra que va en el
/// espacio en blanco.
class JuegoCompleta extends JuegoBase {
  final ActividadCompleta actividad;

  const JuegoCompleta({
    super.key,
    required this.actividad,
    required super.onResponder,
    required super.onCompletado,
    required super.random,
    required super.pausa,
    super.moduloId,
  });

  @override
  State<JuegoCompleta> createState() => _JuegoCompletaState();
}

class _JuegoCompletaState extends State<JuegoCompleta>
    with EstadoJuego<JuegoCompleta> {
  int _indice = 0;
  late List<int> _orden;
  final Set<int> _falladas = {};
  bool _acerto = false;

  OracionCompleta get _oracion => widget.actividad.oraciones[_indice];

  @override
  void initState() {
    super.initState();
    _orden = indicesMezclados(_oracion.opciones.length);
  }

  void _elegir(int opcion) {
    if (_acerto || _falladas.contains(opcion)) {
      return;
    }

    final esCorrecta = opcion == _oracion.correcta;

    setState(() {
      if (esCorrecta) {
        _acerto = true;
      } else {
        _falladas.add(opcion);
      }
    });
    widget.onResponder(esCorrecta);

    if (esCorrecta) {
      despuesDeLaPausa(_siguiente);
    }
  }

  void _siguiente() {
    if (_indice + 1 >= widget.actividad.oraciones.length) {
      widget.onCompletado();
      return;
    }

    setState(() {
      _indice++;
      _orden = indicesMezclados(_oracion.opciones.length);
      _falladas.clear();
      _acerto = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final oracion = _oracion;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        IndicadorAvance(
          actual: _indice + (_acerto ? 1 : 0),
          total: widget.actividad.oraciones.length,
        ),
        const SizedBox(height: 20),
        Text(
          oracion.emoji,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 56),
        ),
        const SizedBox(height: 12),
        _OracionConEspacio(
          oracion: oracion,
          palabra: _acerto ? oracion.respuesta : null,
          onSoltar: _elegir,
          onEscuchar: () => voz.hablar(
            oracion.texto.replaceFirst(OracionCompleta.espacio, '...'),
          ),
        ),
        if (oracion.pista != null && widget.moduloId != null) ...[
          const SizedBox(height: 10),
          Align(
            alignment: Alignment.centerLeft,
            child: BotonPista(
              pista: oracion.pista!,
              moduloId: widget.moduloId!,
            ),
          ),
        ],
        const SizedBox(height: 24),
        Wrap(
          alignment: WrapAlignment.center,
          spacing: 12,
          runSpacing: 12,
          children: [
            for (final opcion in _orden)
              _PalabraArrastrable(
                key: ValueKey('palabra-$_indice-$opcion'),
                indice: opcion,
                texto: oracion.opciones[opcion],
                estado: _falladas.contains(opcion)
                    ? EstadoTarjeta.incorrecta
                    : _acerto
                        ? (opcion == oracion.correcta
                            ? EstadoTarjeta.correcta
                            : EstadoTarjeta.deshabilitada)
                        : EstadoTarjeta.normal,
                onTap: () => _elegir(opcion),
              ),
          ],
        ),
      ],
    );
  }
}

class _OracionConEspacio extends StatelessWidget {
  final OracionCompleta oracion;
  final String? palabra;
  final ValueChanged<int> onSoltar;
  final VoidCallback onEscuchar;

  const _OracionConEspacio({
    required this.oracion,
    required this.palabra,
    required this.onSoltar,
    required this.onEscuchar,
  });

  @override
  Widget build(BuildContext context) {
    const estilo = TextStyle(
      fontSize: 23,
      height: 1.6,
      fontWeight: FontWeight.w700,
      color: AppTheme.texto,
    );
    final completa = palabra;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.superficie,
        borderRadius: BorderRadius.circular(AppTheme.radio),
        border: Border.all(color: AppTheme.borde, width: 2),
      ),
      child: Row(
        children: [
          Expanded(
            child: Wrap(
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                if (oracion.antes.isNotEmpty) Text(oracion.antes, style: estilo),
                DragTarget<int>(
                  onAcceptWithDetails: (detalles) => onSoltar(detalles.data),
                  builder: (context, candidatas, _) => Container(
                    key: const ValueKey('espacio'),
                    constraints: const BoxConstraints(minWidth: 90),
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    decoration: BoxDecoration(
                      color: completa != null
                          ? AppTheme.verdeSuave
                          : candidatas.isNotEmpty
                              ? AppTheme.azulClaro
                              : AppTheme.ambarSuave,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: completa != null ? AppTheme.verde : AppTheme.ambar,
                        width: 2,
                      ),
                    ),
                    child: Text(
                      completa ?? ' ? ',
                      textAlign: TextAlign.center,
                      style: estilo.copyWith(
                        color: completa != null ? AppTheme.verde : AppTheme.ambar,
                      ),
                    ),
                  ),
                ),
                if (oracion.despues.isNotEmpty)
                  Text(oracion.despues, style: estilo),
              ],
            ),
          ),
          IconButton.filledTonal(
            tooltip: 'Escuchar la oración',
            iconSize: 30,
            onPressed: onEscuchar,
            icon: const Icon(Icons.volume_up_rounded),
          ),
        ],
      ),
    );
  }
}

class _PalabraArrastrable extends StatelessWidget {
  final int indice;
  final String texto;
  final EstadoTarjeta estado;
  final VoidCallback onTap;

  const _PalabraArrastrable({
    super.key,
    required this.indice,
    required this.texto,
    required this.estado,
    required this.onTap,
  });

  Widget _ficha({double elevacion = 0}) {
    final (fondo, borde) = switch (estado) {
      EstadoTarjeta.correcta => (AppTheme.verdeSuave, AppTheme.verde),
      EstadoTarjeta.incorrecta => (AppTheme.ambarSuave, AppTheme.ambar),
      EstadoTarjeta.deshabilitada => (AppTheme.grisSuave, AppTheme.borde),
      _ => (AppTheme.superficie, AppTheme.azul),
    };

    return Material(
      elevation: elevacion,
      color: fondo,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(30),
        side: BorderSide(color: borde, width: 3),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
        child: Text(
          texto,
          style: TextStyle(
            fontSize: 21,
            fontWeight: FontWeight.w800,
            color: estado == EstadoTarjeta.deshabilitada
                ? AppTheme.textoSecundario
                : AppTheme.texto,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final activa = estado == EstadoTarjeta.normal;

    return Semantics(
      button: true,
      enabled: activa,
      label: texto,
      excludeSemantics: true,
      child: activa
          ? Draggable<int>(
              data: indice,
              feedback: _ficha(elevacion: 8),
              childWhenDragging: Opacity(opacity: 0.3, child: _ficha()),
              child: GestureDetector(onTap: onTap, child: _ficha()),
            )
          : _ficha(),
    );
  }
}
