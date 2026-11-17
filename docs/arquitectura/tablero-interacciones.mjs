// Geometría de las maquetas de referencia. Las unidades del dibujo no son píxeles de Godot.
export function crearTableros(k) {
  const width = 550;
  const height = 340;
  const deck = { x: -88, y: -88, w: 176, d: 176, r: 4 };
  const p = k.fitProjection(
    [...k.boxCorners(deck, -9, 0), ...k.boxCorners({ x: -83, y: -35, w: 166, d: 21 }, 0, 71)],
    width, height, { pad: 24, azimuth: 51, elevation: 35 },
  );
  const group = (clase, content) => `<g class="${clase}">${content}</g>`;
  const block = (x, y, z, w, d, h, tone = "mid", bevel = 0.48) =>
    k.solidSvg(k.slabOf({ x, y, w, d, r: 0.9 }, z, h, p, 3, bevel), { tone });
  const cylinder = (x, y, z, r, h, tone = "mid") =>
    k.solidSvg(k.cylinder(x, y, r, z, h, p, 16), { tone });
  const path = (points, clase) => `<path class="${clase}" d="${k.pathOf(points.map(point => k.iso(point, p)), true)}"/>`;
  const cell = (x, y, clase) => path(
    [[x - 12, y - 12, 0], [x + 12, y - 12, 0], [x + 12, y + 12, 0], [x - 12, y + 12, 0]], clase,
  );
  const floor = [`<path class="iso-halo" d="${k.haloOf(deck, -9, 9, p)}"/>`, block(-88, -88, -9, 176, 176, 7)];
  for (let y = -75; y <= 75; y += 25) {
    for (let x = -75; x <= 75; x += 25) {
      const shade = (x / 25 - y / 25 + 6) % 4 === 0 ? " stone-light" : "";
      floor.push(group("floor-tile" + shade, block(x - 12.3, y - 12.3, -2, 24.6, 24.6, 2, "lo", 0.28)));
    }
  }
  const base = floor.join("");

  function portal(x, y, mechanical = false) {
    const stones = [];
    for (const dx of [-30, 21]) {
      stones.push(block(x + dx - 2, y - 9, 0, 13, 19, 4));
      for (let course = 0; course < 6; course++) {
        stones.push(block(x + dx, y - 7, 4 + course * 9, 9, 15, 8.8));
      }
      stones.push(block(x + dx - 1, y - 8, 58, 11, 17, 3));
    }
    for (let stone = 0; stone < 7; stone++) {
      stones.push(block(x - 32 + stone * 9.2, y - 9, 61, 9, 19, 7));
    }
    stones.push(block(x - 33, y - 10, 68, 66, 21, 3));
    const hardware = mechanical ? " gate-mechanical" : "";
    return `<g class="portal${hardware}">${stones.join("")}
      <g class="leaf" data-x="${x}" data-y="${y}" data-hardware="${mechanical ? "gate" : "lock"}">
        ${drawLeaf(k, p, x, y, 0, 0, mechanical)}
      </g></g>`;
  }

  function lever() {
    const y = 50;
    const base = block(-11, y - 8, 0, 22, 16, 3) + block(-7, y - 5, 3, 14, 10, 4);
    const guide = block(-6, y - 4, 7, 4, 8, 3) + block(2, y - 4, 7, 4, 8, 3);
    const [px, py] = k.iso([0, y, 8], p);
    const stem = `<g class="lever-handle" style="transform-origin:${px}px ${py}px">
      ${block(-1.4, y - 1.4, 7, 2.8, 2.8, 18, "hi")}
      ${group("brass", block(-3.2, y - 3.2, 24, 6.4, 6.4, 5, "hi", 0.8))}
    </g>`;
    const screws = k.dotsSvg([[-8, y - 5, 3], [8, y - 5, 3], [-8, y + 5, 3], [8, y + 5, 3]].map(v => k.iso(v, p)), { size: 1.2 });
    return group("lever", base + group("iron", guide + stem) + screws);
  }

  function actor(x, y) {
    return group("actor",
      group("poison-mark", cylinder(x, y, 0, 11, 0.6)) +
      group("piece",
        cylinder(x, y, 0.6, 8, 2.4) + cylinder(x, y, 3, 6.1, 2) +
        block(x - 4, y - 2.5, 5, 8, 5, 8, "hi", 0.65) +
        block(x - 3.5, y - 3, 13, 7, 6, 4, "hi", 0.8) +
        group("iron", block(x - 2, y + 3, 13.8, 4, 0.6, 1.3, "mid"))),
    );
  }

  function key(clase, tooth) {
    const [x, y] = [-27, 24];
    const bore = k.dotsSvg([k.iso([x, y, 1.6], p)], { size: 2.4, tone: "hi" });
    return group("brass key " + clase,
      cylinder(x, y, 0.1, 4.8, 1.4) + bore + block(x + 4, y - 1.1, 0.1, 14, 2.2, 1.4) +
      block(x + tooth, y + 1.1, 0.1, 2.7, 4.2, 1.4) + block(x + 15, y + 1.1, 0.1, 2.7, 2.8, 1.4),
    );
  }

  const plate = group("plate",
    block(-10.6, -10.6, 0, 21.2, 21.2, 1.4) +
    group("plate-top",
      block(-8.4, -8.4, 1.4, 16.8, 16.8, 1.7) +
      k.dotsSvg([[-6, -6, 3.1], [-6, 6, 3.1], [6, -6, 3.1], [6, 6, 3.1]].map(v => k.iso(v, p)), { size: 1.2 })),
  );
  const footprint = [[0, 0], [-25, 0], [25, 0], [0, -25], [0, 25]];
  const cloud = group("cloud", footprint.map(([x, y], i) => {
    const [cx, cy] = k.iso([x, y, 8 + i % 2 * 3], p);
    return `<ellipse cx="${cx}" cy="${cy}" rx="27" ry="13" fill="url(#humo-gradiente)"/>`;
  }).join(""));
  const wrap = (label, body) => k.figureSvg({ width, height, label, body: base + body });

  return {
    projection: p,
    stepDelta: k.iso([0, -25, 0], p).map((value, i) => value - p.origin[i]),
    scenes: {
      puerta: wrap("Puerta con cerrojo sobre un tablero de casillas",
        group("view-cells", [-50, -25].map(y => cell(0, y, "highlight")).join("")) +
        group("route-cells", [-50, -25, 0, 25, 50].map(y => cell(0, y, "highlight")).join("")) +
        cell(0, 0, "highlight target-door") + portal(0, 0) +
        key("matching", 11) + key("mismatched", 7) + actor(0, 25)),
      palanca: wrap("Palanca y dos posiciones para puertas receptoras",
        cell(0, 50, "highlight target-lever") +
        cell(-50, -25, "highlight receiver receiver-a") + cell(50, -25, "highlight receiver receiver-b") +
        group("route-cells", [-50, 50].map(x => [-50, -25, 0].map(y => cell(x, y, "highlight")).join("")).join("")) +
        portal(-50, -25, true) + group("receiver-portal-b", portal(50, -25, true)) + lever() + actor(0, 75)),
      trampa: wrap("Ficha, placa de presión y casillas que puede cubrir el humo",
        '<defs><radialGradient id="humo-gradiente"><stop stop-color="#9562b0" stop-opacity=".58"/><stop offset="1" stop-color="#b788ca" stop-opacity="0"/></radialGradient></defs>' +
        group("smoke-cells", footprint.map(([x, y]) => cell(x, y, "highlight")).join("")) +
        cell(0, 0, "highlight target-plate") + plate + actor(0, 25) + cloud),
    },
  };
}

