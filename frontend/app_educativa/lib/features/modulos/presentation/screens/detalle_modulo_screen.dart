import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../shared/widgets/aviso_resultado.dart';
import '../../../../shared/widgets/boton_grande.dart';
import '../../../../shared/widgets/fondo_divertido.dart';
import '../../../../shared/widgets/panel_jugador.dart';
import '../../../actividades/presentation/screens/mapa_niveles_screen.dart';
import '../../../progreso/domain/progreso_modulo.dart';
import '../../../progreso/presentation/progreso_scope.dart';
import '../../domain/estado_descarga.dart';
import '../../domain/modulo.dart';
import '../controllers/modulos_controller.dart';
import '../controllers/modulos_scope.dart';
import '../widgets/encabezado_mundo.dart';
import '../widgets/estado_descarga_chip.dart';
import '../widgets/marcador_avance.dart';
import 'lector_modulo_screen.dart';

class DetalleModuloScreen extends StatefulWidget {
  final String moduloId;

  const DetalleModuloScreen({
    super.key,
    required this.moduloId,
  });

  @override
  State<DetalleModuloScreen> createState() => _DetalleModuloScreenState();
}

class _DetalleModuloScreenState extends State<DetalleModuloScreen> {
  bool _progresoSolicitado = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    // HU08: se lee el avance guardado en el dispositivo (sin internet).
    if (!_progresoSolicitado) {
      _progresoSolicitado = true;
      ProgresoScope.leer(context)?.cargarProgreso(widget.moduloId);
    }
  }

  @override
  Widget build(BuildContext context) {
    final controller = ModulosScope.of(context);
    final modulo = controller.buscarModulo(widget.moduloId);
    final progreso =
        ProgresoScope.maybeOf(context)?.progresoDe(widget.moduloId);

    if (modulo == null) {
      return const _ModuloNoDisponible();
    }

    return Scaffold(
      // El nombre del módulo ya está en el encabezado grande.
      appBar: AppBar(backgroundColor: Colors.transparent),
      extendBodyBehindAppBar: true,
      body: FondoDivertido(
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
            child: _ContenidoDetalle(
              modulo: modulo,
              controller: controller,
              progreso: progreso,
            ),
          ),
        ),
      ),
    );
  }
}

class _ModuloNoDisponible extends StatelessWidget {
  const _ModuloNoDisponible();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: const Center(
        child: Text(
          'Este módulo ya no está disponible.',
          style: TextStyle(fontSize: 20),
        ),
      ),
    );
  }
}

class _ContenidoDetalle extends StatelessWidget {
  final Modulo modulo;
  final ModulosController controller;
  final ProgresoModulo? progreso;

  const _ContenidoDetalle({
    required this.modulo,
    required this.controller,
    required this.progreso,
  });

  bool get _debeMostrarFechaDescarga =>
      modulo.fechaDescarga != null &&
      controller.obtenerEstado(modulo) == EstadoDescarga.descargado;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        EncabezadoMundo(
          area: modulo.area,
          titulo: modulo.nombre,
          etiquetas: [modulo.area, 'Grado ${modulo.grado}'],
        ),
        const SizedBox(height: 20),
        _Panel(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _SeccionDescarga(
                modulo: modulo,
                controller: controller,
                progreso: progreso,
              ),
              if (_debeMostrarFechaDescarga) ...[
                const SizedBox(height: 8),
                _FechaDescarga(fecha: modulo.fechaDescarga!),
              ],
            ],
          ),
        ),
        const SizedBox(height: 20),
        _Panel(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const _Titulo('Descripción', icono: Icons.info_rounded),
              const SizedBox(height: 10),
              Text(
                modulo.descripcion,
                style: const TextStyle(fontSize: 18, height: 1.5),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        _Panel(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const _Titulo('Contenidos', icono: Icons.auto_stories_rounded),
              const SizedBox(height: 12),
              _ListaContenidos(contenidos: modulo.contenidos),
            ],
          ),
        ),
      ],
    );
  }
}

