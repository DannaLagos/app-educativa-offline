import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../domain/modulo.dart';
import '../controllers/modulos_scope.dart';
import '../widgets/estado_descarga_chip.dart';

class DetalleModuloScreen extends StatelessWidget {
  final String moduloId;

  const DetalleModuloScreen({
    super.key,
    required this.moduloId,
  });

  @override
  Widget build(BuildContext context) {
    final controller = ModulosScope.of(context);
    final modulo = controller.modulo(moduloId);

    if (modulo == null) {
      return Scaffold(
        appBar: AppBar(),
        body: const Center(
          child: Text(
            'Este módulo ya no está disponible.',
            style: TextStyle(fontSize: 20),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(modulo.nombre),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                modulo.nombre,
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 12),

              _Dato(
                icono: Icons.school_outlined,
                texto: modulo.area,
              ),

              const SizedBox(height: 8),

              _Dato(
                icono: Icons.grade_outlined,
                texto: 'Grado ${modulo.grado}',
              ),

              const SizedBox(height: 24),

              EstadoDescargaChip(
                estado: modulo.estadoDescarga,
                grande: true,
              ),

              if (modulo.fechaDescarga != null) ...[
                const SizedBox(height: 8),
                Text(
                  'Descargado el ${_formatearFecha(modulo.fechaDescarga!)}',
                  style: const TextStyle(
                    fontSize: 16,
                    color: AppTheme.textoSecundario,
                  ),
                ),
              ],

              const SizedBox(height: 28),

              const _Titulo('Descripción'),

              const SizedBox(height: 10),

              Text(
                modulo.descripcion,
                style: const TextStyle(
                  fontSize: 18,
                  height: 1.5,
                ),
              ),

              const SizedBox(height: 28),

              const _Titulo('Contenidos'),

              const SizedBox(height: 10),

              _ListaContenidos(modulo: modulo),
            ],
          ),
        ),
      ),
    );
  }

  static String _formatearFecha(DateTime fecha) {
    String dosDigitos(int valor) => valor.toString().padLeft(2, '0');

    return '${dosDigitos(fecha.day)}/${dosDigitos(fecha.month)}/${fecha.year}';
  }
}

class _Titulo extends StatelessWidget {
  final String texto;

  const _Titulo(this.texto);

  @override
  Widget build(BuildContext context) {
    return Semantics(
      header: true,
      child: Text(
        texto,
        style: const TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

class _Dato extends StatelessWidget {
  final IconData icono;
  final String texto;

  const _Dato({
    required this.icono,
    required this.texto,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icono, size: 24),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            texto,
            style: const TextStyle(fontSize: 18),
          ),
        ),
      ],
    );
  }
}

class _ListaContenidos extends StatelessWidget {
  final Modulo modulo;

  const _ListaContenidos({required this.modulo});

  @override
  Widget build(BuildContext context) {
    if (modulo.contenidos.isEmpty) {
      return const Text(
        'Este módulo aún no tiene contenidos.',
        style: TextStyle(fontSize: 18),
      );
    }

    return Column(
      children: [
        for (var i = 0; i < modulo.contenidos.length; i++)
          Container(
            width: double.infinity,
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border.all(color: const Color(0xFF90A4AE)),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 18,
                  backgroundColor: AppTheme.azul,
                  foregroundColor: Colors.white,
                  child: Text(
                    '${i + 1}',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    modulo.contenidos[i],
                    style: const TextStyle(fontSize: 18),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}