export function drawLeaf(k, p, x, y, angle, extension, mechanical) {
  const c = Math.cos(angle);
  const s = Math.sin(angle);
  const world = (u, v) => [x - 20 + u * c - v * s, y + 9 + u * s + v * c];
  const plank = (u, v, z, w, d, h, tone = "mid") => {
    const plan = [[u, v], [u + w, v], [u + w, v + d], [u, v + d]];
    return k.solidSvg(k.extrude(plan.map(([a, b]) => world(a, b)), z, h, p), { tone });
  };
  const front = angle < p.azimuth * Math.PI / 180;
  const side = front ? 0 : -4.6;
  const parts = [plank(0.6, -4, 1.5, 39, 4, 57, "hi")];
  for (let i = 0; i < 7; i++) {
    parts.push(plank(0.9 + i * 5.52, side, 2, 5.35, 0.6, 56));
  }
  for (const z of [11, 46]) {
    const strap = front ? 0.6 : -5.8;
    const rivets = [3, 8, 17, 26, 33].map(u => k.iso([...world(u, front ? 1.8 : -5.8), z + 2.2], p));
    parts.push(`<g class="iron">${plank(0, strap, z, 35, 1.2, 4.4)}${k.dotsSvg(rivets, { size: 1.15, tone: "hi" })}</g>`);
  }
  if (front && !mechanical) {
    const keyhole = k.dotsSvg([k.iso([...world(32, 2), 29], p)], { size: 1.7, tone: "hi" });
    parts.push(`<g class="iron lock">${plank(28, 0.6, 22, 11, 1.4, 13)}${keyhole}</g>`);
  }
  if (extension > 0.02) {
    parts.push(`<g class="brass bolt">${plank(39.5, -3.8, 26, extension, 3.6, 4, "hi")}</g>`);
  }
  return parts.join("");
}
