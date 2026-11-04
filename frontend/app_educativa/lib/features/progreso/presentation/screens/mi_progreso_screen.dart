import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../shared/widgets/dibujo.dart';
import '../../../../shared/widgets/fondo_divertido.dart';
import '../../../actividades/data/actividades_local_datasource.dart';
import '../../../actividades/domain/actividad.dart';
import '../../../modulos/domain/modulo.dart';
import '../../../modulos/presentation/controllers/modulos_scope.dart';
import '../../../modulos/presentation/widgets/icono_area.dart';
import '../../../modulos/presentation/widgets/encabezado_mundo.dart';
import '../../../sincronizacion/presentation/widgets/barra_conexion.dart';
import '../../domain/progreso_modulo.dart';
import '../../domain/resumen_modulo.dart';
import '../progreso_scope.dart';
import 'detalle_progreso_screen.dart';

typedef CargadorPlanModulo = Future<PlanActividades?> Function(
  BuildContext context,
  Modulo modulo,
);

/// "Mi progreso" (HU09): todos los módulos con lo que el estudiante lleva.
/// Solo usa datos del dispositivo, así que funciona sin internet.
class MiProgresoScreen extends StatefulWidget {
  /// Reemplazable en pruebas. Por defecto lee `actividades.json` del módulo
  /// descargado.
  final CargadorPlanModulo? cargarPlan;

  const MiProgresoScreen({super.key, this.cargarPlan});

  @override
  State<MiProgresoScreen> createState() => _MiProgresoScreenState();
}

class _MiProgresoScreenState extends State<MiProgresoScreen> {
  final Map<String, PlanActividades?> _planes = {};
  List<Modulo> _modulos = const [];
  bool _estaCargando = true;
  bool _cargaSolicitada = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    if (!_cargaSolicitada) {
      _cargaSolicitada = true;
      // Se carga después del primer cuadro: cargar el catálogo avisa a las
      // pantallas, y eso no se puede hacer mientras se dibujan.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _cargar();
        }
      });
    }
  }

  Future<PlanActividades?> _planDesdeModulo(
    BuildContext context,
    Modulo modulo,
  ) async {
    final recursos = await ModulosScope.of(context).obtenerRecursos(modulo);

    return const ActividadesLocalDataSource().leer(recursos);
  }

  Future<void> _cargar() async {
    final modulos = ModulosScope.of(context);
    final progreso = ProgresoScope.leer(context);
    final cargarPlan = widget.cargarPlan ?? _planDesdeModulo;

    if (modulos.catalogo.isEmpty) {
      await modulos.cargarCatalogo();
    }
    await modulos.cargarDescargados();

    final porId = <String, Modulo>{
      for (final modulo in [...modulos.catalogo, ...modulos.descargados])
        modulo.id: modulo,
    };
    final lista = porId.values.toList()
      ..sort((a, b) {
        final area = a.area.compareTo(b.area);
        return area != 0 ? area : a.grado.compareTo(b.grado);
      });

    for (final modulo in lista) {
      await progreso?.cargarProgreso(modulo.id);

      if (!mounted) {
        return;
      }

      PlanActividades? plan;
      if (modulo.estaDescargado) {
        try {
          plan = await cargarPlan(context, modulo);
        } catch (error) {
          debugPrint('No se pudieron leer los juegos de ${modulo.id}: $error');
        }
      }
      _planes[modulo.id] = plan;
    }

    if (mounted) {
      setState(() {
        _modulos = lista;
        _estaCargando = false;
      });
    }
  }

  void _abrirDetalle(ResumenModulo resumen) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => DetalleProgresoScreen(
          modulo: resumen.modulo,
          plan: resumen.plan,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final progreso = ProgresoScope.maybeOf(context);
    final resumenes = [
      for (final modulo in _modulos)
        ResumenModulo(
          modulo: modulo,
          progreso: progreso?.progresoDe(modulo.id) ??
              ProgresoModulo.vacio(modulo.id),
          plan: _planes[modulo.id],
        ),
    ];
    final iniciados = resumenes.where((r) => r.estaIniciado).toList();
    final sinEmpezar = resumenes.where((r) => !r.estaIniciado).toList();

    return Scaffold(
      body: FondoDivertido(
        child: SafeArea(
          child: _estaCargando
              ? const Center(child: CircularProgressIndicator())
              : ListView(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                  children: [
                    EncabezadoMundo(
                      area: '',
                      titulo: 'Mi progreso',
                      subtitulo: '¡Mira todo lo que has aprendido!',
                      color: AppTheme.morado,
                      emoji: '🏆',
                      accion: _Totales(resumenes: iniciados),
                    ),
                    const SizedBox(height: 24),
                    const _Titulo('Módulos que empezaste'),
                    const SizedBox(height: 10),
                    if (iniciados.isEmpty)
                      const Text(
                        'Todavía no has empezado ningún módulo. ¡Elige uno y '
                        'empieza a jugar!',
                        style: TextStyle(fontSize: 18),
                      ),
                    for (final resumen in iniciados) ...[
                      _TarjetaModulo(
                        resumen: resumen,
                        onTap: () => _abrirDetalle(resumen),
                      ),
                      const SizedBox(height: 12),
                    ],
                    if (sinEmpezar.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      const _Titulo('Sin empezar'),
                      const SizedBox(height: 10),
                      for (final resumen in sinEmpezar) ...[
                        _TarjetaModulo(
                          resumen: resumen,
                          onTap: () => _abrirDetalle(resumen),
                        ),
                        const SizedBox(height: 12),
                      ],
                    ],
                    const SizedBox(height: 24),
                    const _PieGuardado(),
                  ],
                ),
        ),
      ),
    );
  }
}

