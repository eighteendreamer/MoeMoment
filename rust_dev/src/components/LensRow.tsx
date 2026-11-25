import { ImageOff } from 'lucide-react'
import { imageUrl } from '@/lib/api'
import { remainingText, remainingTone, STATE_LABEL, cycleText } from '@/lib/format'
import type { Lens, LensState } from '@/lib/types'

export function StatusChip({ state }: { state: LensState }) {
  return (
    <span className={`chip ${state}`}>
      {STATE_LABEL[state] ?? state}
    </span>
  )
}

interface LensRowProps {
  lens: Lens
  onClick: () => void
  showStatus?: boolean
}

export function LensRow({ lens, onClick, showStatus = true }: LensRowProps) {
  const cover = lens.images[0] ? imageUrl(lens.images[0].path) : null
  const tone = remainingTone(lens.daysRemaining)

  return (
    <button className="lens-row" onClick={onClick} type="button">
      <div className="thumb">
        {cover ? <img src={cover} alt={`${lens.brand} ${lens.name}`} /> : <ImageOff size={20} strokeWidth={1.6} />}
      </div>
      <div className="lens-row-main">
        <div className="lens-row-title">
          <span
            style={{
              overflow: 'hidden',
              textOverflow: 'ellipsis',
              whiteSpace: 'nowrap',
            }}
          >
            {lens.brand} · {lens.name}
          </span>
        </div>
        <div className="lens-row-meta">
          <span>{cycleText(lens.cycleUnit, lens.cycleValue)}</span>
          {lens.colorScheme ? <span>{lens.colorScheme}</span> : null}
          {showStatus ? <StatusChip state={lens.state} /> : null}
        </div>
      </div>
      <div className="lens-row-side">
        {lens.expiryDate ? (
          <>
            <div
              className={
                tone === 'danger' ? 'days-strong' : tone === 'warning' ? 'days-warn' : 'days-calm'
              }
            >
              {remainingText(lens.daysRemaining)}
            </div>
            <div style={{ fontSize: 11.5, color: 'var(--mm-ink-3)', marginTop: 2 }}>
              {lens.expiryDate}
            </div>
          </>
        ) : (
          <div className="days-calm">{lens.status === 'discarded' ? '已丢弃' : '未设有效期'}</div>
        )}
      </div>
    </button>
  )
}
