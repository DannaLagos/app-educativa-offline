import 'package:flutter/material.dart';

import '../../../../core/network/servidor_exception.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../modulos/domain/modulo.dart';
import '../../data/catalogo_admin.dart';

/// HU13, criterio 2: registrar un módulo nuevo o modificar uno existente.
/// Al guardar devuelve el módulo con `Navigator.pop`.
class FormularioModuloScreen extends StatefulWidget {
  final CatalogoAdmin catalogo;

  /// null para registrar uno nuevo.
  final Modulo? modulo;

  /// Para avisar antes de enviar si el id ya está en uso.
  final Set<String> idsExistentes;

  const FormularioModuloScreen({
    super.key,
    required this.catalogo,
    this.modulo,
    this.idsExistentes = const {},
  });

  @override
  State<FormularioModuloScreen> createState() => _FormularioModuloScreenState();
}

class _FormularioModuloScreenState extends State<FormularioModuloScreen> {
  final _formulario = GlobalKey<FormState>();

  late final Modulo? _original = widget.modulo;
  late final _id = TextEditingController(text: _original?.id);
  late final _nombre = TextEditingController(text: _original?.nombre);
  late final _area = TextEditingController(text: _original?.area);
  late final _grado = TextEditingController(text: _original?.grado.toString());
  late final _descripcion =
      TextEditingController(text: _original?.descripcion);
  late final _version =
      TextEditingController(text: '${_original?.version ?? 1}');
  late final _contenidos =
      TextEditingController(text: _original?.contenidos.join('\n'));

  // Un módulo nuevo empieza deshabilitado: sus archivos deben estar en
  // Storage antes de que los estudiantes intenten descargarlo.
  late bool _habilitado = _original?.estaHabilitado ?? false;

  bool _guardando = false;
  String? _error;

  bool get _esNuevo => _original == null;

  @override
  void dispose() {
    for (final campo in [
      _id,
      _nombre,
      _area,
      _grado,
      _descripcion,
      _version,
      _contenidos,
    ]) {
      campo.dispose();
    }
    super.dispose();
  }

  Modulo _leerFormulario() {
    return Modulo(
      id: _id.text.trim(),
      nombre: _nombre.text.trim(),
      area: _area.text.trim(),
      grado: int.parse(_grado.text.trim()),
      descripcion: _descripcion.text.trim(),
      version: int.parse(_version.text.trim()),
      estaHabilitado: _habilitado,
      contenidos: [
        for (final linea in _contenidos.text.split('\n'))
          if (linea.trim().isNotEmpty) linea.trim(),
      ],
    );
  }

  Future<void> _guardar() async {
    if (!_formulario.currentState!.validate()) return;

    final modulo = _leerFormulario();

    setState(() {
      _guardando = true;
      _error = null;
    });

    try {
      if (_esNuevo) {
        await widget.catalogo.registrar(modulo);
      } else {
        await widget.catalogo.actualizar(modulo);
      }

      if (!mounted) return;

      Navigator.of(context).pop(modulo);
    } on ModuloYaExisteException {
      _mostrarError('Ya existe un módulo con el identificador "${modulo.id}".');
    } on ServidorException catch (error) {
      debugPrint('$error');
      _mostrarError(error.mensaje);
    }
  }

