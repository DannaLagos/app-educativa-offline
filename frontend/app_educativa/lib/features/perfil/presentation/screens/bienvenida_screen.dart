import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../shared/widgets/boton_escuchar.dart';
import '../../../../shared/widgets/fondo_divertido.dart';
import '../../../../shared/widgets/logo_aprendo.dart';
import '../../../../shared/widgets/panel_jugador.dart';
import '../../../admin/presentation/screens/login_admin_screen.dart';
import '../../../mascota/domain/mascota.dart';
import '../../../mascota/presentation/widgets/escenario_mascota.dart';
import '../../../mascota/presentation/widgets/mascota_animada.dart';
import 'crear_perfil_screen.dart';

class BienvenidaScreen extends StatelessWidget {
  static const String _saludo =
      '¡Hola, amiguito! Estoy listo para explorar nuevos mundos contigo hoy. '
      '¿Empezamos?';

  const BienvenidaScreen({super.key});

  void _abrir(BuildContext context, Widget pantalla) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => pantalla),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FondoDivertido(
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 28, 16, 24),
            children: [
              const LogoAprendo(),
              const SizedBox(height: 6),
              const Text(
                'Tu aventura de aprendizaje',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textoSecundario,
                ),
              ),
              const SizedBox(height: 22),
              _Escenario(
                accion: BotonJugar(
                  texto: 'Comenzar aventura',
                  detalle: 'Crea tu perfil y elige tu mascota',
                  onPressed: () => _abrir(context, const CrearPerfilScreen()),
                ),
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
      ),
    );
  }
}

/// Escenario morado, como el del inicio: la burbuja que saluda, las cinco
/// mascotas saltando sobre la isla y el botón para empezar.
class _Escenario extends StatelessWidget {
  static const Color _fondoClaro = Color(0xFF8C6CF2);

  final Widget accion;

  const _Escenario({required this.accion});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [_fondoClaro, AppTheme.morado],
        ),
        borderRadius: BorderRadius.circular(30),
        boxShadow: const [
          BoxShadow(color: Color(0xFF4A2BB0), offset: Offset(0, 7)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const BurbujaDialogo(
            texto: '¡Hola, amiguito!',
            detalle: 'Estoy listo para explorar nuevos mundos contigo hoy. '
                '¿Empezamos?',
            botonEscuchar: BotonEscuchar(texto: BienvenidaScreen._saludo),
          ),
          const SizedBox(height: 6),
          const _DesfileMascotas(),
          const SizedBox(height: 18),
          accion,
        ],
      ),
    );
  }
}

/// Las cinco mascotas saltando sobre una isla de pasto, para que el niño
/// las conozca desde el inicio.
class _DesfileMascotas extends StatelessWidget {
  static const Color _pasto = Color(0xFF5BD47A);

  const _DesfileMascotas();

  @override
  Widget build(BuildContext context) {
    const especies = EspecieMascota.values;

    return LayoutBuilder(
      builder: (context, limites) {
        final tamano = (limites.maxWidth / especies.length).clamp(48.0, 76.0);

        return SizedBox(
          height: tamano + 22,
          child: Stack(
            alignment: Alignment.bottomCenter,
            children: [
              Container(
                height: 30,
                decoration: BoxDecoration(
                  color: _pasto,
                  borderRadius: const BorderRadius.all(
                    Radius.elliptical(200, 15),
                  ),
                  border: Border(
                    bottom: BorderSide(
                      color: Color.lerp(_pasto, Colors.black, 0.3)!,
                      width: 6,
                    ),
                  ),
                ),
              ),
              Positioned(
                bottom: 10,
                left: 0,
                right: 0,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    for (var i = 0; i < especies.length; i++)
                      MascotaAnimada(
                        especie: especies[i],
                        etapa: EtapaMascota.bebe,
                        tamano: tamano,
                        desfase: i / especies.length,
                      ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
