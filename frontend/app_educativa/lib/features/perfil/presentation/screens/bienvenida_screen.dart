import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../shared/widgets/boton_grande.dart';
import '../../../../shared/widgets/logo_aprendo.dart';
import '../../../admin/presentation/screens/login_admin_screen.dart';
import 'crear_perfil_screen.dart';

class BienvenidaScreen extends StatelessWidget {
  const BienvenidaScreen({super.key});

  void _abrir(BuildContext context, Widget pantalla) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => pantalla),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.superficie,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(24, 48, 24, 24),
          children: [
            const _Presentacion(),
            const SizedBox(height: 36),
            BotonGrande(
              texto: 'Comenzar aventura',
              icono: Icons.rocket_launch_rounded,
              onPressed: () => _abrir(context, const CrearPerfilScreen()),
            ),
            const SizedBox(height: 12),
            TextButton.icon(
              onPressed: () => _abrir(context, const LoginAdminScreen()),
              icon: const Icon(Icons.admin_panel_settings_outlined),
              label: const Text('Acceso administrador'),
            ),
          ],
        ),
      ),
    );
  }
}

class _Presentacion extends StatelessWidget {
  static const double _tamanoIlustracion = 168;
  static const double _tamanoIconoIlustracion = 88;

  const _Presentacion();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const LogoAprendo(),
        const SizedBox(height: 4),
        const Text(
          'Tu aventura de aprendizaje',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 17, color: AppTheme.textoSecundario),
        ),
        const SizedBox(height: 36),
        Center(
          child: Container(
            width: _tamanoIlustracion,
            height: _tamanoIlustracion,
            decoration: const BoxDecoration(
              color: AppTheme.azulSuave,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.auto_stories_rounded,
              size: _tamanoIconoIlustracion,
              color: AppTheme.azul,
            ),
          ),
        ),
        const SizedBox(height: 32),
        const Text(
          '¡Hola, amiguito!',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 10),
        const Text(
          'Estoy listo para explorar nuevos mundos contigo hoy. '
          '¿Empezamos?',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 18),
        ),
      ],
    );
  }
}