  void _mostrarError(String mensaje) {
    if (!mounted) return;

    setState(() {
      _guardando = false;
      _error = mensaje;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_esNuevo ? 'Nuevo módulo' : 'Editar módulo'),
      ),
      body: Form(
        key: _formulario,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
          children: [
            _Campo(
              controlador: _id,
              etiqueta: 'Identificador',
              ayuda: 'Nombre de la carpeta en Storage. Ej.: mt-grado-2',
              habilitado: _esNuevo,
              validar: (valor) => validarIdModulo(
                valor,
                idsExistentes: _esNuevo ? widget.idsExistentes : const {},
              ),
            ),
            _Campo(
              controlador: _nombre,
              etiqueta: 'Nombre',
              validar: validarObligatorio,
            ),
            _Campo(
              controlador: _area,
              etiqueta: 'Área',
              ayuda: 'Ej.: Lenguaje, Ciencias Sociales',
              validar: validarObligatorio,
            ),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: _Campo(
                    controlador: _grado,
                    etiqueta: 'Grado',
                    esNumero: true,
                    validar: (valor) => validarEntero(valor, minimo: 1, maximo: 11),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _Campo(
                    controlador: _version,
                    etiqueta: 'Versión',
                    esNumero: true,
                    validar: (valor) => validarEntero(valor, minimo: 1),
                  ),
                ),
              ],
            ),
            if (!_esNuevo)
              const Padding(
                padding: EdgeInsets.only(bottom: 16),
                child: Text(
                  'Sube la versión solo si cambiaste los archivos en Storage: '
                  'quien ya lo descargó verá que hay una actualización.',
                  style: TextStyle(
                    fontSize: 14,
                    color: AppTheme.textoSecundario,
                  ),
                ),
              ),
            _Campo(
              controlador: _descripcion,
              etiqueta: 'Descripción',
              lineas: 3,
              validar: validarObligatorio,
            ),
            _Campo(
              controlador: _contenidos,
              etiqueta: 'Contenidos (uno por línea)',
              lineas: 5,
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Habilitado'),
              subtitle: const Text(
                'Solo los módulos habilitados se muestran a los estudiantes.',
              ),
              value: _habilitado,
              onChanged: (valor) => setState(() => _habilitado = valor),
            ),
            if (_error case final error?)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  error,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.error,
                    fontSize: 15,
                  ),
                ),
              ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _guardando ? null : _guardar,
              child: _guardando
                  ? const CircularProgressIndicator()
                  : const Text('Guardar'),
            ),
          ],
        ),
      ),
    );
  }
}

class _Campo extends StatelessWidget {
  final TextEditingController controlador;
  final String etiqueta;
  final String? ayuda;
  final bool habilitado;
  final bool esNumero;
  final int lineas;
  final FormFieldValidator<String>? validar;

  const _Campo({
    required this.controlador,
    required this.etiqueta,
    this.ayuda,
    this.habilitado = true,
    this.esNumero = false,
    this.lineas = 1,
    this.validar,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        controller: controlador,
        enabled: habilitado,
        keyboardType: esNumero
            ? TextInputType.number
            : (lineas > 1 ? TextInputType.multiline : TextInputType.text),
        minLines: lineas,
        maxLines: lineas,
        validator: validar,
        decoration: InputDecoration(labelText: etiqueta, helperText: ayuda),
      ),
    );
  }
}

String? validarObligatorio(String? valor) {
  return (valor == null || valor.trim().isEmpty) ? 'Este campo es obligatorio.' : null;
}

/// Solo minúsculas, números y guiones: es también el nombre de la carpeta en
/// Storage y del documento en Firestore.
String? validarIdModulo(String? valor, {Set<String> idsExistentes = const {}}) {
  final id = valor?.trim() ?? '';

  if (id.isEmpty) {
    return 'Este campo es obligatorio.';
  }

  if (!RegExp(r'^[a-z0-9]+(-[a-z0-9]+)*$').hasMatch(id)) {
    return 'Usa solo minúsculas, números y guiones.';
  }

  if (idsExistentes.contains(id)) {
    return 'Ya existe un módulo con este identificador.';
  }

  return null;
}

String? validarEntero(String? valor, {required int minimo, int? maximo}) {
  final numero = int.tryParse(valor?.trim() ?? '');

  if (numero == null) {
    return 'Escribe un número.';
  }

  if (numero < minimo || (maximo != null && numero > maximo)) {
    return maximo == null
        ? 'Debe ser $minimo o más.'
        : 'Debe estar entre $minimo y $maximo.';
  }

  return null;
}
