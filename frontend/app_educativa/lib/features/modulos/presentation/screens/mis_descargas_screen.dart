import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../shared/widgets/aviso_resultado.dart';
import '../../../../shared/widgets/boton_grande.dart';
import '../../../../shared/widgets/mensaje_con_accion.dart';
import '../../domain/modulo.dart';
import '../controllers/carga_al_mostrar.dart';
import '../controllers/modulos_controller.dart';
import '../controllers/modulos_scope.dart';
import '../widgets/confirmar_eliminar_dialog.dart';
import 'areas_screen.dart';
import 'lector_modulo_screen.dart';

class MisDescargasScreen extends StatefulWidget {
  const MisDescargasScreen({super.key});

  @override
  State<MisDescargasScreen> createState() => _MisDescargasScreenState();
}

class _MisDescargasScreenState extends State<MisDescargasScreen>
    with CargaAlMostrar<MisDescargasScreen> {
  bool _estaCargando = true;

  @override
  Future<void> cargarAlMostrar(ModulosController controller) async {
    await controller.cargarDescargados();

    if (mounted) {
      setState(() => _estaCargando = false);
    }
  }

  void _abrir(Widget pantalla) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => pantalla),
    );
  }

  Future<void> _eliminar(Modulo modulo) async {
    final controller = ModulosScope.of(context);
    final mensajero = ScaffoldMessenger.of(context);

    final fueConfirmado = await ConfirmarEliminarDialog.mostrar(
      context,
      modulo.nombre,
    );

    if (!fueConfirmado) {
      return;
    }

    final fueEliminado = await controller.eliminarDescarga(modulo);

    mostrarAvisoResultado(
      mensajero,
      fueExitoso: fueEliminado,
      mensaje: fueEliminado
          ? 'Se eliminó "${modulo.nombre}" del dispositivo.'
          : 'No se pudo eliminar el módulo. Inténtalo de nuevo.',
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mis descargas'),
      ),
      body: SafeArea(
        child: _construirCuerpo(ModulosScope.of(context).descargados),
      ),
    );
  }

  Widget _construirCuerpo(List<Modulo> descargados) {
    if (_estaCargando) {
      return const Center(child: CircularProgressIndicator());
    }

    if (descargados.isEmpty) {
      return _construirSinDescargas();
    }

    return ListView(
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
            onAbrir: () => _abrir(LectorModuloScreen(modulo: modulo)),
            onEliminar: () => _eliminar(modulo),
          ),
      ],
    );
  }

  Widget _construirSinDescargas() {
    return MensajeConAccion(
      icono: const Icon(
        Icons.download_for_offline_outlined,
        color: AppTheme.gris,
      ),
      mensaje: 'Aún no tienes módulos descargados.',
      accion: BotonGrande(
        texto: 'Ver módulos',
        icono: Icons.menu_book_rounded,
        onPressed: () => _abrir(const AreasScreen()),
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
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.radio),
        side: const BorderSide(color: AppTheme.borde),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ..._construirEncabezado(),
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
              tieneContorno: true,
              onPressed: onEliminar,
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _construirEncabezado() {
    return [
      Text(
        modulo.nombre,
        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
      ),
      const SizedBox(height: 6),
      Text(
        modulo.areaYGrado,
        style: const TextStyle(
          fontSize: 16,
          color: AppTheme.textoSecundario,
        ),
      ),
      const SizedBox(height: 10),
      const _EtiquetaSinConexion(),
      if (modulo.tieneActualizacion) ...[
        const SizedBox(height: 10),
        const Text(
          'Hay una versión nueva. Búscala en Inicio para actualizarla.',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: AppTheme.azul,
          ),
        ),
      ],
    ];
  }
}

class _EtiquetaSinConexion extends StatelessWidget {
  const _EtiquetaSinConexion();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppTheme.verde,
        borderRadius: BorderRadius.circular(AppTheme.radioBoton),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.offline_pin_rounded, color: Colors.white, size: 20),
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
    );
  }
}
