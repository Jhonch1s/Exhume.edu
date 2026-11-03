# Exportar Exhume para navegador en PC

Requisitos: Godot 4.7, sus plantillas de exportación instaladas y Node.js para el servidor local.

Desde Godot: **Proyecto → Exportar → Web → Exportar proyecto**, con salida `build/web/index.html`.
Crear primero la carpeta `build/web` si aún no existe. Para una versión final, desmarcar **Exportar con depuración**.

También se puede exportar desde PowerShell, situado en la raíz del proyecto:

```powershell
New-Item -ItemType Directory -Path build/web -Force | Out-Null
& C:\godot\Godot_v4.7-stable_win64_console.exe --headless --path . --export-release Web build/web/index.html
node tools/servir_web.cjs
```

Abrir **http://localhost:8060** en el navegador. Detener el servidor con **Ctrl+C**.
Para otro puerto: `node tools/servir_web.cjs 8061`.
No abrir el HTML con doble clic: necesita un servidor HTTP.
La carpeta `build` está ignorada en Git; conservar todos los archivos generados juntos.

El preset usa Compatibility, un solo hilo y soporte de extensiones para LimboAI,
que selecciona las acciones de los NPC. La versión web inicia en el menú principal
mediante `application/run/main_scene.web`. El servidor incluye las cabeceras COOP/COEP
necesarias para cargar esa extensión. Al alojarlo en otro servidor, usar HTTPS y:

```text
Cross-Origin-Opener-Policy: same-origin
Cross-Origin-Embedder-Policy: require-corp
```

El navegador necesita WebGL 2 y WebAssembly. El audio puede requerir un primer clic;
la pantalla completa debe activarse mediante una acción del usuario.
Las partidas web se guardan en el almacenamiento del navegador, separado del juego
de escritorio. Mantener el mismo navegador y dirección (incluido el puerto) para
conservar el acceso; borrar los datos del sitio elimina las partidas web.

Comprobar después de exportar: menú, creación de personaje, entrada a la prisión,
movimiento, interacción, turnos de NPC, audio y guardado/carga tras recargar la página.
La prueba del servidor se ejecuta con `node --test tests/web/servidor_web.test.cjs`;
requiere la exportación en `build/web`.

Verificación inicial (1 de noviembre de 2026): exportación release sin errores;
prueba HTTP del servidor y prueba de IDs correctas; `prueba_inicio_prision.gd`
correcta, incluyendo guardado/carga (con avisos de recursos pendientes al cerrar
el motor headless). En navegador se verificaron menú, pantalla de creación,
tiradas y sorteo de origen sin errores en consola. Quedan por comprobar una partida
completa, el audio y la persistencia web tras recargar. La carpeta exportada ocupa
aproximadamente 289 MB; aún no se optimizó el peso de los recursos.

Referencia: [Exportar para la web, documentación de Godot](https://docs.godotengine.org/en/stable/tutorials/export/exporting_for_web.html).
