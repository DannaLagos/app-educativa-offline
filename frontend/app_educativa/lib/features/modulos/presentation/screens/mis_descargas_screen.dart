import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../shared/widgets/aviso_resultado.dart';
import '../../../../shared/widgets/boton_grande.dart';
import '../../../../shared/widgets/dibujo.dart';
import '../../../../shared/widgets/fondo_divertido.dart';
import '../../domain/modulo.dart';
import '../controllers/carga_al_mostrar.dart';
import '../controllers/modulos_controller.dart';
import '../controllers/modulos_scope.dart';
import '../widgets/confirmar_eliminar_dialog.dart';
import '../widgets/encabezado_mundo.dart';
import '../widgets/icono_area.dart';
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
      body: FondoDivertido(
        child: SafeArea(
          child: _construirCuerpo(ModulosScope.of(context).descargados),
        ),
      ),
    );
  }

  Widget _construirCuerpo(List<Modulo> descargados) {
    if (_estaCargando) {
      return const Center(child: CircularProgressIndicator());
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      children: [
        // La mochila: lo que el niño lleva consigo para usar sin internet.
        const EncabezadoMundo(
          area: '',
          titulo: 'Mis descargas',
          subtitulo: 'Tus módulos guardados. Funcionan sin internet.',
          color: AppTheme.turquesa,
          emoji: '🎒',
        ),
        const SizedBox(height: 20),
        if (descargados.isEmpty) _construirSinDescargas(),
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
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.superficie,
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: AppTheme.borde, width: 2),
        boxShadow: const [
          BoxShadow(color: AppTheme.borde, offset: Offset(0, 5)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Dibujo('📦', tamano: 90),
          const SizedBox(height: 10),
          const Text(
            'Aún no tienes módulos descargados.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 16),
          BotonGrande(
            texto: 'Ver módulos',
            icono: Icons.menu_book_rounded,
            color: AppTheme.naranja,
            onPressed: () => _abrir(const AreasScreen()),
          ),
        ],
      ),
    );
  }
}

class _TarjetaDescarga extends StatelessWidget {
  static const double _relieve = 5;

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
    final apariencia = AparienciaArea.de(modulo.area);

    return Container(
      margin: const EdgeInsets.only(bottom: 14 + _relieve),
      padding: const EdgeInsets.all(14),
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
            offset: const Offset(0, _relieve),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 76,
                height: 76,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: apariencia.color,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Dibujo(apariencia.emoji, tamano: 48),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      modulo.nombre,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      modulo.areaYGrado,
                      style: const TextStyle(
                        fontSize: 15,
                        color: AppTheme.textoSecundario,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const _EtiquetaSinConexion(),
                  ],
                ),
              ),
            ],
          ),
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
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: BotonGrande(
                  texto: 'Abrir',
                  icono: Icons.menu_book_rounded,
                  color: AppTheme.verde,
                  onPressed: onAbrir,
                ),
              ),
              const SizedBox(width: 10),
              // Compacto: eliminar es la acción menos importante.
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: OutlinedButton.icon(
                  onPressed: onEliminar,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppTheme.rojo,
                    minimumSize: const Size(0, 64),
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    side: const BorderSide(color: AppTheme.rojo, width: 3),
                    textStyle: const TextStyle(
                      fontFamily: AppTheme.fuente,
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  icon: const Icon(Icons.delete_outline_rounded, size: 26),
                  label: const Text('Eliminar'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
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
          // En pantallas angostas o con letra grande baja a otra línea.
          Flexible(
            child: Text(
              'Disponible sin conexión',
              style: TextStyle(
                color: Colors.white,
                fontSize: 15,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
