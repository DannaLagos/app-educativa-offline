import 'package:flutter/material.dart';

import '../../../modulos/presentation/controllers/modulos_scope.dart';
import '../../../modulos/presentation/screens/mis_descargas_screen.dart';
import '../../domain/perfil_estudiante.dart';
import 'inicio_screen.dart';

/// Pantallas principales del estudiante con la barra inferior del diseño.
/// La pestaña "Progreso" se agregará en el Sprint 2.
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
  int _pestana = 0;

  void _seleccionar(int indice) {
    if (indice == 1) {
      // Las descargas pueden haber cambiado desde otra pantalla.
      ModulosScope.of(context).cargarDescargados();
    }

    setState(() => _pestana = indice);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _pestana,
        children: [
          InicioScreen(perfil: widget.perfil),
          const MisDescargasScreen(),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _pestana,
        onDestinationSelected: _seleccionar,
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
