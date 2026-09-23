import 'package:flutter/material.dart';

import '../../data/modulo_local_datasource.dart';
import '../../domain/modulo.dart';
import '../widgets/modulo_card.dart';
import 'detalle_modulo_screen.dart';

class ModulosScreen extends StatefulWidget {
  const ModulosScreen({super.key});

  @override
  State<ModulosScreen> createState() => _ModulosScreenState();
}

class _ModulosScreenState extends State<ModulosScreen> {
  final ModuloLocalDataSource _moduloLocalDataSource =
      ModuloLocalDataSource();

  late Future<List<Modulo>> _modulosFuture;

  @override
  void initState() {
    super.initState();
    _modulosFuture = _moduloLocalDataSource.obtenerModulosDisponibles();
  }

  void _abrirModulo(Modulo modulo) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => DetalleModuloScreen(
          modulo: modulo,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Módulos educativos'),
      ),
      body: SafeArea(
        child: FutureBuilder<List<Modulo>>(
          future: _modulosFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: CircularProgressIndicator(),
              );
            }

            if (snapshot.hasError) {
              return const Center(
                child: Padding(
                  padding: EdgeInsets.all(24),
                  child: Text(
                    'No fue posible cargar los módulos.',
                    textAlign: TextAlign.center,
                  ),
                ),
              );
            }

            final modulos = snapshot.data ?? [];

            if (modulos.isEmpty) {
              return const Center(
                child: Text(
                  'No hay módulos disponibles.',
                ),
              );
            }

            return ListView(
              padding: const EdgeInsets.all(20),
              children: [
                const Text(
                  '¿Qué quieres aprender hoy?',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Selecciona un módulo para consultar su contenido.',
                  style: TextStyle(
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 24),

                ...modulos.map(
                  (modulo) => ModuloCard(
                    modulo: modulo,
                    onTap: () => _abrirModulo(modulo),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}