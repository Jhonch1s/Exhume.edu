// Cada fila describe una llamada, un retorno, una señal o un cambio local del paso.
// La proximidad en la línea de tiempo no implica que un sistema llame al siguiente.
const escenario = "EscenarioBase";
const constructor = "ConstructorContextoAccion";
const gestor = "GestorAcciones";
const puerta = "PuertaInteractuable";
const tablero = "TableroGrid";
const celda = "Celda";
const palanca = "PalancaInteractuable";
const trampa = "TrampaSuperficie";
const humo = "HumoVeneno";
const movimiento = "MovimientoPorCasillas";
const consultor = "ConsultorReaccionesCelda";
const resolver = "ResolverReaccionesCelda";
const agregado = "ResultadoReacciones";
const ficha = "Ficha";

const construir = receptor => [
  [escenario, constructor, "OpcionAccion + actor + coordenadas + item si aplica"],
  [constructor, receptor, "construir_contexto_accion(…)"],
  [receptor, constructor, "ContextoAccion", "Retorno"],
  [constructor, escenario, "ContextoAccion comprobado", "Retorno"],
];
const validar = (origen, receptor) => [
  [origen, gestor, "procesar_accion(contexto)"],
  [gestor, receptor, "validar_accion(contexto)"],
];
const presentar = receptor => [
  [receptor, gestor, "ResultadoAccion", "Retorno"],
  [gestor, escenario, "ResultadoAccion final · registro y presentación", "Retorno"],
];
const presencia = [[puerta, tablero, "presencia_cambiada()", "Señal"]];
const vision = [
  [tablero, "FOVManager", "presencia_interactuable_cambiada(coord)", "Señal"],
  ["FOVManager", celda, "bloquea_vision_efectiva()", "Consulta"],
  [celda, "FOVManager", "Opacidad efectiva de la casilla", "Retorno"],
];
const ruta = [
  ["PathfindingManager", celda, "es_caminable_efectiva()", "Consulta posterior"],
  [celda, puerta, "permite_caminar_interactuable()", "Consulta"],
  [puerta, celda, "abierta", "Retorno"],
];
const elegirLlave = [["Jugador", escenario, "Usar item → selecciona ItemInstancia", "Selección"]];
const elegirPalanca = [[palanca, escenario, "OpcionAccion · INTERACTUAR / accionar", "Opción"]];
const buscarReceptor = [[palanca, tablero, "obtener_interactuable(id_receptor)", "Consulta"]];

const preparar = [
  [movimiento, escenario, "preparar_paso(origen, destino, actor)"],
  [escenario, tablero, "reserva la celda de destino"],
];
const entrar = [
  [movimiento, escenario, "confirmar_paso(origen, destino, actor)"],
  [escenario, tablero, "confirmar_movimiento(origen, destino, actor)"],
  [movimiento, escenario, "procesar_entrada(origen, destino, actor)"],
];
const consultar = [
  [escenario, consultor, "obtener_reacciones(celda, ENTRAR, actor)"],
  [consultor, escenario, "Lista ordenada de reacciones", "Retorno"],
];
const repartir = [
  [escenario, resolver, "resolver(tipo, actor, origen, destino, reacciones)"],
  [resolver, resolver, "ContextoAccion por receptor · id_evento compartido", "Construcción"],
];
const interrumpir = [
  [resolver, escenario, "ResultadoReacciones · interrumpe_movimiento", "Retorno"],
  [escenario, ficha, "solicitar_interrupcion() si el flag está activo"],
  [ficha, movimiento, "solicitar_interrupcion()"],
];
const tirarVoluntad = [
  [gestor, humo, "resolver_accion(contexto)"],
  [humo, "EfectosEquipo", "resolver_prueba(…, voluntad, AUTOMATICA, SOLO_LOG)"],
  ["EfectosEquipo", "MotorDados", "Voluntad y modificadores de la prueba"],
  ["MotorDados", "EfectosEquipo", "ResultadoPrueba", "Retorno"],
  ["EfectosEquipo", humo, "ResultadoPrueba", "Retorno"],
];
const humareda = [preparar, entrar, consultar, repartir, validar(resolver, humo), tirarVoluntad];

