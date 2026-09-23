import 'package:flutter/material.dart';

import 'features/perfil/data/perfil_local_datasource.dart';
import 'features/perfil/domain/perfil_estudiante.dart';
import 'features/perfil/presentation/screens/crear_perfil_screen.dart';
import 'features/perfil/presentation/screens/inicio_screen.dart';

void main() {
  runApp(const AppEducativa());
}

class AppEducativa extends StatelessWidget {
  const AppEducativa({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'App Educativa',
      home: VerificarPerfilScreen(),
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

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<PerfilEstudiante?>(
      future: _perfilLocalDataSource.obtenerPerfil(),
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