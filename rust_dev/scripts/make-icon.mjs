/**
 * 生成应用图标源图（1024×1024 PNG），零依赖：自绘 + 原生 zlib 编码。
 * 设计：粉色渐变圆角底 + 镜片（外圈环、虹膜、瞳孔、高光），与 App 主色 #E9789A 一致。
 *
 * 用法：node scripts/make-icon.mjs [输出路径]
 */
import zlib from 'node:zlib'
import fs from 'node:fs'
import path from 'node:path'

const SIZE = 1024
const CX = SIZE / 2
const CY = SIZE / 2

const hex = (value) => {
  const clean = value.replace('#', '')
  return [
    parseInt(clean.slice(0, 2), 16),
    parseInt(clean.slice(2, 4), 16),
    parseInt(clean.slice(4, 6), 16),
  ]
}

const mix = (a, b, t) => [
  a[0] + (b[0] - a[0]) * t,
  a[1] + (b[1] - a[1]) * t,
  a[2] + (b[2] - a[2]) * t,
]

/** 1px 宽的抗锯齿覆盖率：distance <= -0.5 实心，>= 0.5 为空 */
const coverage = (distance) => Math.min(1, Math.max(0, 0.5 - distance))

/** 圆角矩形 SDF */
function roundedRectSdf(x, y, half, radius) {
  const dx = Math.abs(x - CX) - (half - radius)
  const dy = Math.abs(y - CY) - (half - radius)
  const ax = Math.max(dx, 0)
  const ay = Math.max(dy, 0)
  return Math.hypot(ax, ay) + Math.min(Math.max(dx, dy), 0) - radius
}

const pixels = new Float32Array(SIZE * SIZE * 4)

/** 直通道 alpha 合成（over） */
function blend(index, color, alpha) {
  if (alpha <= 0) return
  const dstA = pixels[index + 3]
  const outA = alpha + dstA * (1 - alpha)
  if (outA <= 0) return
  for (let channel = 0; channel < 3; channel += 1) {
    const dst = pixels[index + channel]
    pixels[index + channel] = (color[channel] * alpha + dst * dstA * (1 - alpha)) / outA
  }
  pixels[index + 3] = outA
}

const BG_TOP = hex('#F7A7BF')
const BG_BOTTOM = hex('#DF6E92')
const LENS_LIGHT = hex('#FFFFFF')
const LENS_SHADE = hex('#FFD9E4')
const IRIS_OUTER = hex('#8E3B55')
const IRIS_INNER = hex('#C4627F')
const LIMBAL = hex('#7A2F44')
const PUPIL = hex('#3B2029')

for (let y = 0; y < SIZE; y += 1) {
  for (let x = 0; x < SIZE; x += 1) {
    const index = (y * SIZE + x) * 4

    // 1. 圆角底：对角线渐变
    const bgDistance = roundedRectSdf(x, y, SIZE / 2, SIZE * 0.225)
    const bgCoverage = coverage(bgDistance)
    if (bgCoverage > 0) {
      const t = Math.min(1, Math.max(0, (x / SIZE) * 0.35 + (y / SIZE) * 0.65))
      blend(index, mix(BG_TOP, BG_BOTTOM, t), bgCoverage)
    }
    if (bgCoverage <= 0) continue

    const dx = x - CX
    const dy = y - CY
    const radius = Math.hypot(dx, dy)

    // 2. 柔光
    const glow = coverage(radius - SIZE * 0.42)
    if (glow > 0) blend(index, [255, 255, 255], 0.1 * glow)

    // 3. 镜片外环 250..332
    const lensBody = coverage(radius - 332) * (1 - coverage(radius - 250))
    if (lensBody > 0) {
      const t = Math.min(1, Math.max(0, (y - (CY - 332)) / 664))
      blend(index, mix(LENS_LIGHT, LENS_SHADE, t), 0.97 * lensBody)
    }

    // 4. 虹膜：径向着色
    const iris = coverage(radius - 250)
    if (iris > 0) {
      const t = Math.min(1, Math.max(0, radius / 250))
      const irisColor = mix(IRIS_INNER, IRIS_OUTER, t * t)
      blend(index, irisColor, iris)
    }

    // 5. 角膜缘（加深边缘）
    const limbal = coverage(radius - 250) * (1 - coverage(radius - 232))
    if (limbal > 0) blend(index, LIMBAL, 0.5 * limbal)

    // 6. 瞳孔
    const pupil = coverage(radius - 118)
    if (pupil > 0) blend(index, PUPIL, pupil)

    // 7. 高光：主光斑 + 次光斑
    const main = coverage(Math.hypot(x - (CX - 84), y - (CY - 104)) - 52)
    if (main > 0) blend(index, [255, 255, 255], 0.88 * main)
    const sub = coverage(Math.hypot(x - (CX + 72), y - (CY + 118)) - 20)
    if (sub > 0) blend(index, [255, 255, 255], 0.55 * sub)
  }
}