class _Titulo extends StatelessWidget {
  final String texto;

  const _Titulo(this.texto);

  @override
  Widget build(BuildContext context) {
    // Pastilla blanca: se lee bien sobre el paisaje.
    return Align(
      alignment: Alignment.centerLeft,
      child: Semantics(
        header: true,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          decoration: BoxDecoration(
            color: AppTheme.superficie,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppTheme.borde, width: 2),
          ),
          child: Text(
            texto,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: AppTheme.morado,
            ),
          ),
        ),
      ),
    );
  }
}

class _Totales extends StatelessWidget {
  final List<ResumenModulo> resumenes;

  const _Totales({required this.resumenes});

  @override
  Widget build(BuildContext context) {
    final juegos = resumenes.fold(0, (t, r) => t + r.juegosTerminados);
    final estrellas = resumenes.fold(0, (t, r) => t + r.estrellas);

    return Row(
      children: [
        Expanded(
          child: _Dato(
            emoji: '🎮',
            valor: '$juegos',
            etiqueta: 'juegos terminados',
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _Dato(
            emoji: '⭐',
            valor: '$estrellas',
            etiqueta: 'estrellas',
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _Dato(
            emoji: '📚',
            valor: '${resumenes.length}',
            etiqueta: resumenes.length == 1 ? 'módulo' : 'módulos',
          ),
        ),
      ],
    );
  }
}

class _Dato extends StatelessWidget {
  final String emoji;
  final String valor;
  final String etiqueta;

  const _Dato({
    required this.emoji,
    required this.valor,
    required this.etiqueta,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
      decoration: BoxDecoration(
        color: const Color(0x26FFFFFF),
        borderRadius: BorderRadius.circular(AppTheme.radioBoton),
      ),
      child: Column(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 28)),
          Text(
            valor,
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w800,
              color: Colors.white,
            ),
          ),
          Text(
            etiqueta,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}

/// Pie discreto: dónde está guardado el progreso y si ya se envió (HU10).
class _PieGuardado extends StatelessWidget {
  const _PieGuardado();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.75),
        borderRadius: BorderRadius.circular(18),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              SizedBox(
                width: 36,
                child: Icon(
                  Icons.phone_android_rounded,
                  color: AppTheme.textoSecundario,
                  size: 22,
                ),
              ),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Guardado en este teléfono. Puedes verlo sin internet.',
                  style: TextStyle(
                    fontSize: 14,
                    color: AppTheme.textoSecundario,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 10),
          TarjetaSincronizacion(),
        ],
      ),
    );
  }
}

class _TarjetaModulo extends StatelessWidget {
  final ResumenModulo resumen;
  final VoidCallback onTap;

  const _TarjetaModulo({required this.resumen, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final modulo = resumen.modulo;
    final total = resumen.juegosTotales;
    final avance = resumen.avanceJuegos;
    final lectura = resumen.lectura;

    final apariencia = AparienciaArea.de(modulo.area);

    return Container(
      margin: const EdgeInsets.only(bottom: 5),
      decoration: BoxDecoration(
        color: AppTheme.superficie,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: Color.lerp(apariencia.color, Colors.white, 0.6)!,
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: Color.lerp(apariencia.color, Colors.white, 0.45)!,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          key: ValueKey('resumen-${modulo.id}'),
          borderRadius: BorderRadius.circular(24),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 56,
                      height: 56,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: apariencia.color,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Dibujo(apariencia.emoji, tamano: 36),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        modulo.nombre,
                        style: const TextStyle(
                          fontSize: 19,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    if (resumen.estaTerminado) const Dibujo('🏆', tamano: 36),
                    const Icon(Icons.chevron_right_rounded),
                  ],
                ),
                const SizedBox(height: 10),
                if (!resumen.estaIniciado)
                  const Text(
                    'Sin empezar',
                    style: TextStyle(
                      fontSize: 16,
                      color: AppTheme.textoSecundario,
                    ),
                  )
                else ...[
                  Text(
                    total == null
                        ? '🎮 ${resumen.juegosTerminados} juegos terminados'
                        : '🎮 ${resumen.juegosTerminados} de $total juegos · '
                            '⭐ ${resumen.estrellas}',
                    style: const TextStyle(fontSize: 17),
                  ),
                  if (avance != null) ...[
                    const SizedBox(height: 6),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: LinearProgressIndicator(
                        minHeight: 14,
                        value: avance,
                        color: AparienciaArea.de(modulo.area).color,
                      ),
                    ),
                  ],
                  if (lectura != null) ...[
                    const SizedBox(height: 6),
                    Text(
                      '📖 Página ${lectura.ultimaPagina} de ${lectura.totalPaginas}',
                      style: const TextStyle(fontSize: 16),
                    ),
                  ],
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
