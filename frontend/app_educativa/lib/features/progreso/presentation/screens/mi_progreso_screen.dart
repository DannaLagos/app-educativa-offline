import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../actividades/data/actividades_local_datasource.dart';
import '../../../actividades/domain/actividad.dart';
import '../../../modulos/domain/modulo.dart';
import '../../../modulos/presentation/controllers/modulos_scope.dart';
import '../../../modulos/presentation/widgets/icono_area.dart';
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
      appBar: AppBar(title: const Text('Mi progreso')),
      body: SafeArea(
        child: _estaCargando
            ? const Center(child: CircularProgressIndicator())
            : ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  _Totales(resumenes: iniciados),
                  const SizedBox(height: 12),
                  const _AvisoSinInternet(),
                  const SizedBox(height: 12),
                  // HU10: si el progreso ya se envió o está pendiente.
                  const TarjetaSincronizacion(),
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
                ],
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
    return Semantics(
      header: true,
      child: Text(
        texto,
        style: const TextStyle(fontSize: 21, fontWeight: FontWeight.w800),
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

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppTheme.azul,
        borderRadius: BorderRadius.circular(AppTheme.radio),
      ),
      child: Row(
        children: [
          Expanded(
            child: _Dato(valor: '$juegos', etiqueta: 'juegos terminados'),
          ),
          Expanded(child: _Dato(valor: '⭐ $estrellas', etiqueta: 'estrellas')),
          Expanded(
            child: _Dato(
              valor: '${resumenes.length}',
              etiqueta: resumenes.length == 1 ? 'módulo' : 'módulos',
            ),
          ),
        ],
      ),
    );
  }
}

class _Dato extends StatelessWidget {
  final String valor;
  final String etiqueta;

  const _Dato({required this.valor, required this.etiqueta});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          valor,
          style: const TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.w800,
            color: Colors.white,
          ),
        ),
        Text(
          etiqueta,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 14, color: Colors.white),
        ),
      ],
    );
  }
}

class _AvisoSinInternet extends StatelessWidget {
  const _AvisoSinInternet();

  @override
  Widget build(BuildContext context) {
    return const Row(
      children: [
        Icon(Icons.phone_android_rounded, color: AppTheme.verde),
        SizedBox(width: 8),
        Expanded(
          child: Text(
            'Tu progreso está guardado en este teléfono. Puedes verlo sin '
            'internet.',
            style: TextStyle(fontSize: 16, color: AppTheme.verde),
          ),
        ),
      ],
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

    return Card(
      child: InkWell(
        key: ValueKey('resumen-${modulo.id}'),
        borderRadius: BorderRadius.circular(AppTheme.radio),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  IconoArea(area: modulo.area, tamano: 44),
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
                  if (resumen.estaTerminado)
                    const Text('🏆', style: TextStyle(fontSize: 26)),
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
                      minHeight: 10,
                      value: avance,
                      color: AppTheme.verdeVivo,
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
    );
  }
}
