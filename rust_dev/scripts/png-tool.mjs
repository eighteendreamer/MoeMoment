/**
 * PNG 处理工具（零依赖）：解码 → 裁掉透明留白 → 缩放 → 可选合成底色 → 重新编码。
 * 仅用于生成应用图标源图，不参与应用打包。
 *
 * 用法：
 *   node scripts/png-tool.mjs prepare <源图.png> <输出目录>
 *
 * 输出：
 *   icon-source.png        裁切并缩放后的透明图（1024×1024）
 *   icon-opaque.png        合成品牌粉底后的不透明图（给 iOS 用）
 */
import fs from 'node:fs'
import path from 'node:path'
import zlib from 'node:zlib'

// ---------- 解码 ----------

function paeth(a, b, c) {
  const p = a + b - c
  const pa = Math.abs(p - a)
  const pb = Math.abs(p - b)
  const pc = Math.abs(p - c)
  if (pa <= pb && pa <= pc) return a
  if (pb <= pc) return b
  return c
}

export function decodePng(file) {
  const buf = fs.readFileSync(file)
  if (buf.readUInt32BE(0) !== 0x89504e47) throw new Error('不是 PNG 文件')

  let offset = 8
  let width = 0
  let height = 0
  let bitDepth = 0
  let colorType = 0
  let interlace = 0
  const idat = []

  while (offset < buf.length) {
    const length = buf.readUInt32BE(offset)
    const type = buf.toString('ascii', offset + 4, offset + 8)
    const data = buf.subarray(offset + 8, offset + 8 + length)
    if (type === 'IHDR') {
      width = data.readUInt32BE(0)
      height = data.readUInt32BE(4)
      bitDepth = data[8]
      colorType = data[9]
      interlace = data[12]
    } else if (type === 'IDAT') {
      idat.push(data)
    } else if (type === 'IEND') {
      break
    }
    offset += 12 + length
  }

  if (bitDepth !== 8 || interlace !== 0 || (colorType !== 6 && colorType !== 2)) {
    throw new Error(`暂不支持该 PNG：depth=${bitDepth} colorType=${colorType} interlace=${interlace}`)
  }

  const channels = colorType === 6 ? 4 : 3
  const raw = zlib.inflateSync(Buffer.concat(idat))
  const stride = width * channels
  const pixels = Buffer.alloc(width * height * 4)
  let previous = Buffer.alloc(stride)

  for (let y = 0; y < height; y += 1) {
    const filter = raw[y * (stride + 1)]
    const line = Buffer.from(raw.subarray(y * (stride + 1) + 1, y * (stride + 1) + 1 + stride))
    for (let i = 0; i < stride; i += 1) {
      const left = i >= channels ? line[i - channels] : 0
      const up = previous[i]
      const upLeft = i >= channels ? previous[i - channels] : 0
      let value = line[i]
      if (filter === 1) value += left
      else if (filter === 2) value += up
      else if (filter === 3) value += Math.floor((left + up) / 2)
      else if (filter === 4) value += paeth(left, up, upLeft)
      line[i] = value & 0xff
    }
    for (let x = 0; x < width; x += 1) {
      const dst = (y * width + x) * 4
      const src = x * channels
      pixels[dst] = line[src]
      pixels[dst + 1] = line[src + 1]
      pixels[dst + 2] = line[src + 2]
      pixels[dst + 3] = channels === 4 ? line[src + 3] : 255
    }
    previous = line
  }

  return { width, height, data: pixels }
}

// ---------- 编码 ----------

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

export function encodePng(file, { width, height, data }) {
  const raw = Buffer.alloc(height * (width * 4 + 1))
  for (let y = 0; y < height; y += 1) {
    raw[y * (width * 4 + 1)] = 0
    data.copy(raw, y * (width * 4 + 1) + 1, y * width * 4, (y + 1) * width * 4)
  }
  const ihdr = Buffer.alloc(13)
  ihdr.writeUInt32BE(width, 0)
  ihdr.writeUInt32BE(height, 4)
  ihdr[8] = 8
  ihdr[9] = 6
  fs.writeFileSync(
    file,
    Buffer.concat([
      Buffer.from([0x89, 0x50, 0x4e, 0x47, 0x0d, 0x0a, 0x1a, 0x0a]),
      chunk('IHDR', ihdr),
      chunk('IDAT', zlib.deflateSync(raw, { level: 9 })),
      chunk('IEND', Buffer.alloc(0)),
    ]),
  )
}

// ---------- 变换 ----------

