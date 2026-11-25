import { useEffect, useMemo, useState } from 'react'
import { imageUrl } from '@/lib/api'
import type { LensImage } from '@/lib/types'

interface PhotoBannerProps {
  images: LensImage[]
  onOpen?: (source: string) => void
}

/** 多于 3 张时的换图间隔 */
const INTERVAL = 4500
/** 交叉淡入淡出时长，需与 CSS 动画时长一致 */
const FADE_MS = 650

/**
 * 照片横幅：仅在 3 张及以上时使用。
 *
 * 布局是「一个容器横向切成 6:3:1 三格」，容器尺寸固定；
 * 多于 3 张时每格只轮换图片，新旧图交叉淡入淡出，并带轻微推近，
 * 整条横幅首次出现时三格依次渐入。
 */
export function PhotoBanner({ images, onOpen }: PhotoBannerProps) {
  const [start, setStart] = useState(0)
  const [paused, setPaused] = useState(false)

  const sources = useMemo(
    () => images.map((image) => imageUrl(image.path)).filter((src): src is string => Boolean(src)),
    [images],
  )
  const count = sources.length

  useEffect(() => {
    if (count <= 3 || paused) return
    const timer = window.setInterval(() => {
      setStart((current) => (current + 1) % count)
    }, INTERVAL)
    return () => window.clearInterval(timer)
  }, [count, paused])

  if (count === 0) return null

  return (
    <div
      className="photo-strip"
      onMouseEnter={() => setPaused(true)}
      onMouseLeave={() => setPaused(false)}
    >
      {[0, 1, 2].map((slot) => (
        <PhotoSlot
          key={slot}
          src={sources[(start + slot) % count]}
          order={slot}
          onOpen={onOpen}
        />
      ))}
    </div>
  )
}

interface PhotoSlotProps {
  src: string
  order: number
  onOpen?: (source: string) => void
}

/** 单格：新图淡入、旧图同时淡出，避免硬切 */
function PhotoSlot({ src, order, onOpen }: PhotoSlotProps) {
  const [current, setCurrent] = useState(src)
  const [previous, setPrevious] = useState<string | null>(null)
  const [token, setToken] = useState(0)
  const [fading, setFading] = useState(false)

  // 图片换了：把上一张留作淡出层，并递增 token 触发一次新的动画
  useEffect(() => {
    if (src === current) return
    setPrevious(current)
    setCurrent(src)
    setToken((value) => value + 1)
    setFading(true)
  }, [src, current])

  // 动画结束后清掉淡出层；依赖 token，保证每次切换都会重新计时
  useEffect(() => {
    if (!fading) return
    const timer = window.setTimeout(() => {
      setPrevious(null)
      setFading(false)
    }, FADE_MS)
    return () => window.clearTimeout(timer)
  }, [fading, token])

  return (
    <button
      type="button"
      className="photo-strip-slot"
      style={{ animationDelay: `${order * 90}ms` }}
      aria-label="查看这张照片"
      onClick={() => onOpen?.(src)}
    >
      {previous ? (
        <img key={`prev-${previous}`} className="leaving" src={previous} alt="" aria-hidden="true" />
      ) : null}
      <img
        key={current}
        className={fading ? 'entering' : ''}
        src={current}
        alt="美瞳照片"
        draggable={false}
      />
    </button>
  )
}
