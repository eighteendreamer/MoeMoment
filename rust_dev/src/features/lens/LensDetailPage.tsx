import { useCallback, useEffect, useState } from 'react'
import { CalendarCheck, CalendarDays, ChevronDown, ImageOff, Pencil, Trash2, Undo2 } from 'lucide-react'
import { Page } from '@/components/Page'
import { PhotoBanner } from './PhotoBanner'
import { StatusChip } from '@/components/LensRow'
import { ConfirmDialog } from '@/components/ConfirmDialog'
import { Button } from '@/components/arc/button/button'
import { Calendar } from '@/components/arc/calendar/calendar'
import { Dialog, DialogContent } from '@/components/arc/dialog/dialog'
import { useNav } from '@/app/navigation'
import { api, imageUrl } from '@/lib/api'
import {
  cycleText,
  formatDate,
  isoToDate,
  dateToISO,
  remainingText,
  remainingTone,
  STORAGE_STATE_LABEL,
  todayISO,
} from '@/lib/format'
import type { Lens } from '@/lib/types'

const SPEC_FIELDS: { key: keyof Lens['lensSpecs']; label: string; suffix?: string }[] = [
  { key: 'Lens_diameter', label: '镜片直径', suffix: 'mm' },
  { key: 'Colored_diameter', label: '着色直径', suffix: 'mm' },
  { key: 'Moisture_content', label: '含水量', suffix: '%' },
  { key: 'Base_arc', label: '基弧', suffix: 'mm' },
  { key: 'Left_eye_prescription', label: '左眼度数', suffix: 'D' },
  { key: 'right_eye_prescription', label: '右眼度数', suffix: 'D' },
]

const SOURCE_TEXT: Record<string, string> = {
  package: '按包装有效期计算',
  usage: '按开封日期与使用周期计算',
  earlier_of_both: '包装有效期与使用周期取较早者',
  none: '尚未能计算到期日',
}

