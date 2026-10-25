import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/etiqueta.dart';
import '../../../admin/presentation/screens/login_admin_screen.dart';
import '../../../modulos/domain/area_resumen.dart';
import '../../../modulos/presentation/controllers/modulos_scope.dart';
import '../../../modulos/presentation/screens/areas_screen.dart';
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

class _InicioScreenState extends State<InicioScreen> {
  bool _cargaIniciada = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    if (!_cargaIniciada) {
      _cargaIniciada = true;
      final controller = ModulosScope.of(context);
      WidgetsBinding.instance.addPostFrameCallback(
        (_) => controller.cargarCatalogo(),
      );
    }
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
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '¡Hola, ${widget.perfil.nombre}! 👋',
                          style: const TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 8),
                        if (!controller.cargando || areas.isNotEmpty)
                          controller.desdeCache
                              ? const Etiqueta.gris(
                                  'Sin conexión',
                                  icono: Icons.wifi_off_rounded,
                                )
                              : const Etiqueta(
                                  texto: 'Conectado',
                                  color: AppTheme.verde,
                                  fondo: AppTheme.verdeSuave,
                                  icono: Icons.wifi_rounded,
                                ),
                      ],
                    ),
                  ),
                  IconButton(
                    tooltip: 'Acceso administrador',
                    iconSize: 28,
                    icon: const Icon(Icons.admin_panel_settings_outlined),
                    onPressed: () => _abrir(const LoginAdminScreen()),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              // Tarjeta "Continúa aprendiendo" (diseño de Karen).
              _TarjetaContinuar(
                onContinuar: () => _abrir(const AreasScreen()),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: Semantics(
                      header: true,
                      child: const Text(
                        'Tus áreas educativas',
                        style: TextStyle(
                          fontSize: 21,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: () => _abrir(const AreasScreen()),
                    child: const Text('Ver todas'),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              if (controller.cargando && areas.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(32),
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (areas.isEmpty)
                _SinAreas(onReintentar: controller.cargarCatalogo)
              else
                _CuadriculaAreas(areas: areas),
              const SizedBox(height: 16),
              // Mensaje motivacional (diseño de Karen).
              const _TarjetaMotivacion(),
            ],
          ),
        ),
      ),
    );
  }
}

class _CuadriculaAreas extends StatelessWidget {
  final List<AreaResumen> areas;

  const _CuadriculaAreas({required this.areas});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (var i = 0; i < areas.length; i += 2)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(
                    child: TarjetaArea(area: areas[i], compacta: true),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: i + 1 < areas.length
                        ? TarjetaArea(area: areas[i + 1], compacta: true)
                        : const SizedBox.shrink(),
                  ),
                ],
              ),
            ),
          ),
      ],
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
            color: Color(0x0A1F2A44),
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
            style: TextStyle(
              color: AppTheme.textoSecundario,
              fontSize: 17,
            ),
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
            style: TextStyle(
              color: AppTheme.textoSecundario,
              fontSize: 15,
            ),
          ),
        ],
      ),
    );
  }
}