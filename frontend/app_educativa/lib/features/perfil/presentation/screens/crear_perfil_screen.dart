import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../admin/presentation/screens/login_admin_screen.dart';
import '../../data/perfil_local_datasource.dart';
import '../../domain/perfil_estudiante.dart';
import 'estudiante_shell.dart';

class CrearPerfilScreen extends StatefulWidget {
  final PerfilLocalDataSource? perfilLocalDataSource;

  const CrearPerfilScreen({
    super.key,
    this.perfilLocalDataSource,
  });

  @override
  State<CrearPerfilScreen> createState() => _CrearPerfilScreenState();
}

class _CrearPerfilScreenState extends State<CrearPerfilScreen> {
  static const double _alturaBotonContinuar = 60;

  final TextEditingController _nombreController = TextEditingController();
  late final PerfilLocalDataSource _perfilLocalDataSource =
      widget.perfilLocalDataSource ?? PerfilLocalDataSource();

  bool _estaGuardando = false;
  String? _mensajeError;

  @override
  void dispose() {
    _nombreController.dispose();
    super.dispose();
  }

  Future<void> _crearPerfil() async {
    final nombre = _nombreController.text.trim();

    if (nombre.isEmpty) {
      setState(() => _mensajeError = 'Ingresa tu nombre para continuar.');
      return;
    }

    setState(() {
      _estaGuardando = true;
      _mensajeError = null;
    });

    final perfil = PerfilEstudiante(id: const Uuid().v4(), nombre: nombre);
    final fueGuardado = await _intentarGuardar(perfil);

    if (!mounted || !fueGuardado) {
      return;
    }

    _irAlInicio(perfil);
  }

  Future<bool> _intentarGuardar(PerfilEstudiante perfil) async {
    try {
      await _perfilLocalDataSource.guardarPerfil(perfil);
      return true;
    } catch (error, stack) {
      debugPrint('Error al guardar el perfil: $error\n$stack');

      if (mounted) {
        setState(() {
          _estaGuardando = false;
          _mensajeError = 'No fue posible guardar tu perfil. Intenta de nuevo.';
        });
      }
      return false;
    }
  }

  // Se quita la bienvenida de la pila: desde el inicio no se vuelve atrás.
  void _irAlInicio(PerfilEstudiante perfil) {
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
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
          children: [
            const _Encabezado(),
            const SizedBox(height: 10),
            TextField(
              controller: _nombreController,
              textCapitalization: TextCapitalization.words,
              style: const TextStyle(fontSize: 19),
              decoration: InputDecoration(
                hintText: 'Por ejemplo, Valentina',
                errorText: _mensajeError,
              ),
              onSubmitted: (_) => _crearPerfil(),
            ),
            const SizedBox(height: 32),
            SizedBox(
              height: _alturaBotonContinuar,
              child: ElevatedButton(
                onPressed: _estaGuardando ? null : _crearPerfil,
                child: _estaGuardando
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

class _Encabezado extends StatelessWidget {
  const _Encabezado();

  @override
  Widget build(BuildContext context) {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Crea tu perfil',
          style: TextStyle(fontSize: 30, fontWeight: FontWeight.w800),
        ),
        SizedBox(height: 6),
        Text(
          '¡Comencemos tu nuevo viaje educativo!',
          style: TextStyle(fontSize: 18, color: AppTheme.textoSecundario),
        ),
        SizedBox(height: 32),
        Text(
          '¿Cómo te llamas?',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
        ),
      ],
    );
  }
}
