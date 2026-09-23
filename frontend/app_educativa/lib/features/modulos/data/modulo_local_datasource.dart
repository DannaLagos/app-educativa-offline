import '../domain/modulo.dart';

class ModuloLocalDataSource {
  Future<List<Modulo>> obtenerModulosDisponibles() async {
    final modulos = <Modulo>[
      const Modulo(
        id: 'cs-grado-1',
        nombre: 'Ciencias Sociales',
        area: 'Ciencias Sociales',
        grado: 1,
        descripcion: 'Módulo educativo de Ciencias Sociales para grado primero.',
        archivo: 'CS_Fichas.pdf',
        habilitado: true,
      ),
      const Modulo(
        id: 'lg-grado-3-01',
        nombre: 'Lenguaje - Módulo 1',
        area: 'Lenguaje',
        grado: 3,
        descripcion: 'Primer módulo educativo de Lenguaje para grado tercero.',
        archivo: 'LG_Grado03_01.pdf',
        habilitado: true,
      ),
      const Modulo(
        id: 'lg-grado-3-02',
        nombre: 'Lenguaje - Módulo 2',
        area: 'Lenguaje',
        grado: 3,
        descripcion: 'Segundo módulo educativo de Lenguaje para grado tercero.',
        archivo: 'LG_Grado03_02.pdf',
        habilitado: true,
      ),
      const Modulo(
        id: 'lg-grado-3-03',
        nombre: 'Lenguaje - Módulo 3',
        area: 'Lenguaje',
        grado: 3,
        descripcion: 'Tercer módulo educativo de Lenguaje para grado tercero.',
        archivo: 'LG_Grado03_03.pdf',
        habilitado: true,
      ),
    ];

    return modulos
        .where((modulo) => modulo.habilitado)
        .toList();
  }

  Future<Modulo?> obtenerModuloPorId(String id) async {
    final modulos = await obtenerModulosDisponibles();

    for (final modulo in modulos) {
      if (modulo.id == id) {
        return modulo;
      }
    }

    return null;
  }
}