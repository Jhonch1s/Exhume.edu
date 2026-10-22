const fs = require('node:fs');
const path = require('node:path');
const sharp = require('sharp');
const root = path.resolve(__dirname, '../..');
async function image(relative, width) {
  const { data, info } = await sharp(path.join(root, relative)).resize({ width, withoutEnlargement: true }).png().toBuffer({ resolveWithObject: true });
  return { name: path.basename(relative), data: 'data:image/png;base64,' + data.toString('base64'), width: info.width, height: info.height };
}
(async () => {
  const definitions = [
    ['bomba_humo', 'Bomba de humo', 'objeto', ['arrojable', 'fragil', 'humo'], 1, 10, 'assets/items/bomba_humo/icons/bomba_humo_icono.png', 'assets/items/bomba_humo/sprites/bomba_humo_isometric1.png'],
    ['piedra', 'Piedra', 'objeto', ['mineral', 'solido', 'contundente', 'arrojable'], 3, 99, 'assets/items/piedra/icons/piedra_icon.png.png', 'assets/items/piedra/sprites/piedra_isometrica.png'],
    ['racion', 'Ración de viaje', 'objeto', ['consumible', 'comida'], 0.5, 20, 'assets/items/racion/icons/racion_icono.png'],
    ['llave_prueba', 'Llave de cripta', 'llave', ['llave', 'solido'], 0.2, 1, 'assets/items/llave_prueba/icons/llave_prueba_icono.png', 'assets/items/llave_prueba/sprite/llave_prueba.png'],
    ['antorcha', 'Antorcha', 'antorcha', ['luz', 'consumible'], 1, 10, 'assets/items/antorcha/icons/antorcha_icono.png', 'assets/items/antorcha/sprites/antorcha.png'],
  ];
  const seeds = [];
  for (const [id, name, kind, tags, weight, maxStack, iconPath, worldPath] of definitions) {
    const resourcePath = `assets/items/${id}/${id}.tres`;
    const text = fs.readFileSync(path.join(root, resourcePath), 'utf8');
    const description = text.match(/descripcion_base = (".*")/)?.[1];
    seeds.push({ id, name, kind, tags, weight, maxStack, stackable: maxStack > 1,
      description: description ? JSON.parse(description) : '',
      icon: await image(iconPath, 192), world: worldPath ? await image(worldPath, id === 'piedra' ? 768 : 256) : null,
      hframes: id === 'piedra' ? 3 : 1,
      heal: id === 'racion' ? 50 : 0, lockPattern: id === 'llave_prueba' ? 'cripta_simple' : '',
      impact: { type: id === 'bomba_humo' ? 'humo' : 'none', radius: id === 'bomba_humo' ? 2 : 0, duration: 10, ticks: 2, dice: 1, sides: 2 },
      source: { id, path: resourcePath, uid: text.match(/uid="([^"]+)"/)?.[1] || '' }
    });
  }
  fs.writeFileSync(path.join(__dirname, 'dist/catalog.js'), 'globalThis.FORJA_CATALOG = ' + JSON.stringify(seeds) + ';\n');
  console.log('Catálogo: cinco plantillas reales, imágenes incluidas.');
})().catch(error => { console.error(error); process.exitCode = 1; });
