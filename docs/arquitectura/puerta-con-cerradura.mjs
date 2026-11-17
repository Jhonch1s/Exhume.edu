// node docs/arquitectura/puerta-con-cerradura.mjs [ruta/a/anatomy]
import assert from "node:assert/strict";
import { readFileSync, writeFileSync } from "node:fs";
import { homedir } from "node:os";
import { basename, resolve } from "node:path";
import { pathToFileURL } from "node:url";
import { crearTableros, drawLeaf } from "./tablero-interacciones.mjs";
import { intercambios } from "./intercambios-interacciones.mjs";

const escenario = "scenes/escenario_base/escenario_base.gd";
const base = "scripts/interacciones/";
const gestor = base + "gestor_acciones.gd";
const puerta = base + "interactuables/puertas/puerta_interactuable.gd";
const palanca = base + "interactuables/mecanismos/palanca_interactuable.gd";
const trampa = base + "interactuables/trampas/trampa_superficie.gd";
const humo = base + "reacciones/efectos_superficie/humo_veneno.gd";
const tablero = "scripts/tablero_grid.gd";
const fov = "scripts/fov_manager.gd";
const reacciones = base + "reacciones/resolver_reacciones_celda.gd";
const archivos = new Map();

function fuente(archivo, ancla, cantidad = 10) {
  if (!archivos.has(archivo)) {
    const texto = readFileSync(new URL("../../" + archivo, import.meta.url), "utf8");
    archivos.set(archivo, texto.split(/\r?\n/));
  }
  const lineas = archivos.get(archivo);
  const inicio = lineas.findIndex(linea => linea.trimStart().startsWith(ancla));
  if (inicio < 0) throw new Error(`No se encontró ${ancla} en ${archivo}`);
  return { archivo, nombre: basename(archivo), inicio: inicio + 1, lineas: lineas.slice(inicio, inicio + cantidad) };
}

function paso(fase, sistema, evento, titulo, entrada, salida, explicacion, ...fuentes) {
  return { fase, sistema, evento, titulo, entrada, salida, explicacion, fuentes };
}

const contexto = paso("Contexto", "ConstructorContextoAccion", "delega al objetivo",
  "Construye ContextoAccion",
  "OpcionAccion + actor + origen + celda objetivo + item seleccionado (si aplica)",
  "ContextoAccion coherente o motivo de bloqueo",
  "El objetivo construye el contexto. El constructor comprueba tipo, identidad, coordenadas, línea de efecto, costes y, para USAR_ITEM, los datos de la instancia elegida.",
  fuente(base + "constructor_contexto_accion.gd", 'var contexto: Variant = opcion.objetivo.call(', 15));

const validar = paso("Validación", "GestorAcciones", "procesar_accion(contexto)",
  "Valida alcance, receptor y costes",
  "ContextoAccion del jugador o de un evento",
  "Validación aceptada → resolver_accion(contexto) · motivo → BLOQUEO",
  "El gestor valida actor y objetivo, alcance y línea de efecto si corresponden. Luego llama a validar_accion del receptor y revisa los costes solicitados antes de resolver.",
  fuente(gestor, "if contexto.alcance_maximo >= 0.0:", 13),
  fuente(gestor, "var motivo_validacion: Variant", 18));

const resultado = paso("Salida", "GestorAcciones → EscenarioBase", "devuelve ResultadoAccion",
  "Emite señales y presenta el resultado",
  "ResultadoAccion del receptor",
  "accion_resuelta(contexto, resultado_receptor) → accion_finalizada(contexto, resultado_final)",
  "El gestor comprueba las solicitudes de efecto y cobra los costes según la política si corresponde. En una acción contextual, EscenarioBase recibe el resultado, registra la entrada narrativa y presenta el feedback.",
  fuente(gestor, "var motivo_efectos :=", 13),
  fuente(escenario, "_presentar_resultado_contextual(titulo_resultado, resultado, contexto)", 2));

