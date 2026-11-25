import { useCallback, useEffect, useMemo, useState } from 'react'
import { Pencil, Plus, Trash2 } from 'lucide-react'
import { Page } from '@/components/Page'
import { Button } from '@/components/arc/button/button'
import { Dialog, DialogContent } from '@/components/arc/dialog/dialog'
import { Input } from '@/components/arc/input/input'
import { Select } from '@/components/arc/select/select'
import { ConfirmDialog } from '@/components/ConfirmDialog'
import { useToast } from '@/components/ToastProvider'
import { useNav } from '@/app/navigation'
import { api } from '@/lib/api'
import { cycleText } from '@/lib/format'
import type { Cycle, CycleUnit } from '@/lib/types'

const UNIT_OPTIONS = [
  { value: 'day', label: '天' },
  { value: 'week', label: '周' },
  { value: 'month', label: '月' },
  { value: 'year', label: '年' },
]

export function CyclePage() {
  const { refresh, version } = useNav()
  const toast = useToast()
  const [cycles, setCycles] = useState<Cycle[]>([])
  const [error, setError] = useState<string | null>(null)
  const [loading, setLoading] = useState(true)

  const [dialogOpen, setDialogOpen] = useState(false)
  const [dialogError, setDialogError] = useState<string | null>(null)
  const [editingId, setEditingId] = useState<number | null>(null)
  const [name, setName] = useState('')
  const [unit, setUnit] = useState<CycleUnit>('day')
  const [value, setValue] = useState('10')
  const [busy, setBusy] = useState(false)
  const [deleteId, setDeleteId] = useState<number | null>(null)

  const load = useCallback(() => {
    setLoading(true)
    api
      .listCycles()
      .then((data) => {
        setCycles(data)
        setError(null)
      })
      .catch((err: Error) => setError(err.message))
      .finally(() => setLoading(false))
  }, [])

  useEffect(() => {
    load()
  }, [load, version])

  const builtin = useMemo(() => cycles.filter((cycle) => cycle.isBuiltin), [cycles])
  const custom = useMemo(() => cycles.filter((cycle) => !cycle.isBuiltin), [cycles])

  const openCreate = () => {
    setEditingId(null)
    setName('')
    setUnit('day')
    setValue('10')
    setDialogError(null)
    setDialogOpen(true)
  }

  const openEdit = (cycle: Cycle) => {
    setEditingId(cycle.id)
    setName(cycle.cycleName)
    setUnit(cycle.cycleUnit)
    setValue(String(cycle.cycleValue))
    setDialogError(null)
    setDialogOpen(true)
  }

  const submit = async () => {
    const numeric = Number(value)
    // 校验错误留在弹窗内，不再甩到页面顶部
    if (!name.trim()) {
      setDialogError('请填写周期名称')
      return
    }
    if (!Number.isInteger(numeric) || numeric <= 0) {
      setDialogError('周期数值必须是正整数')
      return
    }
    setBusy(true)
    try {
      const payload = { cycleName: name.trim(), cycleUnit: unit, cycleValue: numeric }
      if (editingId) {
        await api.updateCycle(editingId, payload)
        toast('周期已更新')
      } else {
        await api.createCycle(payload)
        toast('周期已创建')
      }
      setDialogOpen(false)
      load()
      refresh()
    } catch (err) {
      setDialogError((err as Error).message)
    } finally {
      setBusy(false)
    }
  }

  const remove = async () => {
    if (!deleteId) return
    setBusy(true)
    try {
      await api.deleteCycle(deleteId)
      setDeleteId(null)
      toast('周期已删除')
      load()
      refresh()
    } catch (err) {
      setError((err as Error).message)
      setDeleteId(null)
    } finally {
      setBusy(false)
    }
  }

  return (
    <Page
      title="周期管理"
      actions={
        <button className="icon-button" aria-label="新建周期" onClick={openCreate}>
          <Plus size={20} />
        </button>
      }
    >
      {error ? (
        <div className="error-box" style={{ marginBottom: 12 }}>
          {error}
        </div>
      ) : null}

      {loading ? (
        <div className="skeleton" style={{ height: 240 }} />
      ) : (
        <>
          {/* 内置周期：只读，紧凑两列网格 */}
          <section className="section">
            <div className="section-head">
              <h2>内置周期</h2>
              <span className="cycle-count">{builtin.length} 个</span>
            </div>
            <div className="cycle-grid">
              {builtin.map((cycle) => (
                <div className="cycle-chip" key={cycle.id}>
                  <span className="cycle-chip-name">{cycle.cycleName}</span>
                  <span className="cycle-chip-meta">
                    {cycleText(cycle.cycleUnit, cycle.cycleValue)}
                    {cycle.lensCount > 0 ? ` · ${cycle.lensCount} 副在用` : ''}
                  </span>
                </div>
              ))}
            </div>
          </section>

          {/* 自定义周期：可编辑、可删除 */}
          <section className="section">
            <div className="section-head">
              <h2>自定义周期</h2>
            </div>

            {custom.length === 0 ? (
              <button
                type="button"
                className="cycle-empty-add"
                onClick={openCreate}
                aria-label="新建自定义周期"
              >
                <span className="cycle-empty-icon">
                  <Plus size={16} />
                </span>
                <span>
                  <span style={{ display: 'block', fontSize: 14, fontWeight: 600 }}>
                    还没有自定义周期
                  </span>
                  <span style={{ display: 'block', fontSize: 12, color: 'var(--mm-ink-3)', marginTop: 1 }}>
                    点击这里新建一个
                  </span>
                </span>
              </button>
            ) : (
              <div className="card">
                <div className="list">
                  {custom.map((cycle) => (
                    <div className="cycle-row" key={cycle.id}>
                      <div className="cycle-row-main">
                        <div className="cycle-row-title">{cycle.cycleName}</div>
                        <div className="cycle-row-meta">
                          {cycleText(cycle.cycleUnit, cycle.cycleValue)}
                          {cycle.lensCount > 0 ? ` · ${cycle.lensCount} 副在用` : ''}
                        </div>
                      </div>
                      <button
                        className="icon-button"
                        aria-label="编辑周期"
                        onClick={() => openEdit(cycle)}
                      >
                        <Pencil size={15} strokeWidth={1.8} />
                      </button>
                      <button
                        className="icon-button"
                        aria-label="删除周期"
                        style={{ color: 'var(--mm-danger)' }}
                        onClick={() => setDeleteId(cycle.id)}
                      >
                        <Trash2 size={15} strokeWidth={1.8} />
                      </button>
                    </div>
                  ))}
                </div>
              </div>
            )}
          </section>
        </>
      )}

      <Dialog open={dialogOpen} onOpenChange={setDialogOpen}>
        <DialogContent
          title={editingId ? '编辑周期' : '新建周期'}
          description="周期用于开封后计算到期日，月与年按自然日历推进"
        >
          <div className="form-grid-2" style={{ marginTop: 14 }}>
            <Input
              label="周期名称"
              value={name}
              onChange={(event) => setName(event.target.value)}
              placeholder="如 10 天抛"
              maxLength={20}
            />
            <div className="arc-field">
              <Select
                label="单位"
                value={unit}
                onValueChange={(next) => setUnit(next as CycleUnit)}
                options={UNIT_OPTIONS}
                placeholder="选择单位"
              />
            </div>
          </div>
          <div style={{ marginTop: 12 }}>
            <Input
              label="数值"
              type="number"
              min="1"
              max="999"
              value={value}
              onChange={(event) => setValue(event.target.value)}
              placeholder="如 10"
            />
          </div>

          {dialogError ? (
            <div className="error-box" style={{ marginTop: 12 }}>
              {dialogError}
            </div>
          ) : null}

          <div style={{ display: 'flex', gap: 10, marginTop: 18 }}>
            <Button variant="secondary" style={{ flex: 1 }} onClick={() => setDialogOpen(false)}>
              取消
            </Button>
            <Button style={{ flex: 1 }} loading={busy} onClick={submit}>
              保存
            </Button>
          </div>
        </DialogContent>
      </Dialog>

      <ConfirmDialog
        open={deleteId !== null}
        onOpenChange={(open) => !open && setDeleteId(null)}
        title="删除这个周期？"
        description="只有未被任何美瞳引用的自定义周期才能删除。删除后无法恢复。"
        confirmText="删除"
        danger
        busy={busy}
        onConfirm={remove}
      />
    </Page>
  )
}
