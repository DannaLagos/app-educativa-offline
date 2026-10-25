import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';

import 'core/config/api_config.dart';
import 'core/network/conectividad_service.dart';
import 'core/theme/app_theme.dart';
import 'features/modulos/data/almacenamiento_modulos.dart';
import 'features/modulos/data/descarga_service.dart';
import 'features/modulos/data/firebase_modulo_remote_datasource.dart';
import 'features/modulos/data/http_modulo_remote_datasource.dart';
import 'features/modulos/data/modulo_local_datasource.dart';
import 'features/modulos/data/modulo_remote_datasource.dart';
import 'features/modulos/data/modulo_repository.dart';
import 'features/modulos/presentation/controllers/modulos_controller.dart';
import 'features/modulos/presentation/controllers/modulos_scope.dart';
import 'features/perfil/presentation/screens/verificar_perfil_screen.dart';
import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Firebase se inicializa sin red: solo carga la configuración local.
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  final modulosController = _crearModulosController();
  await modulosController.inicializar();

  runApp(
    AppEducativa(modulosController: modulosController),
  );
}

/// Arma las dependencias (inyección por constructor). Aquí es el único lugar
/// donde se decide qué servidor de contenidos usar.
ModulosController _crearModulosController() {
  final remote = _crearRemoteDataSource();
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

ModuloRemoteDataSource _crearRemoteDataSource() {
  if (!ApiConfig.usaFirebase) {
    return HttpModuloRemoteDataSource();
  }

  final storage = FirebaseStorage.instance
    ..setMaxDownloadRetryTime(ApiConfig.reintentoFirebase)
    ..setMaxOperationRetryTime(ApiConfig.reintentoFirebase);

  return FirebaseModuloRemoteDataSource(storage: storage);
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
