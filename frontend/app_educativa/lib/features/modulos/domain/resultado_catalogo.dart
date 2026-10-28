import 'modulo.dart';

class ResultadoCatalogo {
  final List<Modulo> modulos;
  final bool vieneDeCache;

  const ResultadoCatalogo({
    required this.modulos,
    required this.vieneDeCache,
  });
}
