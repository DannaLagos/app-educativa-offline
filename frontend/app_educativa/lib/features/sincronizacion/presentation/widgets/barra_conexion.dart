import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../domain/resultado_sincronizacion.dart';
import '../sincronizacion_controller.dart';
import '../sincronizacion_scope.dart';

/// Barra corta en la parte de arriba de toda la app (HU10). Solo aparece
/// cuando no hay internet (criterio 1) o cuando un envío falló (criterio 3),
/// para no distraer al niño mientras juega.
class BarraConexion extends StatelessWidget {
  const BarraConexion({super.key});

  static bool seMuestra(SincronizacionController? sincronizacion) {
    return sincronizacion != null &&
        (!sincronizacion.hayConexion ||
            sincronizacion.estado == EstadoSincronizacion.error);
  }

  /// Pone la barra encima de [child] (se usa en `MaterialApp.builder`).
  static Widget envolver(BuildContext context, Widget? child) {
    final visible = seMuestra(SincronizacionScope.maybeOf(context));

    // La estructura es siempre la misma para no reconstruir la navegación
    // al aparecer o desaparecer la barra.
    return Column(
      children: [
        const BarraConexion(),
        Expanded(
          // Con la barra visible, ella ya ocupa el espacio de la barra de
          // estado del teléfono.
          child: MediaQuery.removePadding(
            context: context,
            removeTop: visible,
            child: child ?? const SizedBox.shrink(),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final sincronizacion = SincronizacionScope.maybeOf(context);

    if (!seMuestra(sincronizacion)) {
      return const SizedBox.shrink();
    }

    if (!sincronizacion!.hayConexion) {
      return const _Barra(
        key: ValueKey('barra-sin-conexion'),
        icono: Icons.wifi_off_rounded,
        color: AppTheme.ambar,
        fondo: AppTheme.ambarSuave,
        texto: 'Sin internet · Tu progreso se guarda en el teléfono',
      );
    }

    return _Barra(
      key: const ValueKey('barra-error-sincronizacion'),
      icono: Icons.cloud_off_rounded,
      color: AppTheme.rojo,
      fondo: AppTheme.rojoSuave,
      texto: 'No se pudo enviar tu progreso · Está guardado',
      accion: TextButton(
        key: const ValueKey('boton-reintentar-barra'),
        onPressed: sincronizacion.sincronizar,
        child: const Text('Reintentar'),
      ),
    );
  }
}

class _Barra extends StatelessWidget {
  final IconData icono;
  final Color color;
  final Color fondo;
  final String texto;
  final Widget? accion;

  const _Barra({
    super.key,
    required this.icono,
    required this.color,
    required this.fondo,
    required this.texto,
    this.accion,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      liveRegion: true,
      child: Material(
        color: fondo,
        child: SafeArea(
          bottom: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 6, 8, 6),
            child: Row(
              children: [
                Icon(icono, color: color, size: 22),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    texto,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: color,
                    ),
                  ),
                ),
                if (accion != null) accion!,
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Tarjeta con el estado completo de la conexión y del envío (se muestra en
/// "Mi progreso").
class TarjetaSincronizacion extends StatelessWidget {
  const TarjetaSincronizacion({super.key});

  @override
  Widget build(BuildContext context) {
    final sincronizacion = SincronizacionScope.maybeOf(context);

    if (sincronizacion == null) {
      return const SizedBox.shrink();
    }

    final pendientes = sincronizacion.pendientes;
    final avances = pendientes == 1 ? '1 avance' : '$pendientes avances';
    final hayConexion = sincronizacion.hayConexion;

    final (IconData icono, Color color, Color fondo, String titulo, String detalle) =
        switch (sincronizacion.estado) {
      EstadoSincronizacion.sincronizando => (
          Icons.cloud_upload_rounded,
          AppTheme.azul,
          AppTheme.azulSuave,
          'Enviando tu progreso…',
          'No cierres la app por un momento.',
        ),
      EstadoSincronizacion.alDia => (
          Icons.cloud_done_rounded,
          AppTheme.verde,
          AppTheme.verdeSuave,
          'Todo tu progreso está enviado',
          sincronizacion.ultimaSincronizacion == null
              ? 'No tienes avances por enviar.'
              : 'Último envío: ${_hora(sincronizacion.ultimaSincronizacion!)}.',
        ),
      EstadoSincronizacion.pendiente => (
          Icons.schedule_rounded,
          hayConexion ? AppTheme.azul : AppTheme.ambar,
          hayConexion ? AppTheme.azulSuave : AppTheme.ambarSuave,
          'Tienes $avances por enviar',
          hayConexion
              ? 'Se enviarán en un momento.'
              : 'Están guardados en el teléfono. Se enviarán cuando vuelva '
                  'el internet.',
        ),
      EstadoSincronizacion.error => (
          Icons.cloud_off_rounded,
          AppTheme.rojo,
          AppTheme.rojoSuave,
          pendientes == 1
              ? 'No se pudo enviar 1 avance'
              : 'No se pudieron enviar $avances',
          'No se perdió nada: siguen guardados en el teléfono y se '
              'intentará otra vez.',
        ),
    };

    return Container(
      key: const ValueKey('tarjeta-sincronizacion'),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: fondo,
        borderRadius: BorderRadius.circular(AppTheme.radio),
        border: Border.all(color: color, width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                hayConexion ? Icons.wifi_rounded : Icons.wifi_off_rounded,
                color: hayConexion ? AppTheme.verde : AppTheme.ambar,
              ),
              const SizedBox(width: 8),
              Text(
                hayConexion ? 'Con internet' : 'Sin internet',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: hayConexion ? AppTheme.verde : AppTheme.ambar,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icono, color: color, size: 28),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      titulo,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: color,
                      ),
                    ),
                    Text(detalle, style: const TextStyle(fontSize: 16)),
                  ],
                ),
              ),
            ],
          ),
          if (hayConexion &&
              (sincronizacion.estado == EstadoSincronizacion.error ||
                  sincronizacion.estado == EstadoSincronizacion.pendiente)) ...[
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: FilledButton.icon(
                key: const ValueKey('boton-reintentar'),
                onPressed: sincronizacion.sincronizar,
                icon: const Icon(Icons.refresh_rounded),
                label: Text(
                  sincronizacion.estado == EstadoSincronizacion.error
                      ? 'Intentar de nuevo'
                      : 'Enviar ahora',
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  static String _hora(DateTime fecha) {
    String dos(int n) => n.toString().padLeft(2, '0');

    return '${dos(fecha.day)}/${dos(fecha.month)} a las '
        '${dos(fecha.hour)}:${dos(fecha.minute)}';
  }
}
