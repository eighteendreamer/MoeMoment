/**
 * 图片预处理：在落盘前压缩，避免把几 MB 的原图直接写进应用数据目录。
 *
 * 规则：
 * - 最长边超过 MAX_EDGE 才缩放，尺寸已经足够小则不缩放只重编码；
 * - 统一转成 JPEG（白底），照片类图片体积收益最大；
 * - 解码失败（例如部分平台的 HEIC）时退回原始文件，保证能存进去而不是直接报错。
 */

const MAX_EDGE = 1600
const QUALITY = 0.85
/** 小于这个体积且不是 PNG 时直接用原图，省一次重编码 */
const SKIP_BELOW_BYTES = 320 * 1024

export interface PreparedImage {
  dataUrl: string
  mime: string
  /** 压缩后的大致字节数，用于界面提示 */
  bytes: number
  compressed: boolean
}

function readAsDataUrl(file: Blob): Promise<string> {
  return new Promise((resolve, reject) => {
    const reader = new FileReader()
    reader.onload = () => resolve(String(reader.result))
    reader.onerror = () => reject(new Error('读取图片失败'))
    reader.readAsDataURL(file)
  })
}

function loadImage(dataUrl: string): Promise<HTMLImageElement> {
  return new Promise((resolve, reject) => {
    const image = new Image()
    image.onload = () => resolve(image)
    image.onerror = () => reject(new Error('无法解码这张图片'))
    image.src = dataUrl
  })
}

export async function prepareImage(file: File): Promise<PreparedImage> {
  const original = await readAsDataUrl(file)
  const originalMime = file.type || 'image/jpeg'

  // 小图直接使用原文件，避免无意义的重新编码
  if (file.size <= SKIP_BELOW_BYTES && file.type !== 'image/png') {
    return { dataUrl: original, mime: originalMime, bytes: file.size, compressed: false }
  }

  let image: HTMLImageElement
  try {
    image = await loadImage(original)
  } catch {
    // 解码失败时按原图提交，由后端做体积校验
    return { dataUrl: original, mime: originalMime, bytes: file.size, compressed: false }
  }

  const longest = Math.max(image.naturalWidth, image.naturalHeight)
  const scale = longest > MAX_EDGE ? MAX_EDGE / longest : 1
  const width = Math.max(1, Math.round(image.naturalWidth * scale))
  const height = Math.max(1, Math.round(image.naturalHeight * scale))

  const canvas = document.createElement('canvas')
  canvas.width = width
  canvas.height = height
  const context = canvas.getContext('2d')
  if (!context) {
    return { dataUrl: original, mime: originalMime, bytes: file.size, compressed: false }
  }

  // 白底，避免透明 PNG 转 JPEG 后变黑
  context.fillStyle = '#ffffff'
  context.fillRect(0, 0, width, height)
  context.imageSmoothingQuality = 'high'
  context.drawImage(image, 0, 0, width, height)

  const dataUrl = canvas.toDataURL('image/jpeg', QUALITY)
  const bytes = Math.round((dataUrl.length - dataUrl.indexOf(',') - 1) * 0.75)

  // 尺寸本来就小、压完反而更大，就用原图
  if (bytes >= file.size && scale === 1) {
    return { dataUrl: original, mime: originalMime, bytes: file.size, compressed: false }
  }

  return { dataUrl, mime: 'image/jpeg', bytes, compressed: true }
}

export function formatSize(bytes: number): string {
  if (bytes < 1024) return `${bytes} B`
  if (bytes < 1024 * 1024) return `${(bytes / 1024).toFixed(0)} KB`
  return `${(bytes / 1024 / 1024).toFixed(1)} MB`
}