const usarItem = paso("Disparador", "EscenarioBase", "selección del jugador",
  "Elige Usar item y una llave",
  "OpcionAccion de tipo USAR_ITEM",
  "opcion_uso_item_pendiente + ItemInstancia → _ejecutar_opcion_contextual",
  "La primera elección abre el selector de inventario. Elegir el item entrega la instancia concreta a la acción contextual.",
  fuente(escenario, "if opcion != null and opcion.tipo == TiposInteraccion.TipoAccion.USAR_ITEM:", 12),
  fuente(escenario, "func _on_item_contextual_elegido(", 9));

const presencia = paso("Propagación", "PuertaInteractuable → TableroGrid", "presencia_cambiada.emit()",
  "Notifica las celdas ocupadas por la puerta",
  "Interactuable registrado cuya presencia cambió",
  "presencia_interactuable_cambiada(coord) por cada coordenada de su huella",
  "TableroGrid conecta la señal al registrar el interactuable y la traduce a coordenadas para sus suscriptores.",
  fuente(tablero, "var cambio_presencia := _on_presencia_interactuable_cambiada.bind(", 3),
  fuente(tablero, "func _on_presencia_interactuable_cambiada(", 9));

const vision = paso("Propagación", "TableroGrid → FOVManager → Celda", "señal por coordenada",
  "Actualiza opacidad y, si cambió, la visión",
  "presencia_interactuable_cambiada(coord)",
  "Actualización de la opacidad efectiva · nuevo cálculo si cambió y ya había visión",
  "FOVManager consulta la opacidad de la celda. La puerta aporta su estado junto al terreno y otros obstáculos. Si cambia el resultado efectivo, vuelve a calcular la visión del jugador cuando ya existe un cálculo inicial.",
  fuente(fov, "func _on_presencia_interactuable_cambiada(", 15));

const ruta = paso("Consulta posterior", "PathfindingManager → Celda → PuertaInteractuable", "siguiente solicitud de ruta",
  "Consulta si la casilla se puede atravesar",
  "Nueva consulta de ruta después de cambiar abierta",
  "A* evalúa es_caminable_efectiva(), ocupación y reservas",
  "La señal anterior alimenta FOV. Pathfinding comprueba el paso en cada búsqueda consultando la celda y sus interactuables. Abrir retira el bloqueo de esta puerta; otras restricciones de la casilla todavía aplican.",
  fuente("scripts/pathfinding_manager.gd", "# La ocupacion es dinamica:", 16),
  fuente("scripts/celda.gd", "func es_caminable_efectiva(", 18),
  fuente(puerta, "func permite_caminar_interactuable(", 2));

const prepararEntrada = paso("Disparador", "MovimientoPorCasillas → EscenarioBase", "preparar_paso.call(...)",
  "Prepara el paso hacia la casilla de destino",
  "Actor en origen + próxima casilla del camino",
  "Destino reservado para animar el paso, o rechazo si falla la reserva",
  "El recorrido ilustra una reserva exitosa. MovimientoPorCasillas anima el desplazamiento antes de confirmar la ocupación y procesar la entrada.",
  fuente("scripts/movimiento/movimiento_por_casillas.gd", "if not preparar_paso.call(origen, destino, actor):", 15),
  fuente(escenario, "func _preparar_paso_actor(", 7));

const entrar = paso("Disparador", "MovimientoPorCasillas → EscenarioBase", "procesar_entrada.call(...)",
  "Confirma el paso y genera ENTRAR",
  "Actor completa un paso de origen a destino",
  "Ocupación confirmada + coordenada del actor actualizada → ENTRAR(destino)",
  "El callback SALIR ocurre antes de confirmar. Una vez confirmado el paso, el actor cambia de celda, consume movimiento y llama al callback de entrada.",
  fuente("scripts/movimiento/movimiento_por_casillas.gd", "if procesar_salida.is_valid():", 14),
  fuente(escenario, "func _procesar_entrada_paso_actor(", 12));

