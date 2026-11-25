import { useEffect, useState } from 'react'
import { CalendarDays, ChevronDown, Droplets, Sparkles, Timer } from 'lucide-react'
import { Page } from '@/components/Page'
import { Button } from '@/components/arc/button/button'
import { Calendar } from '@/components/arc/calendar/calendar'
import { Dialog, DialogContent } from '@/components/arc/dialog/dialog'
import { Input } from '@/components/arc/input/input'
import SegmentedControl from '@/components/arc/segmented-control/segmented-control'
import { Select } from '@/components/arc/select/select'
import { Switch } from '@/components/arc/switch/switch'
import { Textarea } from '@/components/arc/textarea/textarea'
import { TimeWheelPicker } from '@/components/TimeWheelPicker'
import { BottomSheet } from '@/components/arc/bottom-sheet/bottom-sheet'
import { useNav } from '@/app/navigation'
import { useToast } from '@/components/ToastProvider'
import { api } from '@/lib/api'
import { dateToISO, formatDate, isoToDate, todayISO } from '@/lib/format'
import type { CareState, LensReminderSetting } from '@/lib/types'

const FREQUENCY_OPTIONS = [
  { value: 'daily', label: '每天', days: 1 },
  { value: 'every_2_days', label: '每 2 天', days: 2 },
  { value: 'every_3_days', label: '每 3 天', days: 3 },
  { value: 'weekly', label: '每周', days: 7 },
  { value: 'custom', label: '自定义', days: 0 },
]

