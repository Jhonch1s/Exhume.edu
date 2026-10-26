const assert = require('node:assert/strict');
const fs = require('node:fs');
const path = require('node:path');
const vm = require('node:vm');
const F = require('../dist/core.js');
const context = {};
vm.runInNewContext(fs.readFileSync(path.join(__dirname, '../dist/catalog.js'), 'utf8'), context);
const seeds = JSON.parse(JSON.stringify(context.FORJA_CATALOG));
let checks = 0;
function check(value, message) { assert.ok(value, message); checks++; }
function invalid(change) { const item = F.createItem({ ...seeds[0], id: 'prueba', ...change }); check(F.validate(item).errors.length > 0, JSON.stringify(change)); }
const items = seeds.map(seed => F.createItem({ ...seed, id: 'forja_' + seed.id }));
for (const item of items) {
  check(!F.validate(item).errors.length, item.id);
  const files = F.exportItem(item);
  check(files.some(file => file.path.endsWith('/suelo.tscn')), 'escena de suelo');
  check(files.some(file => file.path.endsWith('/ficha.forja.json')), 'ficha reeditable');
  const restored = F.parseProject(JSON.parse(files.find(file => file.path.endsWith('.json')).data)).items[0];
  check(restored.icon.data === item.icon.data && restored.id === item.id, 'ida y vuelta');
  check(files.find(file => file.path.endsWith('/suelo.tscn')).data.includes('position = Vector2(0, 0)'), 'sprite de suelo centrado en su celda');
}
for (const seed of seeds) {
  const item = F.createItem({ ...seed, updateExisting: true });
  const resource = F.exportItem(item)[0];
  check(resource.path === seed.source.path, 'ruta original');
  check(!seed.source.uid || resource.data.includes(seed.source.uid), 'UID original');
}
invalid({ id: '../fuera' }); invalid({ id: 'piedra' }); invalid({ weight: -1 }); invalid({ weight: Infinity });
invalid({ stackable: false, maxStack: 2 }); invalid({ maxStack: 0 }); invalid({ hframes: 5 });
invalid({ tags: ['no válida'] }); invalid({ magnitudes: { peso: 2 } }); invalid({ magnitudes: { dureza: -2 } });
invalid({ kind: 'llave', lockPattern: '' }); invalid({ impact: { type: 'otro' } }); invalid({ impact: { type: 'fuego', radius: 9 } });
invalid({ icon: null }); invalid({ updateExisting: true, source: { id: 'prueba', path: '../fuera' } });
for (const heal of ['1d1', '1d101', '0d6', '10d6', '1d6-2', '1d6+10000', 'curacion=5', '', -1, 1.5, null]) invalid({ heal });
for (const [formula, dice, sides, bonus, min, max] of [['1d6', 1, 6, 0, 1, 6], [' 2D4 + 2 ', 2, 4, 2, 4, 10], [5, 0, 0, 5, 5, 5], ['0', 0, 0, 0, 0, 0]]) {
  const heal = F.healing(formula);
  check(heal.dice === dice && heal.sides === sides && heal.bonus === bonus && heal.min === min && heal.max === max, 'fórmula y rango: ' + formula);
}
invalid({ magnitudes: { recuperacion_pv_dados: 1 } });
const potion = F.createItem({ ...seeds[2], id: 'pocion_1d6', heal: '1d6' });
check(F.tags(potion).includes('consumible'), 'curación con dados añade consumible');
check(F.exportItem(potion)[0].data.includes('&"recuperacion_pv_dados": 1.0') && F.exportItem(potion)[0].data.includes('&"recuperacion_pv_caras": 6.0'), 'dados exportados como magnitudes numéricas');
check(F.parseProject(F.project([potion])).items[0].heal === '1d6', 'la ficha conserva la fórmula');
check(F.validate(F.createItem({ ...potion, tags: ['arrojable'] })).warnings.some(message => message.includes('lanzamiento')), 'advertir incompatibilidad de acceso rápido');
const cold = F.createItem({ ...seeds[0], id: 'frio', magnitudes: { temperatura: -20 } });
check(!F.validate(cold).errors.length, 'temperatura negativa');
const copy = F.createItem({ ...items[0], key: F.uid() });
check(F.validate(copy, [items[0], copy]).errors.some(error => error.includes('otro ítem')), 'ID duplicado');
check(F.createItem({ impact: { type: 'fuego' } }).impact.duration === 7, 'valores parciales');
check(!Object.hasOwn(F.createItem(JSON.parse('{"__proto__":{"unsafe":true}}')), 'unsafe'), 'campos desconocidos');
assert.throws(() => F.parseProject({ version: 1, items: [{ torch: null }] })); checks++;
assert.throws(() => F.parseProject({ version: 2, items: [] })); checks++;
assert.throws(() => F.zip([{ path: '../fuera', data: '' }])); checks++;
check(F.crc32(new TextEncoder().encode('123456789')) === 0xcbf43926, 'CRC conocido');
const torch = items.find(item => item.kind === 'antorcha');
check(F.validate(torch).warnings.some(message => message.includes('encenderse')), 'límite de encendido explícito');
check(F.equipment(items[0]).includes('Mano principal'), 'equipo arrojable');
check(F.tags(items.find(item => item.kind === 'llave')).includes('llave'), 'llave semántica');
for (const type of ['fuego', 'veneno']) items.push(F.createItem({ ...seeds[0], id: 'forja_' + type, impact: { type, radius: 2, duration: 13, ticks: 4, dice: 2, sides: 6 } }));
items.push(potion, F.createItem({ ...potion, id: 'pocion_2d4_mas_2', heal: '2d4+2' }), F.createItem({ ...potion, id: 'pocion_fija', heal: '5' }));
const sword = F.createItem({ ...seeds[0], id: 'espada_forja', name: 'Espada de prueba de Forja', tags: ['arma'], weaponDice: '1d3', stackable: false, maxStack: 1, impact: { type: 'none' }, equipmentEffects: [
  { tipo: 'atributo', atributo: 'fuerza', valor: 1 },
  { tipo: 'dano', valor: 2, alcance: 'arma' },
  { tipo: 'tirada', prueba: 'ataque', modo: 'ventaja' },
  { tipo: 'estado', estado: 'veneno', valor: 1, duracion: 2, alcance: 'arma', salvacion: '' },
  { tipo: 'penalizacion', atributo: 'fuerza', valor: 1, duracion: 2, alcance: 'arma', salvacion: '' }
] });
sword.classRestrictions = ['Guerrero'];
check(F.exportItem(sword)[0].data.includes('clases_permitidas = Array[StringName]([&"Guerrero"])'), 'clase permitida exportada');
check(F.parseProject(F.project([sword])).items[0].classRestrictions[0] === 'Guerrero', 'clase permitida conservada');
invalid({ classRestrictions: ['Paladín'] });
invalid({ classRestrictions: ['Mago', 'Mago'] });
invalid({ classRestrictions: ['Guerrero'], tags: [], impact: { type: 'none' } });
invalid({ twoHanded: true, tags: [], impact: { type: 'none' } });
const ring = F.createItem({ ...sword, id: 'anillo_forja', name: 'Anillo de prueba de Forja', tags: ['anillo'], weaponDice: '0', equipmentEffects: [
  { tipo: 'atributo', atributo: 'voluntad', valor: 1 }, { tipo: 'atributo', atributo: 'destreza', valor: -1 },
  { tipo: 'dano', valor: 1, alcance: 'directo' }, { tipo: 'tirada', prueba: 'voluntad', modo: 'ventaja' }
] });
for (const item of [sword, ring]) {
  check(F.validEffects(item.equipmentEffects) && F.validate(item).errors.length === 0, 'efectos válidos: ' + item.id);
  const exported = F.exportItem(item)[0].data;
  check(exported.includes('efectos_equipo = Array[Dictionary]('), 'efectos exportados nativos');
  check(F.parseProject(F.project([item])).items[0].equipmentEffects.length === item.equipmentEffects.length, 'ida y vuelta efectos');
}
check(F.exportItem(sword)[0].data.includes('&"dano_arma_dados": 1.0') && F.exportItem(sword)[0].data.includes('&"dano_arma_caras": 3.0'), 'dado de espada exportado');
check(F.parseProject(F.project([sword])).items[0].weaponDice === '1d3', 'dado de arma conservado en la ficha');
for (const weaponDice of ['1d1', '1d3+2', '5', '0d2', '']) check(F.validate(F.createItem({ ...sword, weaponDice })).errors.length > 0, 'dado de arma inválido: ' + weaponDice);
check(F.validate(F.createItem({ ...sword, tags: [] })).errors.length > 0, 'dado de arma exige mano principal');
for (const equipmentEffects of [null, {}, [null], [{ tipo: 'otro' }], [{ tipo: 'atributo', atributo: 'fuerza', valor: 0 }], [{ tipo: 'atributo', atributo: 'fuerza', valor: 6 }], [{ tipo: 'tirada', prueba: 'todas', modo: 'ventaja' }], Array(17).fill(F.effectDefault())]) invalid({ equipmentEffects });
invalid({ tags: [], impact: { type: 'none' }, equipmentEffects: [F.effectDefault()] });
check(F.validate(F.createItem({ ...ring, equipmentEffects: [{ tipo: 'dano', valor: 1, alcance: 'arma' }] })).errors.length > 0, 'arma requiere mano principal');
const dagger = F.createItem({ ...sword, id: 'daga_forja', name: 'Daga de prueba', tags: ['arma', 'daga'], weaponDice: '1d2', equipmentEffects: [] });
const staff = F.createItem({ ...sword, id: 'baston_forja', name: 'Bastón de prueba', weaponDice: '1d2', equipmentEffects: [] });
staff.classRestrictions = ['Mago'];
staff.twoHanded = true;
check(F.exportItem(staff)[0].data.includes('requiere_dos_manos = true'), 'bastón a dos manos exportado');
check(F.validate(dagger).errors.length === 0 && F.validate(staff).errors.length === 0, 'daga y bastón aceptan 1d2');
items.push(sword, ring, dagger, staff);
items[0].description = 'Frasco «bruma»\nDijo: "ábreme". Ruta \\ y una ñ.';
items[0].illustration = items[0].icon;
items[0].magnitudes = { temperatura: -4.5 };
const files = F.exportFiles(items);
const root = path.resolve(__dirname, '../../..');
const fixture = path.join(root, '.godot/forja_export_test');
fs.mkdirSync(fixture, { recursive: true });
fs.writeFileSync(path.join(fixture, 'paquete.zip'), F.zip(files));
// Aislar las rutas de recursos en el área de pruebas sin tocar los assets del juego.
for (const file of files) {
  const target = path.join(fixture, file.path);
  fs.mkdirSync(path.dirname(target), { recursive: true });
  const data = typeof file.data === 'string' ? file.data.replaceAll('res://assets/items/forja/', 'res://.godot/forja_export_test/assets/items/forja/') : file.data;
  fs.writeFileSync(target, data);
}
fs.writeFileSync(path.join(fixture, 'manifest.json'), JSON.stringify(items.map(item => ({ id: item.id, name: item.name, description: item.description, kind: item.kind, weight: item.weight, maxStack: item.maxStack, hframes: item.hframes, heal: F.healing(item.heal), pattern: item.lockPattern, impact: item.impact, torch: item.torch, equipmentEffects: item.equipmentEffects }))));
const audioItem = F.createItem({ ...seeds[0], id: 'con_audio', pickupSound: { ext: 'wav', data: 'data:audio/wav;base64,UklGRg==' } });
check(F.exportItem(audioItem).some(file => file.path.endsWith('recoger.wav')), 'audio incluido');
check(F.exportItem(audioItem)[0].data.includes('sonido_recoger = ExtResource'), 'audio enlazado');
console.log(`${checks} comprobaciones correctas; ${items.length} recursos y ZIP listos para verificar con Godot.`);