const consultar = paso("Selección", "EscenarioBase → ConsultorReaccionesCelda", "obtener_reacciones(celda, ENTRAR, actor)",
  "Toma la lista de receptores del paso",
  "Celda de destino y sus receptores actuales",
  "Lista ordenada de reacciones automáticas aptas para ENTRAR",
  "Consulta terreno, superficies, interactuables, items del suelo y ocupantes. Puede agregar reacciones encadenadas antes de ordenar. Para una placa de superficie elegible, esto puede incluir placas vecinas.",
  fuente(escenario, "var reacciones := consultor_reacciones.obtener_reacciones(", 8),
  fuente(base + "reacciones/consultor_reacciones_celda.gd", "var fuentes_encadenadas_visitadas:", 10),
  fuente(trampa, "func reacciona_automaticamente(", 6));

const repartir = paso("Contexto", "ResolverReaccionesCelda → GestorAcciones", "procesar_accion por receptor",
  "Crea un contexto por receptor",
  "Lista de reacciones + actor + origen + destino",
  "ContextoAccion por receptor, con id_evento compartido",
  "Deduplica por instancia. Cada contexto mantiene el mismo evento y puede usar la coordenada del receptor, por ejemplo en una placa vecina. Un resultado terminal puede cortar el procesamiento de la lista.",
  fuente(reacciones, "var receptores_procesados:", 20),
  fuente(reacciones, "agregado.agregar(gestor_acciones.procesar_accion(contexto))", 7));

const interrupcion = paso("Salida", "ResultadoReacciones → EscenarioBase → MovimientoPorCasillas", "resultado.interrumpe_movimiento",
  "Detiene la ruta según el resultado agregado",
  "Resultados individuales con sus flags de interrupción",
  "actor.solicitar_interrupcion() → se detiene después del paso confirmado",
  "El agregado combina el flag con OR. EscenarioBase pide interrumpir el movimiento si quedó activo. El paso que generó ENTRAR ya está confirmado.",
  fuente(base + "reacciones/resultado_reacciones.gd", "_interrumpe_movimiento = (", 4),
  fuente(escenario, "if resultado.interrumpe_movimiento:", 5),
  fuente("scripts/movimiento/movimiento_por_casillas.gd", "paso_dado.emit(destino)", 8));

const menuPalanca = paso("Disparador", "PalancaInteractuable → EscenarioBase", "selección de Accionar",
  "Publica una opción contextual",
  "Actor selecciona una palanca visible",
  "INTERACTUAR · id_accion = accionar · alcance = 1",
  "La palanca publica la opción. EscenarioBase puede intentar acercarse si el contexto queda fuera de alcance y reconstruirlo al llegar. El recorrido muestra el caso en que el actor ya está adyacente.",
  fuente(palanca, "func obtener_opciones_accion(", 22),
  fuente(escenario, "if gestor_acciones.esta_en_alcance(contexto):", 10));

const prevalidar = paso("Validación", "PalancaInteractuable → Interactuable → TableroGrid", "validar_accion(contexto)",
  "Prevalida la lista de receptores por ID",
  "ids_receptores_mecanismo + estado destino = not activada",
  "Receptores ordenados y validados, o motivo de rechazo",
  "Ordena IDs, detecta duplicados, busca cada instancia en el tablero y llama a validar_cambio_mecanismo. La palanca solo entra a resolver si la prevalidación completa es exitosa.",
  fuente(palanca, "var receptores: Variant = _resolver_receptores_mecanismo(", 8),
  fuente(base + "interactuables/interactuable.gd", "var ids := ids_receptores.duplicate()", 26));

