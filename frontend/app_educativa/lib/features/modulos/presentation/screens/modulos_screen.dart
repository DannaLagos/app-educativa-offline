import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../shared/widgets/aviso_resultado.dart';
import '../../../../shared/widgets/boton_grande.dart';
import '../../../../shared/widgets/fondo_divertido.dart';
import '../../../../shared/widgets/mensaje_con_accion.dart';
import '../../domain/modulo.dart';
import '../controllers/carga_al_mostrar.dart';
import '../controllers/modulos_controller.dart';
import '../controllers/modulos_scope.dart';
import '../widgets/encabezado_mundo.dart';
import '../widgets/modulo_card.dart';
import 'detalle_modulo_screen.dart';

class ModulosScreen extends StatefulWidget {
  final String? area;

  const ModulosScreen({
    super.key,
    this.area,
  });

  @override
  State<ModulosScreen> createState() => _ModulosScreenState();
}

class _ModulosScreenState extends State<ModulosScreen>
    with CargaAlMostrar<ModulosScreen> {
  @override
  Future<void> cargarAlMostrar(ModulosController controller) {
    return controller.cargarCatalogo();
  }

  void _abrirModulo(Modulo modulo) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => DetalleModuloScreen(moduloId: modulo.id),
      ),
    );
  }

  Future<void> _descargar(Modulo modulo) async {
    final controller = ModulosScope.of(context);
    final mensajero = ScaffoldMessenger.of(context);

    final fueDescargado = await controller.descargar(modulo);
    final actualizado = controller.buscarModulo(modulo.id) ?? modulo;

    mostrarAvisoResultado(
      mensajero,
      fueExitoso: fueDescargado,
      mensaje: fueDescargado
          ? '"${modulo.nombre}" ya está disponible sin internet.'
          : controller.obtenerMensajeError(actualizado) ??
              'No se pudo descargar el módulo.',
    );
  }

  List<Modulo> _filtrarPorArea(List<Modulo> modulos) {
    final area = widget.area;

    if (area == null) {
      return modulos;
    }

    return modulos.where((modulo) => modulo.area == area).toList();
  }

  @override
  Widget build(BuildContext context) {
    final controller = ModulosScope.of(context);

    return Scaffold(
      appBar: AppBar(
        // El nombre del mundo ya está en el encabezado grande.
        title: Text(widget.area == null ? 'Módulos educativos' : ''),
        backgroundColor: Colors.transparent,
      ),
      extendBodyBehindAppBar: true,
      body: FondoDivertido(
        child: SafeArea(
          child: _construirCuerpo(
            controller,
            _filtrarPorArea(controller.catalogo),
          ),
        ),
      ),
    );
  }

  Widget _construirCuerpo(ModulosController controller, List<Modulo> modulos) {
    if (controller.estaCargando && modulos.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (modulos.isEmpty) {
      return _construirMensajeVacio(controller);
    }

    return RefreshIndicator(
      onRefresh: controller.cargarCatalogo,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        children: [
          ..._construirEncabezado(controller),
          for (final grupo in _agruparPorAreaYGrado(modulos).entries)
            ..._construirGrupo(controller, grupo),
        ],
      ),
    );
  }

  List<Widget> _construirEncabezado(ModulosController controller) {
    final area = widget.area;

    return [
      if (controller.vieneDeCache) ...[
        const _AvisoSinConexion(),
        const SizedBox(height: 20),
      ],
      if (area == null) ...[
        const Text(
          '¿Qué quieres aprender hoy?',
          style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 8),
        const Text(
          'Toca un módulo para ver su contenido.',
          style: TextStyle(fontSize: 18),
        ),
      ] else
        EncabezadoMundo(
          area: area,
          titulo: area,
          subtitulo: 'Toca un módulo para ver su contenido.',
        ),
    ];
  }

  List<Widget> _construirGrupo(
    ModulosController controller,
    MapEntry<String, List<Modulo>> grupo,
  ) {
    return [
      const SizedBox(height: 22),
      _TituloGrupo(grupo.key),
      const SizedBox(height: 12),
      for (final modulo in grupo.value)
        ModuloCard(
          modulo: modulo,
          estado: controller.obtenerEstado(modulo),
          progreso: controller.obtenerProgreso(modulo.id),
          onTap: () => _abrirModulo(modulo),
          onDescargar: () => _descargar(modulo),
        ),
    ];
  }

  Map<String, List<Modulo>> _agruparPorAreaYGrado(List<Modulo> modulos) {
    final grupos = <String, List<Modulo>>{};

    for (final modulo in modulos) {
      grupos.putIfAbsent(modulo.areaYGrado, () => []).add(modulo);
    }

    return grupos;
  }

  Widget _construirMensajeVacio(ModulosController controller) {
    return MensajeConAccion(
      icono: const Icon(Icons.cloud_off_rounded, color: AppTheme.gris),
      mensaje: _elegirMensajeVacio(controller),
      accion: BotonGrande(
        texto: 'Intentar de nuevo',
        icono: Icons.refresh_rounded,
        onPressed: controller.cargarCatalogo,
      ),
    );
  }

  String _elegirMensajeVacio(ModulosController controller) {
    if (controller.huboErrorAlCargar) {
      return 'No fue posible cargar los módulos.';
    }
    if (controller.vieneDeCache) {
      return 'No tienes internet. Conéctate una vez para ver los módulos.';
    }

    return 'No hay módulos disponibles.';
  }
}

class _TituloGrupo extends StatelessWidget {
  final String texto;

  const _TituloGrupo(this.texto);

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

class _AvisoSinConexion extends StatelessWidget {
  const _AvisoSinConexion();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.gris,
        borderRadius: BorderRadius.circular(AppTheme.radio),
      ),
      child: const Row(
        children: [
          Icon(Icons.wifi_off_rounded, color: Colors.white, size: 30),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              'Sin internet. Estás viendo los módulos guardados.',
              style: TextStyle(
                color: Colors.white,
                fontSize: 17,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
