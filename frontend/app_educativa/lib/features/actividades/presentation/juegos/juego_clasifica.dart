import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../domain/actividad.dart';
import '../widgets/tarjeta_elemento.dart';
import 'juego_base.dart';

/// Clasifica: aparece una tarjeta a la vez y el niño toca la canasta donde
/// va.
class JuegoClasifica extends JuegoBase {
  final ActividadClasifica actividad;

  const JuegoClasifica({
    super.key,
    required this.actividad,
    required super.onResponder,
    required super.onCompletado,
    required super.random,
    required super.pausa,
  });

  @override
  State<JuegoClasifica> createState() => _JuegoClasificaState();
}

class _JuegoClasificaState extends State<JuegoClasifica>
    with EstadoJuego<JuegoClasifica> {
  late final List<int> _orden =
      indicesMezclados(widget.actividad.tarjetas.length);
  final Map<String, int> _porGrupo = {};
  int _indice = 0;
  String? _grupoFallido;
  bool _acerto = false;

  TarjetaClasifica get _tarjeta => widget.actividad.tarjetas[_orden[_indice]];

  void _elegirGrupo(GrupoClasifica grupo) {
    if (_acerto) {
      return;
    }

    final esCorrecto = grupo.id == _tarjeta.grupo;

    setState(() {
      if (esCorrecto) {
        _acerto = true;
        _grupoFallido = null;
        _porGrupo[grupo.id] = (_porGrupo[grupo.id] ?? 0) + 1;
      } else {
        _grupoFallido = grupo.id;
      }
    });
    widget.onResponder(esCorrecto);

    if (esCorrecto) {
      despuesDeLaPausa(_siguiente);
    }
  }

  void _siguiente() {
    if (_indice + 1 >= _orden.length) {
      widget.onCompletado();
      return;
    }

    setState(() {
      _indice++;
      _acerto = false;
      _grupoFallido = null;
    });
    voz.hablar(_tarjeta.elemento.texto);
  }

  @override
  Widget build(BuildContext context) {
    final grupos = widget.actividad.grupos;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        IndicadorAvance(
          actual: _indice + (_acerto ? 1 : 0),
          total: _orden.length,
        ),
        const SizedBox(height: 24),
        const Text(
          '¿Dónde va?',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 12),
        TarjetaElemento(
          key: ValueKey('tarjeta-$_indice'),
          elemento: _tarjeta.elemento,
          estado: _acerto ? EstadoTarjeta.correcta : EstadoTarjeta.normal,
          tamanoEmoji: 64,
          onTap: () => voz.hablar(_tarjeta.elemento.texto),
        ),
        const SizedBox(height: 28),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (var i = 0; i < grupos.length; i++) ...[
              if (i > 0) const SizedBox(width: 12),
              Expanded(
                child: _Canasta(
                  grupo: grupos[i],
                  cantidad: _porGrupo[grupos[i].id] ?? 0,
                  fallo: _grupoFallido == grupos[i].id,
                  onTap: () => _elegirGrupo(grupos[i]),
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }
}

class _Canasta extends StatelessWidget {
  final GrupoClasifica grupo;
  final int cantidad;
  final bool fallo;
  final VoidCallback onTap;

  const _Canasta({
    required this.grupo,
    required this.cantidad,
    required this.fallo,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = fallo ? AppTheme.ambar : AppTheme.azul;

    return Semantics(
      button: true,
      label: grupo.elemento.texto,
      excludeSemantics: true,
      child: Material(
        color: fallo ? AppTheme.ambarSuave : AppTheme.azulSuave,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.radio),
          side: BorderSide(color: color, width: 3),
        ),
        child: InkWell(
          key: ValueKey('canasta-${grupo.id}'),
          borderRadius: BorderRadius.circular(AppTheme.radio),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 8),
            child: Column(
              children: [
                Text(grupo.elemento.emoji, style: const TextStyle(fontSize: 48)),
                const SizedBox(height: 8),
                Text(
                  grupo.elemento.texto,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.w800,
                    color: color,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  '🧺 $cantidad',
                  style: const TextStyle(fontSize: 18),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
