import 'package:app_educativa/features/actividades/domain/actividad.dart';

const elige = ActividadElige(
  id: 'a1-cuerpo',
  titulo: 'Las partes de mi cuerpo',
  instruccion: 'Toca la parte del cuerpo correcta.',
  preguntas: [
    PreguntaElige(
      enunciado: '¿Cuál es la mano?',
      opciones: [
        ElementoVisual(emoji: '✋', texto: 'Mano'),
        ElementoVisual(emoji: '👂', texto: 'Oreja'),
      ],
      correcta: 0,
    ),
    PreguntaElige(
      enunciado: '¿Con qué vemos?',
      opciones: [
        ElementoVisual(emoji: '👄', texto: 'Boca'),
        ElementoVisual(emoji: '👀', texto: 'Ojos'),
      ],
      correcta: 1,
    ),
  ],
);

const parejas = ActividadParejas(
  id: 'a2-emociones',
  titulo: '¿Cómo me siento?',
  instruccion: 'Une cada carita con lo que hace sentir así.',
  pares: [
    Pareja(
      izquierda: ElementoVisual(emoji: '😀', texto: 'Alegre'),
      derecha: ElementoVisual(emoji: '🎁', texto: 'Un regalo'),
    ),
    Pareja(
      izquierda: ElementoVisual(emoji: '😨', texto: 'Con miedo'),
      derecha: ElementoVisual(emoji: '⛈️', texto: 'Una tormenta'),
    ),
  ],
);

const clasifica = ActividadClasifica(
  id: 'a3-cuidar',
  titulo: '¿Cuida o daña?',
  instruccion: 'Toca la canasta correcta.',
  grupos: [
    GrupoClasifica(
      id: 'cuida',
      elemento: ElementoVisual(emoji: '💚', texto: 'La cuida'),
    ),
    GrupoClasifica(
      id: 'dana',
      elemento: ElementoVisual(emoji: '💔', texto: 'La daña'),
    ),
  ],
  tarjetas: [
    TarjetaClasifica(
      elemento: ElementoVisual(emoji: '🌱', texto: 'Sembrar un árbol'),
      grupo: 'cuida',
    ),
    TarjetaClasifica(
      elemento: ElementoVisual(emoji: '🔥', texto: 'Quemar el bosque'),
      grupo: 'dana',
    ),
  ],
);

const ordena = ActividadOrdena(
  id: 'a4-agricultor',
  titulo: 'El trabajo del agricultor',
  instruccion: 'Toca los dibujos en orden.',
  pasos: [
    ElementoVisual(emoji: '🌱', texto: 'Siembra'),
    ElementoVisual(emoji: '💧', texto: 'Riega'),
    ElementoVisual(emoji: '🌽', texto: 'Cosecha'),
  ],
);

const nivel1 = Nivel(
  id: 'n1',
  numero: 1,
  titulo: 'Yo soy único',
  emoji: '🧒',
  objetivo: 'Me reconozco.',
  actividades: [elige, parejas],
);

const nivel2 = Nivel(
  id: 'n2',
  numero: 2,
  titulo: 'Mi región',
  emoji: '🏞️',
  objetivo: 'Cuido la naturaleza.',
  actividades: [clasifica, ordena],
);

const plan = PlanActividades(niveles: [nivel1, nivel2]);

const memoria = ActividadMemoria(
  id: 'a5-memoria',
  titulo: 'Memoria de los oficios',
  instruccion: 'Voltea dos cartas.',
  pares: [
    Pareja(
      izquierda: ElementoVisual(emoji: '👩‍🌾', texto: 'Agricultora'),
      derecha: ElementoVisual(emoji: '🌽', texto: 'Maíz'),
    ),
    Pareja(
      izquierda: ElementoVisual(emoji: '👨‍🍳', texto: 'Cocinero'),
      derecha: ElementoVisual(emoji: '🍳', texto: 'Sartén'),
    ),
  ],
);

const arrastra = ActividadArrastra(
  id: 'a6-arrastra',
  titulo: '¿Cuida o daña?',
  instruccion: 'Arrastra cada dibujo a su canasta.',
  grupos: [
    GrupoClasifica(
      id: 'cuida',
      elemento: ElementoVisual(emoji: '💚', texto: 'La cuida'),
    ),
    GrupoClasifica(
      id: 'dana',
      elemento: ElementoVisual(emoji: '💔', texto: 'La daña'),
    ),
  ],
  tarjetas: [
    TarjetaClasifica(
      elemento: ElementoVisual(emoji: '🌱', texto: 'Sembrar'),
      grupo: 'cuida',
    ),
    TarjetaClasifica(
      elemento: ElementoVisual(emoji: '🔥', texto: 'Quemar'),
      grupo: 'dana',
    ),
  ],
);

const atrapa = ActividadAtrapa(
  id: 'a7-atrapa',
  titulo: 'Globos de la naturaleza',
  instruccion: 'Revienta lo que hizo la naturaleza.',
  objetivo: ElementoVisual(emoji: '🌳', texto: 'lo que hizo la naturaleza'),
  elementos: [
    ElementoAtrapa(
      elemento: ElementoVisual(emoji: '⛰️', texto: 'Montaña'),
      esCorrecto: true,
    ),
    ElementoAtrapa(
      elemento: ElementoVisual(emoji: '🏠', texto: 'Casa'),
      esCorrecto: false,
    ),
    ElementoAtrapa(
      elemento: ElementoVisual(emoji: '🌳', texto: 'Árbol'),
      esCorrecto: true,
    ),
  ],
);

const completa = ActividadCompleta(
  id: 'a8-completa',
  titulo: 'Completa con un adjetivo',
  instruccion: 'Toca la palabra que completa la oración.',
  oraciones: [
    OracionCompleta(
      emoji: '🏫',
      texto: 'La escuela era muy ___.',
      opciones: ['pequeña', 'corrió'],
      correcta: 0,
    ),
    OracionCompleta(
      emoji: '🔴',
      texto: 'Marte es un planeta ___.',
      opciones: ['salta', 'rojo'],
      correcta: 1,
    ),
  ],
);

const arma = ActividadArma(
  id: 'a9-arma',
  titulo: 'Arma la oración',
  instruccion: 'Toca las palabras en orden.',
  oraciones: [
    OracionArma(emoji: '🐶', partes: ['El', 'perro', 'ladra.']),
  ],
);

const sopa = ActividadSopa(
  id: 'a10-sopa',
  titulo: 'Sopa del espacio',
  instruccion: 'Encuentra las palabras.',
  palabras: [
    ElementoVisual(emoji: '🌙', texto: 'Luna'),
    ElementoVisual(emoji: '🔄', texto: 'Órbita'),
  ],
  tamano: 7,
);