/** 非透明像素的包围盒，用于裁掉四周留白 */
export function alphaBounds({ width, height, data }) {
  let minX = width
  let minY = height
  let maxX = -1
  let maxY = -1
  for (let y = 0; y < height; y += 1) {
    for (let x = 0; x < width; x += 1) {
      if (data[(y * width + x) * 4 + 3] > 8) {
        if (x < minX) minX = x
        if (x > maxX) maxX = x
        if (y < minY) minY = y
        if (y > maxY) maxY = y
      }
    }
  }
  return { minX, minY, maxX, maxY }
}

/** 以正方形裁切（带 padding 比例），双线性缩放到 size，返回 RGBA */
export function squareCropResize(image, bounds, padding, size) {
  const contentW = bounds.maxX - bounds.minX + 1
  const contentH = bounds.maxY - bounds.minY + 1
  const side = Math.round(Math.max(contentW, contentH) * (1 + padding * 2))
  const startX = Math.round((bounds.minX + bounds.maxX + 1) / 2 - side / 2)
  const startY = Math.round((bounds.minY + bounds.maxY + 1) / 2 - side / 2)

  const out = Buffer.alloc(size * size * 4)
  const scale = side / size

  for (let y = 0; y < size; y += 1) {
    for (let x = 0; x < size; x += 1) {
      const sx = startX + (x + 0.5) * scale - 0.5
      const sy = startY + (y + 0.5) * scale - 0.5
      const x0 = Math.floor(sx)
      const y0 = Math.floor(sy)
      const fx = sx - x0
      const fy = sy - y0

      let r = 0
      let g = 0
      let b = 0
      let a = 0
      let weight = 0

      for (const [dx, dy, w] of [
        [0, 0, (1 - fx) * (1 - fy)],
        [1, 0, fx * (1 - fy)],
        [0, 1, (1 - fx) * fy],
        [1, 1, fx * fy],
      ]) {
        const px = x0 + dx
        const py = y0 + dy
        if (px < 0 || py < 0 || px >= image.width || py >= image.height) continue
        const src = (py * image.width + px) * 4
        const alpha = image.data[src + 3]
        // 预乘 alpha 后再插值，避免透明边缘出现黑边
        r += image.data[src] * alpha * w
        g += image.data[src + 1] * alpha * w
        b += image.data[src + 2] * alpha * w
        a += alpha * w
        weight += w
      }

      const dst = (y * size + x) * 4
      if (a > 0 && weight > 0) {
        out[dst] = Math.round(r / a)
        out[dst + 1] = Math.round(g / a)
        out[dst + 2] = Math.round(b / a)
        out[dst + 3] = Math.round(a / weight)
      }
    }
  }
  return { width: size, height: size, data: out }
}

const hex = (value) => [
  parseInt(value.slice(1, 3), 16),
  parseInt(value.slice(3, 5), 16),
  parseInt(value.slice(5, 7), 16),
]

/** 把透明图合到纯色底上（iOS 图标不允许 alpha） */
export function flatten(image, color) {
  const [br, bg, bb] = hex(color)
  const out = Buffer.alloc(image.width * image.height * 4)
  for (let i = 0; i < image.width * image.height; i += 1) {
    const src = i * 4
    const a = image.data[src + 3] / 255
    out[src] = Math.round(image.data[src] * a + br * (1 - a))
    out[src + 1] = Math.round(image.data[src + 1] * a + bg * (1 - a))
    out[src + 2] = Math.round(image.data[src + 2] * a + bb * (1 - a))
    out[src + 3] = 255
  }
  return { width: image.width, height: image.height, data: out }
}

// ---------- CLI ----------

const [, , command, source, outDir, bgColor] = process.argv
if (command === 'prepare') {
  if (!source || !outDir) throw new Error('用法: node scripts/png-tool.mjs prepare <源图.png> <输出目录>')

  const image = decodePng(source)
  const bounds = alphaBounds(image)
  const contentW = bounds.maxX - bounds.minX + 1
  const contentH = bounds.maxY - bounds.minY + 1

  // 留白 6%，让图形在圆形/方形遮罩里都不贴边
  const cropped = squareCropResize(image, bounds, 0.06, 1024)
  const opaque = flatten(cropped, bgColor ?? '#FFF7FA')

  fs.mkdirSync(outDir, { recursive: true })
  const transparentPath = path.join(outDir, 'icon-source.png')
  const opaquePath = path.join(outDir, 'icon-opaque.png')
  encodePng(transparentPath, cropped)
  encodePng(opaquePath, opaque)

  console.log(`源图：${image.width}×${image.height}，内容区域 ${contentW}×${contentH}`)
  console.log(`已输出：${transparentPath}`)
  console.log(`已输出：${opaquePath}`)
}
