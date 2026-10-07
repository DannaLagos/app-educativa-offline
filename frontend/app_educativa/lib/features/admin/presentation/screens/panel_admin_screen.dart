import 'package:flutter/material.dart';

import '../../../modulos/presentation/screens/modulos_screen.dart';
import '../../../perfil/data/perfil_local_datasource.dart';
import '../../../perfil/domain/perfil_estudiante.dart';
import '../../domain/sesion_admin.dart';

class PanelAdminScreen extends StatefulWidget {
  const PanelAdminScreen({super.key});

  @override
  State<PanelAdminScreen> createState() => _PanelAdminScreenState();
}

class _PanelAdminScreenState extends State<PanelAdminScreen> {
  final PerfilLocalDataSource _perfilLocalDataSource =
      PerfilLocalDataSource();

  late Future<PerfilEstudiante?> _perfilFuture;

  @override
  void initState() {
    super.initState();
    _perfilFuture = _perfilLocalDataSource.obtenerPerfil();
  }

  void _cerrarSesion() {
    SesionAdmin.instance.cerrar();
    Navigator.of(context).pop();
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
    final admin = SesionAdmin.instance.actual;

    return PopScope(
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) {
          SesionAdmin.instance.cerrar();
        }
      },
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
              Text(
                'Hola, ${admin?.usuario ?? ''}',
                style: const TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Desde aquí puedes consultar la información de la aplicación.',
                style: TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 28),
              const Text(
                'Estudiante registrado',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 10),
              FutureBuilder<PerfilEstudiante?>(
                future: _perfilFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                      child: CircularProgressIndicator(),
                    );
                  }

                  final perfil = snapshot.data;

                  return Card(
                    margin: EdgeInsets.zero,
                    child: ListTile(
                      leading: const Icon(Icons.person_outline),
                      title: Text(
                        perfil?.nombre ?? 'Aún no hay un perfil creado.',
                      ),
                      subtitle: perfil == null
                          ? null
                          : Text('ID: ${perfil.id}'),
                    ),
                  );
                },
              ),
              const SizedBox(height: 28),
              const Text(
                'Contenidos',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 10),
              Card(
                margin: EdgeInsets.zero,
                child: ListTile(
                  leading: const Icon(Icons.menu_book_rounded),
                  title: const Text('Módulos educativos'),
                  subtitle: const Text('Consulta los módulos disponibles.'),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: _abrirModulos,
                ),
              ),
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
