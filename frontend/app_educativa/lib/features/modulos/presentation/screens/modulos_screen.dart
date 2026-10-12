import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../domain/modulo.dart';
import '../controllers/modulos_scope.dart';
import '../widgets/modulo_card.dart';
import 'detalle_modulo_screen.dart';

class ModulosScreen extends StatefulWidget {
  const ModulosScreen({super.key});

  @override
  State<ModulosScreen> createState() => _ModulosScreenState();
}

class _ModulosScreenState extends State<ModulosScreen> {
  bool _cargaIniciada = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    if (!_cargaIniciada) {
      _cargaIniciada = true;
      // Se agenda para después del build porque cargar notifica cambios.
      final controller = ModulosScope.of(context);
      WidgetsBinding.instance.addPostFrameCallback(
        (_) => controller.cargarCatalogo(),
      );
    }
  }

  void _abrirModulo(Modulo modulo) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => DetalleModuloScreen(
          moduloId: modulo.id,
        ),
      ),
    );
  }

  /// Agrupa los módulos (ya ordenados por área y grado) en secciones.
  Map<String, List<Modulo>> _agruparPorAreaYGrado(List<Modulo> modulos) {
    final grupos = <String, List<Modulo>>{};

    for (final modulo in modulos) {
      grupos
          .putIfAbsent(
            '${modulo.area} · Grado ${modulo.grado}',
            () => [],
          )
          .add(modulo);
    }

    return grupos;
  }

  @override
  Widget build(BuildContext context) {
    final controller = ModulosScope.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Módulos educativos'),
      ),
      body: SafeArea(
        child: _construirCuerpo(controller.catalogo),
      ),
    );
  }

  Widget _construirCuerpo(List<Modulo> modulos) {
    final controller = ModulosScope.of(context);

    if (controller.cargando && modulos.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (modulos.isEmpty) {
      return _MensajeVacio(
        mensaje: controller.errorCarga
            ? 'No fue posible cargar los módulos.'
            : controller.desdeCache
                ? 'No tienes internet. Conéctate una vez para ver los módulos.'
                : 'No hay módulos disponibles.',
        onReintentar: controller.cargarCatalogo,
      );
    }

    final grupos = _agruparPorAreaYGrado(modulos);

    return RefreshIndicator(
      onRefresh: controller.cargarCatalogo,
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          if (controller.desdeCache) ...[
            const _AvisoSinConexion(),
            const SizedBox(height: 20),
          ],
          const Text(
            '¿Qué quieres aprender hoy?',
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Toca un módulo para ver su contenido.',
            style: TextStyle(fontSize: 18),
          ),
          for (final grupo in grupos.entries) ...[
            const SizedBox(height: 24),
            Semantics(
              header: true,
              child: Text(
                grupo.key,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.azul,
                ),
              ),
            ),
            const SizedBox(height: 12),
            for (final modulo in grupo.value)
              ModuloCard(
                modulo: modulo,
                estado: modulo.estadoDescarga,
                onTap: () => _abrirModulo(modulo),
              ),
          ],
        ],
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
        borderRadius: BorderRadius.circular(16),
      ),
      child: const Row(
        children: [
          Icon(
            Icons.wifi_off_rounded,
            color: Colors.white,
            size: 30,
          ),
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

class _MensajeVacio extends StatelessWidget {
  final String mensaje;
  final Future<void> Function() onReintentar;

  const _MensajeVacio({
    required this.mensaje,
    required this.onReintentar,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.cloud_off_rounded,
              size: 72,
              color: AppTheme.gris,
            ),
            const SizedBox(height: 16),
            Text(
              mensaje,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 20),
            ),
            const SizedBox(height: 24),
            BotonGrande(
              texto: 'Intentar de nuevo',
              icono: Icons.refresh_rounded,
              onPressed: onReintentar,
            ),
          ],
        ),
      ),
    );
  }
}