const humoTirada = paso("Resolución", "HumoVeneno → EfectosEquipo → MotorDados", "resolver_accion(contexto)",
  "Resuelve una prueba automática de Voluntad",
  "ENTRAR en una celda donde ya existe HumoVeneno",
  "ResultadoAccion con tirada SOLO_LOG · solicitud de veneno si falla",
  "HumoVeneno usa Voluntad para resistir. El resultado puede interrumpir el movimiento según interrumpe_al_entrar tanto si se resiste como si se falla.",
  fuente(humo, "var salvacion := EfectosEquipo.resolver_prueba(", 27));

const traces = [
  {
    title: "Puerta y llave", board: "puerta", contract: "11A_USO_LLAVES_Y_DESTINO_DE_ITEMS.md", cases: [
      {
        name: "Abrir desbloqueada", initial: "Puerta cerrada, desbloqueada y actor adyacente.",
        result: "abierta: false → true · FOV recibe señal · la próxima ruta lee el cambio",
        poses: [
          { label: "Cerrada y desbloqueada", focus: "door" }, {}, {},
          { open: true, label: "Abierta · la puerta emite presencia_cambiada" },
          { label: "TableroGrid notifica la casilla de la puerta" },
          { focus: "vision", label: "FOV vuelve a evaluar la opacidad de la casilla" },
          { focus: "", label: "Abierta · ResultadoAccion devuelto" },
          { focus: "route", label: "Nueva consulta de ruta · esta puerta permite el paso" },
        ],
        steps: [
          paso("Disparador", "PuertaInteractuable → EscenarioBase", "selección de Abrir",
            "Publica Abrir habilitado",
            "Puerta cerrada y desbloqueada", "OpcionAccion: INTERACTUAR / abrir",
            "EscenarioBase recoge la opción del menú. La apertura manual tiene alcance uno y se distingue de USAR_ITEM.",
            fuente(puerta, 'var id_accion: StringName = &"cerrar"', 24)),
          contexto, validar,
          paso("Resolución", "GestorAcciones → PuertaInteractuable", "resolver_accion(contexto)",
            "Abre la puerta y actualiza su representación",
            "INTERACTUAR · id_accion = abrir", "abierta: false → true · mensaje puerta.abierta",
            "La puerta actualiza su representación y emite presencia_cambiada antes de devolver su ResultadoAccion.",
            fuente(puerta, "var estado_anterior := abierta", 16)),
          presencia, vision, resultado, ruta,
        ],
      },
      {
        name: "Llave compatible", initial: "Puerta cerrada y bloqueada. Llave con patrón compatible.",
        result: "bloqueada: true → false · abierta sigue en false",
        poses: [
          { locked: true, key: "matching", focus: "key", label: "Cerrada y bloqueada · llave compatible" },
          {}, {},
          { locked: false, focus: "door", label: "Cerrojo retraído · la puerta sigue cerrada" },
          {},
        ],
        steps: [usarItem, contexto, validar,
          paso("Resolución", "PuertaInteractuable", "_resolver_uso_item(contexto)", "Desbloquea la puerta",
            "Etiqueta llave + DefinicionLlave + patrón compatible",
            "bloqueada = false · mensaje puerta.desbloqueada · destino del item según configuración",
            "Si la llave se configura como consumible, primero se consume una unidad y se bloquea la operación si el inventario no puede entregarla. La apertura pertenece a una segunda acción.",
            fuente(puerta, "func _resolver_uso_item(", 29)),
          resultado,
        ],
      },
      {
        name: "Llave incompatible", initial: "Puerta cerrada y bloqueada. Llave válida con otro patrón.",
        result: "FALLO: llave_incompatible · la puerta sigue bloqueada",
        poses: [
          { locked: true, key: "mismatched", focus: "key", label: "Cerrada y bloqueada · llave incompatible" },
          {}, {},
          { focus: "rejected", label: "Patrón rechazado · el cerrojo queda extendido" },
          {},
        ],
        steps: [usarItem, contexto, validar,
          paso("Rechazo", "PuertaInteractuable", "_resolver_uso_item(contexto)", "Rechaza el patrón de la llave",
            "llave.patron_cerradura ≠ datos.patron_cerradura", "ResultadoAccion: FALLO / llave_incompatible",
            "El receptor llega a resolver y rechaza la incompatibilidad antes de consumir el item o escribir bloqueada.",
            fuente(puerta, "if llave.patron_cerradura != datos.patron_cerradura:", 10)),
          resultado,
        ],
      },
      {
        name: "Puerta bloqueada", initial: "Puerta cerrada y bloqueada.",
        result: "Abrir deshabilitado · el menú ofrece Usar item",
        poses: [{ locked: true, focus: "rejected", label: "Cerrojo extendido · Abrir deshabilitado" }],
        steps: [
          paso("Disparador", "PuertaInteractuable", "obtener_opciones_accion(actor)", "Publica Abrir deshabilitado",
            "bloqueada = true", "OpcionAccion.habilitada = false · motivo = puerta_bloqueada",
            "El menú presenta la opción bloqueada. Si la ejecución contextual recibe una opción deshabilitada, EscenarioBase crea un BLOQUEO antes de construir el contexto o llamar al gestor.",
            fuente(puerta, "if bloqueada:", 12),
            fuente(escenario, "if opcion == null or not opcion.habilitada:", 9)),
        ],
      },
    ],
  },
  {
    title: "Palanca y puertas", board: "palanca", contract: "12_MECANISMOS.md", cases: [
      {
        name: "Receptores válidos", initial: "Palanca desactivada. Dos puertas en modo MECANISMO, ambas cerradas.",
        result: "Dos puertas abiertas · palanca activada · un resultado con los cambios",
        poses: [
          { focus: "lever", label: "Palanca desactivada · dos puertas cerradas" },
          {}, {},
          { focus: "receivers", label: "Los dos receptores superan la prevalidación" },
          { open: true, label: "Las puertas se abren por ID · la palanca aún no cambió" },
          { label: "TableroGrid recibe cambios de presencia por puerta" },
          { label: "FOV comprueba la opacidad de las casillas notificadas" },
          { activated: true, focus: "lever", label: "Palanca activada tras aplicar ambos cambios" },
          { focus: "", label: "Resultado único · cambios de las puertas y la palanca" },
          { focus: "route", label: "Nueva consulta de ruta · ambas puertas permiten el paso" },
        ],
        steps: [menuPalanca, contexto, validar, prevalidar,
          paso("Resolución", "PalancaInteractuable → PuertaInteractuable", "aplicar_cambio_mecanismo(id_instancia, nueva)",
            "Envía el cambio a cada puerta", "Receptores prevalidados + nueva = true",
            "Cada puerta asigna abierta = true y emite presencia_cambiada si hubo cambio",
            "La palanca vuelve a comprobar los receptores al resolver y después los invoca en orden de ID. Cada puerta verifica el contrato de mecanismo y devuelve su propio resultado.",
            fuente(palanca, "for receptor: Interactuable in receptores:", 12),
            fuente(puerta, "func aplicar_cambio_mecanismo(", 19)),
          presencia, vision,
          paso("Resolución", "PalancaInteractuable", "retorno de los receptores",
            "Consolida cambios y activa la palanca", "Resultados exitosos de ambas puertas",
            "activada = true · cambios de la palanca y de las puertas",
            "La palanca actualiza su estado tras recorrer los receptores. Si un receptor falla durante la aplicación, el código retorna el fallo. El bucle no revierte aplicaciones anteriores.",
            fuente(palanca, "for receptor: Interactuable in receptores:", 24)),
          resultado, ruta,
        ],
      },
      {
        name: "Falta un receptor", initial: "Uno de los IDs configurados no está registrado en TableroGrid.",
        result: "BLOQUEO: receptor_mecanismo_inexistente · la palanca no envía cambios",
        poses: [
          { missing: true, focus: "lever", label: "Palanca desactivada · falta registrar un receptor" },
          {}, {},
          { focus: "missing", label: "La búsqueda por ID no encuentra la segunda puerta" },
          { label: "Acción bloqueada · la primera puerta sigue cerrada" },
        ],
        steps: [menuPalanca, contexto, validar, prevalidar,
          paso("Rechazo", "TableroGrid → PalancaInteractuable → GestorAcciones", "validar_accion devuelve un motivo",
            "Corta la acción antes de aplicar cambios", "obtener_interactuable(id) devuelve null",
            "BLOQUEO / receptor_mecanismo_inexistente",
            "Falla la prevalidación. El gestor finaliza el intento sin llamar a resolver_accion. Las puertas que ya se habían validado todavía no recibieron cambios.",
            fuente(base + "interactuables/interactuable.gd", "var receptor := tablero.obtener_interactuable(", 6),
            fuente(gestor, 'if motivo_validacion != &"":', 5)),
        ],
      },
    ],
  },
  {
    title: "Trampa de superficie", board: "trampa", contract: "09_TRAMPAS.md", cases: [
      {
        name: "Pisar la placa", initial: "Placa oculta sin activar. Sin humo previo. Interrupción habilitada.",
        result: "Placa ACTIVADA · superficies registradas · la ruta se detiene en la placa",
        poses: [
          { focus: "plate", label: "La ficha se prepara para avanzar una casilla" },
          { focus: "plate", moved: true, label: "ENTRAR · la ficha ya ocupa la casilla de la placa" },
          { label: "Placa elegible · todavía no hay humo en la lista de reacciones" },
          {}, {},
          { smoke: true, pressed: true, focus: "smoke", label: "Placa activada · humo registrado en un radio Manhattan de 1" },
          { label: "Ruta interrumpida · la ficha queda sobre la placa" },
        ],
        steps: [prepararEntrada, entrar, consultar, repartir, validar,
          paso("Resolución", "TrampaSuperficie → TableroGrid", "_activar() → desplegar_efecto_superficie(...)",
            "Despliega el humo por radio Manhattan",
            "Escena de superficie, centro, radio y prefijo de ID",
            "Superficies registradas en celdas aptas · estado de placa = ACTIVADA",
            "El tablero instancia la superficie en celdas con terreno caminable dentro del radio. El nuevo humo queda disponible para consultas futuras de reacciones. La lista del ENTRAR actual se reunió antes de desplegarlo.",
            fuente(trampa, "func _activar() -> ResultadoAccion:", 28),
            fuente(tablero, "for desplazamiento_y in range(-radio, radio + 1):", 25)),
          interrupcion,
        ],
      },
      {
        name: "Entrar al humo y fallar", initial: "Humo activo en destino. Actor falla la prueba de Voluntad.",
        result: "Solicitud de veneno agregada y aplicada al actor · la ruta se detiene si el humo lo pide",
        poses: [
          { smoke: true, pressed: true, focus: "smoke", label: "El destino ya tiene humo antes del paso" },
          { smoke: true, pressed: true, moved: true, focus: "smoke", label: "ENTRAR · el humo ya estaba registrado" },
          {}, {}, {},
          { focus: "actor", label: "Falla Voluntad · HumoVeneno devuelve una solicitud" },
          { poisoned: true, label: "AplicadorEfectos aplica veneno a la ficha" },
          { label: "El movimiento consulta el flag de interrupción" },
        ],
        steps: [prepararEntrada, entrar, consultar, repartir, validar, humoTirada,
          paso("Aplicación", "ResultadoReacciones → AplicadorEfectos", "finalizar_solicitudes() → aplicar_efectos(...)",
            "Agrega y aplica las solicitudes de veneno",
            "SolicitudEfecto: veneno · id_evento · NO_APILAR_Y_RENOVAR",
            "Estado de veneno aplicado al actor y cambios añadidos al agregado",
            "ResolverReaccionesCelda reúne las solicitudes de todos los resultados, las agrega y luego valida y aplica las admitidas. El historial guarda la tirada devuelta por el humo.",
            fuente(reacciones, "agregado.finalizar_solicitudes()", 3),
            fuente(base + "reacciones/resultado_reacciones.gd", "func finalizar_solicitudes()", 25),
            fuente(escenario, "for resultado_individual in resultado.resultados:", 5)),
          interrupcion,
        ],
      },
      {
        name: "Entrar al humo y resistir", initial: "Humo activo en destino. Actor supera la prueba de Voluntad.",
        result: "estado.veneno_resistido · sin solicitud de veneno · la interrupción depende de la superficie",
        poses: [
          { smoke: true, pressed: true, focus: "smoke", label: "El destino ya tiene humo antes del paso" },
          { smoke: true, pressed: true, moved: true, focus: "smoke", label: "ENTRAR · el humo ya estaba registrado" },
          {}, {}, {},
          { focus: "actor", label: "La ficha supera la prueba de Voluntad" },
          { label: "Veneno resistido · no se solicita aplicar el estado" },
          { label: "La resistencia no cambia el flag de interrupción del humo" },
        ],
        steps: [prepararEntrada, entrar, consultar, repartir, validar, humoTirada,
          paso("Salida", "HumoVeneno → ResultadoReacciones", "salvacion.exitosa",
            "Devuelve la tirada y el mensaje de resistencia",
            "Prueba de Voluntad exitosa",
            "EXITO · mensaje estado.veneno_resistido · flag interrumpe_al_entrar",
            "El resultado exitoso de la reacción describe que la prueba fue resistida. El flag de interrupción de la superficie sigue disponible para el controlador de movimiento.",
            fuente(humo, "if salvacion.exitosa:", 5)),
          interrupcion,
        ],
      },
    ],
  },
];

