// Generates a 1024x1024 PNG source for `tauri icon` — no external deps.
// DoomForge mark: a horned demon skull in ember on a dark rounded badge,
// matching public/favicon.svg and the in-app BrandMark.
const zlib = require("zlib");
const fs = require("fs");
const path = require("path");

const S = 1024;

function crc32(buf) {
  let c = ~0;
  for (let i = 0; i < buf.length; i++) {
    c ^= buf[i];
    for (let k = 0; k < 8; k++) c = (c >>> 1) ^ (0xedb88320 & -(c & 1));
  }
  return ~c >>> 0;
}

function chunk(type, data) {
  const len = Buffer.alloc(4);
  len.writeUInt32BE(data.length, 0);
  const t = Buffer.from(type, "ascii");
  const crc = Buffer.alloc(4);
  crc.writeUInt32BE(crc32(Buffer.concat([t, data])), 0);
  return Buffer.concat([len, t, data, crc]);
}

// ---- geometry helpers ----
function ell(x, y, cx, cy, rx, ry) {
  const dx = (x - cx) / rx, dy = (y - cy) / ry;
  return dx * dx + dy * dy <= 1;
}
function tri(px, py, ax, ay, bx, by, cx, cy) {
  const s = (ax - cx) * (py - cy) - (ay - cy) * (px - cx);
  const t = (bx - ax) * (py - ay) - (by - ay) * (px - ax);
  if ((s < 0) !== (t < 0) && s !== 0 && t !== 0) return false;
  const d = (cx - bx) * (py - by) - (cy - by) * (px - bx);
  return d === 0 || (d < 0) === (s + t <= 0);
}
function poly(px, py, pts) {
  let inside = false;
  for (let i = 0, j = pts.length - 1; i < pts.length; j = i++) {
    const xi = pts[i][0], yi = pts[i][1], xj = pts[j][0], yj = pts[j][1];
    if (((yi > py) !== (yj > py)) && px < ((xj - xi) * (py - yi)) / (yj - yi) + xi)
      inside = !inside;
  }
  return inside;
}
// Stamp a tapered horn as disks along a quadratic Bezier; return true if (x,y)
// is within the swept thickness.
function horn(x, y, p0, p1, p2, r0, r1) {
  for (let i = 0; i <= 40; i++) {
    const t = i / 40;
    const mt = 1 - t;
    const bx = mt * mt * p0[0] + 2 * mt * t * p1[0] + t * t * p2[0];
    const by = mt * mt * p0[1] + 2 * mt * t * p1[1] + t * t * p2[1];
    const r = r0 + (r1 - r0) * t;
    if ((x - bx) ** 2 + (y - by) ** 2 <= r * r) return true;
  }
  return false;
}

const cx = S / 2;
// Skull silhouette polygon (cheeks taper toward the jaw).
const cheeks = [
  [cx - 235, 480], [cx + 235, 480], [cx + 132, 772], [cx - 132, 772],
];
// Knockout shapes (cut to background): slanted eyes + nose.
const eyeL = [[388, 452], [505, 505], [392, 540]];
const eyeR = [[2 * cx - 388, 452], [2 * cx - 505, 505], [2 * cx - 392, 540]];
const nose = [[cx - 26, 560], [cx + 26, 560], [cx, 620]];

const px = Buffer.alloc(S * S * 4);
for (let y = 0; y < S; y++) {
  for (let x = 0; x < S; x++) {
    const i = (y * S + x) * 4;

    // Rounded-rect badge background.
    const m = 70, r = 175;
    let inBg = x >= m && x <= S - m && y >= m && y <= S - m;
    if (inBg) {
      const corners = [[m + r, m + r], [S - m - r, m + r], [m + r, S - m - r], [S - m - r, S - m - r]];
      for (const [ccx, ccy] of corners) {
        // Only round the corner the pixel actually sits in (within its r-box).
        if (Math.abs(x - ccx) < r && Math.abs(y - ccy) < r &&
          (x < m + r || x > S - m - r) && (y < m + r || y > S - m - r) &&
          Math.hypot(x - ccx, y - ccy) > r) inBg = false;
      }
    }

    let R = 0, G = 0, B = 0, A = 0;
    if (inBg) {
      // dark base with a faint ember glow toward the centre
      const g = Math.max(0, 1 - Math.hypot(x - cx, y - S * 0.5) / 620);
      R = Math.round(20 + 26 * g);
      G = Math.round(17 + 12 * g);
      B = Math.round(15 + 8 * g);
      A = 255;
    }

    // Skull silhouette: cranium + cheeks + jaw + horns.
    const skull =
      ell(x, y, cx, 480, 235, 220) ||
      poly(x, y, cheeks) ||
      ell(x, y, cx, 760, 132, 78) ||
      horn(x, y, [cx - 150, 360], [cx - 360, 250], [cx - 330, 120], 58, 10) ||
      horn(x, y, [cx + 150, 360], [cx + 360, 250], [cx + 330, 120], 58, 10);

    if (inBg && skull) {
      // ember gradient, brighter at the top
      const t = Math.min(1, Math.max(0, (y - 200) / 620));
      R = Math.round(240 + (226 - 240) * t);
      G = Math.round(162 + (96 - 162) * t);
      B = Math.round(58 + (58 - 58) * t);
      A = 255;

      // Knock eyes / nose back to the dark base.
      const eye = poly(x, y, eyeL) || poly(x, y, eyeR);
      const sniff = poly(x, y, nose);
      // Teeth: a dark mouth band with ember vertical teeth.
      const inMouth = y >= 650 && y <= 720 && x >= cx - 150 && x <= cx + 150;
      const isTooth = inMouth && ((x - (cx - 150)) % 50) < 32 && y <= 705;
      if ((eye || sniff || (inMouth && !isTooth))) {
        R = 22; G = 18; B = 15;
        // a faint inner glow at the eye cores
        if (eye && (x - 448) ** 2 + (y - 498) ** 2 < 900) { R = 255; G = 232; B = 180; }
        if (eye && (x - (2 * cx - 448)) ** 2 + (y - 498) ** 2 < 900) { R = 255; G = 232; B = 180; }
      }
    }

    px[i] = R; px[i + 1] = G; px[i + 2] = B; px[i + 3] = A;
  }
}

// Add filter byte (0) per scanline.
const raw = Buffer.alloc(S * (S * 4 + 1));
for (let y = 0; y < S; y++) {
  raw[y * (S * 4 + 1)] = 0;
  px.copy(raw, y * (S * 4 + 1) + 1, y * S * 4, (y + 1) * S * 4);
}

const ihdr = Buffer.alloc(13);
ihdr.writeUInt32BE(S, 0);
ihdr.writeUInt32BE(S, 4);
ihdr[8] = 8; // bit depth
ihdr[9] = 6; // RGBA
const sig = Buffer.from([137, 80, 78, 71, 13, 10, 26, 10]);
const png = Buffer.concat([
  sig,
  chunk("IHDR", ihdr),
  chunk("IDAT", zlib.deflateSync(raw, { level: 9 })),
  chunk("IEND", Buffer.alloc(0)),
]);

const out = path.join(__dirname, "..", "app-icon.png");
fs.writeFileSync(out, png);
console.log("wrote", out, png.length, "bytes");
