import 'package:flutter/material.dart';

import '../../../../core/network/servidor_exception.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../shared/widgets/aviso_resultado.dart';
import '../../../../shared/widgets/etiqueta.dart';
import '../../../../shared/widgets/mensaje_con_accion.dart';
import '../../../modulos/domain/modulo.dart';
import '../../data/catalogo_admin.dart';
import 'formulario_modulo_screen.dart';

/// HU13: lista de los módulos registrados, con el interruptor para
/// habilitarlos o deshabilitarlos y acceso al formulario.
class GestionContenidosScreen extends StatefulWidget {
  final CatalogoAdmin catalogo;

  const GestionContenidosScreen({super.key, required this.catalogo});

  @override
  State<GestionContenidosScreen> createState() =>
      _GestionContenidosScreenState();
}

class _GestionContenidosScreenState extends State<GestionContenidosScreen> {
  List<Modulo>? _modulos;
  String? _error;

  /// Módulos con un cambio de estado en curso: su interruptor se desactiva.
  final Set<String> _cambiando = {};

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  Future<void> _cargar() async {
    setState(() => _error = null);

    try {
      final modulos = await widget.catalogo.obtenerModulos();

      if (!mounted) return;

      setState(() => _modulos = modulos);
    } on ServidorException catch (error) {
      debugPrint('$error');

      if (!mounted) return;

      setState(() => _error = error.mensaje);
    }
  }

  Future<void> _cambiarHabilitado(Modulo modulo, bool habilitado) async {
    setState(() => _cambiando.add(modulo.id));

    try {
      await widget.catalogo.cambiarHabilitado(modulo.id, habilitado);

      if (!mounted) return;

      _reemplazar(_conHabilitado(modulo, habilitado));
      _avisar(
        fueExitoso: true,
        mensaje: habilitado
            ? '"${modulo.nombre}" ahora está disponible.'
            : '"${modulo.nombre}" ya no se mostrará a los estudiantes.',
      );
    } on ServidorException catch (error) {
      debugPrint('$error');

      if (!mounted) return;

      _avisar(fueExitoso: false, mensaje: error.mensaje);
    } finally {
      if (mounted) {
        setState(() => _cambiando.remove(modulo.id));
      }
    }
  }

  Future<void> _abrirFormulario([Modulo? modulo]) async {
    final guardado = await Navigator.of(context).push<Modulo>(
      MaterialPageRoute(
        builder: (_) => FormularioModuloScreen(
          catalogo: widget.catalogo,
          modulo: modulo,
          idsExistentes: {for (final m in _modulos ?? <Modulo>[]) m.id},
        ),
      ),
    );

    if (guardado == null || !mounted) return;

    if (modulo == null) {
      setState(() => _modulos = [...?_modulos, guardado]);
    } else {
      _reemplazar(guardado);
    }

    _avisar(fueExitoso: true, mensaje: 'Se guardó "${guardado.nombre}".');
  }

  void _reemplazar(Modulo actualizado) {
    setState(() {
      _modulos = [
        for (final m in _modulos ?? <Modulo>[])
          m.id == actualizado.id ? actualizado : m,
      ];
    });
  }

  void _avisar({required bool fueExitoso, required String mensaje}) {
    final mensajero = ScaffoldMessenger.of(context)..hideCurrentSnackBar();
    mostrarAvisoResultado(mensajero, fueExitoso: fueExitoso, mensaje: mensaje);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gestión de contenidos'),
        actions: [
          IconButton(
            tooltip: 'Actualizar',
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _cargar,
          ),
        ],
      ),
      floatingActionButton: _modulos == null
          ? null
          : FloatingActionButton.extended(
              onPressed: _abrirFormulario,
              icon: const Icon(Icons.add_rounded),
              label: const Text('Nuevo módulo'),
            ),
      body: _construirCuerpo(),
    );
  }

  Widget _construirCuerpo() {
    final error = _error;
    final modulos = _modulos;

    if (error != null) {
      return MensajeConAccion(
        icono: const Icon(Icons.cloud_off_rounded, color: AppTheme.rojo),
        mensaje: error,
        accion: ElevatedButton(
          onPressed: _cargar,
          child: const Text('Reintentar'),
        ),
      );
    }

    if (modulos == null) {
      return const Center(child: CircularProgressIndicator());
    }

    if (modulos.isEmpty) {
      return const Center(
        child: Text(
          'Aún no hay módulos registrados.',
          style: TextStyle(fontSize: 18),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _cargar,
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
        itemCount: modulos.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (context, indice) {
          final modulo = modulos[indice];

          return _TarjetaModuloAdmin(
            modulo: modulo,
            estaCambiando: _cambiando.contains(modulo.id),
            onEditar: () => _abrirFormulario(modulo),
            onCambiarHabilitado: (valor) => _cambiarHabilitado(modulo, valor),
          );
        },
      ),
    );
  }
}

Modulo _conHabilitado(Modulo modulo, bool habilitado) {
  return Modulo(
    id: modulo.id,
    nombre: modulo.nombre,
    area: modulo.area,
    grado: modulo.grado,
    descripcion: modulo.descripcion,
    version: modulo.version,
    estaHabilitado: habilitado,
    contenidos: modulo.contenidos,
  );
}

class _TarjetaModuloAdmin extends StatelessWidget {
  final Modulo modulo;
  final bool estaCambiando;
  final VoidCallback onEditar;
  final ValueChanged<bool> onCambiarHabilitado;

  const _TarjetaModuloAdmin({
    required this.modulo,
    required this.estaCambiando,
    required this.onEditar,
    required this.onCambiarHabilitado,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(AppTheme.radio),
        onTap: onEditar,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 8, 12),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      modulo.nombre,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${modulo.areaYGrado} · versión ${modulo.version}',
                      style: const TextStyle(
                        fontSize: 15,
                        color: AppTheme.textoSecundario,
                      ),
                    ),
                    const SizedBox(height: 8),
                    modulo.estaHabilitado
                        ? const Etiqueta(
                            texto: 'Habilitado',
                            color: AppTheme.verde,
                            fondo: AppTheme.verdeSuave,
                            icono: Icons.visibility_rounded,
                          )
                        : const Etiqueta.gris(
                            'Deshabilitado',
                            icono: Icons.visibility_off_rounded,
                          ),
                  ],
                ),
              ),
              Switch(
                value: modulo.estaHabilitado,
                onChanged: estaCambiando ? null : onCambiarHabilitado,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
