(() => {
  'use strict';
  const F = window.Forja, $ = selector => document.querySelector(selector), $$ = selector => [...document.querySelectorAll(selector)];
  let items = [], selected = '', view = 'inventory', quantity = 1, database = null, saveTimer, revision = 0, toastTimer, imported = null;
  const current = () => items.find(item => item.key === selected);
  const text = (element, value) => { element.textContent = value; return element; };
  const make = (tag, className, value) => { const node = document.createElement(tag); if (className) node.className = className; if (value != null) node.textContent = value; return node; };
  const icon = name => { const svg = document.createElementNS('http://www.w3.org/2000/svg', 'svg'); const use = document.createElementNS(svg.namespaceURI, 'use'); use.setAttribute('href', '#i-' + name); svg.append(use); return svg; };
  const image = (asset, className) => { const img = make('img', className); img.src = asset.data; img.alt = ''; return img; };
  const read = (object, path) => path.split('.').reduce((value, key) => value?.[key], object);
  const write = (object, path, value) => { const keys = path.split('.'); const key = keys.pop(); keys.reduce((value, part) => value[part], object)[key] = value; };
  const format = value => new Intl.NumberFormat('es-UY', { maximumFractionDigits: 2 }).format(Number.isFinite(value) ? value : 0);
  function toast(message, error = false) { const node = $('#toast'); node.textContent = message; node.classList.toggle('error', error); node.hidden = false; clearTimeout(toastTimer); toastTimer = setTimeout(() => { node.hidden = true; }, error ? 8000 : 4500); }
  function download(name, data, type) { const blob = new Blob([data], { type }); const url = URL.createObjectURL(blob); const a = make('a'); a.href = url; a.download = name; a.click(); setTimeout(() => URL.revokeObjectURL(url), 5000); }
  const backup = () => download('exhume-forja-' + new Date().toISOString().slice(0, 10) + '.json', JSON.stringify(F.project(items), null, 2), 'application/json');
  function uniqueId(id) { let value = id, n = 2; while (items.some(item => item.id === value)) value = id.slice(0, 58) + '_' + n++; return value; }
  function fromTemplate(seed, example = false) {
    const item = F.createItem(seed);
    item.id = uniqueId(seed.id + '_nuevo'); item.name = seed.name + ' · variante';
    if (example) { item.id = 'frasco_de_bruma'; item.name = 'Frasco de bruma'; item.description = 'Un pequeño recipiente de cerámica sellado con cera. Al romperse, libera una niebla densa que oculta el camino a quienes lo vigilan.'; item.weight = 0.8; item.maxStack = 6; item.impact.radius = 2; }
    return item;
  }
  async function openStorage() {
    return new Promise((resolve, reject) => {
      const request = indexedDB.open('exhume-forja-items', 1);
      request.onupgradeneeded = () => request.result.createObjectStore('taller');
      request.onerror = () => reject(request.error);
      request.onsuccess = () => resolve(request.result);
      request.onblocked = () => reject(new Error('Cierra otras pestañas antiguas del taller para guardar.'));
    });
  }
  async function storageRead() { return new Promise((resolve, reject) => { const request = database.transaction('taller').objectStore('taller').get('proyecto'); request.onsuccess = () => resolve(request.result); request.onerror = () => reject(request.error); }); }
  async function persistNow() {
    clearTimeout(saveTimer);
    if (!database) return;
    const savedRevision = revision;
    const snapshot = { version: F.VERSION, selected, items: F.clone(items) };
    try {
      await new Promise((resolve, reject) => { const transaction = database.transaction('taller', 'readwrite'); transaction.objectStore('taller').put(snapshot, 'proyecto'); transaction.oncomplete = resolve; transaction.onabort = transaction.onerror = () => reject(transaction.error); });
      if (savedRevision === revision) { text($('#save-state'), '● Guardado en este navegador'); $('#save-state').classList.remove('error'); }
    } catch (_) { text($('#save-state'), 'No se pudo guardar · descarga copia'); $('#save-state').classList.add('error'); toast('El navegador no pudo guardar. Descarga una copia de seguridad para conservar tus imágenes y cambios.', true); }
  }
  function changed() { revision++; text($('#save-state'), database ? 'Guardando…' : 'Sin guardado local · descarga copia'); clearTimeout(saveTimer); saveTimer = setTimeout(persistNow, 350); renderLibrary(); renderPreview(); renderConditions(); }
  function selectItem(key) { selected = key; quantity = 1; renderForm(); renderLibrary(); renderPreview(); persistNow(); }
  function renderLibrary() {
    text($('#item-count'), items.length);
    const term = $('#search').value.trim().toLocaleLowerCase('es'); const list = $('#item-list'); list.replaceChildren();
    const visible = items.filter(item => (item.name + ' ' + item.id).toLocaleLowerCase('es').includes(term));
    for (const item of visible) {
      const button = make('button', 'library-item' + (item.key === selected ? ' selected' : '')); button.setAttribute('aria-pressed', item.key === selected);
      const thumb = make('span', 'library-icon'); thumb.append(item.icon ? image(item.icon) : icon('image'));
      const labels = make('span', 'library-item-text'); labels.append(make('b', '', item.name || 'Objeto sin nombre'), make('small', '', '#' + (item.id || 'sin_id')));
      const valid = F.validate(item, items).errors.length === 0; const dot = make('span', 'status-dot' + (valid ? '' : ' invalid')); dot.title = valid ? 'Listo para exportar' : 'Tiene campos por completar';
      button.append(thumb, labels, dot); button.addEventListener('click', () => selectItem(item.key)); list.append(button);
    }
    if (!visible.length) list.append(make('p', 'empty-state', term ? 'No hay coincidencias. Prueba otro nombre.' : 'Tu próximo hallazgo empieza aquí. Crea un ítem o elige una plantilla.'));
  }
  function renderForm() {
    const item = current(); $('#item-form').hidden = !item;
    $('#duplicate').disabled = $('#delete').disabled = !item;
    if (!item) { text($('#editor-title'), 'Un objeto, muchas posibilidades.'); return; }
    text($('#editor-title'), item.name || 'Un objeto por descubrir');
    for (const field of $$('[data-field]')) { const value = read(item, field.dataset.field); if (field.type === 'checkbox') field.checked = !!value; else field.value = value ?? ''; }
    $('#tags').value = item.tags.join(', ');
    renderConditions(); renderImages(); renderAudio(); renderMagnitudes(); renderTags(); renderClassRestrictions(); renderEquipmentEffects();
  }
  function renderConditions() {
    const item = current(); if (!item) return;
    $('#stack-limit').hidden = !item.stackable; $('#key-fields').hidden = item.kind !== 'llave'; $('#torch-fields').hidden = item.kind !== 'antorcha';
    $('#kind-help').textContent = item.kind === 'llave' ? 'Abre cerraduras por patrón.' : item.kind === 'antorcha' ? 'Luz de exploración y equipo.' : 'Objeto, equipo o consumible.';
    $('#impact-fields').hidden = item.impact.type === 'none'; $('#state-fields').hidden = item.impact.type === 'humo';
    $('#update-original-wrap').hidden = !item.source;
    if (item.source) $('#original-help').textContent = 'Reemplaza ' + item.source.id + '. Las imágenes nuevas se guardan en una carpeta propia.';
    $$('[data-effect]').forEach(button => { const active = button.dataset.effect === item.impact.type; button.classList.toggle('active', active); button.setAttribute('aria-pressed', active); });
    $('#equipment-help').textContent = F.equipment(item).length ? 'Se puede colocar en: ' + F.equipment(item).join(' · ') + '. Sus efectos de equipo se activan al equiparlo.' : 'Sin ranura de equipo específica. Puede llevarse en la mochila y arrastrarse al acceso rápido si tiene un uso compatible.';
    const heal = F.healing(item.heal);
    $('#healing-help').textContent = !heal ? 'Usa una cantidad fija (5) o dados (1d6, 2d4+2). 0 = sin curación.' : heal.dice ? 'Recupera entre ' + heal.min + ' y ' + heal.max + ' PV. Se tira ' + heal.formula + ' cada vez que se usa. Añade automáticamente consumible.' : heal.max ? 'Recupera ' + heal.max + ' PV fijos al usar. También puedes escribir 1d6 o 1d6+2.' : '5 = fija · 1d6 = entre 1 y 6 · 1d6+2 = entre 3 y 8 · 0 = sin curación.';
    if (item.impact.type !== 'none') {
      const footprint = $('#effect-footprint'); footprint.replaceChildren(); const grid = make('div', 'effect-cells');
      for (let y = -3; y <= 3; y++) for (let x = -3; x <= 3; x++) grid.append(make('span', Math.abs(x) + Math.abs(y) <= item.impact.radius ? (x === 0 && y === 0 ? 'center' : 'lit') : ''));
      const radius = item.impact.radius, count = 1 + 2 * radius * (radius + 1);
      footprint.append(grid, make('span', '', count + ' casilla' + (count === 1 ? '' : 's') + ' · radio ' + radius + (radius > 3 ? '\nVista recortada a 7 × 7.' : '')));
      $('#effect-help').textContent = item.impact.type === 'humo' ? 'El humo bloquea la visión. El recipiente se consume al impactar. No causa daño por sí solo.' : (item.impact.type === 'veneno' ? 'El veneno permite la salvación normal de Voluntad. ' : 'El fuego aplica Quemado a quien entre. ') + 'El estado usa ' + item.impact.ticks + ' pulsos de ' + item.impact.dice + 'd' + item.impact.sides + '. La duración del suelo se cuenta por separado.';
    }
  }
  function renderTags() {
    const area = $('#tag-suggestions'); area.replaceChildren(); const item = current(); if (!item) return;
    const suggestions = { arrojable: 'Arrojable', consumible: 'Consumible', arma: 'Arma', daga: 'Daga / otra mano', escudo: 'Escudo', casco: 'Cabeza', armadura: 'Pecho', guantes: 'Guantes', botas: 'Botas', amuleto: 'Amuleto', anillo: 'Anillo' };
    for (const [tag, label] of Object.entries(suggestions)) { const button = make('button', item.tags.includes(tag) ? 'active' : '', label); button.type = 'button'; button.setAttribute('aria-pressed', item.tags.includes(tag)); button.addEventListener('click', () => { item.tags = item.tags.includes(tag) ? item.tags.filter(value => value !== tag) : [...item.tags, tag]; $('#tags').value = item.tags.join(', '); renderTags(); changed(); }); area.append(button); }
  }
  function renderClassRestrictions() {
    const area = $('#class-restrictions'); area.replaceChildren(); const item = current(); if (!item) return;
    for (const [name, label] of Object.entries(F.CLASSES)) {
      const button = make('button', item.classRestrictions.includes(name) ? 'active' : '', label); button.type = 'button';
      button.setAttribute('aria-pressed', item.classRestrictions.includes(name));
      button.addEventListener('click', () => { item.classRestrictions = item.classRestrictions.includes(name) ? item.classRestrictions.filter(value => value !== name) : [...item.classRestrictions, name]; renderClassRestrictions(); changed(); });
      area.append(button);
    }
  }
  function renderEquipmentEffects() {
    const area = $('#equipment-effects'); area.replaceChildren(); const item = current(); if (!item) return;
    $('#add-equipment-effect').disabled = item.equipmentEffects.length >= 16;
    item.equipmentEffects.forEach((effect, index) => {
      const card = make('div', 'equipment-effect'), heading = make('div', 'effect-heading');
      heading.append(make('b', '', 'Efecto ' + (index + 1)));
      const remove = make('button', 'icon-button'); remove.type = 'button'; remove.setAttribute('aria-label', 'Eliminar efecto ' + (index + 1)); remove.append(icon('trash')); remove.addEventListener('click', () => { item.equipmentEffects.splice(index, 1); renderEquipmentEffects(); changed(); }); heading.append(remove); card.append(heading);
      const fields = make('div', 'effect-fields');
      function select(label, key, options) {
        const wrap = make('label', '', label), control = make('select'); control.setAttribute('aria-label', label + ' del efecto ' + (index + 1));
        for (const [value, text] of Object.entries(options)) { const option = make('option', '', text); option.value = value; control.append(option); }
        control.value = effect[key]; control.addEventListener('change', () => { if (key === 'tipo') { item.equipmentEffects[index] = F.effectDefault(control.value); if (item.equipmentEffects[index].alcance && !F.equipment(item).includes('Mano principal')) item.equipmentEffects[index].alcance = 'directo'; renderEquipmentEffects(); } else effect[key] = control.value; changed(); }); wrap.append(control); fields.append(wrap);
      }
      function number(label, key, min, max) {
        const wrap = make('label', '', label), control = make('input'); control.type = 'number'; control.min = min; control.max = max; control.step = 1; control.value = effect[key]; control.setAttribute('aria-label', label + ' del efecto ' + (index + 1)); control.addEventListener('input', () => { effect[key] = Number(control.value); changed(); }); wrap.append(control); fields.append(wrap);
      }
      select('Tipo', 'tipo', F.EFFECT_TYPES);
      if (['atributo', 'penalizacion'].includes(effect.tipo)) select('Atributo', 'atributo', F.ATTRIBUTES);
      if (effect.tipo === 'atributo') number('Bono / penalización', 'valor', -5, 5);
      if (effect.tipo === 'tirada') { select('Tirada', 'prueba', F.TESTS); select('Modo', 'modo', { ventaja: 'Ventaja', desventaja: 'Desventaja' }); }
      if (['dano', 'estado', 'penalizacion'].includes(effect.tipo)) {
        select('Alcance', 'alcance', { arma: 'Arma de mano principal', directo: 'Ataques y Bola de fuego' });
        if (effect.tipo === 'estado') select('Estado', 'estado', { veneno: 'Veneno', quemado: 'Quemado' });
        number(effect.tipo === 'estado' ? 'Daño por turno' : effect.tipo === 'dano' ? 'Daño extra' : 'Reducción', 'valor', 1, effect.tipo === 'penalizacion' ? 5 : 99);
        if (effect.tipo !== 'dano') { number('Turnos del objetivo', 'duracion', 1, 99); select('Salvación para evitarlo', 'salvacion', { '': 'Sin salvación', ...F.ATTRIBUTES }); }
      }
      card.append(fields); area.append(card);
    });
    if (!item.equipmentEffects.length) area.append(make('p', 'note', 'Sin efectos de equipo. Añade los que quieras combinar.'));
  }
  function renderMagnitudes() {
    const list = $('#magnitude-list'); list.replaceChildren(); const item = current(); if (!item) return;
    for (const [key, value] of Object.entries(item.magnitudes)) {
      const row = make('div', 'magnitude-row'), inputKey = make('input'), inputValue = make('input'), remove = make('button', 'icon-button');
      inputKey.value = key; inputKey.placeholder = 'temperatura'; inputKey.setAttribute('aria-label', 'Nombre de la magnitud'); inputValue.type = 'number'; inputValue.step = 'any'; inputValue.value = value; inputValue.setAttribute('aria-label', 'Valor de la magnitud'); remove.type = 'button'; remove.setAttribute('aria-label', 'Eliminar magnitud'); remove.append(icon('trash')); let oldKey = key;
      inputKey.addEventListener('change', () => { const next = inputKey.value.trim(); if (next !== oldKey && Object.hasOwn(item.magnitudes, next)) { inputKey.value = oldKey; toast('Esa magnitud ya existe.', true); return; } const entries = Object.entries(item.magnitudes).map(([k, v]) => [k === oldKey ? next : k, v]); item.magnitudes = Object.fromEntries(entries); oldKey = next; changed(); });
      inputValue.addEventListener('input', () => { item.magnitudes[oldKey] = Number(inputValue.value); changed(); });
      remove.addEventListener('click', () => { delete item.magnitudes[oldKey]; renderMagnitudes(); changed(); }); row.append(inputKey, inputValue, remove); list.append(row);
    }
  }
  async function readFile(file) { return new Promise((resolve, reject) => { const reader = new FileReader(); reader.onload = () => resolve(reader.result); reader.onerror = () => reject(new Error('No se pudo leer el archivo.')); reader.readAsDataURL(file); }); }
  async function loadImage(file, field) {
    try {
      if (!file || !/^image\//.test(file.type)) throw new Error('Elige una imagen PNG, JPEG, WebP o SVG.');
      if (file.size > 8 * 1024 * 1024) throw new Error('Usa una imagen de hasta 8 MB.');
      const target = current(); if (!target) return;
      const data = await readFile(file); const bitmap = new Image(); bitmap.src = data; await bitmap.decode();
      if (!bitmap.naturalWidth || bitmap.naturalWidth > 8192 || bitmap.naturalHeight > 8192) throw new Error('La imagen debe medir entre 1 y 8192 píxeles por lado.');
      const max = field === 'icon' ? 512 : 2048, ratio = Math.min(1, max / Math.max(bitmap.naturalWidth, bitmap.naturalHeight));
      const canvas = document.createElement('canvas'); canvas.width = Math.max(1, Math.round(bitmap.naturalWidth * ratio)); canvas.height = Math.max(1, Math.round(bitmap.naturalHeight * ratio)); canvas.getContext('2d').drawImage(bitmap, 0, 0, canvas.width, canvas.height);
      const png = canvas.toDataURL('image/png'); if (png.length > 12 * 1024 * 1024) throw new Error('La imagen resultante es demasiado grande. Reduce su tamaño.');
      target[field] = { name: file.name.replace(/\.[^.]+$/, '') + '.png', width: canvas.width, height: canvas.height, data: png };
      if (field === 'world') { target.hframes = 1; target.vframes = 1; }
      if (target === current()) { renderImages(); renderFormNumbers(); }
      changed(); toast('Imagen incorporada. Se incluirá en la copia y en el ZIP.');
    } catch (error) { toast(error.message, true); }
  }
  function renderFormNumbers() { for (const field of $$('[data-number]')) field.value = read(current(), field.dataset.field); }
  function renderImages() {
    const item = current(), area = $('#image-inputs'); area.replaceChildren(); if (!item) return;
    for (const [field, title, hint] of [['icon', 'Icono del inventario', 'Obligatorio · mochila y HUD'], ['world', 'Sprite en el suelo', 'Opcional · usa el icono por defecto'], ['illustration', 'Ilustración al examinar', 'Opcional · vista detallada']]) {
      const tile = make('div', 'image-tile'); tile.tabIndex = 0; tile.setAttribute('aria-label', title + ': arrastra o selecciona una imagen');
      const preview = make('div', 'image-preview'); preview.append(item[field] ? image(item[field]) : icon('image'));
      const file = make('input'); file.type = 'file'; file.accept = 'image/png,image/jpeg,image/webp,image/svg+xml'; file.hidden = true;
      const button = make('button', '', item[field] ? 'Cambiar imagen' : 'Elegir imagen'); button.type = 'button'; button.addEventListener('click', () => file.click()); file.addEventListener('change', () => loadImage(file.files[0], field));
      tile.append(preview, make('h3', '', title), make('small', '', item[field] ? item[field].width + ' × ' + item[field].height + ' · ' + item[field].name : hint), button, file);
      if (item[field]) { const remove = make('button', 'remove-image icon-button'); remove.type = 'button'; remove.title = 'Quitar imagen'; remove.setAttribute('aria-label', 'Quitar ' + title); remove.append(icon('close')); remove.addEventListener('click', () => { item[field] = null; renderImages(); changed(); }); tile.append(remove); }
      tile.addEventListener('dragover', event => { event.preventDefault(); tile.classList.add('dragging'); }); tile.addEventListener('dragleave', () => tile.classList.remove('dragging')); tile.addEventListener('drop', event => { event.preventDefault(); tile.classList.remove('dragging'); loadImage(event.dataTransfer.files[0], field); });
      tile.addEventListener('paste', event => { const pasted = [...event.clipboardData.files].find(file => file.type.startsWith('image/')); if (pasted) { event.preventDefault(); loadImage(pasted, field); } }); area.append(tile);
    }
  }
  function renderAudio() {
    const item = current(), area = $('#audio-inputs'); area.replaceChildren(); if (!item) return;
    for (const [field, title] of [['pickupSound', 'Al recoger'], ['impactSound', 'Al impactar']]) {
      const row = make('div', 'audio-row'), heading = make('div', 'audio-heading'); heading.append(make('span', '', title));
      const file = make('input'); file.type = 'file'; file.accept = '.wav,.ogg,.mp3'; file.hidden = true;
      const button = make('button', 'quiet', item[field] ? 'Cambiar audio' : 'Añadir audio'); button.type = 'button'; button.addEventListener('click', () => file.click());
      file.addEventListener('change', async () => { try { const sound = file.files[0]; if (!sound) return; const ext = sound.name.split('.').pop().toLowerCase(); if (!['wav', 'ogg', 'mp3'].includes(ext) || sound.size > 8 * 1024 * 1024) throw new Error('Usa WAV, OGG o MP3 de hasta 8 MB.'); const target = current(); target[field] = { name: sound.name, ext, data: await readFile(sound) }; if (target === current()) renderAudio(); changed(); } catch (error) { toast(error.message, true); } }); heading.append(button); row.append(heading, file);
      if (item[field]) { const audio = make('audio'); audio.controls = true; audio.src = item[field].data; const remove = make('button', 'quiet', 'Quitar audio'); remove.type = 'button'; remove.addEventListener('click', () => { item[field] = null; renderAudio(); changed(); }); row.append(audio, make('small', '', item[field].name), remove); } else row.append(make('small', '', 'Si lo dejas vacío, se utiliza el sonido por defecto del juego.')); area.append(row);
    }
  }
  function renderPreview() {
    const item = current(), stage = $('#preview-stage'); stage.replaceChildren();
    if (!item) { stage.append(make('div', 'placeholder-art', '◇')); for (const id of ['preview-name', 'preview-description', 'preview-type', 'stack-weight']) text($('#' + id), ''); $('#preview-stats').replaceChildren(); $('#preview-tags').replaceChildren(); $('#preview-equipment-effects').replaceChildren(); $('#validation').hidden = true; return; }
    $('#validation').hidden = false;
    if (view === 'inventory') {
      const grid = make('div', 'bag-grid');
      for (let i = 0; i < 12; i++) { const slot = make('div', 'bag-slot' + (i === 5 ? ' selected' : '')); if (i === 5 && item.icon) { slot.append(image(item.icon)); if (item.stackable) slot.append(make('small', '', quantity)); } else if ([0, 3, 8].includes(i)) slot.append(image(FORJA_CATALOG[{ 0: 1, 3: 4, 8: 3 }[i]].icon)); grid.append(slot); } stage.append(grid, make('div', 'bag-caption', 'MOCHILA · VISTA DE UNA RANURA'));
    } else if (view === 'world') {
      const world = item.world || item.icon, area = make('div', 'world-stage'); area.append(make('div', 'iso-grid'));
      if (world) { const sprite = make('div', 'world-sprite'); sprite.style.width = Math.min(220, item.worldWidth) + 'px'; sprite.style.height = Math.min(220, item.worldWidth) * (world.height / item.vframes) / (world.width / item.hframes) + 'px'; sprite.style.maxHeight = '190px'; sprite.style.backgroundImage = 'url(' + world.data + ')'; sprite.style.backgroundSize = item.hframes * 100 + '% ' + item.vframes * 100 + '%'; sprite.style.backgroundRepeat = 'no-repeat'; area.append(sprite); } else area.append(make('span', 'placeholder-art', '◇')); stage.append(area, make('div', 'bag-caption', 'SUELO ISOMÉTRICO · PRIMERA VARIANTE'));
    } else { if (item.illustration || item.icon) stage.append(image(item.illustration || item.icon, 'examine-image')); else stage.append(make('span', 'placeholder-art', '◇')); }
    const heal = F.healing(item.heal);
    text($('#preview-type'), item.kind === 'llave' ? 'LLAVE · ' + (item.lockPattern || 'sin patrón') : item.kind === 'antorcha' ? 'LUZ DE EXPLORACIÓN' : item.impact.type !== 'none' ? 'ARROJABLE · ' + F.SURFACES[item.impact.type][0].toUpperCase() : (item.equipmentEffects.length || F.healing(item.weaponDice)?.dice > 0) ? 'EQUIPO · ' + F.equipment(item).join(' / ').toUpperCase() : heal?.max > 0 ? 'CONSUMIBLE · CURACIÓN' : 'OBJETO DE INVENTARIO');
    text($('#preview-name'), item.name || 'Objeto sin nombre'); text($('#preview-description'), item.description || 'La historia de este objeto todavía no está escrita.');
    const stats = $('#preview-stats'); stats.replaceChildren(make('span', '', format(item.weight) + ' kg / ud.'), make('span', '', item.stackable ? 'Pila de ' + item.maxStack : 'No apilable'));
    if (heal?.max > 0) stats.append(make('span', '', '+' + heal.formula + ' PV al usar' + (heal.dice ? ' · ' + heal.min + '–' + heal.max + ' PV' : '')));
    const weapon = F.healing(item.weaponDice);
    if (weapon?.dice > 0) stats.append(make('span', '', weapon.formula + ' de daño + bono de FUE'));
    const tagArea = $('#preview-tags'); tagArea.replaceChildren(...F.tags(item).map(tag => make('span', '', tag)));
    const effectArea = $('#preview-equipment-effects'); effectArea.replaceChildren(...item.equipmentEffects.map(effect => make('li', '', F.effectDescription(effect))));
    quantity = Math.max(1, Math.min(quantity, item.stackable ? item.maxStack : 1)); $('#preview-quantity').max = item.stackable ? item.maxStack : 1; $('#preview-quantity').value = quantity; $('#preview-quantity').disabled = !item.stackable;
    text($('#stack-value'), quantity + (quantity === 1 ? ' unidad' : ' unidades')); text($('#stack-weight'), format(item.weight * quantity) + ' kg');
    const result = F.validate(item, items), status = $('#validation'); status.classList.toggle('invalid', result.errors.length > 0); status.replaceChildren(make('strong', '', result.errors.length ? 'Revisa antes de exportar' : '✓ Listo para tu mundo'));
    if (result.errors.length) { const list = make('ul'); result.errors.forEach(error => list.append(make('li', '', error))); status.append(list); }
    result.warnings.forEach(warning => status.append(make('div', 'warning', warning)));
  }
  function renderExport() {
    const selectedOnly = $('[name="scope"]:checked').value === 'selected', targets = selectedOnly ? (current() ? [current()] : []) : items;
    const messages = $('#export-messages'), listing = $('#export-files'); messages.replaceChildren(); listing.replaceChildren(); let files = [];
    try {
      // Validar también los IDs del resto de la biblioteca al exportar un único ítem.
      for (const target of targets) { const result = F.validate(target, items); if (result.errors.length) throw new Error(target.name + ': ' + result.errors.join(' ')); result.warnings.forEach(warning => messages.append(make('p', 'notice', warning))); }
      files = F.exportFiles(targets);
      files.forEach(file => { const row = make('div', 'export-file'); row.append(icon('file'), document.createTextNode(file.path)); listing.append(row); });
      text($('#resource-code'), files.find(file => file.path.endsWith('.tres'))?.data || ''); $('#download-zip').disabled = false;
    } catch (error) { messages.append(make('p', 'notice', error.message)); $('#download-zip').disabled = true; text($('#resource-code'), 'Completa los campos señalados para generar los recursos.'); }
    return files;
  }
  function addItem(item) { items.push(item); selected = item.key; quantity = 1; $('#search').value = ''; renderForm(); changed(); $('#template-dialog').close(); setTab('details'); }
  function setTab(tab) { $$('[data-tab]').forEach(button => { const active = button.dataset.tab === tab; button.classList.toggle('active', active); button.setAttribute('aria-selected', active); }); $$('[data-panel]').forEach(panel => panel.hidden = panel.dataset.panel !== tab); }
  $('#item-form').addEventListener('submit', event => event.preventDefault());
  $('#item-form').addEventListener('input', event => {
    const field = event.target, item = current(); if (!field.dataset.field || !item) return;
    const previousName = item.name; write(item, field.dataset.field, field.type === 'checkbox' ? field.checked : field.hasAttribute('data-number') ? Number(field.value) : field.value);
    if (field.dataset.field === 'name') { if (!item.id || (!item.source && item.id === F.slug(previousName))) { item.id = F.slug(item.name); $('#item-id').value = item.id; } text($('#editor-title'), item.name || 'Un objeto por descubrir'); }
    if (field.dataset.field === 'stackable') { item.maxStack = item.stackable ? Math.max(2, item.maxStack) : 1; $('#max-stack').value = item.maxStack; }
    if (field.dataset.field === 'updateExisting') { item.id = item.updateExisting ? item.source.id : uniqueId(item.source.id + '_nuevo'); $('#item-id').value = item.id; }
    changed();
  });
  $('#tags').addEventListener('input', () => { const item = current(); if (item) { item.tags = [...new Set($('#tags').value.split(',').map(t => t.trim()).filter(Boolean))]; renderTags(); changed(); } });
  $$('[data-tab]').forEach(button => button.addEventListener('click', () => setTab(button.dataset.tab)));
  $$('[data-view]').forEach(button => button.addEventListener('click', () => { view = button.dataset.view; $$('[data-view]').forEach(other => other.classList.toggle('active', other === button)); renderPreview(); }));
  $$('[data-effect]').forEach(button => button.addEventListener('click', () => { const item = current(); if (!item) return; const next = button.dataset.effect; item.impact.type = next; if (next !== 'none') { item.impact.duration = next === 'fuego' ? 7 : 10; item.impact.ticks = next === 'veneno' ? 2 : 3; } renderFormNumbers(); changed(); }));
  $('#search').addEventListener('input', renderLibrary);
  $('#preview-quantity').addEventListener('input', () => { quantity = Number($('#preview-quantity').value); renderPreview(); });
  $('#add-magnitude').addEventListener('click', () => { const item = current(); let key = 'temperatura', i = 2; while (Object.hasOwn(item.magnitudes, key)) key = 'magnitud_' + i++; item.magnitudes[key] = 0; renderMagnitudes(); changed(); });
  $('#add-equipment-effect').addEventListener('click', () => { const item = current(); if (!item || item.equipmentEffects.length >= 16) return; item.equipmentEffects.push(F.effectDefault()); renderEquipmentEffects(); changed(); });
  $('#duplicate').addEventListener('click', () => { const item = F.clone(current()); item.key = F.uid(); item.id = uniqueId(item.id + '_copia'); item.name += ' · copia'; item.updateExisting = false; addItem(F.createItem(item)); toast('Copia creada con un ID diferente.'); });
  $('#delete').addEventListener('click', () => $('#delete-dialog').showModal());
  $('#confirm-delete').addEventListener('click', () => { items = items.filter(item => item.key !== selected); selected = items[0]?.key || ''; $('#delete-dialog').close(); renderForm(); changed(); });
  for (const button of $$('.close-dialog')) button.addEventListener('click', () => button.closest('dialog').close());
  const templates = $('#template-list');
  FORJA_CATALOG.forEach(seed => { const button = make('button', 'template-option'); const labels = make('span'); labels.append(make('b', '', seed.name), make('small', '', seed.kind === 'llave' ? 'Cerraduras por patrón' : seed.kind === 'antorcha' ? 'Luz y duración en pasos' : seed.id === 'racion' ? 'Curación y consumo' : seed.id === 'piedra' ? 'Peso, apilado y lanzamiento' : 'Superficie al impactar')); button.append(image(seed.icon), labels); button.addEventListener('click', () => addItem(fromTemplate(seed))); templates.append(button); });
  $('#new-item').addEventListener('click', () => $('#template-dialog').showModal()); $('#templates').addEventListener('click', () => $('#template-dialog').showModal());
  $('#blank-item').addEventListener('click', () => addItem(F.createItem()));
  $('#backup').addEventListener('click', backup);
  const exportOpen = code => { renderExport(); $('#code-details').open = code; $('#export-dialog').showModal(); };
  $('#open-export').addEventListener('click', () => exportOpen(false)); $('#preview-code').addEventListener('click', () => exportOpen(true));
  $$('[name="scope"]').forEach(radio => radio.addEventListener('change', renderExport));
  $('#download-zip').addEventListener('click', () => { try { const files = renderExport(); if ($('#download-zip').disabled) return; const name = $('[name="scope"]:checked').value === 'all' ? 'biblioteca_exhume' : current().id; download(name + '_godot.zip', F.zip(files), 'application/zip'); toast('Paquete descargado. El ZIP incluye instrucciones de integración.'); } catch (error) { toast(error.message, true); } });
  $('#import-project').addEventListener('click', () => $('#project-file').click());
  $('#project-file').addEventListener('change', async () => { try { const file = $('#project-file').files[0]; if (!file) return; if (file.size > 50 * 1024 * 1024) throw new Error('El proyecto debe pesar menos de 50 MB.'); imported = F.parseProject(JSON.parse(await file.text())).items; text($('#import-info'), 'El archivo contiene ' + imported.length + ' ítems con sus imágenes. ¿Cómo quieres incorporarlos?'); $('#import-dialog').showModal(); } catch (error) { toast('No se importó ningún cambio: ' + error.message, true); } finally { $('#project-file').value = ''; } });
  function importItems(replace) {
    if (!imported) return;
    if (replace) { if (items.length) backup(); items = imported; }
    else { for (const item of imported) { item.id = uniqueId(item.id || 'importado'); if (item.updateExisting && item.source?.id !== item.id) item.updateExisting = false; items.push(item); } }
    selected = (replace ? items[0] : imported[0])?.key || items[0]?.key || ''; imported = null; $('#import-dialog').close(); $('#search').value = ''; renderForm(); changed(); toast('Proyecto incorporado. Las imágenes y los efectos se conservan.');
  }
  $('#merge-import').addEventListener('click', () => importItems(false)); $('#replace-import').addEventListener('click', () => importItems(true));
  document.addEventListener('visibilitychange', () => { if (document.visibilityState === 'hidden') persistNow(); });
  window.addEventListener('pagehide', persistNow);
  async function start() {
    try { database = await openStorage(); database.onversionchange = () => database.close(); const saved = await storageRead(); if (saved?.version === F.VERSION && Array.isArray(saved.items)) { items = saved.items.map(item => F.createItem(item)); selected = saved.selected; } else { const example = fromTemplate(FORJA_CATALOG[0], true); items = [example]; selected = example.key; } }
    catch (_) { const example = fromTemplate(FORJA_CATALOG[0], true); items = [example]; selected = example.key; $('#save-state').classList.add('error'); toast('El almacenamiento local no está disponible. Puedes trabajar y descargar copias de seguridad.', true); }
    if (!current()) selected = items[0]?.key || '';
    renderForm(); renderLibrary(); renderPreview(); if (database) await persistNow(); else text($('#save-state'), 'Sin guardado local · descarga copia'); document.body.dataset.ready = 'true';
  }
  start().catch(error => { toast('No se pudo abrir el taller: ' + error.message, true); });
})();
