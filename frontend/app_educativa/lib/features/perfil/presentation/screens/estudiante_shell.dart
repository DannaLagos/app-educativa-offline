import 'package:flutter/material.dart';

import '../../../modulos/presentation/controllers/modulos_scope.dart';
import '../../../modulos/presentation/screens/mis_descargas_screen.dart';
import '../../../progreso/presentation/screens/mi_progreso_screen.dart';
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
  static const int _indiceProgreso = 2;

  int _pestanaSeleccionada = _indiceInicio;

  /// Cambia cada vez que se abre "Mi progreso" para volver a leerlo.
  int _visitasProgreso = 0;

  void _seleccionarPestana(int indice) {
    if (indice == _indiceDescargas) {
      ModulosScope.of(context).cargarDescargados();
    }

    setState(() {
      if (indice == _indiceProgreso) {
        _visitasProgreso++;
      }
      _pestanaSeleccionada = indice;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _pestanaSeleccionada,
        children: [
          InicioScreen(perfil: widget.perfil),
          const MisDescargasScreen(),
          // HU09: solo se construye cuando se abre la pestaña.
          if (_visitasProgreso > 0)
            MiProgresoScreen(key: ValueKey(_visitasProgreso))
          else
            const SizedBox.shrink(),
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
          NavigationDestination(
            icon: Icon(Icons.emoji_events_outlined),
            selectedIcon: Icon(Icons.emoji_events_rounded),
            label: 'Mi progreso',
          ),
        ],
      ),
    );
  }
}
