import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_tts/flutter_tts.dart';

/// Lee textos en voz alta para los niños que todavía no leen bien.
abstract class LectorVoz {
  /// Corta lo que se estaba diciendo y lee [texto]. Termina cuando la voz
  /// acaba de hablar (o la cortan), así se pueden leer textos en orden.
  Future<void> hablar(String texto);

  Future<void> detener();

  /// false si el teléfono no tiene un motor de voz instalado (pasa en
  /// algunos emuladores y teléfonos sin los servicios de Google): entonces
  /// [hablar] no suena.
  Future<bool> estaDisponible();
}

/// No dice nada. Se usa en pruebas y cuando no hay [VozScope].
class LectorVozSilencioso implements LectorVoz {
  const LectorVozSilencioso();

  @override
  Future<void> hablar(String texto) async {}

  @override
  Future<void> detener() async {}

  // Calla a propósito: no hay que avisar que falta la voz.
  @override
  Future<bool> estaDisponible() async => true;
}

/// Usa el motor de voz del teléfono (no necesita internet si el teléfono
/// tiene instalada una voz en español). Si algo falla, la app sigue
/// funcionando sin voz.
class LectorVozTts implements LectorVoz {
  static const List<String> _idiomas = ['es-CO', 'es-US', 'es-MX', 'es-ES'];

  /// Un poco más lento de lo normal para que los niños entiendan.
  static const double _velocidad = 0.45;

  /// Por si el motor de voz nunca avisa que terminó: la lectura en orden
  /// no se queda esperando para siempre.
  static const Duration _esperaMaxima = Duration(seconds: 15);

  final FlutterTts _tts = FlutterTts();
  Future<bool>? _configuracion;
  bool _hayMotor = false;

  Future<bool> _configurar() async {
    try {
      for (final idioma in _idiomas) {
        if (await _tts.isLanguageAvailable(idioma) == true) {
          await _tts.setLanguage(idioma);
          break;
        }
      }
      await _tts.setSpeechRate(_velocidad);
      await _tts.setPitch(1.05);
      // speak() termina cuando la voz acaba de hablar, no al empezar.
      await _tts.awaitSpeakCompletion(true);

      return true;
    } catch (error) {
      debugPrint('No se pudo configurar la voz: $error');
      return false;
    }
  }

  @override
  Future<void> hablar(String texto) async {
    if (!await (_configuracion ??= _configurar())) {
      return;
    }

    try {
      await _tts.stop();
      await _tts.speak(texto).timeout(_esperaMaxima, onTimeout: () => null);
    } catch (error) {
      debugPrint('No se pudo leer en voz alta: $error');
    }
  }

  @override
  Future<void> detener() async {
    try {
      await _tts.stop();
    } catch (error) {
      debugPrint('No se pudo detener la voz: $error');
    }
  }

  /// Solo Android dice qué motores de voz hay. Si se encuentra uno se
  /// recuerda; si no, se vuelve a preguntar la próxima vez (por si un adulto
  /// lo instala mientras la app está abierta).
  @override
  Future<bool> estaDisponible() async {
    if (_hayMotor || defaultTargetPlatform != TargetPlatform.android) {
      return true;
    }

    try {
      final motores = await _tts.getEngines;
      _hayMotor = motores is List && motores.isNotEmpty;
      return _hayMotor;
    } catch (error) {
      // Ante la duda no se molesta al niño con avisos.
      debugPrint('No se pudo revisar el motor de voz: $error');
      return true;
    }
  }
}

class VozScope extends InheritedWidget {
  final LectorVoz voz;

  const VozScope({
    super.key,
    required this.voz,
    required super.child,
  });

  static LectorVoz de(BuildContext context) {
    return context.getInheritedWidgetOfExactType<VozScope>()?.voz ??
        const LectorVozSilencioso();
  }

  @override
  bool updateShouldNotify(VozScope oldWidget) => voz != oldWidget.voz;
}
