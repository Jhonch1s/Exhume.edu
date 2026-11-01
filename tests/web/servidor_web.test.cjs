const { test } = require('node:test');
const assert = require('node:assert/strict');
const { spawn } = require('node:child_process');
const { once } = require('node:events');
const path = require('node:path');

test('sirve la exportación con aislamiento y limita el acceso a build/web', { timeout: 15000 }, async () => {
  const servidor = spawn(process.execPath, [path.resolve(__dirname, '../../tools/servir_web.cjs'), '0']);
  try {
    const [salida] = await once(servidor.stdout, 'data');
    const base = salida.toString().match(/http:\/\/localhost:\d+/)?.[0];
    assert.ok(base, 'el servidor debe anunciar su dirección');
    const pagina = await fetch(base);
    assert.equal(pagina.status, 200);
    assert.match(pagina.headers.get('content-type'), /text\/html/);
    assert.equal(pagina.headers.get('cross-origin-opener-policy'), 'same-origin');
    assert.equal(pagina.headers.get('cross-origin-embedder-policy'), 'require-corp');
    assert.match(await pagina.text(), /<canvas/);
    const wasm = await fetch(`${base}/index.wasm`, { method: 'HEAD' });
    assert.equal(wasm.status, 200);
    assert.equal(wasm.headers.get('content-type'), 'application/wasm');
    assert.ok(Number(wasm.headers.get('content-length')) > 0);
    assert.equal((await fetch(`${base}/index.html?v=1`)).status, 200);
    assert.equal((await fetch(`${base}/%2e%2e%2fproject.godot`)).status, 404);
    assert.equal((await fetch(`${base}/inexistente`)).status, 404);
    assert.equal((await fetch(`${base}/%ZZ`)).status, 400);
    assert.equal((await fetch(base, { method: 'POST' })).status, 405);
  } finally {
    servidor.kill();
    await once(servidor, 'exit');
  }
});
