# Host PS4 13.52 — lanzador de GoldHEN

Host web (una página que se abre **en el navegador de la PS4**) que ejecuta el
exploit y lanza **GoldHEN oficial v2.4b18.13** en consolas con firmware
**13.52** (y también 13.02, 13.04 y 13.50).

Está basado en el proyecto [raw13g/raw13g.github.io](https://github.com/raw13g/raw13g.github.io)
(“RAW GAME”). La lógica del exploit y los offsets son los originales; se ha
cambiado la presentación (HTML, CSS, textos en español, logo y nombre) y se ha
actualizado el payload al **GoldHEN oficial v2.4b18.13**.

> ⚠️ **Úsalo bajo tu propia responsabilidad.** Es un jailbreak: puede provocar
> cuelgues o *kernel panic* (la consola se apaga o se reinicia). No actualices la
> consola. El jailbreak **no es permanente**: se pierde al apagar la PS4.

🌐 **Ya está publicado:** <https://toniigibertt.github.io/host-ps4-1352/>
— abre esa URL en el navegador de la PS4.

---

## Qué hace exactamente

1. `index.html` lee el firmware desde el *User-Agent* de la PS4.
2. Redirige a `jb.html`, que carga `jb.js`.
3. `jb.js` explota un fallo de WebKit (bug 663) y obtiene lectura/escritura de
   memoria del kernel.
4. Aplica el parche de kernel correspondiente (`patches/1352.bin` en 13.52).
5. Copia el payload (`goldhen.bin`, GoldHEN oficial v2.4b18.13) en memoria y lo
   ejecuta con `pthread_create`.
6. Si todo va bien, aparece **LISTO**: GoldHEN queda activo hasta que apagues
   la consola. Tendrás su menú en **Ajustes**, FTP en el puerto **2121** y
   PayLoader en el **9090**.

No instala nada permanente, no modifica el firmware en disco y no hace falta
un USB. Solo hay que abrir la página en el navegador de la PS4.

---

## Archivos

| Archivo | Para qué sirve |
|---|---|
| `index.html` | Pantalla inicial: detecta el firmware y lanza todo |
| `jb.html` | Pantalla de ejecución (logo, spinner, mensajes) |
| `jb.js` | Exploit + parche de kernel + carga del payload |
| `core.js`, `mem.js`, `int64.js` | Primitivas de memoria del exploit |
| `ps4_offsets.js` | Tabla de offsets por firmware |
| `rpc_worker.js` | Worker auxiliar del exploit |
| `goldhen.bin` | GoldHEN oficial v2.4b18.13 (se usa en 13.52) |
| `payload2.bin` | GoldHEN oficial v2.4b18.13 (13.50 / 13.02 / 13.04) |
| `patches/1352.bin` | Parche de kernel de 13.52 |
| `patches/1350.bin`, `patches/1302.bin` | Parches de otros firmwares |
| `cache.appcache` | Caché offline (la PS4 guarda la página) |
| `INICIAR-LOCAL.ps1` | Servidor local para probar desde el PC |

---

## Cómo publicarlo

### Opción A — GitHub Pages (recomendada)

1. Crea un repositorio **público**, por ejemplo `goldhen-1352`.
2. Sube **todos** los archivos y la carpeta `patches` (manteniendo la estructura).
3. En el repo: **Settings → Pages → Build and deployment**:
   * Source: *Deploy from a branch*
   * Branch: `main` y carpeta `/ (root)`
4. Espera un minuto. Tu URL será:
   `https://TU-USUARIO.github.io/goldhen-1352/`

GitHub Pages sirve los `.bin` como descarga, pero `fetch()` los lee igual, así
que funciona.

### Opción B — Netlify Drop

1. Entra en <https://app.netlify.com/drop>.
2. Arrastra la carpeta `goldhen-host-1352` completa.
3. Te da una URL `https://algo.netlify.app` lista para usar.

### Opción C — Servidor local en tu red (sin subirlo a internet)

1. En el PC, clic derecho en `INICIAR-LOCAL.ps1` → **Ejecutar con PowerShell**.
   (Si Windows lo bloquea: `powershell -ExecutionPolicy Bypass -File .\INICIAR-LOCAL.ps1`)
2. El script muestra tu IP local, por ejemplo `http://192.168.1.50:8080/`.
3. Abre esa URL en el navegador de la PS4 (misma red Wi-Fi/LAN).
4. Si no carga, permite el puerto 8080 en el Firewall de Windows.

---

## Cómo usarlo en la PS4

1. Enciende la PS4 y **cierra cualquier juego** que esté abierto.
2. Abre el **navegador** de la PS4.
3. Entra a la URL del host.
4. La primera vez verás “Guardando en caché…”. Cuando termine, **toca la
   pantalla** (o pulsa X) para ejecutar.
5. Aparece el logo con el spinner. **No toques nada** durante 1–2 minutos.
6. Resultado:
   * **LISTO** → el HEN está cargado. Ya puedes abrir homebrew.
   * **Reinicia la consola** → el exploit falló. Reinicia la PS4 y vuelve a
     intentarlo (es normal que falle algunas veces).
   * Si se queda colgada o se apaga sola → *kernel panic*; reinicia y reintenta.

Consejos:

* Tras la primera carga, la página queda en caché: puedes volver a entrar sin
  internet usando **la misma URL**.
* No encadenes intentos sin reiniciar después de un fallo.
* Si quieres ver el registro técnico completo, abre `jb.html?log=1` (o añade
  `?log=1` a la URL). Es útil para diagnosticar. Ese registro interno está en
  inglés a propósito: son los mensajes del exploit original y así se pueden
  buscar soluciones en la escena.

---

## Personalizarlo

Todo lo visual está en `index.html` y `jb.html`:

* **Nombre del host**: busca `Host PS4` y cámbialo por el tuyo (aparece en
  `title`, en la cabecera y en el logo textual). Cámbialo en **los dos** HTML.
* **Colores**: al principio de cada HTML, en `:root`, cambia `--gold`,
  `--gold-2`, `--bg`, etc.
* **Logo**: es un SVG en línea (el rayo). Puedes cambiar el `<path>` o sustituir
  el bloque `<svg class="logo">` por `<img src="mi-logo.png">`. Si añades una
  imagen nueva, agrégala también a `cache.appcache`.
* **Textos**: los mensajes de la pantalla de ejecución están en `jb.js`, en la
  función `finishUI` (`LISTO`, `Reinicia la consola`, etc.).
* **Pie de página / avisos**: en `index.html`.

**No cambies** los nombres de archivo, las rutas (`patches/…`, `goldhen.bin`) ni
la lógica de `jb.js`, `core.js`, `mem.js`, `ps4_offsets.js` o los `.bin`: un
error ahí puede provocar un *kernel panic*.

### Cambiar el payload

`goldhen.bin` y `payload2.bin` son **el mismo GoldHEN oficial v2.4b18.13**
(297.496 bytes, empieza por `0xE9`). Esa versión soporta oficialmente 13.00,
13.02, 13.04, 13.50, 13.52 y 14.00, así que sirve para todos los firmwares de
este host.

Si en el futuro quieres actualizarlo:

1. Descarga el `goldhen.bin` oficial nuevo.
2. Comprueba que empieza por el byte `0xE9` (el loader del host lo exige).
3. Sustituye `goldhen.bin` y `payload2.bin` por ese archivo.
4. Actualiza los hashes y el `# rev` de `cache.appcache`.
5. Comprueba en el `CHANGELOG` del release que soporta tu firmware exacto.

No cambies el parche de kernel (`patches/1352.bin`): es independiente de
GoldHEN y lo necesita el exploit.

---

## Problemas frecuentes

| Síntoma | Qué hacer |
|---|---|
| “Firmware no compatible” | Tu firmware no está en la tabla. Puedes tocar la pantalla para forzarlo, pero lo normal es que falle. Comprueba la versión en Ajustes. |
| Se queda en “Comprobando caché” | Sal del navegador y vuelve a entrar, o prueba `?force=1`. |
| Falla siempre en el mismo punto | Reinicia la PS4 entre intentos. Los exploits de kernel no son 100 % estables. |
| No veo los cambios que subí | Sube el número de `# rev` en `cache.appcache`. La PS4 guarda la copia antigua; también puedes borrar los datos del navegador de la PS4. |
| La consola se apaga al cargar | *Kernel panic*. Reinicia y reintenta. No sigas intentando sin reiniciar. |

---

## Créditos y licencia

* Base, exploit y payloads: [raw13g/raw13g.github.io](https://github.com/raw13g/raw13g.github.io)
  (licencia MIT para su código; ver `LICENSE`).
* El exploit parte del trabajo de **thebelx** y de otros autores de la escena
  PS4 (ver el issue #1 del repositorio original).
* GoldHEN oficial v2.4b18.13: **SiSTRo** y colaboradores.
* `core.js`, `mem.js`, `int64.js`, los payloads `.bin` y los parches de kernel
  conservan las licencias de sus autores originales.

Este proyecto es una **modificación de la presentación** del host original, sin
cambios en el exploit. No está afiliado a Sony, a SiSTRo ni al autor original.