// ---- 最小 PNG 编码（RGBA8，无滤波） ----
const CRC_TABLE = (() => {
  const table = new Uint32Array(256)
  for (let n = 0; n < 256; n += 1) {
    let c = n
    for (let k = 0; k < 8; k += 1) c = c & 1 ? 0xedb88320 ^ (c >>> 1) : c >>> 1
    table[n] = c >>> 0
  }
  return table
})()

function crc32(buffer) {
  let crc = 0xffffffff
  for (const byte of buffer) crc = CRC_TABLE[(crc ^ byte) & 0xff] ^ (crc >>> 8)
  return (crc ^ 0xffffffff) >>> 0
}

function chunk(type, data) {
  const length = Buffer.alloc(4)
  length.writeUInt32BE(data.length, 0)
  const body = Buffer.concat([Buffer.from(type, 'ascii'), data])
  const crc = Buffer.alloc(4)
  crc.writeUInt32BE(crc32(body), 0)
  return Buffer.concat([length, body, crc])
}

const raw = Buffer.alloc(SIZE * (SIZE * 4 + 1))
for (let y = 0; y < SIZE; y += 1) {
  raw[y * (SIZE * 4 + 1)] = 0
  for (let x = 0; x < SIZE; x += 1) {
    const src = (y * SIZE + x) * 4
    const dst = y * (SIZE * 4 + 1) + 1 + x * 4
    raw[dst] = Math.round(Math.min(255, Math.max(0, pixels[src])))
    raw[dst + 1] = Math.round(Math.min(255, Math.max(0, pixels[src + 1])))
    raw[dst + 2] = Math.round(Math.min(255, Math.max(0, pixels[src + 2])))
    raw[dst + 3] = Math.round(Math.min(255, Math.max(0, pixels[src + 3] * 255)))
  }
}

const ihdr = Buffer.alloc(13)
ihdr.writeUInt32BE(SIZE, 0)
ihdr.writeUInt32BE(SIZE, 4)
ihdr[8] = 8
ihdr[9] = 6
ihdr[10] = 0
ihdr[11] = 0
ihdr[12] = 0

const png = Buffer.concat([
  Buffer.from([0x89, 0x50, 0x4e, 0x47, 0x0d, 0x0a, 0x1a, 0x0a]),
  chunk('IHDR', ihdr),
  chunk('IDAT', zlib.deflateSync(raw, { level: 9 })),
  chunk('IEND', Buffer.alloc(0)),
])

const out = path.resolve(process.argv[2] ?? 'src-tauri/icons/icon-source.png')
fs.mkdirSync(path.dirname(out), { recursive: true })
fs.writeFileSync(out, png)
console.log(`图标已生成：${out}（${SIZE}×${SIZE}, ${(png.length / 1024).toFixed(0)} KB）`)