export function LensDetailPage({ id }: { id: number }) {
  const { push, back, refresh, version } = useNav()
  const [lens, setLens] = useState<Lens | null>(null)
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState<string | null>(null)
  const [busy, setBusy] = useState(false)
  const [openDialog, setOpenDialog] = useState(false)
  const [discardDialog, setDiscardDialog] = useState(false)
  const [deleteDialog, setDeleteDialog] = useState(false)
  const [preview, setPreview] = useState<string | null>(null)
  const [openedDate, setOpenedDate] = useState<Date | undefined>(isoToDate(todayISO()))
  const [openCalendar, setOpenCalendar] = useState(false)

  const load = useCallback(() => {
    setLoading(true)
    api
      .getLens(id)
      .then((data) => {
        setLens(data)
        setError(null)
      })
      .catch((err: Error) => setError(err.message))
      .finally(() => setLoading(false))
  }, [id])

  useEffect(() => {
    load()
  }, [load, version])

  const handleOpen = async () => {
    setBusy(true)
    try {
      const updated = await api.openLens(id, dateToISO(openedDate))
      setLens(updated)
      setOpenDialog(false)
      refresh()
    } catch (err) {
      setError((err as Error).message)
    } finally {
      setBusy(false)
    }
  }

  const handleDiscard = async () => {
    setBusy(true)
    try {
      const updated = await api.discardLens(id)
      setLens(updated)
      setDiscardDialog(false)
      refresh()
    } catch (err) {
      setError((err as Error).message)
    } finally {
      setBusy(false)
    }
  }

  const handleDelete = async () => {
    setBusy(true)
    try {
      await api.deleteLens(id)
      setDeleteDialog(false)
      refresh()
      back()
    } catch (err) {
      setError((err as Error).message)
      setBusy(false)
    }
  }

  const handleRestore = async () => {
    setBusy(true)
    try {
      const updated = await api.restoreLens(id)
      setLens(updated)
      refresh()
    } catch (err) {
      setError((err as Error).message)
    } finally {
      setBusy(false)
    }
  }

  if (loading && !lens) {
    return (
      <Page title="美瞳详情">
        <div className="skeleton" style={{ height: 116, marginBottom: 14 }} />
        <div className="skeleton" style={{ height: 180 }} />
      </Page>
    )
  }

  if (!lens) {
    return (
      <Page title="美瞳详情">
        <div className="error-box">{error ?? '未能加载这条美瞳记录'}</div>
      </Page>
    )
  }

  const cover = lens.images[0] ? imageUrl(lens.images[0].path) : null
  const tone = remainingTone(lens.daysRemaining)

  return (
    <Page title="美瞳详情">
      {error ? (
        <div className="error-box" style={{ marginBottom: 12 }}>
          {error}
        </div>
      ) : null}

      <div className="detail-hero">
        <div className="thumb">
          {cover ? (
            <img src={cover} alt={lens.name} />
          ) : (
            <ImageOff size={26} strokeWidth={1.5} />
          )}
        </div>
        <div style={{ flex: 1, minWidth: 0 }}>
          <div style={{ display: 'flex', gap: 6, alignItems: 'center', marginBottom: 2 }}>
            <StatusChip state={lens.state} />
            {lens.isExpiringSoon ? <span className="chip soon">即将到期</span> : null}
          </div>
          <h2 style={{ overflow: 'hidden', textOverflow: 'ellipsis' }}>{lens.name}</h2>
          <p>
            {lens.brand} · {cycleText(lens.cycleUnit, lens.cycleValue)}
            {lens.colorScheme ? ` · ${lens.colorScheme}` : ''}
          </p>
        </div>
      </div>

      <div className="card card-pad" style={{ marginTop: 14 }}>
        <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'flex-start' }}>
          <div>
            <div style={{ fontSize: 12.5, color: 'var(--mm-ink-3)' }}>到期日</div>
            <div style={{ fontSize: 19, fontWeight: 650, marginTop: 2 }}>
              {lens.expiryDate ? formatDate(lens.expiryDate) : '未设置'}
            </div>
          </div>
          <div style={{ textAlign: 'right' }}>
            <div
              style={{
                fontSize: 15,
                fontWeight: 650,
                color:
                  tone === 'danger'
                    ? 'var(--mm-danger)'
                    : tone === 'warning'
                      ? 'var(--mm-warning)'
                      : 'var(--mm-ink-2)',
              }}
            >
              {remainingText(lens.daysRemaining)}
            </div>
            <div style={{ fontSize: 11.5, color: 'var(--mm-ink-3)', marginTop: 2 }}>
              {SOURCE_TEXT[lens.expirySource] ?? ''}
            </div>
          </div>
        </div>

        {lens.status !== 'discarded' ? (
          <div className="actions" style={{ marginTop: 14 }}>
            {lens.status === 'unopened' ? (
              <Button variant="primary" onClick={() => setOpenDialog(true)}>
                <CalendarCheck size={16} style={{ marginRight: 6 }} />
                标记开封
              </Button>
            ) : null}
            <Button variant="secondary" onClick={() => push({ name: 'lens-form', id: lens.id })}>
              <Pencil size={15} style={{ marginRight: 6 }} />
              编辑
            </Button>
            <Button variant="danger" onClick={() => setDiscardDialog(true)}>
              丢弃
            </Button>
          </div>
        ) : (
          <div className="actions" style={{ marginTop: 14 }}>
            <Button variant="secondary" onClick={handleRestore} loading={busy}>
              <Undo2 size={15} style={{ marginRight: 6 }} />
              恢复为未开封
            </Button>
          </div>
        )}
      </div>

      {lens.images.length > 0 ? (
        <section className="section" style={{ marginTop: 18 }}>
          <div className="section-head">
            <h2>照片</h2>
            <span style={{ fontSize: 12.5, color: 'var(--mm-ink-3)' }}>{lens.images.length} 张</span>
          </div>
          {/* 3 张及以上用固定比例横幅轮播，1–2 张保留缩略图行 */}
          {lens.images.length >= 3 ? (
            <PhotoBanner images={lens.images} onOpen={(src) => setPreview(src)} />
          ) : (
            <div className="image-scroller">
              {lens.images.map((image) => {
                const src = imageUrl(image.path)
                return (
                  <button
                    key={image.id}
                    className="image-tile"
                    style={{ padding: 0, border: '1px solid var(--mm-line)' }}
                    onClick={() => src && setPreview(src)}
                  >
                    {src ? <img src={src} alt="美瞳照片" /> : null}
                  </button>
                )
              })}
            </div>
          )}
        </section>
      ) : null}

      <section className="section">
        <div className="section-head">
          <h2>镜片参数</h2>
        </div>
        <div className="spec-grid">
          {SPEC_FIELDS.map((field) => {
            const value = lens.lensSpecs[field.key]
            return (
              <div className="spec-cell" key={field.key}>
                <span>{field.label}</span>
                <strong>
                  {value === undefined || value === null || Number.isNaN(value)
                    ? '—'
                    : `${value}${field.suffix ?? ''}`}
                </strong>
              </div>
            )
          })}
        </div>
      </section>

      <section className="section">
        <div className="section-head">
          <h2>记录信息</h2>
        </div>
        <div className="card">
          <div className="kv">
            <span className="kv-key">周期</span>
            <span className="kv-value">{lens.cycleName}</span>
          </div>
          <div className="kv">
            <span className="kv-key">颜色方案</span>
            <span className="kv-value">{lens.colorScheme || '未填写'}</span>
          </div>
          <div className="kv">
            <span className="kv-key">开封日期</span>
            <span className="kv-value">{lens.openedAt ? formatDate(lens.openedAt) : '未开封'}</span>
          </div>
          <div className="kv">
            <span className="kv-key">包装有效期</span>
            <span className="kv-value">
              {lens.packageExpiryDate ? formatDate(lens.packageExpiryDate) : '未填写'}
            </span>
          </div>
          <div className="kv">
            <span className="kv-key">数据库状态</span>
            <span className="kv-value">{STORAGE_STATE_LABEL[lens.status] ?? lens.status}</span>
          </div>
          {lens.discardedAt ? (
            <div className="kv">
              <span className="kv-key">丢弃日期</span>
              <span className="kv-value">{formatDate(lens.discardedAt)}</span>
            </div>
          ) : null}
          <div className="kv">
            <span className="kv-key">备注</span>
            <span className="kv-value" style={{ maxWidth: '62%' }}>
              {lens.note || '—'}
            </span>
          </div>
        </div>
      </section>

      <div style={{ marginTop: 4, marginBottom: 8 }}>
        <Button variant="ghost" onClick={() => setDeleteDialog(true)}>
          <Trash2 size={15} style={{ marginRight: 6, color: 'var(--mm-danger)' }} />
          <span style={{ color: 'var(--mm-danger)' }}>删除这条记录</span>
        </Button>
      </div>

      {/* 开封日期确认 */}
      <Dialog open={openDialog} onOpenChange={setOpenDialog}>
        <DialogContent
          title="标记开封"
          description="确认开封日期后，会按所选周期计算使用到期日，并重新安排提醒。"
        >
          <div style={{ marginTop: 14 }}>
            <div className="field-label">开封日期</div>
            <button type="button" className="sheet-field" onClick={() => setOpenCalendar(true)}>
              <CalendarDays size={16} strokeWidth={1.8} />
              <span>{openedDate ? formatDate(dateToISO(openedDate)) : '选择日期'}</span>
              <ChevronDown size={16} strokeWidth={1.8} style={{ marginLeft: 'auto', color: 'var(--mm-ink-3)' }} />
            </button>
          </div>
          <div style={{ display: 'flex', gap: 10, marginTop: 18 }}>
            <Button variant="secondary" style={{ flex: 1 }} onClick={() => setOpenDialog(false)}>
              取消
            </Button>
            <Button style={{ flex: 1 }} loading={busy} onClick={handleOpen} disabled={!openedDate}>
              确认开封
            </Button>
          </div>
        </DialogContent>
      </Dialog>

      {/* 日期选择用独立弹层，避免日历在小弹窗里被裁切 */}
      <Dialog open={openCalendar} onOpenChange={setOpenCalendar}>
        <DialogContent title="选择开封日期" description="不能晚于今天">
          <div style={{ display: 'flex', justifyContent: 'center', marginTop: 8 }}>
            <Calendar
              value={openedDate}
              onChange={(next) => {
                setOpenedDate(next)
                setOpenCalendar(false)
              }}
              locale="zh-CN"
              maxDate={new Date()}
            />
          </div>
          <div style={{ display: 'flex', justifyContent: 'center', marginTop: 8 }}>
            <Button
              variant="secondary"
              onClick={() => {
                setOpenedDate(isoToDate(todayISO()))
                setOpenCalendar(false)
              }}
            >
              选择今天
            </Button>
          </div>
        </DialogContent>
      </Dialog>

      <ConfirmDialog
        open={discardDialog}
        onOpenChange={setDiscardDialog}
        title="标记为已丢弃？"
        description="丢弃后不再计入使用中、未开封和已过期统计，也不再安排到期提醒。之后可以恢复为未开封。"
        confirmText="确认丢弃"
        danger
        busy={busy}
        onConfirm={handleDiscard}
      />

      <ConfirmDialog
        open={deleteDialog}
        onOpenChange={setDeleteDialog}
        title="删除这条美瞳记录？"
        description="记录和它的照片会一起删除，此操作不可恢复。如果只是想停用，建议改为「丢弃」。"
        confirmText="删除"
        danger
        busy={busy}
        onConfirm={handleDelete}
      />

      <Dialog open={preview !== null} onOpenChange={(open) => !open && setPreview(null)}>
        <DialogContent title="照片预览" description="点击关闭按钮返回">
          {preview ? (
            <img
              src={preview}
              alt="美瞳照片预览"
              style={{ width: '100%', borderRadius: 16, marginTop: 12 }}
            />
          ) : null}
        </DialogContent>
      </Dialog>
    </Page>
  )
}
