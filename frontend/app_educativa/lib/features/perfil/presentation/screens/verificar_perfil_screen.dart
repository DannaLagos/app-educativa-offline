import 'package:flutter/material.dart';

import '../../data/perfil_local_datasource.dart';
import '../../domain/perfil_estudiante.dart';
import 'bienvenida_screen.dart';
import 'estudiante_shell.dart';

class VerificarPerfilScreen extends StatefulWidget {
  final PerfilLocalDataSource? perfilLocalDataSource;

  const VerificarPerfilScreen({
    super.key,
    this.perfilLocalDataSource,
  });

  @override
  State<VerificarPerfilScreen> createState() => _VerificarPerfilScreenState();
}

class _VerificarPerfilScreenState extends State<VerificarPerfilScreen> {
  late final Future<PerfilEstudiante?> _perfilFuture =
      (widget.perfilLocalDataSource ?? PerfilLocalDataSource()).obtenerPerfil();

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<PerfilEstudiante?>(
      future: _perfilFuture,
      builder: _construirSegunPerfil,
    );
  }

  Widget _construirSegunPerfil(
    BuildContext context,
    AsyncSnapshot<PerfilEstudiante?> snapshot,
  ) {
    if (snapshot.connectionState == ConnectionState.waiting) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (snapshot.hasError) {
      debugPrint('Error al cargar el perfil: ${snapshot.error}');
      return const Scaffold(
        body: Center(child: Text('Ocurrió un error al cargar el perfil.')),
      );
    }

    final perfil = snapshot.data;

    if (perfil == null) {
      return const BienvenidaScreen();
    }

    return EstudianteShell(perfil: perfil);
  }
}
