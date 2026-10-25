import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/voz/lector_voz.dart';
import '../../../../shared/widgets/boton_grande.dart';
import '../../../modulos/presentation/controllers/modulos_scope.dart';
import '../../../modulos/presentation/screens/lector_modulo_screen.dart';
import '../../../modulos/presentation/widgets/visor_pdf.dart';
import '../../domain/actividad.dart';

/// Botón "Pista": muestra el fragmento de la cartilla donde está la
/// respuesta y permite abrir el PDF del módulo en esa página. Todo es local:
/// funciona sin internet.
class BotonPista extends StatelessWidget {
  final Pista pista;
  final String moduloId;

  const BotonPista({
    super.key,
    required this.pista,
    required this.moduloId,
  });

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      key: const ValueKey('boton-pista'),
      style: OutlinedButton.styleFrom(
        foregroundColor: AppTheme.ambar,
        backgroundColor: AppTheme.ambarSuave,
        side: const BorderSide(color: AppTheme.ambar, width: 2),
        minimumSize: const Size(0, AppTheme.tamanoMinimoToque),
        padding: const EdgeInsets.symmetric(horizontal: 14),
      ),
      onPressed: () => mostrarPista(context, pista: pista, moduloId: moduloId),
      icon: const Text('💡', style: TextStyle(fontSize: 20)),
      label: const Text('Pista'),
    );
  }
}

Future<void> mostrarPista(
  BuildContext context, {
  required Pista pista,
  required String moduloId,
}) {
  final voz = VozScope.de(context);
  voz.hablar(pista.texto);

  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (contextoHoja) => SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              '💡 Pista de la cartilla',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                color: AppTheme.ambarSuave,
                border: Border(
                  left: BorderSide(color: AppTheme.ambar, width: 6),
                ),
              ),
              child: Text(
                pista.texto,
                style: const TextStyle(
                  fontSize: 19,
                  height: 1.4,
                  fontStyle: FontStyle.italic,
                  color: AppTheme.texto,
                ),
              ),
            ),
            const SizedBox(height: 12),
            TextButton.icon(
              onPressed: () => voz.hablar(pista.texto),
              icon: const Icon(Icons.volume_up_rounded),
              label: const Text('Escuchar la pista'),
            ),
            if (pista.pagina != null) ...[
              const SizedBox(height: 8),
              BotonGrande(
                texto: 'Ver en la cartilla (página ${pista.pagina})',
                icono: Icons.menu_book_rounded,
                color: AppTheme.verde,
                onPressed: () {
                  Navigator.of(contextoHoja).pop();
                  abrirCartillaEnPagina(
                    context,
                    moduloId: moduloId,
                    pagina: pista.pagina!,
                  );
                },
              ),
            ],
          ],
        ),
      ),
    ),
  );
}

/// Abre el PDF del módulo descargado en [pagina]. No cambia el progreso de
/// lectura: es solo para consultar.
Future<void> abrirCartillaEnPagina(
  BuildContext context, {
  required String moduloId,
  required int pagina,
}) async {
  final navegador = Navigator.of(context);
  final mensajero = ScaffoldMessenger.maybeOf(context);

  try {
    final controller = ModulosScope.of(context);
    final modulo = controller.buscarModulo(moduloId);

    if (modulo == null) {
      throw StateError('Módulo $moduloId no encontrado');
    }

    final recursos = await controller.obtenerRecursos(modulo);
    final pdf = recursos.firstWhere(
      (recurso) => recurso.tipo == tipoRecursoDocumento,
    );

    await navegador.push(
      MaterialPageRoute<void>(
        builder: (_) => Scaffold(
          appBar: AppBar(title: Text('Cartilla · página $pagina')),
          body: VisorPdf(ruta: pdf.ruta, paginaInicial: pagina),
        ),
      ),
    );
  } catch (error) {
    debugPrint('No se pudo abrir la cartilla: $error');
    mensajero?.showSnackBar(
      const SnackBar(content: Text('No se pudo abrir la cartilla.')),
    );
  }
}
