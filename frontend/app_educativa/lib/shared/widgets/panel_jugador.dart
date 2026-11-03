import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../features/mascota/domain/mascota.dart';
import '../../features/mascota/presentation/apariencia_mascota.dart';
import '../../features/mascota/presentation/widgets/mascota_animada.dart';

/// Barra de jugador, como en un videojuego: la mascota, el nombre, el nivel
/// de la mascota y las estrellas ganadas. Se usa arriba de las pantallas
/// del estudiante.
class BarraJugador extends StatelessWidget {
  static const double _tamanoAvatar = 58;

  final String nombre;

  /// null si todavía no eligió mascota.
  final EspecieMascota? mascota;
  final int estrellas;

  /// null mientras no se sabe si hay internet.
  final bool? hayConexion;
  final VoidCallback? onAbrirAdmin;

  const BarraJugador({
    super.key,
    required this.nombre,
    required this.mascota,
    required this.estrellas,
    this.hayConexion,
    this.onAbrirAdmin,
  });

  @override
  Widget build(BuildContext context) {
    final especie = mascota;
    final etapa = EtapaMascota.segunEstrellas(estrellas);
    final color = especie == null
        ? AppTheme.morado
        : AparienciaMascota.de(especie).principal;

    return Row(
      children: [
        Container(
          width: _tamanoAvatar,
          height: _tamanoAvatar,
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            border: Border.all(color: color, width: 4),
          ),
          alignment: Alignment.center,
          child: especie == null
              ? const Icon(Icons.face_rounded, color: AppTheme.morado, size: 34)
              : MascotaAnimada(
                  especie: especie,
                  etapa: etapa,
                  tamano: _tamanoAvatar - 10,
                  animada: false,
                  saltaAlTocar: false,
                ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                nombre,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.texto,
                ),
              ),
              if (especie != null)
                // Solo el número: la etapa ("Exploradora") ya se ve en el
                // escenario y aquí no cabe en una línea.
                _Chip(
                  texto: 'Nivel ${etapa.index + 1}',
                  fondo: AppTheme.morado,
                  colorTexto: Colors.white,
                ),
            ],
          ),
        ),
        _ContadorEstrellas(estrellas: estrellas),
        if (hayConexion != null) ...[
          const SizedBox(width: 6),
          _IndicadorConexion(hayConexion: hayConexion!),
        ],
        if (onAbrirAdmin != null)
          IconButton(
            tooltip: 'Acceso administrador',
            color: AppTheme.textoSecundario,
            icon: const Icon(Icons.admin_panel_settings_outlined),
            onPressed: onAbrirAdmin,
          ),
      ],
    );
  }
}

class _Chip extends StatelessWidget {
  final String texto;
  final Color fondo;
  final Color colorTexto;

  const _Chip({
    required this.texto,
    required this.fondo,
    required this.colorTexto,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 2),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      decoration: BoxDecoration(
        color: fondo,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        texto,
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w800,
          color: colorTexto,
        ),
      ),
    );
  }
}

class _ContadorEstrellas extends StatelessWidget {
  final int estrellas;

  const _ContadorEstrellas({required this.estrellas});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: '$estrellas estrellas',
      excludeSemantics: true,
      child: Container(
        padding: const EdgeInsets.fromLTRB(6, 4, 12, 4),
        decoration: BoxDecoration(
          color: AppTheme.amarilloSuave,
          borderRadius: BorderRadius.circular(30),
          border: Border.all(color: AppTheme.amarillo, width: 3),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.star_rounded,
              color: Color(0xFFFFB627),
              size: 30,
              shadows: [Shadow(color: Color(0x66C2410C), offset: Offset(0, 2))],
            ),
            const SizedBox(width: 2),
            Text(
              '$estrellas',
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: Color(0xFF5C3A00),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _IndicadorConexion extends StatelessWidget {
  final bool hayConexion;

  const _IndicadorConexion({required this.hayConexion});

  @override
  Widget build(BuildContext context) {
    final texto = hayConexion ? 'Conectado' : 'Sin conexión';

    return Tooltip(
      message: texto,
      child: Semantics(
        label: texto,
        excludeSemantics: true,
        child: Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: hayConexion ? AppTheme.verdeSuave : AppTheme.grisSuave,
            shape: BoxShape.circle,
          ),
          child: Icon(
            hayConexion ? Icons.wifi_rounded : Icons.wifi_off_rounded,
            size: 20,
            color: hayConexion ? AppTheme.verde : AppTheme.gris,
          ),
        ),
      ),
    );
  }
}

/// El botón principal de la app: amarillo, enorme y con relieve, como el
/// botón "Jugar" de un videojuego.
class BotonJugar extends StatefulWidget {
  static const double _relieve = 7;
  static const Color _texto = Color(0xFF5C3A00);

  final String texto;

  /// Debajo del texto, en pequeño (por ejemplo, dónde iba el niño).
  final String? detalle;
  final VoidCallback onPressed;

  const BotonJugar({
    super.key,
    this.texto = '¡A jugar!',
    this.detalle,
    required this.onPressed,
  });

  @override
  State<BotonJugar> createState() => _BotonJugarState();
}

class _BotonJugarState extends State<BotonJugar> {
  bool _presionado = false;

  @override
  Widget build(BuildContext context) {
    const relieve = BotonJugar._relieve;
    final hundido = _presionado ? relieve : 0.0;
    final radio = BorderRadius.circular(22);
    final detalle = widget.detalle;

    return Padding(
      padding: const EdgeInsets.only(bottom: relieve),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 80),
        transform: Matrix4.translationValues(0, hundido, 0),
        decoration: BoxDecoration(
          color: AppTheme.amarillo,
          borderRadius: radio,
          border: Border.all(color: const Color(0xFFFFE08A), width: 3),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFC98A00),
              offset: Offset(0, relieve - hundido),
            ),
          ],
        ),
        child: Material(
          type: MaterialType.transparency,
          child: InkWell(
            borderRadius: radio,
            onTap: widget.onPressed,
            onHighlightChanged: (valor) => setState(() => _presionado = valor),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              child: Row(
                children: [
                  Container(
                    width: 54,
                    height: 54,
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.play_arrow_rounded,
                      size: 40,
                      color: AppTheme.naranja,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.texto,
                          style: const TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.w800,
                            color: BotonJugar._texto,
                            height: 1.1,
                          ),
                        ),
                        if (detalle != null)
                          Text(
                            detalle,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: BotonJugar._texto,
                            ),
                          ),
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
}
