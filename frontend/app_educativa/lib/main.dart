import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';

import 'core/config/api_config.dart';
import 'core/network/conectividad_service.dart';
import 'core/theme/app_theme.dart';
import 'core/voz/lector_voz.dart';
import 'features/modulos/data/almacenamiento_modulos.dart';
import 'features/modulos/data/descarga_service.dart';
import 'features/modulos/data/firebase_modulo_remote_datasource.dart';
import 'features/modulos/data/http_modulo_remote_datasource.dart';
import 'features/modulos/data/modulo_local_datasource.dart';
import 'features/modulos/data/modulo_remote_datasource.dart';
import 'features/modulos/data/modulo_repository.dart';
import 'features/modulos/presentation/controllers/modulos_controller.dart';
import 'features/modulos/presentation/controllers/modulos_scope.dart';
import 'features/perfil/data/perfil_local_datasource.dart';
import 'features/perfil/presentation/screens/verificar_perfil_screen.dart';
import 'features/progreso/data/firestore_progreso_remote_datasource.dart';
import 'features/progreso/data/progreso_local_datasource.dart';
import 'features/progreso/data/progreso_remote_datasource.dart';
import 'features/progreso/data/progreso_repository.dart';
import 'features/progreso/presentation/progreso_controller.dart';
import 'features/progreso/presentation/progreso_scope.dart';
import 'features/sincronizacion/presentation/sincronizacion_controller.dart';
import 'features/sincronizacion/presentation/sincronizacion_scope.dart';
import 'features/sincronizacion/presentation/widgets/barra_conexion.dart';
import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Firebase se inicializa sin red: solo carga la configuración local.
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  final conectividad = ConectividadService();

  final modulosController = _crearModulosController(conectividad);
  await modulosController.inicializar();

  // Un solo repositorio de progreso (offline first) para guardar y sincronizar.
  final progresoRepository = _crearProgresoRepository(conectividad);

  // HU08: carga en segundo plano dónde iba el estudiante.
  final progresoController = ProgresoController(
    repositorio: progresoRepository,
  )..cargarUltimoModulo();

  final sincronizacionController = SincronizacionController(
    repositorio: progresoRepository,
    conectividad: conectividad,
  );

  // HU10 (Observer): cada avance guardado avisa a la sincronización.
  progresoController.addListener(sincronizacionController.alCambiarProgreso);

  // HU11: al terminar un envío, las pantallas muestran qué quedó en la nube.
  var ultimoEnvio = sincronizacionController.ultimaSincronizacion;
  sincronizacionController.addListener(() {
    final envio = sincronizacionController.ultimaSincronizacion;
    if (envio != null && envio != ultimoEnvio) {
      ultimoEnvio = envio;
      progresoController.recargarCargados();
    }
  });
  sincronizacionController.iniciar();

  // HU10: al volver el internet, si la lista de módulos era la copia
  // guardada, se pide de nuevo para poder descargar contenidos.
  conectividad.cambios.where((hayRed) => hayRed).listen((_) {
    if (modulosController.vieneDeCache && !modulosController.estaCargando) {
      modulosController.cargarCatalogo();
    }
  });

  runApp(
    AppEducativa(
      modulosController: modulosController,
      progresoController: progresoController,
      sincronizacionController: sincronizacionController,
      voz: LectorVozTts(),
    ),
  );
}

/// HU06–HU11: SQLite es la fuente de verdad y Firestore recibe una copia.
ProgresoRepository _crearProgresoRepository(ConectividadService conectividad) {
  return ProgresoRepository(
    local: ProgresoLocalDataSource(),
    remote: _crearProgresoRemoteDataSource(),
    conectividad: conectividad,
    obtenerPerfil: PerfilLocalDataSource().obtenerPerfil,
  );
}

ProgresoRemoteDataSource _crearProgresoRemoteDataSource() {
  if (!ApiConfig.usaFirebase) {
    return const SinServidorProgresoRemoteDataSource();
  }

  final firestore = FirebaseFirestore.instance
    // La cola de pendientes es SQLite: sin la caché de Firestore, un envío
    // sin internet falla y los datos siguen marcados como pendientes.
    ..settings = const Settings(persistenceEnabled: false);

  return FirestoreProgresoRemoteDataSource(
    firestore: firestore,
    obtenerUsuario: _usuarioAnonimo,
  );
}

/// HU11: sesión anónima de Firebase. No pide datos al niño; solo da un
/// identificador para que las reglas de Firestore dejen modificar cada
/// progreso únicamente a quien lo creó. Se pide la primera vez que hay
/// internet y Firebase la recuerda en el teléfono.
Future<String> _usuarioAnonimo() async {
  final auth = FirebaseAuth.instance;
  final actual = auth.currentUser;

  if (actual != null) {
    return actual.uid;
  }

  final credencial = await auth.signInAnonymously();

  return credencial.user!.uid;
}

/// Arma las dependencias (inyección por constructor). Aquí es el único lugar
/// donde se decide qué servidor de contenidos usar.
ModulosController _crearModulosController(ConectividadService conectividad) {
  final remote = _crearRemoteDataSource();
  final local = ModuloLocalDataSource();
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

  // Las reglas de Storage solo dejan leer con sesión: se usa la anónima.
  return FirebaseModuloRemoteDataSource(
    storage: storage,
    iniciarSesion: _usuarioAnonimo,
  );
}

class AppEducativa extends StatelessWidget {
  final ModulosController modulosController;
  final ProgresoController progresoController;

  /// Estado de la conexión y del envío del progreso (HU10).
  final SincronizacionController sincronizacionController;

  /// Lee instrucciones en voz alta (HU07).
  final LectorVoz voz;

  const AppEducativa({
    super.key,
    required this.modulosController,
    required this.progresoController,
    required this.sincronizacionController,
    required this.voz,
  });

  @override
  Widget build(BuildContext context) {
    return ModulosScope(
      controller: modulosController,
      child: ProgresoScope(
        controller: progresoController,
        child: SincronizacionScope(
          controller: sincronizacionController,
          child: VozScope(
            voz: voz,
            child: MaterialApp(
              debugShowCheckedModeBanner: false,
              title: 'Aprendo',
              theme: AppTheme.claro,
              // HU10: aviso de "sin internet" encima de todas las pantallas.
              builder: BarraConexion.envolver,
              home: const VerificarPerfilScreen(),
            ),
          ),
        ),
      ),
    );
  }
}
