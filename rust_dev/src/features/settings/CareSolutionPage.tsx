import { useEffect, useState } from 'react'
import { Droplets } from 'lucide-react'
import { Page } from '@/components/Page'
import { Button } from '@/components/arc/button/button'
import { DatePicker } from '@/components/arc/date-picker/date-picker'
import { Input } from '@/components/arc/input/input'
import { Switch } from '@/components/arc/switch/switch'
import { Textarea } from '@/components/arc/textarea/textarea'
import { useNav } from '@/app/navigation'
import { api } from '@/lib/api'
import { dateToISO, formatDate, isoToDate, remainingText } from '@/lib/format'
import type { CareState } from '@/lib/types'

export function CareSolutionPage() {
  const { refresh } = useNav()
  const [care, setCare] = useState<CareState | null>(null)
  const [error, setError] = useState<string | null>(null)
  const [saved, setSaved] = useState<string | null>(null)
  const [busy, setBusy] = useState(false)

  const [brand, setBrand] = useState('')
  const [name, setName] = useState('')
  const [openedAt, setOpenedAt] = useState<Date | undefined>(undefined)
  const [packageExpiry, setPackageExpiry] = useState<Date | undefined>(undefined)
  const [validDays, setValidDays] = useState('')
  const [isCurrent, setIsCurrent] = useState(true)
  const [note, setNote] = useState('')

  useEffect(() => {
    let cancelled = false
    api
      .careState()
      .then((state) => {
        if (cancelled) return
        setCare(state)
        const bottle = state.bottle
        if (bottle) {
          setBrand(bottle.brand)
          setName(bottle.name)
          setOpenedAt(isoToDate(bottle.openedAt))
          setPackageExpiry(isoToDate(bottle.packageExpiryDate))
          setValidDays(bottle.afterOpenValidDays ? String(bottle.afterOpenValidDays) : '')
          setIsCurrent(bottle.isCurrent)
          setNote(bottle.note ?? '')
        }
      })
      .catch((err: Error) => !cancelled && setError(err.message))
    return () => {
      cancelled = true
    }
  }, [])

  const save = async () => {
    setBusy(true)
    setError(null)
    try {
      const updated = await api.saveCareBottle({
        id: care?.bottle?.id ?? null,
        brand: brand.trim(),
        name: name.trim(),
        openedAt: dateToISO(openedAt),
        packageExpiryDate: dateToISO(packageExpiry),
        afterOpenValidDays: validDays.trim() ? Number(validDays) : null,
        isCurrent,
        note: note.trim() || null,
      })
      setCare(updated)
      setSaved('护理液信息已保存')
      refresh()
    } catch (err) {
      setError((err as Error).message)
    } finally {
      setBusy(false)
    }
  }

  const bottle = care?.bottle ?? null

  return (
    <Page title="护理液信息">
      {error ? (
        <div className="error-box" style={{ marginBottom: 12 }}>
          {error}
        </div>
      ) : null}
      {saved ? (
        <div className="notice-soft" style={{ marginBottom: 12 }}>
          {saved}
        </div>
      ) : null}

      {bottle ? (
        <div className="card card-pad" style={{ marginBottom: 14 }}>
          <div style={{ display: 'flex', alignItems: 'center', gap: 10 }}>
            <span
              className="lead"
              style={{
                width: 38,
                height: 38,
                borderRadius: 12,
                background: '#eaf2fb',
                color: '#4a7fb5',
                display: 'flex',
                alignItems: 'center',
                justifyContent: 'center',
              }}
            >
              <Droplets size={18} />
            </span>
            <div style={{ flex: 1 }}>
              <div style={{ fontWeight: 620 }}>
                {bottle.brand || '未填品牌'} {bottle.name}
              </div>
              <div className="muted">
                {bottle.isCurrent ? '当前使用中' : '备用'}
                {bottle.expiryDate ? ` · 到期 ${formatDate(bottle.expiryDate)}` : ' · 到期日未计算'}
              </div>
            </div>
            {bottle.expiryDate ? (
              <span
                className={`chip plain ${bottle.expired ? 'expired' : 'unopened'}`}
                style={{ fontSize: 12 }}
              >
                {remainingText(bottle.daysRemaining)}
              </span>
            ) : (
              <span className="chip info plain">待补充</span>
            )}
          </div>
          {!bottle.expiryDate ? (
            <div className="notice" style={{ marginTop: 12 }}>
              还缺少包装有效期或「开封日期 + 开封后有效天数」，因此无法推算到期日。
            </div>
          ) : null}
        </div>
      ) : (
        <div className="card" style={{ marginBottom: 14 }}>
          <div className="empty">
            <h4>还没有护理液信息</h4>
            <p>填写品牌、开封日期与有效期后，才能计算护理液到期日并安排提醒。</p>
          </div>
        </div>
      )}

      <div className="form-grid">
        <Input
          label="品牌"
          value={brand}
          onChange={(event) => setBrand(event.target.value)}
          placeholder="例如 博士伦"
        />
        <Input
          label="名称"
          value={name}
          onChange={(event) => setName(event.target.value)}
          placeholder="例如 润明清透护理液"
        />

        <div className="arc-field">
          <DatePicker
            label="开封日期"
            value={openedAt}
            onChange={setOpenedAt}
            locale="zh-CN"
            format={{ year: 'numeric', month: 'long', day: 'numeric' }}
            maxDate={new Date()}
            showToday
          />
        </div>

        <div className="arc-field">
          <DatePicker
            label="包装有效期"
            value={packageExpiry}
            onChange={setPackageExpiry}
            description="与「开封后有效天数」同时存在时，取较早的日期"
            locale="zh-CN"
            format={{ year: 'numeric', month: 'long', day: 'numeric' }}
          />
        </div>

        <Input
          label="开封后有效天数"
          type="number"
          min="1"
          max="3650"
          value={validDays}
          onChange={(event) => setValidDays(event.target.value)}
          placeholder="例如 90"
          description="从开封日期起算，例如 90 天"
        />

        <div className="card card-pad" style={{ display: 'flex', alignItems: 'center', gap: 10 }}>
          <div style={{ flex: 1 }}>
            <div style={{ fontWeight: 600 }}>设为当前使用</div>
            <div className="muted">同时只保留一瓶当前使用的护理液</div>
          </div>
          <Switch checked={isCurrent} onCheckedChange={setIsCurrent} aria-label="设为当前使用" />
        </div>

        <Textarea
          label="备注（可选）"
          value={note}
          onChange={(event) => setNote(event.target.value)}
          rows={2}
        />
      </div>

      <div className="actions">
        <Button style={{ flex: 1 }} loading={busy} onClick={save}>
          保存护理液信息
        </Button>
      </div>

      {care && care.change.history.length > 0 ? (
        <section className="section" style={{ marginTop: 22 }}>
          <div className="section-head">
            <h2>更换历史</h2>
            <span style={{ fontSize: 12.5, color: 'var(--mm-ink-3)' }}>
              {care.change.history.length} 条
            </span>
          </div>
          <div className="card">
            <div className="list">
              {care.change.history.map((log) => (
                <div key={log.id} className="kv">
                  <span className="kv-key">{formatDate(log.changedAt)}</span>
                  <span className="kv-value">{log.note || '更换护理液'}</span>
                </div>
              ))}
            </div>
          </div>
        </section>
      ) : null}
    </Page>
  )
}
