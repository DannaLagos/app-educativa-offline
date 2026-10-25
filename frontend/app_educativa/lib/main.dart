import 'package:flutter/material.dart';

import 'core/network/conectividad_service.dart';
import 'core/theme/app_theme.dart';
import 'features/modulos/data/almacenamiento_modulos.dart';
import 'features/modulos/data/descarga_service.dart';
import 'features/modulos/data/modulo_local_datasource.dart';
import 'features/modulos/data/modulo_remote_datasource.dart';
import 'features/modulos/data/modulo_repository.dart';
import 'features/modulos/presentation/controllers/modulos_controller.dart';
import 'features/modulos/presentation/controllers/modulos_scope.dart';
import 'features/perfil/presentation/screens/verificar_perfil_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final modulosController = _crearModulosController();
  await modulosController.inicializar();

  runApp(
    AppEducativa(modulosController: modulosController),
  );
}

ModulosController _crearModulosController() {
  final remote = ModuloRemoteDataSource();
  final local = ModuloLocalDataSource();
  final conectividad = ConectividadService();
  final almacenamiento = AlmacenamientoModulos();

  return ModulosController(
    repositorio: ModuloRepository(
      remote: remote,
      local: local,
      conectividad: conectividad,
      almacenamiento: almacenamiento,
    ),
    descargaService: DescargaService(
      remote: remote,
      local: local,
      conectividad: conectividad,
      almacenamiento: almacenamiento,
    ),
  );
}

class AppEducativa extends StatelessWidget {
  final ModulosController modulosController;

  const AppEducativa({
    super.key,
    required this.modulosController,
  });

  @override
  Widget build(BuildContext context) {
    return ModulosScope(
      controller: modulosController,
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Aprendo',
        theme: AppTheme.claro,
        home: const VerificarPerfilScreen(),
      ),
    );
  }
}