class _FechaDescarga extends StatelessWidget {
  final DateTime fecha;

  const _FechaDescarga({required this.fecha});

  static String _formatear(DateTime fecha) {
    String completarDosDigitos(int valor) => valor.toString().padLeft(2, '0');

    return '${completarDosDigitos(fecha.day)}/'
        '${completarDosDigitos(fecha.month)}/${fecha.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Text(
      'Descargado el ${_formatear(fecha)}',
      style: const TextStyle(
        fontSize: 16,
        color: AppTheme.textoSecundario,
      ),
    );
  }
}

class _SeccionDescarga extends StatelessWidget {
  final Modulo modulo;
  final ModulosController controller;
  final ProgresoModulo? progreso;

  const _SeccionDescarga({
    required this.modulo,
    required this.controller,
    required this.progreso,
  });

  /// El documento que el estudiante leyó por última vez.
  ProgresoLectura? get _ultimaLectura {
    final lecturas = progreso?.lecturas ?? const <ProgresoLectura>[];

    if (lecturas.isEmpty) {
      return null;
    }

    return lecturas.reduce(
      (a, b) => a.ultimaActualizacion.isAfter(b.ultimaActualizacion) ? a : b,
    );
  }

  Future<void> _descargar(BuildContext context) async {
    final mensajero = ScaffoldMessenger.of(context);
    final fueDescargado = await controller.descargar(modulo);

    if (!fueDescargado) {
      return;
    }

    mostrarAvisoResultado(
      mensajero,
      fueExitoso: true,
      mensaje: '¡Listo! Ya puedes usar este módulo sin internet.',
    );
  }

