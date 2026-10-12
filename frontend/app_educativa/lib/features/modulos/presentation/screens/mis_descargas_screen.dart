import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../domain/modulo.dart';
import '../controllers/modulos_scope.dart';
import '../widgets/confirmar_eliminar_dialog.dart';
import 'lector_modulo_screen.dart';
import 'modulos_screen.dart';

class MisDescargasScreen extends StatefulWidget {
  const MisDescargasScreen({super.key});

  @override
  State<MisDescargasScreen> createState() => _MisDescargasScreenState();
}

class _MisDescargasScreenState extends State<MisDescargasScreen> {
  bool _cargaIniciada = false;
  bool _cargando = true;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    if (!_cargaIniciada) {
      _cargaIniciada = true;
      final controller = ModulosScope.of(context);
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        await controller.cargarDescargados();
        if (mounted) {
          setState(() => _cargando = false);
        }
      });
    }
  }

  void _abrir(Modulo modulo) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => LectorModuloScreen(modulo: modulo),
      ),
    );
  }

  Future<void> _eliminar(Modulo modulo) async {
    final controller = ModulosScope.of(context);
    final mensajero = ScaffoldMessenger.of(context);

    final confirmado = await ConfirmarEliminarDialog.mostrar(
      context,
      modulo.nombre,
    );

    if (!confirmado) {
      return;
    }

    final exito = await controller.eliminarDescarga(modulo);

    mensajero.showSnackBar(
      SnackBar(
        backgroundColor: exito ? AppTheme.verde : AppTheme.rojo,
        content: Text(
          exito
              ? 'Se eliminó "${modulo.nombre}" del dispositivo.'
              : 'No se pudo eliminar el módulo. Inténtalo de nuevo.',
          style: const TextStyle(fontSize: 18),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final descargados = ModulosScope.of(context).descargados;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mis descargas'),
      ),
      body: SafeArea(
        child: _cargando
            ? const Center(child: CircularProgressIndicator())
            : descargados.isEmpty
                ? _SinDescargas(
                    onVerModulos: () => Navigator.of(context).pushReplacement(
                      MaterialPageRoute(
                        builder: (_) => const ModulosScreen(),
                      ),
                    ),
                  )
                : ListView(
                    padding: const EdgeInsets.all(20),
                    children: [
                      const Text(
                        'Estos módulos están guardados en tu dispositivo. '
                        'Puedes usarlos sin internet.',
                        style: TextStyle(fontSize: 18),
                      ),
                      const SizedBox(height: 20),
                      for (final modulo in descargados)
                        _TarjetaDescarga(
                          modulo: modulo,
                          onAbrir: () => _abrir(modulo),
                          onEliminar: () => _eliminar(modulo),
                        ),
                    ],
                  ),
      ),
    );
  }
}

class _TarjetaDescarga extends StatelessWidget {
  final Modulo modulo;
  final VoidCallback onAbrir;
  final VoidCallback onEliminar;

  const _TarjetaDescarga({
    required this.modulo,
    required this.onAbrir,
    required this.onEliminar,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: Color(0xFF90A4AE)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              modulo.nombre,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              '${modulo.area} · Grado ${modulo.grado}',
              style: const TextStyle(
                fontSize: 16,
                color: AppTheme.textoSecundario,
              ),
            ),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 10,
                vertical: 6,
              ),
              decoration: BoxDecoration(
                color: AppTheme.verde,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.offline_pin_rounded,
                    color: Colors.white,
                    size: 20,
                  ),
                  SizedBox(width: 6),
                  Text(
                    'Disponible sin conexión',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            if (modulo.tieneActualizacion) ...[
              const SizedBox(height: 10),
              const Text(
                'Hay una versión nueva. Actualízala desde Módulos educativos.',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.azul,
                ),
              ),
            ],
            const SizedBox(height: 16),
            BotonGrande(
              texto: 'Abrir',
              icono: Icons.menu_book_rounded,
              color: AppTheme.verde,
              onPressed: onAbrir,
            ),
            const SizedBox(height: 10),
            BotonGrande(
              texto: 'Eliminar',
              icono: Icons.delete_outline_rounded,
              color: AppTheme.rojo,
              contorno: true,
              onPressed: onEliminar,
            ),
          ],
        ),
      ),
    );
  }
}

class _SinDescargas extends StatelessWidget {
  final VoidCallback onVerModulos;

  const _SinDescargas({required this.onVerModulos});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.download_for_offline_outlined,
              size: 72,
              color: AppTheme.gris,
            ),
            const SizedBox(height: 16),
            const Text(
              'Aún no tienes módulos descargados.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 20),
            ),
            const SizedBox(height: 24),
            BotonGrande(
              texto: 'Ver módulos',
              icono: Icons.menu_book_rounded,
              onPressed: onVerModulos,
            ),
          ],
        ),
      ),
    );
  }
}
