import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

import '../../../admin/presentation/screens/login_admin_screen.dart';
import '../../data/perfil_local_datasource.dart';
import '../../domain/perfil_estudiante.dart';
import 'inicio_screen.dart';

class CrearPerfilScreen extends StatefulWidget {
  const CrearPerfilScreen({super.key});

  @override
  State<CrearPerfilScreen> createState() => _CrearPerfilScreenState();
}

class _CrearPerfilScreenState extends State<CrearPerfilScreen> {
  final TextEditingController _nombreController = TextEditingController();
  final PerfilLocalDataSource _perfilLocalDataSource =
      PerfilLocalDataSource();

  bool _guardando = false;
  String? _error;

  Future<void> _crearPerfil() async {
    final nombre = _nombreController.text.trim();

    if (nombre.isEmpty) {
      setState(() {
        _error = 'Ingresa tu nombre para continuar.';
      });
      return;
    }

    setState(() {
      _guardando = true;
      _error = null;
    });

    final perfil = PerfilEstudiante(
      id: const Uuid().v4(),
      nombre: nombre,
    );

    try {
      await _perfilLocalDataSource.guardarPerfil(perfil);
    } catch (_) {
      if (!mounted) return;

      setState(() {
        _guardando = false;
        _error = 'No fue posible guardar tu perfil. Intenta de nuevo.';
      });
      return;
    }

    if (!mounted) return;

    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => InicioScreen(perfil: perfil),
      ),
    );
  }

  void _abrirLoginAdmin() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => const LoginAdminScreen(),
      ),
    );
  }

  @override
  void dispose() {
    _nombreController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Center(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    '¡Hola!',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    '¿Cómo te llamas?',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Escribe tu nombre para crear tu perfil y guardar tu progreso.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 16),
                  ),
                  const SizedBox(height: 32),
                  TextField(
                    controller: _nombreController,
                    textCapitalization: TextCapitalization.words,
                    decoration: InputDecoration(
                      labelText: 'Nombre',
                      hintText: 'Por ejemplo, Valentina',
                      errorText: _error,
                      border: const OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    height: 52,
                    child: ElevatedButton(
                      onPressed: _guardando ? null : _crearPerfil,
                      child: _guardando
                          ? const CircularProgressIndicator()
                          : const Text(
                              'Comenzar',
                              style: TextStyle(fontSize: 16),
                            ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextButton.icon(
                    onPressed: _abrirLoginAdmin,
                    icon: const Icon(Icons.admin_panel_settings_outlined),
                    label: const Text('Acceso administrador'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}