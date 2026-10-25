import 'package:flutter/material.dart';

import '../../../modulos/presentation/screens/modulos_screen.dart';
import '../../../perfil/data/perfil_local_datasource.dart';
import '../../../perfil/domain/perfil_estudiante.dart';
import '../../domain/sesion_admin.dart';

class PanelAdminScreen extends StatefulWidget {
  final PerfilLocalDataSource? perfilLocalDataSource;

  const PanelAdminScreen({
    super.key,
    this.perfilLocalDataSource,
  });

  @override
  State<PanelAdminScreen> createState() => _PanelAdminScreenState();
}

class _PanelAdminScreenState extends State<PanelAdminScreen> {
  late final Future<PerfilEstudiante?> _perfilFuture =
      (widget.perfilLocalDataSource ?? PerfilLocalDataSource()).obtenerPerfil();

  void _cerrarSesion() {
    SesionAdmin.instance.cerrar();
    Navigator.of(context).pop();
  }

  void _cerrarSesionAlSalir(bool didPop, Object? _) {
    if (didPop) {
      SesionAdmin.instance.cerrar();
    }
  }

  void _abrirModulos() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => const ModulosScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      onPopInvokedWithResult: _cerrarSesionAlSalir,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Panel de administración'),
          actions: [
            IconButton(
              tooltip: 'Cerrar sesión',
              icon: const Icon(Icons.logout),
              onPressed: _cerrarSesion,
            ),
          ],
        ),
        body: SafeArea(
          child: ListView(
            padding: const EdgeInsets.all(24),
            children: [
              _Bienvenida(usuario: SesionAdmin.instance.actual?.usuario ?? ''),
              const SizedBox(height: 28),
              const _TituloSeccion('Estudiante registrado'),
              const SizedBox(height: 10),
              _TarjetaEstudiante(perfilFuture: _perfilFuture),
              const SizedBox(height: 28),
              const _TituloSeccion('Contenidos'),
              const SizedBox(height: 10),
              _TarjetaModulos(onTap: _abrirModulos),
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
    );
  }
}

class _Bienvenida extends StatelessWidget {
  final String usuario;

  const _Bienvenida({required this.usuario});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Hola, $usuario',
          style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        const Text(
          'Desde aquí puedes consultar la información de la aplicación.',
          style: TextStyle(fontSize: 16),
        ),
      ],
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

class _TarjetaModulos extends StatelessWidget {
  final VoidCallback onTap;

  const _TarjetaModulos({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      child: ListTile(
        leading: const Icon(Icons.menu_book_rounded),
        title: const Text('Módulos educativos'),
        subtitle: const Text('Consulta los módulos disponibles.'),
        trailing: const Icon(Icons.chevron_right_rounded),
        onTap: onTap,
      ),
    );
  }
}
