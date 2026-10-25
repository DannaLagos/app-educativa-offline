import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../shared/widgets/boton_grande.dart';
import '../../../../shared/widgets/etiqueta.dart';
import '../../../admin/presentation/screens/login_admin_screen.dart';
import '../../../modulos/domain/area_resumen.dart';
import '../../../modulos/presentation/controllers/carga_al_mostrar.dart';
import '../../../modulos/presentation/controllers/modulos_controller.dart';
import '../../../modulos/presentation/controllers/modulos_scope.dart';
import '../../../modulos/presentation/screens/areas_screen.dart';
import '../../../modulos/presentation/widgets/tarjeta_area.dart';
import '../../domain/perfil_estudiante.dart';

class InicioScreen extends StatefulWidget {
  final PerfilEstudiante perfil;

  const InicioScreen({
    super.key,
    required this.perfil,
  });

  @override
  State<InicioScreen> createState() => _InicioScreenState();
}

class _InicioScreenState extends State<InicioScreen>
    with CargaAlMostrar<InicioScreen> {
  @override
  Future<void> cargarAlMostrar(ModulosController controller) {
    return controller.cargarCatalogo();
  }

  void _abrir(Widget pantalla) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => pantalla),
    );
  }

  @override
  Widget build(BuildContext context) {
    final controller = ModulosScope.of(context);
    final areas = AreaResumen.agrupar(controller.catalogo);

    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: controller.cargarCatalogo,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
            children: [
              _Saludo(
                nombre: widget.perfil.nombre,
                estadoConexion: _construirEstadoConexion(controller, areas),
                onAbrirAdmin: () => _abrir(const LoginAdminScreen()),
              ),
              const SizedBox(height: 24),
              _TarjetaContinuar(
                onContinuar: () => _abrir(const AreasScreen()),
              ),
              const SizedBox(height: 24),
              _EncabezadoAreas(
                onVerTodas: () => _abrir(const AreasScreen()),
              ),
              const SizedBox(height: 8),
              _construirAreas(controller, areas),
              const SizedBox(height: 16),
              const _TarjetaMotivacion(),
            ],
          ),
        ),
      ),
    );
  }

  Widget? _construirEstadoConexion(
    ModulosController controller,
    List<AreaResumen> areas,
  ) {
    if (controller.estaCargando && areas.isEmpty) {
      return null;
    }

    if (controller.vieneDeCache) {
      return const Etiqueta.gris('Sin conexión', icono: Icons.wifi_off_rounded);
    }

    return const Etiqueta(
      texto: 'Conectado',
      color: AppTheme.verde,
      fondo: AppTheme.verdeSuave,
      icono: Icons.wifi_rounded,
    );
  }

  Widget _construirAreas(ModulosController controller, List<AreaResumen> areas) {
    if (controller.estaCargando && areas.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(32),
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (areas.isEmpty) {
      return _SinAreas(onReintentar: controller.cargarCatalogo);
    }

    return _CuadriculaAreas(areas: areas);
  }
}

class _Saludo extends StatelessWidget {
  final String nombre;
  final Widget? estadoConexion;
  final VoidCallback onAbrirAdmin;

  const _Saludo({
    required this.nombre,
    required this.estadoConexion,
    required this.onAbrirAdmin,
  });

  @override
  Widget build(BuildContext context) {
    final estado = estadoConexion;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '¡Hola, $nombre! 👋',
                style: const TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 8),
              if (estado != null) estado,
            ],
          ),
        ),
        IconButton(
          tooltip: 'Acceso administrador',
          iconSize: 28,
          icon: const Icon(Icons.admin_panel_settings_outlined),
          onPressed: onAbrirAdmin,
        ),
      ],
    );
  }
}

class _EncabezadoAreas extends StatelessWidget {
  final VoidCallback onVerTodas;

  const _EncabezadoAreas({required this.onVerTodas});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Semantics(
            header: true,
            child: const Text(
              'Tus áreas educativas',
              style: TextStyle(fontSize: 21, fontWeight: FontWeight.w800),
            ),
          ),
        ),
        TextButton(
          onPressed: onVerTodas,
          child: const Text('Ver todas'),
        ),
      ],
    );
  }
}

class _CuadriculaAreas extends StatelessWidget {
  static const int _areasPorFila = 2;

  final List<AreaResumen> areas;

  const _CuadriculaAreas({required this.areas});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (var indice = 0; indice < areas.length; indice += _areasPorFila)
          _construirFila(indice),
      ],
    );
  }

  Widget _construirFila(int indicePrimera) {
    final indiceSegunda = indicePrimera + 1;
    final haySegunda = indiceSegunda < areas.length;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: TarjetaArea(area: areas[indicePrimera], esCompacta: true),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: haySegunda
                  ? TarjetaArea(area: areas[indiceSegunda], esCompacta: true)
                  : const SizedBox.shrink(),
            ),
          ],
        ),
      ),
    );
  }
}

class _SinAreas extends StatelessWidget {
  final Future<void> Function() onReintentar;

  const _SinAreas({required this.onReintentar});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const Icon(
              Icons.cloud_off_rounded,
              size: 56,
              color: AppTheme.gris,
            ),
            const SizedBox(height: 12),
            const Text(
              'Conéctate a internet una vez para ver los módulos.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 18),
            ),
            const SizedBox(height: 16),
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

class _TarjetaContinuar extends StatelessWidget {
  static const Color _colorSombra = Color(0x0A1F2A44);

  final VoidCallback onContinuar;

  const _TarjetaContinuar({required this.onContinuar});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.superficie,
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(
            color: _colorSombra,
            blurRadius: 18,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Etiqueta.azul('APRENDIZAJE'),
          const SizedBox(height: 16),
          const Text(
            'Continúa aprendiendo',
            style: TextStyle(
              color: AppTheme.texto,
              fontSize: 22,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            '¿Qué quieres aprender hoy?',
            style: TextStyle(color: AppTheme.textoSecundario, fontSize: 17),
          ),
          const SizedBox(height: 20),
          BotonGrande(
            texto: 'Continuar aprendiendo',
            icono: Icons.play_arrow_rounded,
            onPressed: onContinuar,
          ),
        ],
      ),
    );
  }
}

class _TarjetaMotivacion extends StatelessWidget {
  const _TarjetaMotivacion();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppTheme.azulSuave,
        borderRadius: BorderRadius.circular(18),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '⭐ ¡Sigue aprendiendo!',
            style: TextStyle(
              color: AppTheme.texto,
              fontSize: 17,
              fontWeight: FontWeight.w800,
            ),
          ),
          SizedBox(height: 6),
          Text(
            'Cada módulo completado te ayuda a avanzar.',
            style: TextStyle(color: AppTheme.textoSecundario, fontSize: 15),
          ),
        ],
      ),
    );
  }
}
