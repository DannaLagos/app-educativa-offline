import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../admin/presentation/screens/login_admin_screen.dart';
import '../../data/perfil_local_datasource.dart';
import '../../domain/perfil_estudiante.dart';
import 'estudiante_shell.dart';

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

    // Se quita la bienvenida de la pila: desde el inicio no se vuelve atrás.
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(
        builder: (_) => EstudianteShell(perfil: perfil),
      ),
      (_) => false,
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
      appBar: AppBar(),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
          children: [
            const Text(
              'Crea tu perfil',
              style: TextStyle(
                fontSize: 30,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              '¡Comencemos tu nuevo viaje educativo!',
              style: TextStyle(
                fontSize: 18,
                color: AppTheme.textoSecundario,
              ),
            ),
            const SizedBox(height: 32),
            const Text(
              '¿Cómo te llamas?',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _nombreController,
              textCapitalization: TextCapitalization.words,
              style: const TextStyle(fontSize: 19),
              decoration: InputDecoration(
                hintText: 'Por ejemplo, Valentina',
                errorText: _error,
              ),
              onSubmitted: (_) => _crearPerfil(),
            ),
            const SizedBox(height: 32),
            SizedBox(
              height: 60,
              child: ElevatedButton(
                onPressed: _guardando ? null : _crearPerfil,
                child: _guardando
                    ? const CircularProgressIndicator()
                    : const Text('¡Listos, continuar!'),
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
    );
  }
}
