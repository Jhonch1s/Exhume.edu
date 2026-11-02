const http = require('node:http');
const fs = require('node:fs');
const path = require('node:path');

const carpeta = path.resolve(__dirname, '../build/web');
const puerto = Number(process.argv[2] ?? 8060);
const tipos = {
  '.html': 'text/html; charset=utf-8',
  '.js': 'text/javascript; charset=utf-8',
  '.wasm': 'application/wasm',
  '.png': 'image/png',
};

if (!fs.existsSync(path.join(carpeta, 'index.html'))) {
  console.error('Primero exportá el preset Web a build/web/index.html.');
  process.exit(1);
}

http.createServer((peticion, respuesta) => {
  respuesta.setHeader('Cross-Origin-Opener-Policy', 'same-origin');
  respuesta.setHeader('Cross-Origin-Embedder-Policy', 'require-corp');
  respuesta.setHeader('Cache-Control', 'no-store');
  if (!['GET', 'HEAD'].includes(peticion.method)) {
    respuesta.writeHead(405, { Allow: 'GET, HEAD' }).end();
    return;
  }
  let nombre;
  try {
    nombre = decodeURIComponent(peticion.url.split('?')[0]);
  } catch {
    respuesta.writeHead(400).end();
    return;
  }
  nombre = nombre === '/' ? 'index.html' : nombre.slice(1);
  // La exportación de Godot es plana; sólo servimos archivos de build/web.
  if (!/^[a-zA-Z0-9_.-]+$/.test(nombre)) {
    respuesta.writeHead(404).end();
    return;
  }
  const archivo = path.join(carpeta, nombre);
  fs.stat(archivo, (error, estado) => {
    if (error || !estado.isFile()) {
      respuesta.writeHead(404).end();
      return;
    }
    respuesta.writeHead(200, {
      'Content-Type': tipos[path.extname(nombre)] ?? 'application/octet-stream',
      'Content-Length': estado.size,
    });
    if (peticion.method === 'HEAD') respuesta.end();
    else fs.createReadStream(archivo).on('error', () => respuesta.destroy()).pipe(respuesta);
  });
}).on('error', (error) => {
  console.error(error.message);
  process.exitCode = 1;
}).listen(puerto, '127.0.0.1', function () {
  console.log(`Exhume web: http://localhost:${this.address().port}`);
});