const html = readFileSync(new URL("flujo-interacciones.template.html", import.meta.url), "utf8");
const anatomy = resolve(process.argv[2] ?? resolve(homedir(), ".agents/skills/anatomy"));
const kit = await import(pathToFileURL(resolve(anatomy, "kit/iso-kit.mjs")));
const { kitScript } = await import(pathToFileURL(resolve(anatomy, "scripts/inline-kit.mjs")));
const license = readFileSync(resolve(anatomy, "LICENSE"), "utf8").trim();

for (const trace of traces) {
  for (const scenario of trace.cases) {
    assert.equal(scenario.poses.length, scenario.steps.length, scenario.name);
    const traspasos = intercambios[scenario.name];
    assert.equal(traspasos?.length, scenario.steps.length, scenario.name);
    let pose = {};
    for (const [i, update] of scenario.poses.entries()) {
      pose = { ...pose, ...update };
      assert.ok(pose.label, scenario.name);
      assert.ok(traspasos[i].length && traspasos[i].every(pair => pair.slice(0, 3).every(Boolean)), scenario.name);
      scenario.steps[i] = { ...scenario.steps[i], pose, traspasos: traspasos[i] };
    }
    delete scenario.poses;
  }
}

const json = data => JSON.stringify(data).replaceAll("<", "\\u003c");
const board = crearTableros(kit);
const runtime = `${kitScript()}\n${drawLeaf.toString()}\nconst boardGeometry = ${json(board)};`;
writeFileSync(new URL("puerta-con-cerradura.html", import.meta.url), html
  .replace("/* ANATOMY CSS */", () => kit.ISO_CSS)
  .replace("<!-- TRAZAS -->", () => json(traces))
  .replace("/* ANATOMY JS */", () => runtime.replace(/<\/(script)/gi, "<\\/$1")) +
  `\n<!-- Anatomy kit\n${license}\n-->\n`);
