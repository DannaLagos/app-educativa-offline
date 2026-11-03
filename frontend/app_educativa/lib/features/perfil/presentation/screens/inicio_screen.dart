import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../shared/widgets/boton_escuchar.dart';
import '../../../../shared/widgets/boton_grande.dart';
import '../../../../shared/widgets/fondo_divertido.dart';
import '../../../../shared/widgets/panel_jugador.dart';
import '../../../admin/presentation/screens/login_admin_screen.dart';
import '../../../mascota/domain/mascota.dart';
import '../../../mascota/presentation/mascota_scope.dart';
import '../../../mascota/presentation/widgets/selector_mascota.dart';
import '../../../mascota/presentation/widgets/escenario_mascota.dart';
import '../../../mascota/presentation/widgets/mascota_animada.dart';
import '../../../modulos/domain/area_resumen.dart';
import '../../../modulos/presentation/controllers/carga_al_mostrar.dart';
import '../../../modulos/presentation/controllers/modulos_controller.dart';
import '../../../modulos/presentation/controllers/modulos_scope.dart';
import '../../../modulos/presentation/screens/areas_screen.dart';
import '../../../modulos/presentation/screens/detalle_modulo_screen.dart';
import '../../../modulos/presentation/widgets/tarjeta_area.dart';
import '../../../progreso/presentation/progreso_scope.dart';
import '../../../sincronizacion/presentation/sincronizacion_scope.dart';
import '../../data/perfil_local_datasource.dart';
import '../../domain/perfil_estudiante.dart';

class InicioScreen extends StatefulWidget {
  final PerfilEstudiante perfil;
  final PerfilLocalDataSource? perfilLocalDataSource;

  const InicioScreen({
    super.key,
    required this.perfil,
    this.perfilLocalDataSource,
  });

  @override
  State<InicioScreen> createState() => _InicioScreenState();
}

class _InicioScreenState extends State<InicioScreen>
    with CargaAlMostrar<InicioScreen> {
  late MascotaElegida? _mascota = widget.perfil.mascotaElegida;

  @override
  Future<void> cargarAlMostrar(ModulosController controller) {
    return controller.cargarCatalogo();
  }

  Future<void> _elegirMascota() async {
    final elegida = await elegirMascota(context);

    if (elegida == null || !mounted) {
      return;
    }

    // Perfil antiguo: la mascota se llama como su especie.
    final mascota = MascotaElegida.de(elegida);
    setState(() => _mascota = mascota);
    MascotaScope.cambiar(context, mascota);

    try {
      await (widget.perfilLocalDataSource ?? PerfilLocalDataSource())
          .guardarMascota(widget.perfil.id, elegida);
    } catch (error, stack) {
      // Se sigue mostrando en esta sesión; se puede volver a elegir después.
      debugPrint('Error al guardar la mascota: $error\n$stack');
    }
  }

  /// Dos días o más sin jugar: la mascota se duerme esperándolo.
  static bool _llevaDiasSinJugar(DateTime? ultimaActividad) {
    return ultimaActividad != null &&
        DateTime.now().difference(ultimaActividad).inDays >= 2;
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
    // HU08: el módulo donde iba el estudiante (se lee del dispositivo).
    final progresos = ProgresoScope.maybeOf(context);
    final ultimoId = progresos?.ultimoModuloId;
    final ultimoModulo =
        ultimoId == null ? null : controller.buscarModulo(ultimoId);
    final mascota = _mascota;
    final nombre = widget.perfil.nombre;
    final botonJugar = BotonJugar(
      detalle: ultimoModulo == null
          ? 'Elige un mundo'
          : 'Sigue en: ${ultimoModulo.nombre}',
      onPressed: () => _abrir(
        ultimoModulo == null
            ? const AreasScreen()
            : DetalleModuloScreen(moduloId: ultimoModulo.id),
      ),
    );

    return Scaffold(
      body: FondoDivertido(
        child: SafeArea(
          child: RefreshIndicator(
            onRefresh: controller.cargarCatalogo,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
              children: [
                BarraJugador(
                  nombre: nombre,
                  mascota: mascota?.especie,
                  estrellas: progresos?.estrellasTotales ?? 0,
                  hayConexion: _hayConexion(controller, areas),
                  onAbrirAdmin: () => _abrir(const LoginAdminScreen()),
                ),
                const SizedBox(height: 16),
                if (mascota == null) ...[
                  _InvitacionMascota(onElegir: _elegirMascota),
                  const SizedBox(height: 16),
                  botonJugar,
                ] else
                  EscenarioMascota(
                    mascota: mascota,
                    dormida: _llevaDiasSinJugar(progresos?.ultimaActividad),
                    estrellas: progresos?.estrellasTotales,
                    saludo: '¡Hola, $nombre! ¿Jugamos?',
                    botonEscuchar: BotonEscuchar(
                      texto: '¡Hola, $nombre! ¿Jugamos? Toca el botón '
                          'amarillo para seguir jugando, o elige un mundo '
                          'de colores.',
                    ),
                    accion: botonJugar,
                  ),
                const SizedBox(height: 24),
                _EncabezadoAreas(
                  onVerTodas: () => _abrir(const AreasScreen()),
                ),
                const SizedBox(height: 8),
                _construirAreas(controller, areas),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// null mientras carga por primera vez (todavía no se sabe).
  bool? _hayConexion(ModulosController controller, List<AreaResumen> areas) {
    if (controller.estaCargando && areas.isEmpty) {
      return null;
    }

    // HU10: si está disponible, se usa el estado de la red en vivo.
    return SincronizacionScope.maybeOf(context)?.hayConexion ??
        !controller.vieneDeCache;
  }

  Widget _construirAreas(
      ModulosController controller, List<AreaResumen> areas) {
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

class _InvitacionMascota extends StatelessWidget {
  final VoidCallback onElegir;

  const _InvitacionMascota({required this.onElegir});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppTheme.morado,
        borderRadius: BorderRadius.circular(30),
        boxShadow: const [
          BoxShadow(color: Color(0xFF4A2BB0), offset: Offset(0, 7)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Las cinco mascotas se asoman para invitar al niño.
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              for (var i = 0; i < EspecieMascota.values.length; i++)
                MascotaAnimada(
                  especie: EspecieMascota.values[i],
                  etapa: EtapaMascota.bebe,
                  tamano: 58,
                  desfase: i / EspecieMascota.values.length,
                ),
            ],
          ),
          const SizedBox(height: 10),
          const Text(
            '¡Elige tu mascota!',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Crecerá con las estrellas que ganes en los juegos.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 16),
          BotonGrande(
            texto: 'Elegir mascota',
            icono: Icons.pets_rounded,
            color: AppTheme.rosa,
            onPressed: onElegir,
          ),
        ],
      ),
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
        const Icon(Icons.public_rounded, color: AppTheme.morado, size: 30),
        const SizedBox(width: 8),
        Expanded(
          child: Semantics(
            header: true,
            child: const Text(
              'Mis mundos',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800),
            ),
          ),
        ),
        TextButton(
          onPressed: onVerTodas,
          child: const Text('Ver todos'),
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
