import 'package:flutter/material.dart';

import '../../../modulos/presentation/controllers/modulos_scope.dart';
import '../../../modulos/presentation/screens/mis_descargas_screen.dart';
import '../../domain/perfil_estudiante.dart';
import 'inicio_screen.dart';

class EstudianteShell extends StatefulWidget {
  final PerfilEstudiante perfil;

  const EstudianteShell({
    super.key,
    required this.perfil,
  });

  @override
  State<EstudianteShell> createState() => _EstudianteShellState();
}

class _EstudianteShellState extends State<EstudianteShell> {
  static const int _indiceInicio = 0;
  static const int _indiceDescargas = 1;

  int _pestanaSeleccionada = _indiceInicio;

  void _seleccionarPestana(int indice) {
    if (indice == _indiceDescargas) {
      ModulosScope.of(context).cargarDescargados();
    }

    setState(() => _pestanaSeleccionada = indice);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _pestanaSeleccionada,
        children: [
          InicioScreen(perfil: widget.perfil),
          const MisDescargasScreen(),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _pestanaSeleccionada,
        onDestinationSelected: _seleccionarPestana,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home_rounded),
            label: 'Inicio',
          ),
          NavigationDestination(
            icon: Icon(Icons.download_for_offline_outlined),
            selectedIcon: Icon(Icons.download_for_offline_rounded),
            label: 'Descargas',
          ),
        ],
      ),
    );
  }
}