export const intercambios = {
  "Abrir desbloqueada": [
    [[puerta, escenario, "OpcionAccion · INTERACTUAR / abrir", "Opción"]],
    construir(puerta), validar(escenario, puerta),
    [[gestor, puerta, "resolver_accion(contexto) · abrir"], [puerta, puerta, "abierta = true", "Estado"]],
    presencia, vision, presentar(puerta), ruta,
  ],
  "Llave compatible": [
    elegirLlave, construir(puerta), validar(escenario, puerta),
    [[gestor, puerta, "resolver_accion(contexto) · USAR_ITEM"], [puerta, puerta, "bloqueada = false", "Estado"]],
    presentar(puerta),
  ],
  "Llave incompatible": [
    elegirLlave, construir(puerta), validar(escenario, puerta),
    [[gestor, puerta, "resolver_accion(contexto) · USAR_ITEM"], [puerta, puerta, "FALLO / llave_incompatible", "Rechazo"]],
    presentar(puerta),
  ],
  "Puerta bloqueada": [
    [[puerta, escenario, "OpcionAccion deshabilitada · puerta_bloqueada", "Opción"]],
  ],
  "Receptores válidos": [
    elegirPalanca, construir(palanca), validar(escenario, palanca),
    [...buscarReceptor, [tablero, palanca, "Instancia registrada para cada ID", "Retorno"],
      [palanca, puerta, "validar_cambio_mecanismo(id_emisor, activa)"]],
    [[gestor, palanca, "resolver_accion(contexto)"],
      [palanca, puerta, "aplicar_cambio_mecanismo(id_emisor, true) · por puerta"]],
    presencia, vision,
    [[puerta, palanca, "ResultadoAccion por puerta · mensajes y cambios", "Retorno"],
      [palanca, palanca, "activada = true", "Estado"]],
    presentar(palanca), ruta,
  ],
  "Falta un receptor": [
    elegirPalanca, construir(palanca), validar(escenario, palanca), buscarReceptor,
    [[tablero, palanca, "null · ID sin instancia registrada", "Retorno"],
      [palanca, gestor, "receptor_mecanismo_inexistente", "Retorno"],
      [gestor, escenario, "ResultadoAccion · BLOQUEO", "Retorno"]],
  ],
  "Pisar la placa": [
    preparar, entrar, consultar, repartir, validar(resolver, trampa),
    [[gestor, trampa, "resolver_accion(contexto) · ENTRAR"],
      [trampa, tablero, "desplegar_efecto_superficie(escena, centro, radio, prefijo_id)"],
      [tablero, trampa, "Coordenadas donde se registró humo", "Retorno"],
      [trampa, gestor, "ResultadoAccion · cambios y flag de interrupción", "Retorno"],
      [gestor, resolver, "ResultadoAccion para agregar", "Retorno"]],
    interrumpir,
  ],
  "Entrar al humo y fallar": [
    ...humareda,
    [[humo, gestor, "ResultadoAccion con SolicitudEfecto(veneno)", "Retorno"],
      [gestor, resolver, "ResultadoAccion para agregar", "Retorno"],
      [resolver, agregado, "finalizar_solicitudes() → aplicar_efectos(…)"],
      [agregado, "AplicadorEfectos", "validar(solicitud) → aplicar(solicitud)"],
      ["AplicadorEfectos", ficha, "aplicar_o_renovar_estado(veneno, …)"]],
    interrumpir,
  ],
  "Entrar al humo y resistir": [
    ...humareda,
    [[humo, gestor, "ResultadoAccion · estado.veneno_resistido", "Retorno"],
      [gestor, resolver, "ResultadoAccion sin solicitud de veneno", "Retorno"],
      [resolver, agregado, "agregar(resultado)"]],
    interrumpir,
  ],
};
