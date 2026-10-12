import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../admin/presentation/screens/login_admin_screen.dart';
import '../../../modulos/presentation/screens/mis_descargas_screen.dart';
import '../../../modulos/presentation/screens/modulos_screen.dart';
import '../../domain/perfil_estudiante.dart';

class InicioScreen extends StatelessWidget {
  final PerfilEstudiante perfil;

  const InicioScreen({
    super.key,
    required this.perfil,
  });

  void _abrirModulos(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => const ModulosScreen(),
      ),
    );
  }

  void _abrirMisDescargas(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => const MisDescargasScreen(),
      ),
    );
  }

  void _abrirLoginAdmin(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => const LoginAdminScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Inicio'),
        actions: [
          IconButton(
            tooltip: 'Acceso administrador',
            icon: const Icon(Icons.admin_panel_settings_outlined),
            onPressed: () => _abrirLoginAdmin(context),
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Hola, ${perfil.nombre} 👋',
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 12),

              const Text(
                '¿Qué quieres aprender hoy?',
                style: TextStyle(
                  fontSize: 18,
                ),
              ),

              const SizedBox(height: 32),

              _OpcionInicio(
                icono: Icons.menu_book_rounded,
                titulo: 'Módulos educativos',
                descripcion: 'Consulta los contenidos disponibles.',
                onTap: () => _abrirModulos(context),
              ),

              const SizedBox(height: 16),

              _OpcionInicio(
                icono: Icons.download_for_offline_rounded,
                titulo: 'Mis descargas',
                descripcion: 'Módulos guardados para usar sin internet.',
                onTap: () => _abrirMisDescargas(context),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _OpcionInicio extends StatelessWidget {
  final IconData icono;
  final String titulo;
  final String descripcion;
  final VoidCallback onTap;

  const _OpcionInicio({
    required this.icono,
    required this.titulo,
    required this.descripcion,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          border: Border.all(
            color: AppTheme.borde,
          ),
          borderRadius: BorderRadius.circular(18),
        ),
        child: Row(
          children: [
            Icon(
              icono,
              size: 36,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    titulo,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    descripcion,
                    style: const TextStyle(
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.chevron_right_rounded,
            ),
          ],
        ),
      ),
    );
  }
}
