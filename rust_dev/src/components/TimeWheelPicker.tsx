import { useEffect, useRef, useState } from 'react'
import { ChevronDown, Clock3 } from 'lucide-react'
import { BottomSheet } from '@/components/arc/bottom-sheet/bottom-sheet'
import { Button } from '@/components/arc/button/button'

const pad = (n: number) => String(n).padStart(2, '0')
/** 与 app.css 中 .wheel-item 的行高保持一致 */
const ITEM_H = 38
/** 副本数量：渲染 3 份并始终归位到中间一份，实现首尾循环 */
const COPIES = 3

/** 单列循环滚轮：scroll-snap 居中对齐，滚动停下后取中间项作为值 */
function WheelColumn({
  items,
  value,
  onChange,
  ariaLabel,
}: {
  items: string[]
  value: string
  onChange: (v: string) => void
  ariaLabel: string
}) {
  const ref = useRef<HTMLDivElement>(null)
  const timer = useRef<number | undefined>(undefined)
  // 用户手指/滚轮正在滚动时，不让外部值同步抢滚动
  const touching = useRef(false)
  const copyHeight = items.length * ITEM_H

  // 外部值变化（或首次挂载）时滚到中间副本的对应项
  useEffect(() => {
    if (touching.current) return
    const el = ref.current
    const index = items.indexOf(value)
    if (el && index >= 0) {
      const target = copyHeight + index * ITEM_H
      if (Math.abs(el.scrollTop - target) > 2) el.scrollTo({ top: target })
    }
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [value])

  // 卸载时清掉未触发的计时器
  useEffect(() => () => window.clearTimeout(timer.current), [])

  const handleScroll = () => {
    const el = ref.current
    if (!el) return

    // 循环：滚出中间副本就无声归位（三份内容完全一样，视觉上是连续的）
    // 注意阈值必须是副本边界本身：任何更靠内的阈值都会把归位后的位置又弹回去，造成振荡
    if (el.scrollTop < copyHeight) {
      el.scrollTop += copyHeight
    } else if (el.scrollTop >= copyHeight * 2) {
      el.scrollTop -= copyHeight
    }

    window.clearTimeout(timer.current)
    timer.current = window.setTimeout(() => {
      touching.current = false
      const raw = Math.round(el.scrollTop / ITEM_H)
      const count = items.length
      // 归一化到 0..count-1，支持任意方向的循环
      const index = ((raw % count) + count) % count
      const next = items[index]
      // 停稳后把位置精确归位到中间副本，保证下一圈还能继续滚
      const target = copyHeight + index * ITEM_H
      if (Math.abs(el.scrollTop - target) > 2) el.scrollTop = target
      if (next && next !== value) onChange(next)
    }, 110)
  }

  const repeated = Array.from({ length: COPIES }, () => items).flat()

  return (
    <div
      className="wheel-col"
      ref={ref}
      role="listbox"
      aria-label={ariaLabel}
      onScroll={handleScroll}
      onTouchStart={() => {
        touching.current = true
      }}
      onWheel={() => {
        touching.current = true
      }}
    >
      <div className="wheel-pad" aria-hidden="true" />
      {repeated.map((item, position) => {
        const realIndex = position % items.length
        const inMiddleCopy = position >= items.length && position < items.length * 2
        return (
          <div
            key={`${realIndex}-${Math.floor(position / items.length)}`}
            role="option"
            aria-selected={inMiddleCopy && items[realIndex] === value}
            aria-hidden={inMiddleCopy ? undefined : 'true'}
            className={`wheel-item ${items[realIndex] === value ? 'active' : ''}`}
            onClick={() => onChange(items[realIndex])}
          >
            {item}
          </div>
        )
      })}
      <div className="wheel-pad" aria-hidden="true" />
    </div>
  )
}

export interface TimeWheelPickerProps {
  label: string
  value: string
  onChange: (value: string) => void
}

/**
 * 双列循环滚轮时间选择：一列小时、一列分钟，可无限循环滚动。
 * 点击字段后从底部弹出（BottomSheet），在弹层里滚动选择，点「确定」生效。
 */
export function TimeWheelPicker({ label, value, onChange }: TimeWheelPickerProps) {
  const [open, setOpen] = useState(false)
  // 弹层内的草稿值：确定才提交，取消/下拉关闭即丢弃
  const [draft, setDraft] = useState(value)
  const hours = Array.from({ length: 24 }, (_, i) => pad(i))
  const minutes = Array.from({ length: 60 }, (_, i) => pad(i))
  const [draftHour, draftMinute] = draft.split(':')

  const openSheet = () => {
    setDraft(value)
    setOpen(true)
  }

  const confirm = () => {
    onChange(draft)
    setOpen(false)
  }

  return (
    <div>
      <div className="field-label">{label}</div>
      <button type="button" className="sheet-field" aria-haspopup="dialog" onClick={openSheet}>
        <Clock3 size={16} strokeWidth={1.8} />
        <span>{value}</span>
        <ChevronDown size={16} strokeWidth={1.8} style={{ marginLeft: 'auto', color: 'var(--mm-ink-3)' }} />
      </button>

      <BottomSheet
        open={open}
        onOpenChange={setOpen}
        title="选择时间"
        detents={[0.44]}
        closeLabel="关闭"
      >
        <div className="time-wheel">
          <WheelColumn
            items={hours}
            value={draftHour ?? '00'}
            ariaLabel="小时"
            onChange={(nextHour) => setDraft(`${nextHour}:${draftMinute ?? '00'}`)}
          />
          <WheelColumn
            items={minutes}
            value={draftMinute ?? '00'}
            ariaLabel="分钟"
            onChange={(nextMinute) => setDraft(`${draftHour ?? '00'}:${nextMinute}`)}
          />
        </div>
        <div style={{ display: 'flex', gap: 10, marginTop: 14, marginBottom: 6 }}>
          <Button variant="secondary" style={{ flex: 1 }} onClick={() => setOpen(false)}>
            取消
          </Button>
          <Button style={{ flex: 1.4 }} onClick={confirm}>
            确定
          </Button>
        </div>
      </BottomSheet>
    </div>
  )
}
