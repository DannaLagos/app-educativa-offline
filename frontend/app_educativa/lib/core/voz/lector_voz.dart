import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_tts/flutter_tts.dart';

/// Lee textos en voz alta para los niños que todavía no leen bien.
abstract class LectorVoz {
  Future<void> hablar(String texto);

  Future<void> detener();
}

/// No dice nada. Se usa en pruebas y cuando no hay [VozScope].
class LectorVozSilencioso implements LectorVoz {
  const LectorVozSilencioso();

  @override
  Future<void> hablar(String texto) async {}

  @override
  Future<void> detener() async {}
}

/// Usa el motor de voz del teléfono (no necesita internet si el teléfono
/// tiene instalada una voz en español). Si algo falla, la app sigue
/// funcionando sin voz.
class LectorVozTts implements LectorVoz {
  static const List<String> _idiomas = ['es-CO', 'es-US', 'es-MX', 'es-ES'];

  /// Un poco más lento de lo normal para que los niños entiendan.
  static const double _velocidad = 0.45;

  final FlutterTts _tts = FlutterTts();
  Future<bool>? _configuracion;

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
      await _tts.speak(texto);
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
