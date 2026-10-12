import 'package:flutter/material.dart';

import 'core/network/conectividad_service.dart';
import 'core/theme/app_theme.dart';
import 'features/modulos/data/modulo_local_datasource.dart';
import 'features/modulos/data/modulo_remote_datasource.dart';
import 'features/modulos/data/modulo_repository.dart';
import 'features/modulos/presentation/controllers/modulos_controller.dart';
import 'features/modulos/presentation/controllers/modulos_scope.dart';
import 'features/perfil/data/perfil_local_datasource.dart';
import 'features/perfil/domain/perfil_estudiante.dart';
import 'features/perfil/presentation/screens/crear_perfil_screen.dart';
import 'features/perfil/presentation/screens/inicio_screen.dart';

void main() {
  final modulosController = ModulosController(
    repositorio: ModuloRepository(
      remote: ModuloRemoteDataSource(),
      local: ModuloLocalDataSource(),
      conectividad: ConectividadService(),
    ),
  );

  runApp(
    AppEducativa(
      modulosController: modulosController,
    ),
  );
}

class AppEducativa extends StatelessWidget {
  final ModulosController modulosController;

  const AppEducativa({
    super.key,
    required this.modulosController,
  });

  @override
  Widget build(BuildContext context) {
    return ModulosScope(
      controller: modulosController,
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'App Educativa',
        theme: AppTheme.claro,
        home: const VerificarPerfilScreen(),
      ),
    );
  }
}

class VerificarPerfilScreen extends StatefulWidget {
  const VerificarPerfilScreen({super.key});

  @override
  State<VerificarPerfilScreen> createState() =>
      _VerificarPerfilScreenState();
}

class _VerificarPerfilScreenState extends State<VerificarPerfilScreen> {
  final PerfilLocalDataSource _perfilLocalDataSource =
      PerfilLocalDataSource();

  late final Future<PerfilEstudiante?> _perfilFuture =
      _perfilLocalDataSource.obtenerPerfil();

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<PerfilEstudiante?>(
      future: _perfilFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        if (snapshot.hasError) {
          return const Scaffold(
            body: Center(
              child: Text(
                'Ocurrió un error al cargar el perfil.',
              ),
            ),
          );
        }

        final perfil = snapshot.data;

        if (perfil == null) {
          return const CrearPerfilScreen();
        }

        return InicioScreen(
          perfil: perfil,
        );
      },
    );
  }
}