  void _abrirLector(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => LectorModuloScreen(modulo: modulo),
      ),
    );
  }

  void _abrirJuegos(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => MapaNivelesScreen(modulo: modulo),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final estado = controller.obtenerEstado(modulo);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        EstadoDescargaChip(
          estado: estado,
          progreso: controller.obtenerProgreso(modulo.id),
          esGrande: true,
        ),
        const SizedBox(height: 16),
        ..._construirAcciones(context, estado),
      ],
    );
  }

  List<Widget> _construirAcciones(BuildContext context, EstadoDescarga estado) {
    switch (estado) {
      case EstadoDescarga.noDescargado:
        return [
          BotonGrande(
            texto: 'Descargar',
            icono: Icons.download_rounded,
            color: AppTheme.naranja,
            onPressed: () => _descargar(context),
          ),
        ];
      case EstadoDescarga.descargando:
        return const [
          Text(
            'Espera un momento, estamos guardando el módulo.',
            style: TextStyle(fontSize: 18),
          ),
        ];
      case EstadoDescarga.error:
        return _construirAccionesDeError(context);
      case EstadoDescarga.descargado:
        return _construirAccionesDeDescargado(context);
    }
  }

  List<Widget> _construirAccionesDeError(BuildContext context) {
    return [
      _Aviso.error(controller.obtenerMensajeError(modulo) ?? ''),
      const SizedBox(height: 16),
      BotonGrande(
        texto: 'Reintentar',
        icono: Icons.refresh_rounded,
        onPressed: () => _descargar(context),
      ),
    ];
  }

  List<Widget> _construirAccionesDeDescargado(BuildContext context) {
    final mensajeError = controller.obtenerMensajeError(modulo);

    return [
      if (mensajeError != null) ...[
        _Aviso.error(mensajeError),
        const SizedBox(height: 16),
      ],
      if (modulo.tieneActualizacion)
        ..._construirOfertaDeActualizacion(context),
      if (progreso?.estaIniciado ?? false) ...[
        MarcadorAvance(
          progreso: progreso!,
          ultimaLectura: _ultimaLectura,
          onJugar: () => _abrirJuegos(context),
          onLeer: () => _abrirLector(context),
        ),
        const SizedBox(height: 20),
      ],
      BotonJugar(
        texto: (progreso?.actividadesCompletadas ?? 0) > 0
            ? 'Seguir jugando'
            : 'Jugar y aprender',
        detalle: 'Juegos y niveles del módulo',
        onPressed: () => _abrirJuegos(context),
      ),
      const SizedBox(height: 12),
      BotonGrande(
        // HU08: el lector abre en la página donde quedó.
        texto: _ultimaLectura == null
            ? 'Abrir módulo'
            : 'Seguir leyendo (página ${_ultimaLectura!.ultimaPagina})',
        icono: Icons.menu_book_rounded,
        color: AppTheme.verde,
        onPressed: () => _abrirLector(context),
      ),
      const SizedBox(height: 8),
      const Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.check_circle_rounded, color: AppTheme.verde),
          SizedBox(width: 6),
          Flexible(
            child: Text(
              'Disponible sin conexión.',
              style: TextStyle(
                fontSize: 18,
                color: AppTheme.verde,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    ];
  }

  List<Widget> _construirOfertaDeActualizacion(BuildContext context) {
    return [
      const _Aviso.informacion(
        'Hay una versión nueva de este módulo. '
        'Actualízalo cuando tengas internet.',
      ),
      const SizedBox(height: 16),
      BotonGrande(
        texto: 'Actualizar',
        icono: Icons.system_update_rounded,
        onPressed: () => _descargar(context),
      ),
      const SizedBox(height: 12),
    ];
  }
}

class _Aviso extends StatelessWidget {
  final String texto;
  final Color color;
  final Color fondo;

  const _Aviso.error(this.texto)
      : color = AppTheme.rojo,
        fondo = AppTheme.rojoSuave;

  const _Aviso.informacion(this.texto)
      : color = AppTheme.azul,
        fondo = AppTheme.azulSuave;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: fondo,
        border: Border.all(color: color, width: 2),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Text(
        texto,
        style: TextStyle(
          fontSize: 18,
          color: color,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _Titulo extends StatelessWidget {
  final String texto;
  final IconData icono;

  const _Titulo(this.texto, {required this.icono});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      header: true,
      child: Row(
        children: [
          Icon(icono, color: AppTheme.morado, size: 28),
          const SizedBox(width: 8),
          Text(
            texto,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

/// Tarjeta blanca redondeada: se lee bien sobre el paisaje.
class _Panel extends StatelessWidget {
  final Widget child;

  const _Panel({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppTheme.superficie,
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: AppTheme.borde, width: 2),
        boxShadow: const [
          BoxShadow(color: AppTheme.borde, offset: Offset(0, 5)),
        ],
      ),
      child: child,
    );
  }
}

class _ListaContenidos extends StatelessWidget {
  final List<String> contenidos;

  const _ListaContenidos({required this.contenidos});

  @override
  Widget build(BuildContext context) {
    if (contenidos.isEmpty) {
      return const Text(
        'Este módulo aún no tiene contenidos.',
        style: TextStyle(fontSize: 18),
      );
    }

    return Column(
      children: [
        for (var indice = 0; indice < contenidos.length; indice++)
          _ElementoContenido(numero: indice + 1, titulo: contenidos[indice]),
      ],
    );
  }
}

class _ElementoContenido extends StatelessWidget {
  static const List<Color> _colores = [
    AppTheme.azul,
    AppTheme.naranja,
    AppTheme.morado,
    AppTheme.verde,
    AppTheme.rosa,
  ];

  final int numero;
  final String titulo;

  const _ElementoContenido({
    required this.numero,
    required this.titulo,
  });

  @override
  Widget build(BuildContext context) {
    final color = _colores[(numero - 1) % _colores.length];

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Color.lerp(color, Colors.white, 0.88),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            alignment: Alignment.center,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            child: Text(
              '$numero',
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              titulo,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }
}
