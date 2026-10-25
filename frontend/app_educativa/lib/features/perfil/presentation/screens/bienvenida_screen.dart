import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/logo_aprendo.dart';
import '../../../admin/presentation/screens/login_admin_screen.dart';
import 'crear_perfil_screen.dart';

/// Primera pantalla cuando todavía no hay un perfil en el dispositivo.
class BienvenidaScreen extends StatelessWidget {
  const BienvenidaScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.superficie,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(24, 48, 24, 24),
          children: [
            const LogoAprendo(),
            const SizedBox(height: 4),
            const Text(
              'Tu aventura de aprendizaje',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 17,
                color: AppTheme.textoSecundario,
              ),
            ),
            const SizedBox(height: 36),
            Center(
              child: Container(
                width: 168,
                height: 168,
                decoration: const BoxDecoration(
                  color: AppTheme.azulSuave,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.auto_stories_rounded,
                  size: 88,
                  color: AppTheme.azul,
                ),
              ),
            ),
            const SizedBox(height: 32),
            const Text(
              '¡Hola, amiguito!',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              'Estoy listo para explorar nuevos mundos contigo hoy. '
              '¿Empezamos?',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 18),
            ),
            const SizedBox(height: 36),
            BotonGrande(
              texto: 'Comenzar aventura',
              icono: Icons.rocket_launch_rounded,
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const CrearPerfilScreen(),
                ),
              ),
            ),
            const SizedBox(height: 12),
            TextButton.icon(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const LoginAdminScreen(),
                ),
              ),
              icon: const Icon(Icons.admin_panel_settings_outlined),
              label: const Text('Acceso administrador'),
            ),
          ],
        ),
      ),
    );
  }
}
