import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../shared/widgets/boton_escuchar.dart';
import '../../../../shared/widgets/fondo_divertido.dart';
import '../../../../shared/widgets/panel_jugador.dart';
import '../../../admin/presentation/screens/login_admin_screen.dart';
import '../../../mascota/domain/mascota.dart';
import '../../../mascota/presentation/apariencia_mascota.dart';
import '../../../mascota/presentation/widgets/selector_mascota.dart';
import '../../../modulos/presentation/widgets/encabezado_mundo.dart';
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
  final TextEditingController _nombreController = TextEditingController();
  late final PerfilLocalDataSource _perfilLocalDataSource =
      widget.perfilLocalDataSource ?? PerfilLocalDataSource();

  bool _estaGuardando = false;
  String? _mensajeError;
  EspecieMascota? _mascota;
  String? _errorMascota;

  /// Nombre de la mascota: se llena con el de la especie y el niño lo puede
  /// cambiar tocando una sugerencia o escribiendo.
  final _nombreMascotaController = TextEditingController();

  @override
  void dispose() {
    _nombreController.dispose();
    _nombreMascotaController.dispose();
    super.dispose();
  }

  void _seleccionarMascota(EspecieMascota especie) {
    final anterior = _mascota;
    final actual = _nombreMascotaController.text.trim();
    // Si no le había puesto un nombre propio, toma el de la nueva especie.
    final eraSugerido = actual.isEmpty ||
        (anterior != null && anterior.nombresSugeridos.contains(actual));

    setState(() {
      _mascota = especie;
      _errorMascota = null;
    });

    if (eraSugerido) {
      _nombreMascotaController.text = especie.nombre;
    }
  }

  Future<void> _crearPerfil() async {
    final nombre = _nombreController.text.trim();
    final mascota = _mascota;

    if (nombre.isEmpty) {
      setState(() => _mensajeError = 'Ingresa tu nombre para continuar.');
      return;
    }

    if (mascota == null) {
      setState(() {
        _mensajeError = null;
        _errorMascota = 'Elige una mascota para continuar.';
      });
      return;
    }

    setState(() {
      _estaGuardando = true;
      _mensajeError = null;
      _errorMascota = null;
    });

    final perfil = PerfilEstudiante(
      id: const Uuid().v4(),
      nombre: nombre,
      mascota: mascota,
      nombreMascota: _nombreMascotaController.text.trim(),
    );
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
      appBar: AppBar(backgroundColor: Colors.transparent),
      extendBodyBehindAppBar: true,
      body: FondoDivertido(
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 56, 16, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const _Encabezado(),
                const SizedBox(height: 20),
                _Paso(
                  numero: 1,
                  titulo: '¿Cómo te llamas?',
                  color: AppTheme.morado,
                  child: TextField(
                    controller: _nombreController,
                    textCapitalization: TextCapitalization.words,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                    ),
                    decoration: InputDecoration(
                      hintText: 'Por ejemplo, Valentina',
                      prefixIcon: const Icon(Icons.edit_rounded, size: 28),
                      errorText: _mensajeError,
                    ),
                    onSubmitted: (_) => _crearPerfil(),
                  ),
                ),
                const SizedBox(height: 16),
                _Paso(
                  numero: 2,
                  titulo: 'Elige tu mascota',
                  subtitulo: '¡Crecerá contigo mientras aprendes!',
                  color: AppTheme.rosa,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      SelectorMascota(
                        seleccionada: _mascota,
                        onSeleccionar: _seleccionarMascota,
                      ),
                      if (_errorMascota != null) ...[
                        const SizedBox(height: 8),
                        Text(
                          _errorMascota!,
                          style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.rojo,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                if (_mascota case final especie?) ...[
                  const SizedBox(height: 16),
                  _Paso(
                    numero: 3,
                    titulo: 'Ponle un nombre',
                    subtitulo: 'Toca uno o escribe el tuyo',
                    color: AppTheme.turquesa,
                    child: _NombreMascota(
                      especie: especie,
                      controller: _nombreMascotaController,
                    ),
                  ),
                ],
                const SizedBox(height: 24),
                BotonJugar(
                  texto: '¡Listos, continuar!',
                  detalle: 'Ir a mi aventura',
                  // Mientras guarda, un toque más no hace nada.
                  onPressed: _estaGuardando ? () {} : _crearPerfil,
                ),
                const SizedBox(height: 8),
                TextButton.icon(
                  onPressed: _abrirLoginAdmin,
                  icon: const Icon(Icons.admin_panel_settings_outlined),
                  label: const Text('Acceso administrador'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Encabezado extends StatelessWidget {
  static const String _instrucciones =
      'Crea tu perfil. Primero escribe tu nombre. Después toca la mascota '
      'que más te guste y ponle un nombre.';

  const _Encabezado();

  @override
  Widget build(BuildContext context) {
    return const EncabezadoMundo(
      area: '',
      titulo: 'Crea tu perfil',
      subtitulo: '¡Empecemos tu aventura!',
      color: AppTheme.morado,
      emoji: '✏️',
      extremo: BotonEscuchar(texto: _instrucciones, color: AppTheme.naranja),
    );
  }
}

/// Un paso numerado en una tarjeta blanca, para que el niño sepa qué hacer
/// primero y qué después.
class _Paso extends StatelessWidget {
  static const double _tamanoNumero = 40;

  final int numero;
  final String titulo;
  final String? subtitulo;
  final Color color;
  final Widget child;

  const _Paso({
    required this.numero,
    required this.titulo,
    required this.color,
    required this.child,
    this.subtitulo,
  });

  @override
  Widget build(BuildContext context) {
    final detalle = subtitulo;

    return Container(
      padding: const EdgeInsets.all(16),
      // Tarjeta blanca como las del detalle del módulo.
      decoration: BoxDecoration(
        color: AppTheme.superficie,
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: AppTheme.borde, width: 2),
        boxShadow: const [
          BoxShadow(color: AppTheme.borde, offset: Offset(0, 5)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                width: _tamanoNumero,
                height: _tamanoNumero,
                alignment: Alignment.center,
                decoration: BoxDecoration(color: color, shape: BoxShape.circle),
                child: Text(
                  '$numero',
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  titulo,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          if (detalle != null) ...[
            const SizedBox(height: 4),
            Text(
              detalle,
              style: const TextStyle(
                fontSize: 17,
                color: AppTheme.textoSecundario,
              ),
            ),
          ],
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }
}

/// Nombres para tocar (quien aún no escribe bien) y un campo para escribir
/// uno propio.
class _NombreMascota extends StatelessWidget {
  static const int _largoMaximo = 14;

  final EspecieMascota especie;
  final TextEditingController controller;

  const _NombreMascota({required this.especie, required this.controller});

  @override
  Widget build(BuildContext context) {
    final color = AparienciaMascota.de(especie).principal;

    return ValueListenableBuilder<TextEditingValue>(
      valueListenable: controller,
      builder: (context, valor, _) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final nombre in especie.nombresSugeridos)
                ChoiceChip(
                  label: Text(nombre),
                  selected: valor.text.trim() == nombre,
                  selectedColor: color.withValues(alpha: 0.25),
                  side: BorderSide(color: color, width: 2),
                  labelStyle: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.texto,
                  ),
                  onSelected: (_) => controller.text = nombre,
                ),
            ],
          ),
          const SizedBox(height: 12),
          TextField(
            key: const ValueKey('nombre-mascota'),
            controller: controller,
            maxLength: _largoMaximo,
            textCapitalization: TextCapitalization.words,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
            decoration: InputDecoration(
              hintText: especie.nombre,
              prefixIcon: const Icon(Icons.pets_rounded, size: 26),
              counterText: '',
            ),
          ),
        ],
      ),
    );
  }
}
