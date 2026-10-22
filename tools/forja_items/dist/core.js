(function (root, factory) {
  const api = factory();
  if (typeof module !== 'undefined' && module.exports) module.exports = api;
  else root.Forja = api;
})(globalThis, function () {
  'use strict';
  const VERSION = 1;
  const SURFACES = { fuego: ['Fuego', 'Quemado'], humo: ['Humo', 'Cobertura visual'], veneno: ['HumoVeneno', 'Veneno'] };
  const SLOTS = { arma: 'Mano principal', escudo: 'Mano secundaria', casco: 'Cabeza', armadura: 'Pecho', guantes: 'Manos', botas: 'Pies', amuleto: 'Amuleto', anillo: 'Anillo', luz: 'Antorcha / mano secundaria' };
  const RESERVED = ['antorcha', 'racion', 'piedra', 'bomba_humo', 'llave_prueba'];
  const clone = value => JSON.parse(JSON.stringify(value));
  const slug = value => String(value).normalize('NFD').replace(/[\u0300-\u036f]/g, '').toLowerCase().replace(/[^a-z0-9]+/g, '_').replace(/^_+|_+$/g, '').slice(0, 64);
  const uid = () => globalThis.crypto?.randomUUID?.() || 'item_' + Date.now() + '_' + Math.random().toString(36).slice(2);
  function createItem(preset = {}) {
    const item = { key: uid(), id: '', name: '', description: '', kind: 'objeto', tags: [], weight: 0.5, stackable: false, maxStack: 1, heal: 0, magnitudes: {}, icon: null, world: null, illustration: null, pickupSound: null, impactSound: null, worldWidth: 64, hframes: 1, vframes: 1, lockPattern: '', torch: { duration: 80, vision: 5, fade: 10, energy: 1.3, scale: 1, color: '#ffe500' }, impact: { type: 'none', radius: 0, duration: 7, ticks: 3, dice: 1, sides: 2 }, source: null, updateExisting: false };
    item.equipmentEffects = [];
    const input = clone(preset);
    for (const key of Object.keys(item)) {
      if (!Object.hasOwn(input, key)) continue;
      if (key === 'torch' || key === 'impact') item[key] = { ...item[key], ...input[key] };
      else item[key] = input[key];
    }
    return item;
  }
  function healing(value) {
    if (typeof value !== 'string' && typeof value !== 'number') return null;
    const formula = String(value).toLowerCase().replace(/\s+/g, '');
    if (/^\d{1,4}$/.test(formula)) {
      const bonus = Number(formula);
      return { dice: 0, sides: 0, bonus, min: bonus, max: bonus, formula: String(bonus) };
    }
    const match = formula.match(/^([1-9])d([1-9]\d{0,2})(?:\+(\d{1,4}))?$/);
    if (!match) return null;
    const dice = Number(match[1]), sides = Number(match[2]), bonus = Number(match[3] || 0);
    if (sides < 2 || sides > 100) return null;
    return { dice, sides, bonus, min: dice + bonus, max: dice * sides + bonus, formula: dice + 'd' + sides + (bonus ? '+' + bonus : '') };
  }
  const ATTRIBUTES = { fuerza: 'FUE', destreza: 'DES', voluntad: 'VOL' };
  const TESTS = { ataque: 'ataque cuerpo a cuerpo', esquiva: 'esquiva', fuerza: 'pruebas de FUE', destreza: 'pruebas de DES', voluntad: 'pruebas de VOL' };
  const EFFECT_TYPES = { atributo: 'Bono de atributo', dano: 'Daño adicional', tirada: 'Ventaja / desventaja', estado: 'Estado al acertar', penalizacion: 'Reducir atributo al acertar' };
  function effectDefault(tipo = 'atributo') {
    if (tipo === 'atributo') return { tipo, atributo: 'fuerza', valor: 1 };
    if (tipo === 'tirada') return { tipo, prueba: 'ataque', modo: 'ventaja' };
    if (tipo === 'dano') return { tipo, valor: 1, alcance: 'arma' };
    return { tipo, ...(tipo === 'estado' ? { estado: 'veneno' } : { atributo: 'fuerza' }), valor: 1, duracion: 2, alcance: 'arma', salvacion: 'voluntad' };
  }
  function validEffects(effects) {
    const integer = (n, min, max) => Number.isInteger(n) && n >= min && n <= max;
    return Array.isArray(effects) && effects.length <= 16 && effects.every(e => {
      if (!e || typeof e !== 'object' || Array.isArray(e)) return false;
      if (e.tipo === 'atributo') return Object.hasOwn(ATTRIBUTES, e.atributo) && integer(e.valor, -5, 5) && e.valor !== 0;
      if (e.tipo === 'tirada') return Object.hasOwn(TESTS, e.prueba) && ['ventaja', 'desventaja'].includes(e.modo);
      if (!['dano', 'estado', 'penalizacion'].includes(e.tipo) || !['arma', 'directo'].includes(e.alcance) || !integer(e.valor, 1, 99)) return false;
      if (e.tipo === 'dano') return true;
      return integer(e.duracion, 1, 99) && ['', ...Object.keys(ATTRIBUTES)].includes(e.salvacion) && (e.tipo === 'estado' ? ['veneno', 'quemado'].includes(e.estado) : Object.hasOwn(ATTRIBUTES, e.atributo) && e.valor <= 5);
    });
  }
  function effectDescription(e) {
    if (e.tipo === 'atributo') return 'Equipado: ' + (e.valor >= 0 ? '+' : '') + e.valor + ' ' + (ATTRIBUTES[e.atributo] || '?') + '.';
    if (e.tipo === 'tirada') return 'Equipado: ' + e.modo + ' en ' + (TESTS[e.prueba] || '?') + '.';
    const scope = e.alcance === 'arma' ? 'arma de la mano principal' : 'ataques y Bola de fuego';
    if (e.tipo === 'dano') return 'Al causar daño (' + scope + '): +' + e.valor + ' daño directo.';
    return 'Al causar daño (' + scope + '): ' + (e.tipo === 'estado' ? (e.estado === 'veneno' ? 'veneno' : 'quemado') + ', ' + e.valor + ' daño por turno' : '−' + e.valor + ' ' + (ATTRIBUTES[e.atributo] || '?')) + ', ' + e.duracion + ' turnos' + (e.salvacion ? '. Salvación de ' + ATTRIBUTES[e.salvacion] : '. Sin salvación') + '.';
  }
  function tags(item) {
    const result = [...item.tags];
    if (item.kind === 'llave') result.push('llave');
    if (item.kind === 'antorcha') result.push('luz', 'consumible');
    if (healing(item.heal)?.max > 0) result.push('consumible');
    if (item.impact.type !== 'none') result.push('arrojable', 'fragil');
    return [...new Set(result)];
  }
  function equipment(item) {
    const t = tags(item), slots = Object.keys(SLOTS).filter(key => t.includes(key)).map(key => SLOTS[key]);
    if ((t.includes('arrojable') || item.id === 'piedra') && !slots.includes('Mano principal')) slots.push('Mano principal');
    if (t.includes('cabeza') && !slots.includes('Cabeza')) slots.push('Cabeza');
    if (t.includes('pecho') && !slots.includes('Pecho')) slots.push('Pecho');
    if (t.includes('collar') && !slots.includes('Amuleto')) slots.push('Amuleto');
    return slots;
  }
  function validate(item, all = [item]) {
    const errors = [], warnings = [];
    const number = (value, min, max, label, integer = false) => {
      if (typeof value !== 'number' || !Number.isFinite(value) || value < min || value > max || (integer && !Number.isInteger(value))) errors.push(label + ': usa ' + (integer ? 'un entero' : 'un número') + ' entre ' + min + ' y ' + max + '.');
    };
    if (!/^[a-z][a-z0-9_]{0,63}$/.test(item.id)) errors.push('El ID debe empezar por una letra y usar solo minúsculas, números y guiones bajos.');
    if (typeof item.name !== 'string' || !item.name.trim() || item.name.length > 120) errors.push('Escribe un nombre de hasta 120 caracteres.');
    if (typeof item.description !== 'string' || item.description.length > 12000) errors.push('La descripción admite hasta 12.000 caracteres.');
    if (all.some(other => other.key !== item.key && other.id === item.id)) errors.push('Ya hay otro ítem con este ID en tu biblioteca.');
    if (!['objeto', 'llave', 'antorcha'].includes(item.kind)) errors.push('Tipo de recurso no reconocido.');
    if (!validEffects(item.equipmentEffects)) errors.push('Revisa los efectos de equipo: hasta 16 efectos con valores enteros y opciones válidas.');
    else if (item.equipmentEffects.length) {
      if (!equipment(item).length) errors.push('Los efectos de equipo necesitan una etiqueta de ranura en Información: arma, anillo, armadura, etc.');
      if (item.equipmentEffects.some(e => e.alcance === 'arma') && !equipment(item).includes('Mano principal')) errors.push('El alcance «Arma de mano principal» requiere un objeto compatible con esa ranura.');
      if (item.stackable) warnings.push('El equipo aporta sus efectos una sola vez por objeto equipado; la cantidad de la pila no multiplica los bonos.');
    }
    if (!Array.isArray(item.tags) || item.tags.length > 50 || item.tags.some(t => typeof t !== 'string' || !/^[a-z][a-z0-9_]{0,63}$/.test(t))) errors.push('Revisa las etiquetas: letras minúsculas, números y guiones bajos.');
    if (typeof item.stackable !== 'boolean') errors.push('Apilado inválido.');
    number(item.weight, 0, 99999, 'Peso');
    number(item.maxStack, 1, 999, 'Máximo de pila', true);
    if (!item.stackable && item.maxStack !== 1) errors.push('Un objeto no apilable debe tener un máximo de 1.');
    const heal = healing(item.heal);
    if (!heal) errors.push('Curación: escribe 0, una cantidad fija (5) o dados (1d6, 2d4+2). Hasta 9 dados de 2 a 100 caras y bono de 0 a 9999.');
    number(item.worldWidth, 8, 512, 'Ancho en el suelo');
    number(item.hframes, 1, 32, 'Columnas del sprite', true);
    number(item.vframes, 1, 32, 'Filas del sprite', true);
    if (item.kind === 'llave' && !/^[a-z][a-z0-9_]{0,63}$/.test(item.lockPattern)) errors.push('La llave necesita un patrón de cerradura válido.');
    if (!item.impact || !['none', ...Object.keys(SURFACES)].includes(item.impact.type)) errors.push('Efecto de impacto no reconocido.');
    else if (item.impact.type !== 'none') {
      number(item.impact.radius, 0, 8, 'Radio', true);
      number(item.impact.duration, 1, 99, 'Duración de superficie', true);
      number(item.impact.ticks, 1, 99, 'Pulsos de estado', true);
      number(item.impact.dice, 1, 9, 'Dados por pulso', true);
      number(item.impact.sides, 2, 100, 'Caras del dado', true);
    }
    if (item.kind === 'antorcha') {
      number(item.torch.duration, 1, 9999, 'Duración de luz', true);
      number(item.torch.vision, 1, 20, 'Radio de visión', true);
      number(item.torch.fade, 0, 999, 'Atenuación', true);
      number(item.torch.energy, 0, 5, 'Energía de luz');
      number(item.torch.scale, 0.1, 5, 'Escala de luz');
      if (!/^#[a-f\d]{6}$/i.test(item.torch.color)) errors.push('Color de luz inválido.');
      if (item.id !== 'antorcha') warnings.push('El encendido automático del juego usa el ID «antorcha». Una variante con otro ID puede equiparse, pero aún no encenderse desde el acceso rápido.');
    }
    if (!item.magnitudes || typeof item.magnitudes !== 'object' || Array.isArray(item.magnitudes)) errors.push('Magnitudes inválidas.');
    else for (const [key, value] of Object.entries(item.magnitudes)) {
      if (!/^[a-z][a-z0-9_]{0,63}$/.test(key) || ['peso', 'recuperacion_pv', 'recuperacion_pv_dados', 'recuperacion_pv_caras', 'duracion'].includes(key)) errors.push('Magnitud adicional inválida o reservada: ' + key);
      else number(value, key === 'temperatura' ? -99999 : 0, 99999, 'Magnitud ' + key);
    }
    for (const field of ['icon', 'world', 'illustration', 'pickupSound', 'impactSound']) {
      const asset = item[field];
      if (!asset) continue;
      const image = !field.endsWith('Sound');
      const match = typeof asset.data === 'string' && asset.data.match(/^data:([^;,]+);base64,([A-Za-z0-9+/]*={0,2})$/);
      if (!match || match[2].length % 4 || asset.data.length > 12 * 1024 * 1024 || (image && match[1] !== 'image/png') || (!image && !['wav', 'ogg', 'mp3'].includes(asset.ext))) errors.push('Archivo inválido o demasiado grande en ' + field + '.');
      if (image) {
        number(asset.width, 1, 8192, 'Ancho de imagen', true);
        number(asset.height, 1, 8192, 'Alto de imagen', true);
      }
    }
    if (!item.icon) errors.push('Añade un icono para exportar el ítem.');
    const world = item.world || item.icon;
    if (world && (world.width % item.hframes || world.height % item.vframes)) errors.push('La imagen del suelo debe dividirse exactamente entre sus filas y columnas.');
    if (RESERVED.includes(item.id) && !(item.updateExisting && item.source?.id === item.id)) errors.push('El ID «' + item.id + '» ya pertenece al juego. Usa otro ID o marca «Actualizar el original».');
    if (item.updateExisting) {
      const expected = { antorcha: 'assets/items/antorcha/antorcha.tres', racion: 'assets/items/racion/racion.tres', piedra: 'assets/items/piedra/piedra.tres', bomba_humo: 'assets/items/bomba_humo/bomba_humo.tres', llave_prueba: 'assets/items/llave_prueba/llave_prueba.tres' };
      if (!item.source || item.id !== item.source.id || expected[item.id] !== item.source.path) errors.push('Solo puedes actualizar un original reconocido y conservando su ID.');
      else warnings.push('Este paquete reemplaza la definición original de «' + item.id + '» cuando lo copies al juego.');
    }
    if (heal?.max > 0 && (item.impact.type !== 'none' || item.tags.includes('arrojable'))) warnings.push('En acceso rápido se prioriza el lanzamiento. La curación de este objeto no se activará desde esa ranura mientras sea arrojable.');
    return { errors: [...new Set(errors)], warnings };
  }
  function parseProject(value) {
    if (!value || value.version !== VERSION || !Array.isArray(value.items) || value.items.length > 250) throw new Error('Este archivo no es un proyecto de Forja compatible (máximo 250 ítems).');
    const items = value.items.map(raw => {
      if (!raw || typeof raw !== 'object' || Array.isArray(raw)) throw new Error('Ítem de proyecto inválido.');
      for (const field of ['torch', 'impact']) if (Object.hasOwn(raw, field) && (!raw[field] || typeof raw[field] !== 'object' || Array.isArray(raw[field]))) throw new Error('Configuración inválida: ' + field + '.');
      const item = createItem(raw);
      item.key = uid();
      // Las únicas rutas de reemplazo admitidas se comprueban de nuevo al exportar.
      const result = validate(item);
      const critical = result.errors.filter(error => !error.startsWith('Escribe un nombre') && !error.startsWith('El ID debe') && !error.startsWith('Añade un icono'));
      if (critical.length) throw new Error(critical.join('\n'));
      return item;
    });
    return { version: VERSION, items };
  }
  function project(items) { return { application: 'Exhume · Forja de ítems', version: VERSION, items: clone(items) }; }
  const quote = text => JSON.stringify(String(text));
  const float = value => Number.isInteger(value) ? value + '.0' : String(value);
  const decode = data => Uint8Array.from(atob(data.slice(data.indexOf(',') + 1)), char => char.charCodeAt(0));
  function exportItem(item, all = [item]) {
    const result = validate(item, all);
    if (result.errors.length) throw new Error(result.errors.join('\n'));
    const path = 'assets/items/forja/' + item.id + '/';
    const definitionPath = item.updateExisting ? item.source.path : path + item.id + '.tres';
    const refs = [], files = [], properties = [];
    const ref = (type, resourcePath, id) => { refs.push('[ext_resource type=' + quote(type) + ' path=' + quote(resourcePath) + ' id=' + quote(id) + ']'); return 'ExtResource(' + quote(id) + ')'; };
    const add = (name, data) => files.push({ path: path + name, data });
    const assetRef = (field, name, type = 'Texture2D') => {
      if (!item[field]) return null;
      const extension = type === 'Texture2D' ? 'png' : item[field].ext;
      const file = name + '.' + extension;
      add(file, decode(item[field].data));
      return ref(type, 'res://' + path + file, name);
    };
    const script = { objeto: 'definicion_item', llave: 'definicion_llave', antorcha: 'definicion_antorcha' }[item.kind];
    const scriptClass = { objeto: 'DefinicionItem', llave: 'DefinicionLlave', antorcha: 'DefinicionAntorcha' }[item.kind];
    properties.push('script = ' + ref('Script', 'res://scripts/interacciones/items/' + script + '.gd', 'definicion'));
    properties.push('id_definicion = &' + quote(item.id), 'nombre = ' + quote(item.name), 'descripcion_base = ' + quote(item.description));
    properties.push('icono = ' + assetRef('icon', 'icono'));
    const world = item.world || item.icon;
    add('suelo.png', decode(world.data));
    const scale = item.worldWidth / (world.width / item.hframes);
    add('suelo.tscn', '[gd_scene format=3]\n\n[ext_resource type="Script" path="res://scripts/interacciones/items/representacion_item_suelo.gd" id="1"]\n[ext_resource type="Texture2D" path=' + quote('res://' + path + 'suelo.png') + ' id="2"]\n\n[node name="ItemSuelo" type="Node2D"]\nscript = ExtResource("1")\n\n[node name="Sprite2D" type="Sprite2D" parent="."]\ntexture_filter = 1\ntexture = ExtResource("2")\nscale = Vector2(' + float(scale) + ', ' + float(scale) + ')\nposition = Vector2(0, ' + float(-world.height / item.vframes * scale / 2) + ')\nhframes = ' + item.hframes + '\nvframes = ' + item.vframes + '\n');
    properties.push('escena_mundo = ' + ref('PackedScene', 'res://' + path + 'suelo.tscn', 'mundo'));
    for (const [field, name, property, type] of [['illustration', 'ilustracion', 'ilustracion_examen', 'Texture2D'], ['pickupSound', 'recoger', 'sonido_recoger', 'AudioStream'], ['impactSound', 'impacto', 'sonido_impacto', 'AudioStream']]) {
      const value = assetRef(field, name, type);
      if (value) properties.push(property + ' = ' + value);
    }
    properties.push('etiquetas = Array[StringName]([' + tags(item).map(tag => '&' + quote(tag)).join(', ') + '])');
    const magnitudes = { ...item.magnitudes, peso: item.weight };
    const heal = healing(item.heal);
    if (heal.max > 0) magnitudes.recuperacion_pv = heal.bonus;
    if (heal.dice > 0) { magnitudes.recuperacion_pv_dados = heal.dice; magnitudes.recuperacion_pv_caras = heal.sides; }
    if (item.kind === 'antorcha') magnitudes.duracion = item.torch.duration;
    properties.push('magnitudes = Dictionary[StringName, float]({\n' + Object.entries(magnitudes).map(([key, value]) => '&' + quote(key) + ': ' + float(value)).join(',\n') + '\n})');
    properties.push('apilable = ' + item.stackable, 'cantidad_maxima = ' + item.maxStack);
    if (item.equipmentEffects.length) properties.push('efectos_equipo = Array[Dictionary](' + JSON.stringify(item.equipmentEffects) + ')');
    if (item.kind === 'llave') properties.push('patron_cerradura = &' + quote(item.lockPattern));
    if (item.kind === 'antorcha') {
      const rgb = item.torch.color.slice(1).match(/../g).map(hex => float(parseInt(hex, 16) / 255));
      properties.push('radio_vision = ' + item.torch.vision, 'pasos_atenuacion = ' + item.torch.fade, 'energia_luz = ' + float(item.torch.energy), 'escala_luz = ' + float(item.torch.scale), 'color_luz = Color(' + rgb.join(', ') + ', 1)');
    }
    let subresources = '';
    if (item.impact.type !== 'none') {
      const impact = item.impact, base = SURFACES[impact.type][0];
      let effect = '[gd_scene format=3]\n\n[ext_resource type="PackedScene" path=' + quote('res://scenes/efectos_superficie/' + base + '.tscn') + ' id="1"]\n\n[node name=' + quote(base + 'Item') + ' instance=ExtResource("1")]\nduracion_superficie = ' + impact.duration + '\n';
      if (impact.type !== 'humo') effect += (impact.type === 'fuego' ? 'ticks_quemado' : 'ticks_veneno') + ' = ' + impact.ticks + '\ncantidad_dados_tick = ' + impact.dice + '\ncaras_dado_tick = ' + impact.sides + '\n';
      add('efecto.tscn', effect);
      const reactionScript = ref('Script', 'res://scripts/interacciones/items/reaccion_impacto_superficie.gd', 'reaccion');
      const scene = ref('PackedScene', 'res://' + path + 'efecto.tscn', 'efecto');
      subresources = '[sub_resource type="Resource" id="ReaccionImpacto"]\nscript = ' + reactionScript + '\nescena_superficie = ' + scene + '\nradio = ' + impact.radius + '\n';
      properties.push('reaccion_impacto = SubResource("ReaccionImpacto")');
    }
    const resourceUID = item.updateExisting && /^uid:\/\/[a-z0-9]+$/.test(item.source.uid || '') ? ' uid=' + quote(item.source.uid) : '';
    files.unshift({ path: definitionPath, data: '[gd_resource type="Resource" script_class=' + quote(scriptClass) + ' format=3' + resourceUID + ']\n\n' + refs.join('\n') + '\n\n' + subresources + '\n[resource]\n' + properties.join('\n') + '\n' });
    add('ficha.forja.json', JSON.stringify(project([item]), null, 2));
    return files;
  }
  function exportFiles(items) {
    if (!items.length) throw new Error('La biblioteca está vacía.');
    const result = items.flatMap(item => exportItem(item, items));
    const paths = new Set();
    for (const file of result) { if (paths.has(file.path)) throw new Error('Dos archivos tienen el mismo destino. Revisa los IDs.'); paths.add(file.path); }
    result.push({ path: 'LEEME_FORJA.txt', data: 'EXHUME · FORJA DE ÍTEMS\n\n1. Cierra el juego en ejecución.\n2. Extrae este ZIP en la raíz del proyecto (donde está project.godot). Conserva la carpeta assets.\n3. Godot importará las imágenes y recursos. Las definiciones .tres son DefinicionItem compatibles.\n4. En una zona, añade ItemSueloZona en ItemsSuelo y asigna la definición. También puedes asignarla a EntradaInventarioInicial de un cofre o NPC.\n5. Para acceso rápido, arrastra el objeto desde la mochila hasta el HUD.\n\nLos efectos_equipo se activan al equipar y se retiran al desequipar. El juego conserva los atributos base y guarda las ranuras. Revisa el alcance de arma/directo y la salvación elegida en cada efecto. Veneno de superficies mantiene la salvación normal. Los efectos de impacto se consumen al romperse.\n\nLos archivos ficha.forja.json permiten seguir editando cada objeto en el taller. Haz una copia de seguridad antes de reemplazar originales.\n' });
    return result;
  }
  const encoder = new TextEncoder();
  const crcTable = Array.from({ length: 256 }, (_, n) => { let c = n; for (let k = 0; k < 8; k++) c = (c & 1) ? 0xedb88320 ^ (c >>> 1) : c >>> 1; return c >>> 0; });
  function crc32(bytes) { let c = 0xffffffff; for (const byte of bytes) c = crcTable[(c ^ byte) & 255] ^ (c >>> 8); return (c ^ 0xffffffff) >>> 0; }
  function zip(files) {
    const locals = [], centrals = []; let offset = 0;
    for (const file of files) {
      if (!/^[a-zA-Z0-9_./-]+$/.test(file.path) || file.path.includes('..') || file.path.startsWith('/')) throw new Error('Ruta de exportación inválida.');
      const name = encoder.encode(file.path), data = typeof file.data === 'string' ? encoder.encode(file.data) : file.data, crc = crc32(data);
      const local = new Uint8Array(30 + name.length), lv = new DataView(local.buffer);
      lv.setUint32(0, 0x04034b50, true); lv.setUint16(4, 20, true); lv.setUint16(6, 0x800, true); lv.setUint32(14, crc, true); lv.setUint32(18, data.length, true); lv.setUint32(22, data.length, true); lv.setUint16(26, name.length, true); local.set(name, 30);
      const central = new Uint8Array(46 + name.length), cv = new DataView(central.buffer);
      cv.setUint32(0, 0x02014b50, true); cv.setUint16(4, 20, true); cv.setUint16(6, 20, true); cv.setUint16(8, 0x800, true); cv.setUint32(16, crc, true); cv.setUint32(20, data.length, true); cv.setUint32(24, data.length, true); cv.setUint16(28, name.length, true); cv.setUint32(42, offset, true); central.set(name, 46);
      locals.push(local, data); centrals.push(central); offset += local.length + data.length;
    }
    const centralSize = centrals.reduce((n, bytes) => n + bytes.length, 0), end = new Uint8Array(22), ev = new DataView(end.buffer);
    ev.setUint32(0, 0x06054b50, true); ev.setUint16(8, files.length, true); ev.setUint16(10, files.length, true); ev.setUint32(12, centralSize, true); ev.setUint32(16, offset, true);
    const output = new Uint8Array(offset + centralSize + 22); let at = 0;
    for (const bytes of [...locals, ...centrals, end]) { output.set(bytes, at); at += bytes.length; }
    return output;
  }
  return { VERSION, SURFACES, SLOTS, RESERVED, ATTRIBUTES, TESTS, EFFECT_TYPES, effectDefault, validEffects, effectDescription, createItem, clone, slug, uid, healing, tags, equipment, validate, parseProject, project, exportItem, exportFiles, zip, crc32 };
});
