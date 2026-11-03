import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../shared/widgets/fondo_divertido.dart';
import '../../../modulos/presentation/widgets/encabezado_mundo.dart';
import '../../data/admin_local_datasource.dart';
import '../../domain/sesion_admin.dart';
import '../../domain/superadministrador.dart';
import 'panel_admin_screen.dart';

class LoginAdminScreen extends StatefulWidget {
  final AdminLocalDataSource? adminLocalDataSource;

  const LoginAdminScreen({
    super.key,
    this.adminLocalDataSource,
  });

  @override
  State<LoginAdminScreen> createState() => _LoginAdminScreenState();
}

class _LoginAdminScreenState extends State<LoginAdminScreen> {
  static const double _alturaBotonIngresar = 52;

  final TextEditingController _usuarioController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  late final AdminLocalDataSource _adminLocalDataSource =
      widget.adminLocalDataSource ?? AdminLocalDataSource();

  bool _estaVerificando = false;
  bool _debeOcultarPassword = true;
  String? _mensajeError;

  @override
  void dispose() {
    _usuarioController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _iniciarSesion() async {
    final usuario = _usuarioController.text.trim();
    final password = _passwordController.text;

    if (usuario.isEmpty || password.isEmpty) {
      setState(() => _mensajeError = 'Ingresa tu usuario y contraseña.');
      return;
    }

    setState(() {
      _estaVerificando = true;
      _mensajeError = null;
    });

    await _autenticar(usuario, password);
  }

  Future<void> _autenticar(String usuario, String password) async {
    try {
      final admin = await _adminLocalDataSource.autenticar(usuario, password);

      if (!mounted) return;

      if (admin == null) {
        _passwordController.clear();
        _mostrarError('Los datos de acceso no son válidos.');
        return;
      }

      _abrirPanel(admin);
    } catch (error, stack) {
      debugPrint('Error al verificar el administrador: $error\n$stack');

      if (!mounted) return;

      _mostrarError('No fue posible verificar los datos. Intenta de nuevo.');
    }
  }

  void _mostrarError(String mensaje) {
    setState(() {
      _estaVerificando = false;
      _mensajeError = mensaje;
    });
  }

  void _abrirPanel(Superadministrador admin) {
    SesionAdmin.instance.iniciar(admin);

    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => const PanelAdminScreen(),
      ),
    );
  }

  void _alternarVisibilidadPassword() {
    setState(() => _debeOcultarPassword = !_debeOcultarPassword);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Acceso administrador'),
        backgroundColor: Colors.transparent,
      ),
      extendBodyBehindAppBar: true,
      body: FondoDivertido(
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const _Encabezado(),
                  const SizedBox(height: 20),
                  // Formulario en una tarjeta blanca, sobrio: es para el
                  // docente, no para el niño.
                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: AppTheme.superficie,
                      borderRadius: BorderRadius.circular(26),
                      border: Border.all(color: AppTheme.borde, width: 2),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _construirCampoUsuario(),
                        const SizedBox(height: 16),
                        _construirCampoPassword(),
                        ..._construirMensajeError(context),
                        const SizedBox(height: 24),
                        _construirBotonIngresar(),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _construirCampoUsuario() {
    return TextField(
      controller: _usuarioController,
      autocorrect: false,
      textInputAction: TextInputAction.next,
      decoration: const InputDecoration(
        labelText: 'Usuario',
        prefixIcon: Icon(Icons.person_outline),
        border: OutlineInputBorder(),
      ),
    );
  }

  Widget _construirCampoPassword() {
    return TextField(
      controller: _passwordController,
      obscureText: _debeOcultarPassword,
      autocorrect: false,
      enableSuggestions: false,
      textInputAction: TextInputAction.done,
      onSubmitted: (_) => _iniciarSesion(),
      decoration: InputDecoration(
        labelText: 'Contraseña',
        prefixIcon: const Icon(Icons.lock_outline),
        border: const OutlineInputBorder(),
        suffixIcon: IconButton(
          tooltip: _debeOcultarPassword
              ? 'Mostrar contraseña'
              : 'Ocultar contraseña',
          icon: Icon(
            _debeOcultarPassword
                ? Icons.visibility_outlined
                : Icons.visibility_off_outlined,
          ),
          onPressed: _alternarVisibilidadPassword,
        ),
      ),
    );
  }

  List<Widget> _construirMensajeError(BuildContext context) {
    final mensaje = _mensajeError;

    if (mensaje == null) {
      return const [];
    }

    return [
      const SizedBox(height: 16),
      Text(
        mensaje,
        textAlign: TextAlign.center,
        style: TextStyle(
          color: Theme.of(context).colorScheme.error,
          fontSize: 15,
        ),
      ),
    ];
  }

  Widget _construirBotonIngresar() {
    return SizedBox(
      height: _alturaBotonIngresar,
      child: ElevatedButton(
        onPressed: _estaVerificando ? null : _iniciarSesion,
        child: _estaVerificando
            ? const CircularProgressIndicator()
            : const Text('Ingresar', style: TextStyle(fontSize: 16)),
      ),
    );
  }
}

class _Encabezado extends StatelessWidget {
  const _Encabezado();

  @override
  Widget build(BuildContext context) {
    return const EncabezadoMundo(
      area: '',
      titulo: 'Inicia sesión',
      subtitulo: 'Solo para el superadministrador de la aplicación.',
      color: AppTheme.azul,
      emoji: '🔑',
    );
  }
}
