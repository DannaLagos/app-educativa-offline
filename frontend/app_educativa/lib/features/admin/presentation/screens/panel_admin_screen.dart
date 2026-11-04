import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../shared/widgets/fondo_divertido.dart';
import '../../../modulos/presentation/widgets/encabezado_mundo.dart';
import '../../../perfil/data/perfil_local_datasource.dart';
import '../../../perfil/domain/perfil_estudiante.dart';
import '../../data/autenticacion_admin.dart';
import '../../data/catalogo_admin.dart';
import '../../data/uso_app_datasource.dart';
import '../../domain/sesion_admin.dart';
import 'gestion_contenidos_screen.dart';
import 'uso_app_screen.dart';

class PanelAdminScreen extends StatefulWidget {
  final AutenticacionAdmin autenticacion;
  final PerfilLocalDataSource? perfilLocalDataSource;
  final CatalogoAdmin? catalogoAdmin;
  final UsoAppDataSource? usoAppDataSource;

  const PanelAdminScreen({
    super.key,
    required this.autenticacion,
    this.perfilLocalDataSource,
    this.catalogoAdmin,
    this.usoAppDataSource,
  });

  @override
  State<PanelAdminScreen> createState() => _PanelAdminScreenState();
}

class _PanelAdminScreenState extends State<PanelAdminScreen> {
  late final Future<PerfilEstudiante?> _perfilFuture =
      (widget.perfilLocalDataSource ?? PerfilLocalDataSource()).obtenerPerfil();

  // HU12, criterio 3: al salir se cierra también la sesión de Firebase, así
  // que para volver a entrar hay que autenticarse de nuevo.
  void _cerrarSesion() {
    Navigator.of(context).pop();
  }

  void _cerrarSesionAlSalir(bool didPop, Object? _) {
    if (didPop) {
      SesionAdmin.instance.cerrar();
      widget.autenticacion.cerrarSesion().catchError((Object error) {
        debugPrint('No se pudo cerrar la sesión de Firebase: $error');
      });
    }
  }

  void _abrir(Widget pantalla) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => pantalla),
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      onPopInvokedWithResult: _cerrarSesionAlSalir,
      child: Scaffold(
        extendBodyBehindAppBar: true,
        appBar: AppBar(
          title: const Text('Panel de administración'),
          backgroundColor: Colors.transparent,
          actions: [
            IconButton(
              tooltip: 'Cerrar sesión',
              icon: const Icon(Icons.logout),
              onPressed: _cerrarSesion,
            ),
          ],
        ),
        body: FondoDivertido(
          child: SafeArea(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
              children: [
                _Bienvenida(
                    usuario: SesionAdmin.instance.actual?.usuario ?? ''),
                const SizedBox(height: 28),
                const _TituloSeccion('Contenidos'),
                const SizedBox(height: 10),
                _TarjetaOpcion(
                  icono: Icons.menu_book_rounded,
                  titulo: 'Gestión de contenidos',
                  detalle: 'Registra, edita, habilita o deshabilita módulos.',
                  onTap: () => _abrir(
                    GestionContenidosScreen(
                      catalogo:
                          widget.catalogoAdmin ?? FirestoreCatalogoAdmin(),
                    ),
                  ),
                ),
                const SizedBox(height: 28),
                const _TituloSeccion('Seguimiento'),
                const SizedBox(height: 10),
                _TarjetaOpcion(
                  icono: Icons.insights_rounded,
                  titulo: 'Uso de la aplicación',
                  detalle: 'Módulos usados, actividades y progreso '
                      'sincronizado de los estudiantes.',
                  onTap: () => _abrir(
                    UsoAppScreen(
                      datos: widget.usoAppDataSource ??
                          FirestoreUsoAppDataSource(),
                    ),
                  ),
                ),
                const SizedBox(height: 28),
                const _TituloSeccion('Estudiante de este dispositivo'),
                const SizedBox(height: 10),
                _TarjetaEstudiante(perfilFuture: _perfilFuture),
                const SizedBox(height: 32),
                OutlinedButton.icon(
                  onPressed: _cerrarSesion,
                  icon: const Icon(Icons.logout),
                  label: const Text('Cerrar sesión'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Bienvenida extends StatelessWidget {
  final String usuario;

  const _Bienvenida({required this.usuario});

  @override
  Widget build(BuildContext context) {
    return EncabezadoMundo(
      area: '',
      titulo: 'Hola, $usuario',
      subtitulo: 'Desde aquí puedes gestionar los contenidos y consultar '
          'el uso de la aplicación.',
      color: AppTheme.azul,
      emoji: '👨‍🏫',
    );
  }
}

class _TituloSeccion extends StatelessWidget {
  final String texto;

  const _TituloSeccion(this.texto);

  @override
  Widget build(BuildContext context) {
    return Text(
      texto,
      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
    );
  }
}

class _TarjetaEstudiante extends StatelessWidget {
  final Future<PerfilEstudiante?> perfilFuture;

  const _TarjetaEstudiante({required this.perfilFuture});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<PerfilEstudiante?>(
      future: perfilFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final perfil = snapshot.data;

        return Card(
          margin: EdgeInsets.zero,
          child: ListTile(
            leading: const Icon(Icons.person_outline),
            title: Text(perfil?.nombre ?? 'Aún no hay un perfil creado.'),
            subtitle: perfil == null ? null : Text('ID: ${perfil.id}'),
          ),
        );
      },
    );
  }
}

class _TarjetaOpcion extends StatelessWidget {
  final IconData icono;
  final String titulo;
  final String detalle;
  final VoidCallback onTap;

  const _TarjetaOpcion({
    required this.icono,
    required this.titulo,
    required this.detalle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      child: ListTile(
        leading: Icon(icono),
        title: Text(titulo),
        subtitle: Text(detalle),
        trailing: const Icon(Icons.chevron_right_rounded),
        onTap: onTap,
      ),
    );
  }
}
