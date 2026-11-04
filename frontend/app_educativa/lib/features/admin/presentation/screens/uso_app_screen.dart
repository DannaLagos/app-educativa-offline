import 'package:flutter/material.dart';

import '../../../../core/network/servidor_exception.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../shared/widgets/mensaje_con_accion.dart';
import '../../data/uso_app_datasource.dart';
import '../../domain/resumen_uso.dart';

/// HU14: información general del uso de la aplicación con los datos que
/// los dispositivos ya sincronizaron.
class UsoAppScreen extends StatefulWidget {
  final UsoAppDataSource datos;

  const UsoAppScreen({super.key, required this.datos});

  @override
  State<UsoAppScreen> createState() => _UsoAppScreenState();
}

class _UsoAppScreenState extends State<UsoAppScreen> {
  ResumenUso? _resumen;
  String? _error;
  DateTime? _consultadoEn;

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  Future<void> _cargar() async {
    setState(() => _error = null);

    try {
      final resumen = ResumenUso.calcular(await widget.datos.obtenerDatos());

      if (!mounted) return;

      setState(() {
        _resumen = resumen;
        _consultadoEn = DateTime.now();
      });
    } on ServidorException catch (error) {
      debugPrint('$error');

      if (!mounted) return;

      setState(() => _error = error.mensaje);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Uso de la aplicación'),
        actions: [
          IconButton(
            tooltip: 'Actualizar',
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _cargar,
          ),
        ],
      ),
      body: _construirCuerpo(),
    );
  }

  Widget _construirCuerpo() {
    final error = _error;
    final resumen = _resumen;

    if (error != null) {
      return MensajeConAccion(
        icono: const Icon(Icons.cloud_off_rounded, color: AppTheme.rojo),
        mensaje: error,
        accion: ElevatedButton(
          onPressed: _cargar,
          child: const Text('Reintentar'),
        ),
      );
    }

    if (resumen == null) {
      return const Center(child: CircularProgressIndicator());
    }

    return RefreshIndicator(
      onRefresh: _cargar,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        children: [
          const _AvisoSincronizacion(),
          if (_consultadoEn case final fecha?)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                'Consultado: ${formatearFecha(fecha)}',
                style: const TextStyle(
                  fontSize: 14,
                  color: AppTheme.textoSecundario,
                ),
              ),
            ),
          const SizedBox(height: 16),
          if (resumen.estaVacio)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 32),
              child: Text(
                'Aún no hay datos sincronizados de los estudiantes.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 18),
              ),
            )
          else ...[
            _Totales(resumen: resumen),
            const SizedBox(height: 28),
            const _Titulo('Módulos utilizados'),
            const SizedBox(height: 10),
            for (final modulo in resumen.modulos) ...[
              _TarjetaUsoModulo(modulo: modulo),
              const SizedBox(height: 10),
            ],
            const SizedBox(height: 18),
            const _Titulo('Estudiantes'),
            const SizedBox(height: 10),
            for (final estudiante in resumen.estudiantes) ...[
              _TarjetaUsoEstudiante(estudiante: estudiante),
              const SizedBox(height: 10),
            ],
          ],
        ],
      ),
    );
  }
}

/// HU14, criterio 3.
class _AvisoSincronizacion extends StatelessWidget {
  const _AvisoSincronizacion();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.azulSuave,
        borderRadius: BorderRadius.circular(AppTheme.radioBoton),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline_rounded, color: AppTheme.azul),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              'Solo se muestra lo que ya se sincronizó. Lo que esté pendiente '
              'en un dispositivo aparecerá aquí cuando ese dispositivo tenga '
              'internet y envíe su progreso.',
              style: TextStyle(fontSize: 15, color: AppTheme.texto),
            ),
          ),
        ],
      ),
    );
  }
}

class _Titulo extends StatelessWidget {
  final String texto;

  const _Titulo(this.texto);

  @override
  Widget build(BuildContext context) {
    return Text(
      texto,
      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
    );
  }
}

class _Totales extends StatelessWidget {
  final ResumenUso resumen;

  const _Totales({required this.resumen});

  @override
  Widget build(BuildContext context) {
    final cifras = [
      ('Estudiantes', '${resumen.totalEstudiantes}', Icons.groups_rounded),
      ('Módulos usados', '${resumen.modulos.length}', Icons.menu_book_rounded),
      (
        'Actividades completadas',
        '${resumen.actividadesCompletadas}',
        Icons.sports_esports_rounded,
      ),
      ('Avance promedio', '${resumen.avancePromedio} %', Icons.trending_up_rounded),
    ];

    return GridView(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 10,
        crossAxisSpacing: 10,
        mainAxisExtent: 150,
      ),
      children: [
        for (final (etiqueta, valor, icono) in cifras)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Icon(icono, color: AppTheme.azul),
                  Text(
                    valor,
                    style: const TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  Text(
                    etiqueta,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 14,
                      color: AppTheme.textoSecundario,
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

class _TarjetaUsoModulo extends StatelessWidget {
  final UsoModulo modulo;

  const _TarjetaUsoModulo({required this.modulo});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              modulo.nombre,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 6),
            Text(
              '${_plural(modulo.estudiantes, 'estudiante', 'estudiantes')} · '
              '${_plural(modulo.actividadesCompletadas, 'actividad completada', 'actividades completadas')} · '
              '${_plural(modulo.intentos, 'intento', 'intentos')} · '
              '${_plural(modulo.paginasLeidas, 'página leída', 'páginas leídas')}',
              style: const TextStyle(
                fontSize: 15,
                color: AppTheme.textoSecundario,
              ),
            ),
            const SizedBox(height: 10),
            _BarraAvance(porcentaje: modulo.avancePromedio),
          ],
        ),
      ),
    );
  }
}

class _TarjetaUsoEstudiante extends StatelessWidget {
  final UsoEstudiante estudiante;

  const _TarjetaUsoEstudiante({required this.estudiante});

  @override
  Widget build(BuildContext context) {
    final fecha = estudiante.ultimaSincronizacion;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              estudiante.nombre,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 6),
            Text(
              '${_plural(estudiante.modulosUsados, 'módulo', 'módulos')} · '
              '${_plural(estudiante.actividadesCompletadas, 'actividad completada', 'actividades completadas')}',
              style: const TextStyle(
                fontSize: 15,
                color: AppTheme.textoSecundario,
              ),
            ),
            Text(
              fecha == null
                  ? 'Sin fecha de sincronización'
                  : 'Última sincronización: ${formatearFecha(fecha)}',
              style: const TextStyle(
                fontSize: 14,
                color: AppTheme.textoSecundario,
              ),
            ),
            const SizedBox(height: 10),
            _BarraAvance(porcentaje: estudiante.avancePromedio),
          ],
        ),
      ),
    );
  }
}

class _BarraAvance extends StatelessWidget {
  final int porcentaje;

  const _BarraAvance({required this.porcentaje});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: porcentaje / 100,
              minHeight: 10,
            ),
          ),
        ),
        const SizedBox(width: 10),
        Text(
          '$porcentaje %',
          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
        ),
      ],
    );
  }
}

String _plural(int cantidad, String singular, String plural) {
  return '$cantidad ${cantidad == 1 ? singular : plural}';
}

String formatearFecha(DateTime fecha) {
  final local = fecha.toLocal();
  String dos(int n) => n.toString().padLeft(2, '0');

  return '${dos(local.day)}/${dos(local.month)}/${local.year} '
      '${dos(local.hour)}:${dos(local.minute)}';
}