export function ReminderSettingsPage() {
  const { push, refresh } = useNav()
  const toast = useToast()
  const [lensSetting, setLensSetting] = useState<LensReminderSetting | null>(null)
  const [care, setCare] = useState<CareState | null>(null)
  const [error, setError] = useState<string | null>(null)

  const [busy, setBusy] = useState<string | null>(null)


  const [customDays, setCustomDays] = useState('3')
  const [changeDialog, setChangeDialog] = useState(false)
  const [calendarOpen, setCalendarOpen] = useState(false)
  const [changedDate, setChangedDate] = useState<Date | undefined>(isoToDate(todayISO()))
  const [changedNote, setChangedNote] = useState('')

  useEffect(() => {
    let cancelled = false
    Promise.all([api.lensReminderSetting(), api.careState()])
      .then(([nextLens, nextCare]) => {
        if (cancelled) return
        setLensSetting(nextLens)
        setCare(nextCare)
        if (nextCare.change.frequency === 'custom') {
          setCustomDays(String(nextCare.change.intervalDays))
        }
      })
      .catch((err: Error) => !cancelled && setError(err.message))
    return () => {
      cancelled = true
    }
  }, [])

  const saveLens = async () => {
    if (!lensSetting) return
    setBusy('lens')
    try {
      const updated = await api.updateLensReminder(lensSetting)
      setLensSetting(updated)
      toast('美瞳到期提醒已保存')
      refresh()
    } catch (err) {
      setError((err as Error).message)
    } finally {
      setBusy(null)
    }
  }

  const saveChange = async () => {
    if (!care) return
    setBusy('change')
    try {
      const interval =
        care.change.frequency === 'custom'
          ? Number(customDays)
          : (FREQUENCY_OPTIONS.find((item) => item.value === care.change.frequency)?.days ?? 3)
      const updated = await api.updateCareChangeReminder({
        isActive: care.change.isActive,
        frequency: care.change.frequency,
        intervalDays: interval,
        reminderTime: care.change.reminderTime,
      })
      setCare(updated)
      toast('护理液更换提醒已保存')
      refresh()
    } catch (err) {
      setError((err as Error).message)
    } finally {
      setBusy(null)
    }
  }

  const saveExpiry = async () => {
    if (!care) return
    setBusy('expiry')
    try {
      const updated = await api.updateCareExpiryReminder({
        isActive: care.expiry.isActive,
        advanceDays: care.expiry.advanceDays,
        reminderTime: care.expiry.reminderTime,
      })
      setCare(updated)
      toast('护理液到期提醒已保存')
      refresh()
    } catch (err) {
      setError((err as Error).message)
    } finally {
      setBusy(null)
    }
  }

  const markChanged = async () => {
    setBusy('mark')
    try {
      const updated = await api.markCareChanged(dateToISO(changedDate), changedNote)
      setCare(updated)
      setChangeDialog(false)
      setChangedNote('')
      toast('已记录本次更换')
      refresh()
    } catch (err) {
      setError((err as Error).message)
    } finally {
      setBusy(null)
    }
  }

  return (
    <Page title="提醒设置">
      {error ? (
        <div className="error-box" style={{ marginBottom: 12 }}>
          {error}
        </div>
      ) : null}

      {/* A. 美瞳到期提醒 */}
      <section className="section">
        <div className="card card-pad">
          <div style={{ display: 'flex', alignItems: 'center', gap: 10 }}>
            <span className="lead" style={{ background: 'var(--mm-pink-soft)', color: 'var(--mm-pink-strong)' }}>
              <Sparkles size={16} />
            </span>
            <div style={{ flex: 1 }}>
              <div style={{ fontWeight: 620 }}>美瞳到期提醒</div>
            </div>
            <Switch
              checked={lensSetting?.isActive ?? true}
              aria-label="美瞳到期提醒"
              disabled={!lensSetting}
              onCheckedChange={(checked) => {
                if (!lensSetting) return
                setLensSetting({ ...lensSetting, isActive: checked })
              }}
            />
          </div>

          <div style={{ marginTop: 14 }}>
            <SegmentedControl
              label="提前天数"
              fullWidth
              value={String(lensSetting?.advanceDays ?? 3)}
              onValueChange={(value) => {
                if (!lensSetting) return
                setLensSetting({ ...lensSetting, advanceDays: Number(value) })
              }}
              options={[
                { value: '1', label: '1 天' },
                { value: '3', label: '3 天' },
                { value: '7', label: '7 天' },
              ]}
            />
          </div>

          <div style={{ marginTop: 14 }} className="arc-field">
            <TimeWheelPicker
              label="提醒时间"
              value={lensSetting?.reminderTime ?? '09:00'}
              onChange={(value) => {
                if (!lensSetting) return
                setLensSetting({ ...lensSetting, reminderTime: value })
              }}
            />
          </div>

          <Button
            variant="secondary"
            style={{ marginTop: 14, width: '100%' }}
            loading={busy === 'lens'}
            onClick={saveLens}
          >
            保存设置
          </Button>
        </div>
      </section>

      {/* B. 护理液更换提醒 */}
      <section className="section">
        <div className="card card-pad">
          <div style={{ display: 'flex', alignItems: 'center', gap: 10 }}>
            <span className="lead" style={{ background: '#eaf2fb', color: '#4a7fb5' }}>
              <Droplets size={16} />
            </span>
            <div style={{ flex: 1 }}>
              <div style={{ fontWeight: 620 }}>护理液更换提醒</div>
            </div>
            <Switch
              checked={care?.change.isActive ?? true}
              aria-label="护理液更换提醒"
              disabled={!care}
              onCheckedChange={(checked) => {
                if (!care) return
                setCare({ ...care, change: { ...care.change, isActive: checked } })
              }}
            />
          </div>

          <div style={{ marginTop: 14 }} className="arc-field">
            <Select
              label="更换频率"
              value={care?.change.frequency ?? 'every_3_days'}
              placeholder="选择频率"
              onValueChange={(value) => {
                if (!care) return
                const preset = FREQUENCY_OPTIONS.find((item) => item.value === value)
                setCare({ ...care, change: { ...care.change, frequency: value } })
                if (preset && preset.days > 0) setCustomDays(String(preset.days))
              }}
              options={FREQUENCY_OPTIONS.map((item) => ({ value: item.value, label: item.label }))}
            />
          </div>

          {care?.change.frequency === 'custom' ? (
            <div style={{ marginTop: 12 }}>
              <Input
                label="自定义间隔（天）"
                type="number"
                min="1"
                max="365"
                value={customDays}
                onChange={(event) => {
                  setCustomDays(event.target.value)
                }}
              />
            </div>
          ) : null}

          <div style={{ marginTop: 12 }} className="arc-field">
            <TimeWheelPicker
              label="提醒时间"
              value={care?.change.reminderTime ?? '09:00'}
              onChange={(value) => {
                if (!care) return
                setCare({ ...care, change: { ...care.change, reminderTime: value } })
              }}
            />
          </div>

          <div className="kv" style={{ padding: '12px 0 0' }}>
            <span className="kv-key">上次更换</span>
            <span className="kv-value">
              {care?.change.lastChangedDate ? formatDate(care.change.lastChangedDate) : '未记录'}
            </span>
          </div>
          <div className="kv" style={{ padding: '10px 0 0' }}>
            <span className="kv-key">下次更换</span>
            <span
              className="kv-value"
              style={{
                color:
                  care?.change.daysUntilNext !== null &&
                  care?.change.daysUntilNext !== undefined &&
                  care.change.daysUntilNext < 0
                    ? 'var(--mm-danger)'
                    : undefined,
              }}
            >
              {care?.change.nextChangedDate
                ? `${formatDate(care.change.nextChangedDate)}${
                    care.change.daysUntilNext !== null
                      ? care.change.daysUntilNext < 0
                        ? `（已逾期 ${Math.abs(care.change.daysUntilNext)} 天）`
                        : care.change.daysUntilNext === 0
                          ? '（今天）'
                          : `（${care.change.daysUntilNext} 天后）`
                      : ''
                  }`
                : '需先记录一次更换'}
            </span>
          </div>

          <div style={{ display: 'flex', gap: 10, marginTop: 14 }}>
            <Button
              variant="secondary"
              style={{ flex: 1 }}
              loading={busy === 'change'}
              onClick={saveChange}
            >
              保存设置
            </Button>
            <Button style={{ flex: 1 }} onClick={() => setChangeDialog(true)} disabled={!care}>
              已更换护理液
            </Button>
          </div>
        </div>
      </section>

      {/* C. 护理液到期提醒 */}
      <section className="section">
        <div className="card card-pad">
          <div style={{ display: 'flex', alignItems: 'center', gap: 10 }}>
            <span className="lead" style={{ background: 'var(--mm-warning-soft)', color: 'var(--mm-warning)' }}>
              <Timer size={16} />
            </span>
            <div style={{ flex: 1 }}>
              <div style={{ fontWeight: 620 }}>护理液到期提醒</div>
            </div>
            <Switch
              checked={care?.expiry.isActive ?? true}
              aria-label="护理液到期提醒"
              disabled={!care}
              onCheckedChange={(checked) => {
                if (!care) return
                setCare({ ...care, expiry: { ...care.expiry, isActive: checked } })
              }}
            />
          </div>

          <div style={{ marginTop: 14 }}>
            <SegmentedControl
              label="提前天数"
              fullWidth
              value={String(care?.expiry.advanceDays ?? 3)}
              onValueChange={(value) => {
                if (!care) return
                setCare({ ...care, expiry: { ...care.expiry, advanceDays: Number(value) } })
              }}
              options={[
                { value: '1', label: '1 天' },
                { value: '3', label: '3 天' },
                { value: '7', label: '7 天' },
              ]}
            />
          </div>

          <div style={{ marginTop: 14 }} className="arc-field">
            <TimeWheelPicker
              label="提醒时间"
              value={care?.expiry.reminderTime ?? '09:00'}
              onChange={(value) => {
                if (!care) return
                setCare({ ...care, expiry: { ...care.expiry, reminderTime: value } })
              }}
            />
          </div>

          <div style={{ display: 'flex', gap: 10, marginTop: 14 }}>
            <Button
              variant="secondary"
              style={{ flex: 1 }}
              loading={busy === 'expiry'}
              onClick={saveExpiry}
            >
              保存设置
            </Button>
            <Button variant="ghost" style={{ flex: 1 }} onClick={() => push({ name: 'care' })}>
              护理液信息
            </Button>
          </div>

          {care?.bottle ? (
            <p className="muted" style={{ marginTop: 10 }}>
              当前护理液：{care.bottle.brand} {care.bottle.name}，到期日{' '}
              {care.bottle.expiryDate ? formatDate(care.bottle.expiryDate) : '未填写'}
            </p>
          ) : (
            <div className="notice" style={{ marginTop: 12 }}>
              尚未填写护理液信息，无法计算到期日。请先在「护理液信息」中补充包装有效期或开封后有效天数。
            </div>
          )}
        </div>
      </section>

      {/* 用底部弹层而不是居中弹窗：日期日历向上展开，不会被窗口边缘裁切 */}
      <BottomSheet
        open={changeDialog}
        onOpenChange={setChangeDialog}
        title="记录本次更换"
        detents={[0.52, 0.92]}
        initialDetent={0}
        closeLabel="关闭"
      >
        <div>
          <div className="field-label">更换日期</div>
          <button type="button" className="sheet-field" onClick={() => setCalendarOpen(true)}>
            <CalendarDays size={16} strokeWidth={1.8} />
            <span>{formatDate(dateToISO(changedDate))}</span>
            <ChevronDown size={16} strokeWidth={1.8} style={{ marginLeft: 'auto', color: 'var(--mm-ink-3)' }} />
          </button>
        </div>
        <div style={{ marginTop: 12 }}>
          <Textarea
            label="备注"
            value={changedNote}
            onChange={(event) => setChangedNote(event.target.value)}
            rows={2}
            placeholder="例如：换了新的护理液（可选）"
          />
        </div>
        <div style={{ display: 'flex', gap: 10, marginTop: 16, marginBottom: 8 }}>
          <Button variant="secondary" style={{ flex: 1 }} onClick={() => setChangeDialog(false)}>
            取消
          </Button>
          <Button style={{ flex: 1.4 }} loading={busy === 'mark'} onClick={markChanged}>
            确认更换
          </Button>
        </div>
      </BottomSheet>

      <Dialog open={calendarOpen} onOpenChange={setCalendarOpen}>
        <DialogContent title="选择更换日期" description="不能晚于今天">
          <div style={{ display: 'flex', justifyContent: 'center', marginTop: 8 }}>
            <Calendar
              value={changedDate}
              onChange={(next) => {
                setChangedDate(next)
                setCalendarOpen(false)
              }}
              locale="zh-CN"
              maxDate={new Date()}
            />
          </div>
          <div style={{ display: 'flex', justifyContent: 'center', marginTop: 8 }}>
            <Button
              variant="secondary"
              onClick={() => {
                setChangedDate(isoToDate(todayISO()))
                setCalendarOpen(false)
              }}
            >
              选择今天
            </Button>
          </div>
        </DialogContent>
      </Dialog>
    </Page>
  )
}
