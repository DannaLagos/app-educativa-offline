import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../shared/widgets/boton_grande.dart';
import '../../../../shared/widgets/dibujo.dart';
import '../../../../shared/widgets/fondo_divertido.dart';
import '../../../../shared/widgets/mensaje_con_accion.dart';
import '../../domain/modulo.dart';
import '../../domain/recurso_local.dart';
import '../controllers/modulos_scope.dart';
import '../widgets/encabezado_mundo.dart';
import '../widgets/icono_area.dart';
import '../widgets/visor_pdf_con_progreso.dart';

typedef ConstructorVisor = Widget Function(RecursoLocal recurso);

const String tipoRecursoDocumento = 'pdf';

class LectorModuloScreen extends StatefulWidget {
  final Modulo modulo;

  // Reemplazable en pruebas porque pdfx usa código nativo. Si es null se usa
  // el visor de PDF que guarda la página leída (HU06).
  final ConstructorVisor? construirVisor;

  const LectorModuloScreen({
    super.key,
    required this.modulo,
    this.construirVisor,
  });

  @override
  State<LectorModuloScreen> createState() => _LectorModuloScreenState();
}

class _LectorModuloScreenState extends State<LectorModuloScreen> {
  Future<List<RecursoLocal>>? _recursos;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _recursos ??= ModulosScope.of(context).obtenerRecursos(widget.modulo);
  }

  Widget _construirVisor(RecursoLocal recurso) {
    return widget.construirVisor?.call(recurso) ??
        VisorPdfConProgreso(moduloId: widget.modulo.id, recurso: recurso);
  }

  void _abrirRecurso(RecursoLocal recurso) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => Scaffold(
          appBar: AppBar(title: Text(recurso.titulo)),
          body: _construirVisor(recurso),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.modulo.nombre),
      ),
      body: FondoDivertido(
        child: FutureBuilder<List<RecursoLocal>>(
          future: _recursos,
          builder: _construirSegunEstado,
        ),
      ),
    );
  }

  Widget _construirSegunEstado(
    BuildContext context,
    AsyncSnapshot<List<RecursoLocal>> snapshot,
  ) {
    if (snapshot.connectionState != ConnectionState.done) {
      return const Center(child: CircularProgressIndicator());
    }

    // El lector solo muestra documentos; los juegos se abren desde el mapa
    // de niveles (HU07).
    final recursos = snapshot.data
        ?.where((recurso) => recurso.tipo == tipoRecursoDocumento)
        .toList();

    if (snapshot.hasError || recursos == null || recursos.isEmpty) {
      return _construirError();
    }

    if (recursos.length == 1) {
      return _construirVisor(recursos.single);
    }

    return _construirSelectorDeRecursos(recursos);
  }

  Widget _construirError() {
    return MensajeConAccion(
      icono: const Icon(Icons.report_problem_rounded),
      mensaje: 'Faltan archivos de este módulo. Descárgalo de nuevo.',
      accion: BotonGrande(
        texto: 'Volver',
        icono: Icons.arrow_back_rounded,
        onPressed: () => Navigator.of(context).pop(),
      ),
    );
  }

  Widget _construirSelectorDeRecursos(List<RecursoLocal> recursos) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      children: [
        EncabezadoMundo(
          area: widget.modulo.area,
          titulo: widget.modulo.nombre,
          subtitulo: '¿Qué quieres leer?',
        ),
        const SizedBox(height: 20),
        for (final recurso in recursos)
          _TarjetaDocumento(
            titulo: recurso.titulo,
            color: AparienciaArea.de(widget.modulo.area).color,
            onTap: () => _abrirRecurso(recurso),
          ),
      ],
    );
  }
}

/// Un documento de la cartilla como ficha grande para tocar.
class _TarjetaDocumento extends StatelessWidget {
  final String titulo;
  final Color color;
  final VoidCallback onTap;

  const _TarjetaDocumento({
    required this.titulo,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final radio = BorderRadius.circular(24);

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: AppTheme.superficie,
        borderRadius: radio,
        border: Border.all(
          color: Color.lerp(color, Colors.white, 0.6)!,
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: Color.lerp(color, Colors.white, 0.45)!,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          borderRadius: radio,
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                Container(
                  width: 60,
                  height: 60,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: const Dibujo('📖', tamano: 40),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    titulo,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                Icon(Icons.chevron_right_rounded, size: 34, color: color),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
